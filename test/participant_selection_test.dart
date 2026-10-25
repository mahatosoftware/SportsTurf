import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sports_turf/core/models/player.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/tournament/logic/fixture_generator.dart';
import 'package:sports_turf/core/providers/repository_providers.dart';
import 'package:sports_turf/core/repositories/player_repository.dart';
import 'package:sports_turf/core/repositories/team_repository.dart';
import 'package:sports_turf/features/tournament/ui/tournament_setup_screen.dart';

class MockPlayerRepository implements IPlayerRepository {
  final List<Player> _players = [
    Player(id: 'p1', name: 'Alice Smith', seed: 1),
    Player(id: 'p2', name: 'Bob Jones', seed: 2),
    Player(id: 'p3', name: 'Charlie Brown', seed: 3),
    Player(id: 'p4', name: 'Diana Prince', seed: 4),
    Player(id: 'p5', name: 'Evan Wright', seed: 5),
  ];

  @override
  Future<List<Player>> getPlayers() async => List.from(_players);

  @override
  Future<Player?> getPlayerById(String id) async {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlayer(Player player) async {
    final idx = _players.indexWhere((p) => p.id == player.id);
    if (idx >= 0) {
      _players[idx] = player;
    } else {
      _players.add(player);
    }
  }

  @override
  Future<void> deletePlayer(String id) async {
    _players.removeWhere((p) => p.id == id);
  }

  @override
  Stream<List<Player>> watchPlayers() {
    return Stream.value(List.from(_players));
  }
}

class MockTeamRepository implements ITeamRepository {
  final List<Team> _teams = [
    Team(id: 't1', name: 'Red Dragons', seed: 1),
    Team(id: 't2', name: 'Blue Vipers', seed: 2),
    Team(id: 't3', name: 'Green Eagles', seed: 3),
  ];

  @override
  Future<List<Team>> getTeams() async => List.from(_teams);

