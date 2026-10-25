import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/app_user.dart';
import 'package:sports_turf/core/providers/auth_providers.dart';
import 'package:sports_turf/core/providers/repository_providers.dart';
import 'package:sports_turf/core/providers/subscription_providers.dart';
import 'package:sports_turf/core/repositories/league_repository.dart';
import 'package:sports_turf/core/repositories/subscription_repository.dart';
import 'package:sports_turf/core/repositories/team_repository.dart';
import 'package:sports_turf/core/repositories/tournament_repository.dart';
import 'package:sports_turf/core/repositories/venue_repository.dart';
import 'package:sports_turf/features/league/models/league.dart';
import 'package:sports_turf/features/league/ui/league_dashboard_screen.dart';
import 'package:sports_turf/features/teams/ui/teams_screen.dart';
import 'package:sports_turf/features/tournament/models/match.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/ui/tournament_dashboard_screen.dart';
import 'package:sports_turf/features/venue/models/venue.dart';
import 'package:sports_turf/features/venue/ui/venue_management_screen.dart';

class MockTournamentRepo implements ITournamentRepository {
  final Map<String, Tournament> tournaments = {};

  @override
  Future<List<Tournament>> getTournaments({String? sport, TournamentStatus? status}) async =>
      tournaments.values.toList();

  @override
  Future<Tournament?> getTournamentById(String id) async => tournaments[id];

  @override
  Future<Tournament?> getTournamentByShareCode(String code) async =>
      tournaments.values.cast<Tournament?>().firstWhere((t) => t?.shareCode == code, orElse: () => null);

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
  Stream<Tournament?> watchTournament(String id) => Stream.value(tournaments[id]);

  @override
  Stream<List<Tournament>> watchTournaments({String? sport, TournamentStatus? status}) =>
      Stream.value(tournaments.values.toList());

  @override
  Stream<List<Tournament>> watchPublicTournaments({String? sport}) =>
      Stream.value(tournaments.values.where((t) => t.isPublic).toList());

  @override
  Stream<List<Tournament>> watchTournamentsByLeague(String leagueId) =>
      Stream.value(tournaments.values.where((t) => t.leagueId == leagueId).toList());
}

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
  Future<League?> getLeagueByShareCode(String code) async =>
      leagues.values.cast<League?>().firstWhere((l) => l?.shareCode == code, orElse: () => null);

  Future<List<League>> getPublicLeagues({String? sport}) async =>
      leagues.values.where((l) => l.isPublic).toList();

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

class MockTeamRepo implements ITeamRepository {
  final List<Team> teams = [];

  @override
  Future<List<Team>> getTeams() async => teams;

  @override
  Future<Team?> getTeamById(String id) async =>
      teams.cast<Team?>().firstWhere((t) => t?.id == id, orElse: () => null);

  @override
  Future<void> saveTeam(Team team) async {
    teams.removeWhere((t) => t.id == team.id);
    teams.add(team);
  }

  @override
  Future<void> deleteTeam(String id) async {
    teams.removeWhere((t) => t.id == id);
  }

  @override
  Stream<List<Team>> watchTeams() => Stream.value(teams);
}

class MockVenueRepo implements IVenueRepository {
  final List<Venue> venues = [];

  @override
  Future<List<Venue>> getVenues({String? leagueId}) async => venues;

  @override
  Future<Venue?> getVenueById(String id) async =>
      venues.cast<Venue?>().firstWhere((v) => v?.id == id, orElse: () => null);

  @override
  Future<void> saveVenue(Venue venue) async {
    venues.removeWhere((v) => v.id == venue.id);
    venues.add(venue);
  }

  @override
  Future<void> deleteVenue(String id) async {
    venues.removeWhere((v) => v.id == id);
  }

  @override
  Stream<List<Venue>> watchVenues({String? leagueId}) => Stream.value(venues);

