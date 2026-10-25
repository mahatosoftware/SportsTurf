import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/subscription_providers.dart';
import '../models/tournament.dart';
import '../models/match.dart';

final tournamentsListProvider = StreamProvider<List<Tournament>>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchTournaments();
});

final publicTournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchPublicTournaments();
});

/// Tournaments that the current user created, is an assigned official for, participates in, or has subscribed to.
final myTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final tournamentsAsync = ref.watch(tournamentsListProvider);
  final user = ref.watch(currentUserProvider);
  final subTournaments = ref.watch(userSubscribedTournamentIdsProvider);

  return tournamentsAsync.whenData((tournaments) {
    if (user == null) {
      return tournaments.where((t) => subTournaments.contains(t.id)).toList();
    }
    final uid = user.id;
    return tournaments.where((t) {
      final isCreator = t.creatorId == uid;
      final isOfficial = t.managerUserIds.contains(uid) ||
          t.refereeUserIds.contains(uid) ||
          t.scorerUserIds.contains(uid) ||
          t.venueManagerIds.contains(uid);
      final isParticipant = t.participantUserIds.contains(uid);
      final isSubscribed = subTournaments.contains(t.id);
      return isCreator || isOfficial || isParticipant || isSubscribed;
    }).toList();
  });
});

final singleTournamentProvider = StreamProvider.family<Tournament?, String>((ref, id) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchTournament(id);
});

class TournamentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createTournament(Tournament tournament) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.saveTournament(tournament);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTournament(Tournament tournament) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.saveTournament(tournament);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Tournament?> findTournamentByCode(String code) async {
    final repository = ref.read(tournamentRepositoryProvider);
    return repository.getTournamentByShareCode(code);
  }

  Future<void> updateMatchScore({
    required String tournamentId,
    required String matchId,
    required int scoreA,
    required int scoreB,
    String? winnerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.updateMatchScore(tournamentId, matchId, scoreA, scoreB, winnerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMatchStatus({
    required String tournamentId,
    required String matchId,
    required MatchStatus status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.updateMatchStatus(tournamentId, matchId, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTournament(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.deleteTournament(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final tournamentControllerProvider = NotifierProvider<TournamentController, AsyncValue<void>>(
  TournamentController.new,
);