  @override
  Future<Team?> getTeamById(String id) async {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTeam(Team team) async {
    final idx = _teams.indexWhere((t) => t.id == team.id);
    if (idx >= 0) {
      _teams[idx] = team;
    } else {
      _teams.add(team);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    _teams.removeWhere((t) => t.id == id);
  }

  @override
  Stream<List<Team>> watchTeams() {
    return Stream.value(List.from(_teams));
  }
}

void main() {
  group('Tournament Participant Selection Tests', () {
    test('Fixture generation creates matches exclusively for selected participant subset', () {
      final allPlayers = [
        Player(id: 'p1', name: 'Alice Smith', seed: 1),
        Player(id: 'p2', name: 'Bob Jones', seed: 2),
        Player(id: 'p3', name: 'Charlie Brown', seed: 3),
        Player(id: 'p4', name: 'Diana Prince', seed: 4),
      ];

      // Select only Alice and Charlie for Tournament 1 (Bob and Diana do not play)
      final selectedForTournament1 = [
        Team(id: allPlayers[0].id!, name: allPlayers[0].name, seed: 1, playerIds: [allPlayers[0].idString]),
        Team(id: allPlayers[2].id!, name: allPlayers[2].name, seed: 2, playerIds: [allPlayers[2].idString]),
      ];

      final matches = FixtureGenerator.generateSingleElimination(selectedForTournament1, true);
      expect(matches.length, 1);
      expect(matches[0].participantAId, 'p1');
      expect(matches[0].participantBId, 'p3');

      // Select Bob, Charlie, and Diana for Tournament 2 (Alice does not play)
      final selectedForTournament2 = [
        Team(id: allPlayers[1].id!, name: allPlayers[1].name, seed: 1, playerIds: [allPlayers[1].idString]),
        Team(id: allPlayers[2].id!, name: allPlayers[2].name, seed: 2, playerIds: [allPlayers[2].idString]),
        Team(id: allPlayers[3].id!, name: allPlayers[3].name, seed: 3, playerIds: [allPlayers[3].idString]),
      ];

      final matches2 = FixtureGenerator.generateRoundRobin(selectedForTournament2);
      // 3 teams round robin = 3 matches (plus bye handling if odd)
      expect(matches2.any((m) => m.participantAId == 'p2' || m.participantBId == 'p2'), isTrue);
      expect(matches2.any((m) => m.participantAId == 'p1' || m.participantBId == 'p1'), isFalse);
    });

    testWidgets('TournamentSetupScreen renders participant roster controls and quick pick chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(MockPlayerRepository()),
            teamRepositoryProvider.overrideWithValue(MockTeamRepository()),
          ],
          child: const MaterialApp(
            home: TournamentSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter tournament name in step 1
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Club Championship 2026');
      await tester.pumpAndSettle();

      // Tap NEXT STEP to advance to Step 2: Participants
      final nextButton = find.text('NEXT STEP');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify Step 2 hero card is displayed
      expect(find.text('Tournament Player Roster'), findsOneWidget);
      expect(find.text('SELECT FROM PLAYER LIST'), findsOneWidget);
      expect(find.text('5 Available in Roster'), findsOneWidget);

      // Verify quick pick chips are displayed for available players
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Charlie Brown'), findsOneWidget);

      // Tap Alice Smith chip to select her
      await tester.tap(find.text('Alice Smith'));
      await tester.pumpAndSettle();

      // Tap Bob Jones chip to select him
      await tester.tap(find.text('Bob Jones'));
      await tester.pumpAndSettle();

      // Verify 2 selected participants counter
      expect(find.text('2 Selected for Tournament'), findsOneWidget);
      expect(find.text('Selected Participants (2):'), findsOneWidget);

      // Open the Player List modal sheet
      await tester.tap(find.text('SELECT FROM PLAYER LIST'));
      await tester.pumpAndSettle();

      // Verify modal sheet is open
      expect(find.text('Select Players for Tournament'), findsOneWidget);
      expect(find.text('CONFIRM SELECTION (2 PARTICIPANTS)'), findsOneWidget);

      final charlieTile = find.widgetWithText(CheckboxListTile, 'Charlie Brown');
      await tester.scrollUntilVisible(charlieTile, 50, scrollable: find.byType(Scrollable).last);
      await tester.tap(charlieTile);
      await tester.pumpAndSettle();

      // Verify selected count updated to 3
      expect(find.text('CONFIRM SELECTION (3 PARTICIPANTS)'), findsOneWidget);

      // Confirm selection
      await tester.tap(find.text('CONFIRM SELECTION (3 PARTICIPANTS)'));
      await tester.pumpAndSettle();

      // Back on main step 2: 3 participants selected
      expect(find.text('3 Selected for Tournament'), findsOneWidget);

      // Diana Prince and Evan Wright were NOT selected and thus do not play
      expect(find.text('Selected Participants (3):'), findsOneWidget);
    });

    testWidgets('TournamentSetupScreen allows switching to Teams mode and selecting specific teams', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(MockPlayerRepository()),
            teamRepositoryProvider.overrideWithValue(MockTeamRepository()),
          ],
          child: const MaterialApp(
            home: TournamentSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter tournament name in step 1
      await tester.enterText(find.byType(TextFormField).first, 'Inter-Club Cup');
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('NEXT STEP'));
      await tester.pumpAndSettle();

      // Switch to Teams / Squads mode
      await tester.tap(find.text('Teams / Squads'));
      await tester.pumpAndSettle();

      // Verify Team Roster view
      expect(find.text('Tournament Team Roster'), findsOneWidget);
      expect(find.text('3 Available in Roster'), findsOneWidget);
      expect(find.text('SELECT FROM TEAM LIST'), findsOneWidget);

      // Verify quick pick chips for teams
      expect(find.text('Red Dragons'), findsOneWidget);
      expect(find.text('Blue Vipers'), findsOneWidget);
      expect(find.text('Green Eagles'), findsOneWidget);

      // Tap Red Dragons to select it
      await tester.tap(find.text('Red Dragons'));
      await tester.pumpAndSettle();

      // Tap Green Eagles to select it (Blue Vipers will not play)
      await tester.tap(find.text('Green Eagles'));
      await tester.pumpAndSettle();

      expect(find.text('2 Selected for Tournament'), findsOneWidget);
      expect(find.text('Selected Participants (2):'), findsOneWidget);

      // Advance to Format step
      await tester.tap(find.text('NEXT STEP'));
      await tester.pumpAndSettle();

      // Verify ready to launch with 2 participants
      expect(find.text('2 participants registered. Ready to generate automatic fixtures.'), findsOneWidget);
    });
  });
}
