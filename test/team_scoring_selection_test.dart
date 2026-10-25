import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/player.dart';
import 'package:sports_turf/core/providers/repository_providers.dart';
import 'package:sports_turf/core/repositories/player_repository.dart';
import 'package:sports_turf/core/repositories/team_repository.dart';
import 'package:sports_turf/features/cricket/ui/cricket_setup_screen.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/volleyball/ui/volleyball_setup_screen.dart';

class MockTeamRepo implements ITeamRepository {
  final List<Team> teams = [];

  @override
  Future<List<Team>> getTeams() async => teams;

  @override
  Future<Team?> getTeamById(String id) async {
    return teams.cast<Team?>().firstWhere((t) => t?.id == id, orElse: () => null);
  }

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

class MockPlayerRepo implements IPlayerRepository {
  final List<Player> players = [];

  @override
  Future<List<Player>> getPlayers() async => players;

  @override
  Future<Player?> getPlayerById(String id) async {
    return players.cast<Player?>().firstWhere((p) => p?.id == id, orElse: () => null);
  }

  @override
  Future<void> savePlayer(Player player) async {
    players.removeWhere((p) => p.id == player.id);
    players.add(player);
  }

  @override
  Future<void> deletePlayer(String id) async {
    players.removeWhere((p) => p.id == id);
  }

  @override
  Stream<List<Player>> watchPlayers() => Stream.value(players);
}

void main() {
  group('Team Selection in Team Games Scoring Tests', () {
    late MockTeamRepo mockTeamRepo;
    late MockPlayerRepo mockPlayerRepo;

    setUp(() {
      mockTeamRepo = MockTeamRepo();
      mockPlayerRepo = MockPlayerRepo();

      // Add mock players
      mockPlayerRepo.players.addAll([
        Player(id: 'p1', name: 'Virat Kohli'),
        Player(id: 'p2', name: 'Rohit Sharma'),
        Player(id: 'p3', name: 'Jasprit Bumrah'),
        Player(id: 'p4', name: 'Pat Cummins'),
        Player(id: 'p5', name: 'Travis Head'),
      ]);

      // Add mock teams with players
      mockTeamRepo.teams.addAll([
        Team(
          id: 'team_india',
          name: 'India Champions',
          seed: 1,
          playerIds: ['p1', 'p2', 'p3'],
        ),
        Team(
          id: 'team_aus',
          name: 'Aussie Dominators',
          seed: 2,
          playerIds: ['p4', 'p5'],
        ),
      ]);
    });

    testWidgets('CricketSetupScreen loads registered teams and selecting a team populates name and squad', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          ],
          child: const MaterialApp(
            home: CricketSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Cricket Setup'), findsOneWidget);

      // Verify Team selection dropdowns exist for both Team A and Team B
      expect(find.text('Select Registered Team'), findsNWidgets(2));

      // Tap on Team A's dropdown
      await tester.tap(find.byType(DropdownButtonFormField<Team?>).first);
      await tester.pumpAndSettle();

      // Should show the mock teams in the dropdown
      expect(find.textContaining('India Champions').hitTestable(), findsOneWidget);
      expect(find.textContaining('Aussie Dominators').hitTestable(), findsOneWidget);

      // Select 'India Champions' for Team A
      await tester.tap(find.textContaining('India Champions').hitTestable());
      await tester.pumpAndSettle();

      // Team A text controller should be populated with 'India Champions'
      expect(find.widgetWithText(TextField, 'India Champions'), findsOneWidget);

      // Squad A should automatically have the 3 players from India Champions: Virat, Rohit, Bumrah!
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('Jasprit Bumrah'), findsOneWidget);
      expect(find.text('Squad Members (3):'), findsOneWidget);

      // Now select Team B as 'Aussie Dominators'
      await tester.ensureVisible(find.byType(DropdownButtonFormField<Team?>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<Team?>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Aussie Dominators').hitTestable());
      await tester.pumpAndSettle();

      // Team B text controller should have 'Aussie Dominators'
      expect(find.widgetWithText(TextField, 'Aussie Dominators'), findsOneWidget);

      // Squad B should have Pat Cummins and Travis Head
      expect(find.text('Pat Cummins'), findsOneWidget);
      expect(find.text('Travis Head'), findsOneWidget);
      expect(find.text('Squad Members (2):'), findsOneWidget);
    });

    testWidgets('CricketSetupScreen allows adding custom/guest player to squad on the fly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          ],
          child: const MaterialApp(
            home: CricketSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Add Guest / Custom Player" button for Team A
      final addGuestBtn = find.byTooltip('Add Guest / Custom Player').first;
      await tester.tap(addGuestBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Add Player to Squad'), findsOneWidget);

      // Enter guest player name
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Rahul Sharma'), 'Guest Striker');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog closes and squad has 'Guest Striker'
      expect(find.text('Guest Striker'), findsOneWidget);
      expect(find.text('Squad Members (1):'), findsOneWidget);
    });

    testWidgets('VolleyballSetupScreen loads teams and selecting a team sets team name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          ],
          child: const MaterialApp(
            home: VolleyballSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Volleyball Setup'), findsOneWidget);

      // Verify dropdowns
      expect(find.text('Select Registered Team'), findsNWidgets(2));

      // Select Team A
      await tester.tap(find.byType(DropdownButtonFormField<Team?>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('India Champions').hitTestable());
      await tester.pumpAndSettle();

      // Verify Team A name is updated
      expect(find.widgetWithText(TextField, 'India Champions'), findsOneWidget);
      expect(find.text('Linked to team "India Champions" • 3 players'), findsOneWidget);

      // Select Team B
      await tester.tap(find.byType(DropdownButtonFormField<Team?>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Aussie Dominators').hitTestable());
      await tester.pumpAndSettle();

      // Verify Team B name is updated
      expect(find.widgetWithText(TextField, 'Aussie Dominators'), findsOneWidget);
      expect(find.text('Linked to team "Aussie Dominators" • 2 players'), findsOneWidget);
    });

    testWidgets('CricketSetupScreen pre-fills teams and rosters when launched from a tournament match', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          ],
          child: const MaterialApp(
            home: CricketSetupScreen(
              initialTeamA: 'India Champions',
              initialTeamB: 'Aussie Dominators',
              tournamentId: 'tourn_cup_2026',
              matchId: 'match_semi_1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Team A and Team B should be automatically matched to the registered teams!
      expect(find.widgetWithText(TextField, 'India Champions'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Aussie Dominators'), findsOneWidget);

      // Squad A should have been automatically populated from India Champions
      expect(find.text('Squad Members (3):'), findsOneWidget);
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('Jasprit Bumrah'), findsOneWidget);

      // Squad B should have been automatically populated from Aussie Dominators
      expect(find.text('Squad Members (2):'), findsOneWidget);
      expect(find.text('Pat Cummins'), findsOneWidget);
      expect(find.text('Travis Head'), findsOneWidget);
    });

    testWidgets('VolleyballSetupScreen pre-fills teams when launched from a tournament match', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
          ],
          child: const MaterialApp(
            home: VolleyballSetupScreen(
              initialTeamA: 'India Champions',
              initialTeamB: 'Aussie Dominators',
              tournamentId: 'tourn_volleyball_2026',
              matchId: 'match_final',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Team A and Team B text controllers should be pre-filled and linked
      expect(find.widgetWithText(TextField, 'India Champions'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Aussie Dominators'), findsOneWidget);
      expect(find.text('Linked to team "India Champions" • 3 players'), findsOneWidget);
      expect(find.text('Linked to team "Aussie Dominators" • 2 players'), findsOneWidget);
    });
  });
}
