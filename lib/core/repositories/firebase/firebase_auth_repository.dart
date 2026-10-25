import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../firebase_options.dart';
import '../../models/app_user.dart';
import '../auth_repository.dart';

/// Production-ready Firebase Authentication Repository.
/// Uses live Firebase Auth and Google Sign-In SDKs.
class FirebaseAuthRepository implements IAuthRepository {
  final fb.FirebaseAuth? _injectedAuth;

  FirebaseAuthRepository({fb.FirebaseAuth? auth}) : _injectedAuth = auth;

  bool get _isFirebaseInitialized => _injectedAuth != null || Firebase.apps.isNotEmpty;
  fb.FirebaseAuth? get _auth => _injectedAuth ?? (_isFirebaseInitialized ? fb.FirebaseAuth.instance : null);

  void initialize() {
    // Streams hook directly into Firebase Auth
  }

  @override
  AppUser? get currentUser {
    if (_auth != null) {
      final fbUser = _auth!.currentUser;
      return fbUser != null ? _mapFirebaseUser(fbUser) : null;
    }
    return null;
  }

  @override
  Stream<AppUser?> get authStateChanges {
    if (_auth != null) {
      return _auth!.authStateChanges().map((fbUser) => fbUser != null ? _mapFirebaseUser(fbUser) : null);
    }
    return const Stream.empty();
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your device is connected and Firebase is configured.');
    }
    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed: no user returned.');
      }
      return _mapFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your device is connected and Firebase is configured.');
    }
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Account creation failed: no user returned.');
      }
      if (displayName.trim().isNotEmpty) {
        await fbUser.updateDisplayName(displayName.trim());
        await fbUser.reload();
      }
      final updatedUser = _auth!.currentUser ?? fbUser;
      return _mapFirebaseUser(updatedUser);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: DefaultFirebaseOptions.serverClientId,
        );
        _googleSignInInitialized = true;
      } catch (_) {
        _googleSignInInitialized = true;
      }
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your device is connected and Firebase is configured.');
    }
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google Sign-In failed: missing ID Token.');
      }

      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google Sign-In failed: no user returned.');
      }
      return _mapFirebaseUser(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign-in was cancelled.');
      }
      throw Exception('Google sign-in failed: ${e.description ?? e.code.name}');
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<AppUser> signInAnonymously() async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your device is connected and Firebase is configured.');
    }
    try {
      final userCredential = await _auth!.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Anonymous sign in failed.');
      }
      return _mapFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not initialized. Please ensure your device is connected and Firebase is configured.');
    }
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_isFirebaseInitialized && _auth != null) {
        await Future.wait([
          _auth!.signOut(),
          GoogleSignIn.instance.signOut(),
        ]);
      }
    } catch (_) {}
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (!_isFirebaseInitialized || _auth == null || _auth!.currentUser == null) {
      throw Exception('No authenticated user found.');
    }
    if (displayName != null) await _auth!.currentUser!.updateDisplayName(displayName.trim());
    if (photoUrl != null) await _auth!.currentUser!.updatePhotoURL(photoUrl.trim());
    await _auth!.currentUser!.reload();
  }

  AppUser _mapFirebaseUser(fb.User fbUser) {
    String provider = 'password';
    for (final info in fbUser.providerData) {
      if (info.providerId == 'google.com') {
        provider = 'google';
        break;
      }
    }
    if (fbUser.isAnonymous) {
      provider = 'anonymous';
    }

    return AppUser(
      id: fbUser.uid,
      email: fbUser.email,
      displayName: fbUser.displayName,
      photoUrl: fbUser.photoURL,
      isAnonymous: fbUser.isAnonymous,
      authProvider: provider,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  String _handleFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed: ${e.code}';
    }
  }
}
