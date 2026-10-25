import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/subscription_repository.dart';
import 'auth_providers.dart';

final subscriptionRepositoryProvider = Provider<ISubscriptionRepository>((ref) {
  return SqliteSubscriptionRepository();
});

class UserSubscriptionsState {
  final Set<String> subscribedLeagueIds;
  final Set<String> subscribedTournamentIds;

  const UserSubscriptionsState({
    this.subscribedLeagueIds = const {},
    this.subscribedTournamentIds = const {},
  });

  UserSubscriptionsState copyWith({
    Set<String>? subscribedLeagueIds,
    Set<String>? subscribedTournamentIds,
  }) {
    return UserSubscriptionsState(
      subscribedLeagueIds: subscribedLeagueIds ?? this.subscribedLeagueIds,
      subscribedTournamentIds: subscribedTournamentIds ?? this.subscribedTournamentIds,
    );
  }
}

class UserSubscriptionsNotifier extends Notifier<UserSubscriptionsState> {
  @override
  UserSubscriptionsState build() {
    final user = ref.watch(currentUserProvider);
    final repo = ref.read(subscriptionRepositoryProvider);
    if (user != null && user.id.isNotEmpty) {
      _loadSubscriptions(user.id, repo);
    }
    return const UserSubscriptionsState();
  }

  Future<void> _loadSubscriptions(String userId, ISubscriptionRepository repo) async {
    try {
      final leagues = await repo.getSubscribedEntityIds(userId: userId, entityType: 'league');
      final tournaments = await repo.getSubscribedEntityIds(userId: userId, entityType: 'tournament');
      state = UserSubscriptionsState(
        subscribedLeagueIds: leagues,
        subscribedTournamentIds: tournaments,
      );
    } catch (_) {}
  }

  Future<void> toggleLeagueSubscription(String leagueId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(subscriptionRepositoryProvider);
    final currentLeagues = Set<String>.from(state.subscribedLeagueIds);

    if (currentLeagues.contains(leagueId)) {
      currentLeagues.remove(leagueId);
      state = state.copyWith(subscribedLeagueIds: currentLeagues);
      if (user != null) {
        await repo.removeSubscription(userId: user.id, entityType: 'league', entityId: leagueId);
      }
    } else {
      currentLeagues.add(leagueId);
      state = state.copyWith(subscribedLeagueIds: currentLeagues);
      if (user != null) {
        await repo.addSubscription(userId: user.id, entityType: 'league', entityId: leagueId);
      }
    }
  }

  Future<void> toggleTournamentSubscription(String tournamentId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(subscriptionRepositoryProvider);
    final currentTournaments = Set<String>.from(state.subscribedTournamentIds);

    if (currentTournaments.contains(tournamentId)) {
      currentTournaments.remove(tournamentId);
      state = state.copyWith(subscribedTournamentIds: currentTournaments);
      if (user != null) {
        await repo.removeSubscription(userId: user.id, entityType: 'tournament', entityId: tournamentId);
      }
    } else {
      currentTournaments.add(tournamentId);
      state = state.copyWith(subscribedTournamentIds: currentTournaments);
      if (user != null) {
        await repo.addSubscription(userId: user.id, entityType: 'tournament', entityId: tournamentId);
      }
    }
  }

  bool isLeagueSubscribed(String leagueId) => state.subscribedLeagueIds.contains(leagueId);
  bool isTournamentSubscribed(String tournamentId) => state.subscribedTournamentIds.contains(tournamentId);
}

final userSubscriptionsProvider = NotifierProvider<UserSubscriptionsNotifier, UserSubscriptionsState>(
  UserSubscriptionsNotifier.new,
);

final userSubscribedLeagueIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(userSubscriptionsProvider).subscribedLeagueIds;
});

final userSubscribedTournamentIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(userSubscriptionsProvider).subscribedTournamentIds;
});