  @override
  Stream<Venue?> watchVenue(String id) =>
      Stream.value(venues.cast<Venue?>().firstWhere((v) => v?.id == id, orElse: () => null));
}

void main() {
  group('TournamentMatch.canScore Authorization Model Tests', () {
    test('Spectator and unassigned users cannot score when assignedScorerId is null or different', () {
      final match = TournamentMatch(
        id: 'm1',
        round: 1,
        matchNumber: 1,
        participantAId: 'team1',
        participantBId: 'team2',
        status: MatchStatus.live,
        assignedScorerId: null,
      );

      // Spectators or any unassigned users cannot score
      expect(match.canScore(null), isFalse);
      expect(match.canScore('spectator_123'), isFalse);
      expect(match.canScore('some_random_user'), isFalse);

      // When assigned to a specific scorer
      final assignedMatch = match.copyWith(assignedScorerId: 'official_scorer_45');
      expect(assignedMatch.canScore('official_scorer_45'), isTrue);
      expect(assignedMatch.canScore('spectator_123'), isFalse);
      expect(assignedMatch.canScore(null), isFalse);
    });
  });

  group('TournamentDashboardScreen Spectator Access Control UI Tests', () {
    late MockTournamentRepo mockTournamentRepo;
    late MockSubscriptionRepo mockSubRepo;

    final teamA = Team(id: 'team_a', name: 'Alpha Warriors', seed: 1);
    final teamB = Team(id: 'team_b', name: 'Beta Challengers', seed: 2);

    final liveMatch = TournamentMatch(
      id: 'match_101',
      round: 1,
      matchNumber: 1,
      participantA: teamA,
      participantB: teamB,
      participantAId: teamA.id,
      participantBId: teamB.id,
      scoreA: 10,
      scoreB: 8,
      status: MatchStatus.live,
      assignedScorerId: null, // No scorer assigned yet
    );

    final tournament = Tournament(
      id: 'tourney_101',
      name: 'Premier Cricket Cup',
      sportType: 'Cricket',
      format: TournamentFormat.singleElimination,
      creatorId: 'organizer_99',
      participants: [teamA, teamB],
      matches: [liveMatch],
      isPublic: true,
    );

    final spectatorUser = AppUser(
      id: 'spectator_user_1',
      email: 'fan@example.com',
      displayName: 'Cricket Fan',
      createdAt: DateTime.now(),
    );

    final organizerUser = AppUser(
      id: 'organizer_99',
      email: 'owner@sportsturf.in',
      displayName: 'League Owner',
      createdAt: DateTime.now(),
    );

    final scorerUser = AppUser(
      id: 'scorer_user_77',
      email: 'scorer@sportsturf.in',
      displayName: 'Assigned Scorer',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockTournamentRepo = MockTournamentRepo();
      mockTournamentRepo.saveTournament(tournament);
      mockSubRepo = MockSubscriptionRepo();
    });

    testWidgets('Spectator viewing tournament sees Spectator Mode and CANNOT update scores or access admin tools', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            currentUserProvider.overrideWithValue(spectatorUser),
          ],
          child: MaterialApp(
            home: TournamentDashboardScreen(tournament: tournament),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Mode Banner
      expect(find.textContaining('Spectator Mode'), findsOneWidget);
      expect(find.textContaining('Organizer Mode'), findsNothing);

      // 2. Quick Score button (IconButton with edit_note) must NOT be present
      expect(find.byTooltip('Quick Score'), findsNothing);

      // 3. Open match card popup menu
      final matchMenuButton = find.byTooltip('Match Actions');
      expect(matchMenuButton, findsOneWidget);
      await tester.tap(matchMenuButton);
      await tester.pumpAndSettle();

      // 4. Verify restricted options are hidden from spectator
      expect(find.text('Update Score'), findsNothing);
      expect(find.text('Live Cricket Scorer'), findsNothing);
      expect(find.text('Pause Match'), findsNothing);
      expect(find.text('Record Walkover / Forfeit'), findsNothing);
      expect(find.text('Assign Scorer & Referee'), findsNothing);

      // 5. Verify read-only Match Report IS visible to spectator
      expect(find.text('Match Report'), findsOneWidget);

      // Dismiss popup
      await tester.tap(find.text('Match Report'));
      await tester.pumpAndSettle();
      // Dismiss the report dialog
      if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      // 6. Open Tournament Operations AppBar menu
      final appBarMenuButton = find.byTooltip('Tournament Operations');
      expect(appBarMenuButton, findsOneWidget);
      await tester.tap(appBarMenuButton);
      await tester.pumpAndSettle();

      // 7. Verify admin operations are hidden from spectator
      expect(find.text('Registrations & Waitlist'), findsNothing);
      expect(find.text('Venues & Courts'), findsNothing);
      // Read-only exports remain accessible
      expect(find.text('Export Fixtures (CSV)'), findsOneWidget);
    });

    testWidgets('Tournament Organizer sees Organizer Mode and full scoring and management options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            currentUserProvider.overrideWithValue(organizerUser),
          ],
          child: MaterialApp(
            home: TournamentDashboardScreen(tournament: tournament),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Mode Banner
      expect(find.textContaining('Organizer Mode'), findsOneWidget);
      expect(find.textContaining('Spectator Mode'), findsNothing);

      // 2. Quick Score button IS present for organizer
      expect(find.byTooltip('Quick Score'), findsOneWidget);

      // 3. Open match card popup menu
      final matchMenuButton = find.byTooltip('Match Actions');
      expect(matchMenuButton, findsOneWidget);
      await tester.tap(matchMenuButton);
      await tester.pumpAndSettle();

      // 4. Verify organizer has match control options
      expect(find.text('Update Score'), findsOneWidget);
      expect(find.text('Live Cricket Scorer'), findsOneWidget);
      expect(find.text('Pause Match'), findsOneWidget);
      expect(find.text('Record Walkover / Forfeit'), findsOneWidget);
      expect(find.text('Assign Scorer & Referee'), findsOneWidget);

      // Dismiss menu by tapping Update Score then canceling dialog
      await tester.tap(find.text('Update Score'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Match Score'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // 5. Open Tournament Operations AppBar menu
      final appBarMenuButton = find.byTooltip('Tournament Operations');
      await tester.tap(appBarMenuButton);
      await tester.pumpAndSettle();

      // 6. Verify admin operations ARE visible to organizer
      expect(find.text('Registrations & Waitlist'), findsOneWidget);
      expect(find.text('Venues & Courts'), findsOneWidget);
      expect(find.text('Export Fixtures (CSV)'), findsOneWidget);
    });

    testWidgets('Assigned Match Scorer sees scoring options on assigned match without full organizer access', (tester) async {
      // Create tournament where match is assigned to scorerUser
      final matchAssignedToScorer = liveMatch.copyWith(assignedScorerId: scorerUser.id);
      final tournamentWithAssignedScorer = tournament.copyWith(matches: [matchAssignedToScorer]);
      mockTournamentRepo.saveTournament(tournamentWithAssignedScorer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            currentUserProvider.overrideWithValue(scorerUser),
          ],
          child: MaterialApp(
            home: TournamentDashboardScreen(tournament: tournamentWithAssignedScorer),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scorer is not an organizer, so banner shows Spectator/Participant
      expect(find.textContaining('Spectator Mode'), findsOneWidget);

      // Scorer CAN quick-score their assigned match
      expect(find.byTooltip('Quick Score'), findsOneWidget);

      // Open match menu
      await tester.tap(find.byTooltip('Match Actions'));
      await tester.pumpAndSettle();

      // Scorer can score
      expect(find.text('Update Score'), findsOneWidget);
      expect(find.text('Live Cricket Scorer'), findsOneWidget);

      // Scorer cannot record walkover or assign officials (organizer/referee only)
      expect(find.text('Record Walkover / Forfeit'), findsNothing);
      expect(find.text('Assign Scorer & Referee'), findsNothing);
    });
  });

  group('League & Venue & Team Spectator View-Only Tests', () {
    testWidgets('LeagueDashboardScreen renders in Spectator Mode with edit/delete/add hidden', (tester) async {
      final mockLeagueRepo = MockLeagueRepo();
      final mockTournamentRepo = MockTournamentRepo();
      final mockSubRepo = MockSubscriptionRepo();

      final league = League(
        id: 'league_01',
        name: 'Premier Badminton League',
        creatorId: 'owner_99',
        isPublic: true,
      );
      mockLeagueRepo.saveLeague(league);

      final spectatorUser = AppUser(
        id: 'spectator_user_1',
        email: 'fan@example.com',
        displayName: 'Sports Fan',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leagueRepositoryProvider.overrideWithValue(mockLeagueRepo),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
            currentUserProvider.overrideWithValue(spectatorUser),
          ],
          child: MaterialApp(
            home: LeagueDashboardScreen(league: league),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Spectator Banner
      expect(find.textContaining('Spectator Mode'), findsOneWidget);
      expect(find.textContaining('League Admin Mode'), findsNothing);

      // 2. Floating action button (Host Tournament) must NOT be present
      expect(find.byType(FloatingActionButton), findsNothing);

      // 3. More Vert button (Edit League / Delete League) must NOT be present
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('TeamsScreen & CreateEditTeamScreen render view-only for spectators', (tester) async {
      final mockTeamRepo = MockTeamRepo();
      final team = Team(
        id: 'team_01',
        name: 'Royal Challengers',
        userId: 'captain_99',
        captainId: 'captain_99',
        playerIds: ['Virat Kohli'],
      );
      mockTeamRepo.saveTeam(team);

      // Unauthenticated spectator viewing teams
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: TeamsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Spectator banner on Teams screen
      expect(find.textContaining('Spectator Mode: View-only club teams'), findsOneWidget);

      // 2. Delete team icon button must NOT be present on another user's team
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // 3. New Team FAB must NOT be present for unauthenticated spectator
      expect(find.byType(FloatingActionButton), findsNothing);

      // 4. Tap team to open details screen
      await tester.tap(find.text('Royal Challengers'));
      await tester.pumpAndSettle();

      // 5. Verify Team Details renders in Spectator Mode
      expect(find.text('Team Roster'), findsOneWidget);
      expect(find.textContaining('Spectator Mode: View-only team squad & members.'), findsOneWidget);
      expect(find.text('Add Member'), findsNothing);
      expect(find.text('UPDATE TEAM'), findsNothing);
      expect(find.text('SAVE TEAM'), findsNothing);
    });

    testWidgets('VenueManagementScreen renders in Spectator Mode with add/edit hidden', (tester) async {
      final mockVenueRepo = MockVenueRepo();
      final venue = Venue(
        id: 'venue_01',
        name: 'National Sports Complex',
        address: '123 Stadium Way',
        managerUserIds: ['venue_manager_99'],
        playingAreas: [PlayingArea(id: 'c1', name: 'Center Court', isAvailable: true)],
      );
      mockVenueRepo.saveVenue(venue);

      // Spectator viewing venues
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueRepositoryProvider.overrideWithValue(mockVenueRepo),
            currentUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: VenueManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Spectator Banner
      expect(find.textContaining('Spectator Mode: View-only venues'), findsOneWidget);

      // 2. Add Venue actions must NOT be present
      expect(find.byTooltip('Add Venue'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      // 3. Open venue popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 4. Verify Edit and Delete venue options are hidden from spectator
      expect(find.text('Edit Venue Details'), findsNothing);
      expect(find.text('Delete Venue'), findsNothing);
      expect(find.text('View Courts/Pitches'), findsOneWidget);
    });
  });
}
