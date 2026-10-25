import '../models/app_user.dart';

abstract class IAuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInAnonymously();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<void> updateProfile({String? displayName, String? photoUrl});
}
