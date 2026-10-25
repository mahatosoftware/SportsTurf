import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/app_user.dart';
import 'package:sports_turf/core/providers/auth_providers.dart';
import 'package:sports_turf/core/providers/repository_providers.dart';
import 'package:sports_turf/core/providers/subscription_providers.dart';
import 'package:sports_turf/core/repositories/league_repository.dart';
import 'package:sports_turf/core/repositories/subscription_repository.dart';
import 'package:sports_turf/core/repositories/tournament_repository.dart';
import 'package:sports_turf/features/league/models/league.dart';
import 'package:sports_turf/features/league/providers/league_providers.dart';
import 'package:sports_turf/features/tournament/models/match.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/providers/tournament_providers.dart';
import 'package:sports_turf/screens/home_screen.dart';

class MockSubscriptionRepo implements ISubscriptionRepository {
  final Map<String, Set<String>> storage = {};

  String _key(String userId, String entityType) => '$userId:$entityType';

  @override
  Future<Set<String>> getSubscribedEntityIds({
    required String userId,
    required String entityType,
  }) async {
    return storage[_key(userId, entityType)] ?? <String>{};
  }

  @override
  Future<void> addSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final key = _key(userId, entityType);
    final set = storage.putIfAbsent(key, () => <String>{});
    set.add(entityId);
  }

  @override
  Future<void> removeSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final key = _key(userId, entityType);
    storage[key]?.remove(entityId);
  }

  @override
  Future<bool> isSubscribed({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final set = storage[_key(userId, entityType)];
    return set?.contains(entityId) ?? false;
  }

  @override
  Future<void> clearUserSubscriptions(String userId) async {
    storage.remove(_key(userId, 'league'));
    storage.remove(_key(userId, 'tournament'));
  }
}

class MockLeagueRepo implements ILeagueRepository {
  final Map<String, League> leagues = {};

  @override
  Future<List<League>> getLeagues() async => leagues.values.toList();

  @override
  Future<League?> getLeagueById(String id) async => leagues[id];

  @override
  Future<League?> getLeagueByShareCode(String code) async {
    return leagues.values.cast<League?>().firstWhere(
      (l) => l?.shareCode == code,
      orElse: () => null,
    );
  }

  @override
  Future<void> saveLeague(League league) async {
    leagues[league.id] = league;
  }

  @override
  Future<void> deleteLeague(String id) async {
    leagues.remove(id);
  }

  @override
  Future<void> addTournamentToLeague(String leagueId, String tournamentId) async {}

  @override
  Future<void> removeTournamentFromLeague(String leagueId, String tournamentId) async {}

  @override
  Stream<League?> watchLeague(String id) => Stream.value(leagues[id]);

  @override
  Stream<List<League>> watchLeagues() => Stream.value(leagues.values.toList());

  @override
  Stream<List<League>> watchPublicLeagues() =>
      Stream.value(leagues.values.where((l) => l.isPublic).toList());
}

class MockTournamentRepo implements ITournamentRepository {
  final Map<String, Tournament> tournaments = {};

  @override
  Future<List<Tournament>> getTournaments({String? sport, TournamentStatus? status}) async =>
      tournaments.values.toList();

  @override
  Future<Tournament?> getTournamentById(String id) async => tournaments[id];

  @override
  Future<Tournament?> getTournamentByShareCode(String code) async {
    return tournaments.values.cast<Tournament?>().firstWhere(
      (t) => t?.shareCode == code,
      orElse: () => null,
    );
  }

  @override
  Future<List<Tournament>> getPublicTournaments({String? sport}) async =>
      tournaments.values.where((t) => t.isPublic).toList();

  @override
  Future<void> saveTournament(Tournament tournament) async {
    tournaments[tournament.id] = tournament;
  }

  @override
  Future<void> deleteTournament(String id) async {
    tournaments.remove(id);
  }

  @override
  Future<void> updateMatchScore(String tournamentId, String matchId, int scoreA, int scoreB, String? winnerId) async {}

