import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/subscription_providers.dart';
import '../../tournament/models/tournament.dart';
import '../models/league.dart';

final leaguesListProvider = StreamProvider<List<League>>((ref) {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.watchLeagues();
});

final publicLeaguesProvider = StreamProvider<List<League>>((ref) {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.watchPublicLeagues();
});

/// Leagues that the current user has created, manages, or is subscribed to.
final myLeaguesProvider = Provider<AsyncValue<List<League>>>((ref) {
  final leaguesAsync = ref.watch(leaguesListProvider);
  final user = ref.watch(currentUserProvider);
  final subLeagues = ref.watch(userSubscribedLeagueIdsProvider);

  return leaguesAsync.whenData((leagues) {
    if (user == null) {
      return leagues.where((l) => subLeagues.contains(l.id)).toList();
    }
    final uid = user.id;
    return leagues.where((l) {
      final isCreator = l.creatorId == uid || l.ownerIds.contains(uid);
      final isStaff = l.adminUserIds.contains(uid) ||
          l.registrationManagerIds.contains(uid) ||
          l.financeManagerIds.contains(uid) ||
          l.mediaManagerIds.contains(uid);
      final isSubscribed = subLeagues.contains(l.id);
      return isCreator || isStaff || isSubscribed;
    }).toList();
  });
});

final singleLeagueProvider = StreamProvider.family<League?, String>((ref, id) {
  final repository = ref.watch(leagueRepositoryProvider);
  return repository.watchLeague(id);
});

final leagueTournamentsProvider = StreamProvider.family<List<Tournament>, String>((ref, leagueId) {
  final tournamentRepo = ref.watch(tournamentRepositoryProvider);
  return tournamentRepo.watchTournamentsByLeague(leagueId);
});

class LeagueController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createLeague(League league) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(leagueRepositoryProvider);
      await repository.saveLeague(league);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateLeague(League league) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(leagueRepositoryProvider);
      await repository.saveLeague(league);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteLeague(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(leagueRepositoryProvider);
      await repository.deleteLeague(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<League?> findLeagueByCode(String code) async {
    final repository = ref.read(leagueRepositoryProvider);
    return repository.getLeagueByShareCode(code);
  }

  Future<void> addTournamentToLeague(String leagueId, String tournamentId) async {
    try {
      final repository = ref.read(leagueRepositoryProvider);
      await repository.addTournamentToLeague(leagueId, tournamentId);
    } catch (e) {
      // Non-blocking
    }
  }

  Future<void> removeTournamentFromLeague(String leagueId, String tournamentId) async {
    try {
      final repository = ref.read(leagueRepositoryProvider);
      await repository.removeTournamentFromLeague(leagueId, tournamentId);
    } catch (e) {
      // Non-blocking
    }
  }
}

final leagueControllerProvider =
    NotifierProvider<LeagueController, AsyncValue<void>>(() {
  return LeagueController();
});
