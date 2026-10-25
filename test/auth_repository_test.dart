import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/app_user.dart';
import 'package:sports_turf/core/repositories/auth_repository.dart';
import 'package:sports_turf/core/repositories/firebase/firebase_auth_repository.dart';
import 'package:sports_turf/core/providers/auth_providers.dart';

/// Test implementation of IAuthRepository for in-memory / unit testing
class MockAuthRepository implements IAuthRepository {
  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signInWithEmailAndPassword({required String email, required String password}) async {
    final user = AppUser(
      id: 'test_user_id',
      email: email,
      displayName: email.split('@').first,
      authProvider: 'password',
      createdAt: DateTime.now(),
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = AppUser(
      id: 'test_user_id',
      email: email,
      displayName: displayName,
      authProvider: 'password',
      createdAt: DateTime.now(),
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final user = AppUser(
      id: 'google_user_id',
      email: 'test@gmail.com',
      displayName: 'Google Player',
      authProvider: 'google',
      createdAt: DateTime.now(),
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    throw UnimplementedError('Anonymous sign in disabled in production');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (_user != null) {
      _user = _user!.copyWith(displayName: displayName, photoUrl: photoUrl);
      _controller.add(_user);
    }
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Authentication & User Model Tests', () {
    test('AppUser model handles initials and displayTitle correctly', () {
      final userWithFullname = AppUser(
        id: 'u1',
        email: 'alex.morgan@test.com',
        displayName: 'Alex Morgan',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(userWithFullname.initials, 'AM');
      expect(userWithFullname.displayTitle, 'Alex Morgan');

      final userWithEmailOnly = AppUser(
        id: 'u2',
        email: 'ronaldo@sports.com',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(userWithEmailOnly.initials, 'R');
      expect(userWithEmailOnly.displayTitle, 'ronaldo');

      final userWithoutName = AppUser(
        id: 'u3',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(userWithoutName.initials, 'U');
      expect(userWithoutName.displayTitle, 'Sports Enthusiast');
    });

    test('AppUser serialization toMap and fromMap', () {
      final user = AppUser(
        id: 'uid123',
        email: 'player@sportsturf.app',
        displayName: 'John Doe',
        photoUrl: 'https://photo.url',
        isAnonymous: false,
        authProvider: 'google',
        createdAt: DateTime(2026, 5, 10),
      );

      final map = user.toMap();
      expect(map['id'], 'uid123');
      expect(map['email'], 'player@sportsturf.app');
      expect(map['authProvider'], 'google');

      final restored = AppUser.fromMap(map);
      expect(restored.id, user.id);
      expect(restored.displayName, user.displayName);
      expect(restored.authProvider, 'google');
    });

    test('FirebaseAuthRepository throws without creating dummy users when uninitialized', () async {
      final repo = FirebaseAuthRepository();

      // Expect Exception and NO dummy user fallback
      expect(
        () => repo.signInWithEmailAndPassword(email: 'test@turf.com', password: '123'),
        throwsA(isA<Exception>()),
      );

      expect(
        () => repo.signUpWithEmailAndPassword(email: 'test@turf.com', password: '123', displayName: 'Test'),
        throwsA(isA<Exception>()),
      );

      expect(
        () => repo.signInWithGoogle(),
        throwsA(isA<Exception>()),
      );

      // Verify currentUser is null and not a dummy user
      expect(repo.currentUser, isNull);
    });

    test('AuthController manages state transitions using repository', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(() {
        mockRepo.dispose();
        container.dispose();
      });

      // Initial state is null
      expect(container.read(currentUserProvider), isNull);

      // Sign Up
      await container.read(authControllerProvider.notifier).signUpWithEmailAndPassword(
            email: 'organizer@turf.com',
            password: 'secretPassword',
            displayName: 'Head Coach',
          );

      expect(mockRepo.currentUser?.email, 'organizer@turf.com');
      expect(mockRepo.currentUser?.displayName, 'Head Coach');

      // Sign Out
      await container.read(authControllerProvider.notifier).signOut();
      expect(mockRepo.currentUser, isNull);

      // Google Sign In
      await container.read(authControllerProvider.notifier).signInWithGoogle();
      expect(mockRepo.currentUser?.authProvider, 'google');
      expect(mockRepo.currentUser?.email, 'test@gmail.com');
    });
  });
}