  @override
  Future<void> updateMatchStatus(String tournamentId, String matchId, MatchStatus status) async {}

  @override
  Future<List<Tournament>> getTournamentsByLeague(String leagueId) async =>
      tournaments.values.where((t) => t.leagueId == leagueId).toList();

  @override
  Stream<List<Tournament>> watchTournaments({String? sport}) =>
      Stream.value(tournaments.values.toList());

  @override
  Stream<List<Tournament>> watchPublicTournaments({String? sport}) =>
      Stream.value(tournaments.values.where((t) => t.isPublic).toList());

  @override
  Stream<Tournament?> watchTournament(String id) => Stream.value(tournaments[id]);

  @override
  Stream<List<Tournament>> watchTournamentsByLeague(String leagueId) =>
      Stream.value(tournaments.values.where((t) => t.leagueId == leagueId).toList());
}

void main() {
  group('Subscription Repository & Scoping Tests', () {
    test('MockSubscriptionRepo correctly adds, queries, and removes subscriptions', () async {
      final repo = MockSubscriptionRepo();
      const userId = 'user_abc';

      expect(await repo.getSubscribedEntityIds(userId: userId, entityType: 'league'), isEmpty);

      await repo.addSubscription(userId: userId, entityType: 'league', entityId: 'league_10');
      expect(await repo.isSubscribed(userId: userId, entityType: 'league', entityId: 'league_10'), isTrue);
      expect(await repo.isSubscribed(userId: userId, entityType: 'league', entityId: 'league_99'), isFalse);

      await repo.removeSubscription(userId: userId, entityType: 'league', entityId: 'league_10');
      expect(await repo.isSubscribed(userId: userId, entityType: 'league', entityId: 'league_10'), isFalse);
    });

    test('Subscriptions are strictly scoped per user and do not leak to other users', () async {
      final repo = MockSubscriptionRepo();

      await repo.addSubscription(userId: 'user_1', entityType: 'league', entityId: 'league_premier');
      await repo.addSubscription(userId: 'user_1', entityType: 'tournament', entityId: 'tourn_cup');

      // User 2 logs in with a fresh account
      final user2Leagues = await repo.getSubscribedEntityIds(userId: 'user_2', entityType: 'league');
      final user2Tournaments = await repo.getSubscribedEntityIds(userId: 'user_2', entityType: 'tournament');

      expect(user2Leagues, isEmpty);
      expect(user2Tournaments, isEmpty);
    });
  });

  group('My Leagues & My Tournaments Provider Scoping', () {
    testWidgets('New user does not see other users leagues in myLeaguesProvider unless subscribed', (tester) async {
      final mockSubRepo = MockSubscriptionRepo();
      final mockLeagueRepo = MockLeagueRepo();

      // Another user created a league
      final otherLeague = League(
        id: 'league_others',
        name: 'Metropolitan Super League',
        creatorId: 'other_user_id',
        isPublic: true,
      );
      mockLeagueRepo.leagues[otherLeague.id] = otherLeague;

      final newUser = AppUser(
        id: 'new_user_123',
        email: 'newbie@sportsturf.in',
        displayName: 'New User',
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
          leagueRepositoryProvider.overrideWithValue(mockLeagueRepo),
          currentUserProvider.overrideWithValue(newUser),
        ],
      );
      addTearDown(container.dispose);

      container.listen(myLeaguesProvider, (_, _) {});
      await tester.pump(const Duration(milliseconds: 50));

      final myLeagues = container.read(myLeaguesProvider).value;
      expect(myLeagues, isEmpty);

      // Now new user subscribes to the league
      await container.read(userSubscriptionsProvider.notifier).toggleLeagueSubscription('league_others');
      await tester.pump(const Duration(milliseconds: 50));

      final updatedLeagues = container.read(myLeaguesProvider).value;
      expect(updatedLeagues?.length, 1);
      expect(updatedLeagues?.first.name, 'Metropolitan Super League');
    });

    testWidgets('New user does not see other users tournaments in myTournamentsProvider unless subscribed', (tester) async {
      final mockSubRepo = MockSubscriptionRepo();
      final mockTournamentRepo = MockTournamentRepo();

      final otherTournament = Tournament(
        id: 'tourn_others',
        name: 'Winter Badminton Open',
        sportType: 'Badminton',
        format: TournamentFormat.singleElimination,
        participants: [],
        matches: [],
        creatorId: 'creator_999',
        isPublic: true,
      );
      mockTournamentRepo.tournaments[otherTournament.id] = otherTournament;

      final newUser = AppUser(
        id: 'new_user_456',
        email: 'player@sportsturf.in',
        displayName: 'Tennis Player',
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          currentUserProvider.overrideWithValue(newUser),
        ],
      );
      addTearDown(container.dispose);

      container.listen(myTournamentsProvider, (_, _) {});
      await tester.pump(const Duration(milliseconds: 50));

      final myTournaments = container.read(myTournamentsProvider).value;
      expect(myTournaments, isEmpty);

      // User subscribes to the tournament
      await container.read(userSubscriptionsProvider.notifier).toggleTournamentSubscription('tourn_others');
      await tester.pump(const Duration(milliseconds: 50));

      final updatedTournaments = container.read(myTournamentsProvider).value;
      expect(updatedTournaments?.length, 1);
      expect(updatedTournaments?.first.name, 'Winter Badminton Open');
    });
  });

  group('HomeScreen Subscription UI Widget Tests', () {
    testWidgets('New user sees empty states on My Leagues and My Tournaments, and can subscribe from Discover Public', (tester) async {
      final mockSubRepo = MockSubscriptionRepo();
      final mockLeagueRepo = MockLeagueRepo();
      final mockTournamentRepo = MockTournamentRepo();

      // Pre-populate with another organization's league and tournament
      mockLeagueRepo.leagues['league_city'] = League(
        id: 'league_city',
        name: 'City Premier League',
        creatorId: 'org_admin',
        isPublic: true,
      );

      mockTournamentRepo.tournaments['tourn_city'] = Tournament(
        id: 'tourn_city',
        name: 'City Cup 2026',
        sportType: 'Cricket',
        format: TournamentFormat.roundRobin,
        participants: [],
        matches: [],
        creatorId: 'org_admin',
        isPublic: true,
        status: TournamentStatus.inProgress,
      );

      final newUser = AppUser(
        id: 'newly_registered_user',
        email: 'brand_new@sportsturf.in',
        displayName: 'Fresh Member',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            leagueRepositoryProvider.overrideWithValue(mockLeagueRepo),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            currentUserProvider.overrideWithValue(newUser),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. By default, "My Leagues" is selected, and it shows the empty card (not someone else's league!)
      expect(find.text('No Subscribed Leagues Yet'), findsOneWidget);
      expect(find.text('City Premier League'), findsNothing);

      // 2. By default, "My Tournaments" is selected, and it shows the empty card (not someone else's tournament!)
      expect(find.text('No Subscribed Tournaments'), findsOneWidget);
      expect(find.text('City Cup 2026'), findsNothing);

      // 3. Switch Leagues to "Discover Public"
      await tester.tap(find.text('Discover Public'));
      await tester.pumpAndSettle();

      // Now "City Premier League" appears under public discover
      expect(find.text('City Premier League'), findsOneWidget);

      // 4. Tap the bookmark button on City Premier League to subscribe
      final bookmarkIcon = find.byIcon(Icons.bookmark_border).first;
      await tester.tap(bookmarkIcon);
      await tester.pumpAndSettle();

      // 5. Switch back to "My Leagues"
      await tester.tap(find.text('My Leagues'));
      await tester.pumpAndSettle();

      // Now City Premier League is subscribed and shows in My Leagues!
      expect(find.text('City Premier League'), findsOneWidget);
      expect(find.text('No Subscribed Leagues Yet'), findsNothing);
    });
  });
}
