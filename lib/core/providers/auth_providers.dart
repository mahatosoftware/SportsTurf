import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firestore/firestore_league_repository.dart';
import '../repositories/firestore/firestore_tournament_repository.dart';
import '../repositories/firestore/firestore_team_repository.dart';
import 'repository_providers.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final repo = FirebaseAuthRepository();
  repo.initialize();
  return repo;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.value ?? ref.watch(authRepositoryProvider).currentUser;
});

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    final initial = ref.watch(currentUserProvider);
    return AsyncValue.data(initial);
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmailAndPassword(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInAnonymously();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(email);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      try {
        final leagueRepo = ref.read(leagueRepositoryProvider);
        if (leagueRepo is FirestoreLeagueRepository) leagueRepo.clearFallback();
        final tournamentRepo = ref.read(tournamentRepositoryProvider);
        if (tournamentRepo is FirestoreTournamentRepository) tournamentRepo.clearFallback();
        final teamRepo = ref.read(teamRepositoryProvider);
        if (teamRepo is FirestoreTeamRepository) teamRepo.clearFallback();
      } catch (_) {}
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<AppUser?>>(
  AuthController.new,
);
