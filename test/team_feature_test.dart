import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/app_user.dart';
import 'package:sports_turf/core/models/player.dart';
import 'package:sports_turf/core/providers/auth_providers.dart';
import 'package:sports_turf/core/providers/repository_providers.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_team_repository.dart';
import 'package:sports_turf/core/repositories/player_repository.dart';
import 'package:sports_turf/core/repositories/team_repository.dart';
import 'package:sports_turf/features/teams/ui/create_edit_team_screen.dart';
import 'package:sports_turf/features/tournament/models/team.dart';

class MockTeamRepo implements ITeamRepository {
  final Map<String, Team> teams = {};

  @override
  Future<List<Team>> getTeams() async => teams.values.toList();

  @override
  Future<Team?> getTeamById(String id) async => teams[id];

  @override
  Future<void> saveTeam(Team team) async {
    teams[team.id] = team;
  }

  @override
  Future<void> deleteTeam(String id) async {
    teams.remove(id);
  }

  @override
  Stream<List<Team>> watchTeams() => Stream.value(teams.values.toList());
}

class MockPlayerRepo implements IPlayerRepository {
  final Map<String, Player> players = {};

  @override
  Future<List<Player>> getPlayers() async => players.values.toList();

  @override
  Future<Player?> getPlayerById(String id) async => players[id];

  @override
  Future<void> savePlayer(Player player) async {
    final id = player.id ?? 'p_${players.length + 1}';
    players[id] = player.copyWith(id: id);
  }

  @override
  Future<void> deletePlayer(String id) async {
    players.remove(id);
  }

  @override
  Stream<List<Player>> watchPlayers() => Stream.value(players.values.toList());
}

void main() {
  group('Team Model & Serialization Tests', () {
    test('Team properly serializes and deserializes userId and playerIds', () {
      final team = Team(
        id: 'team_alpha',
        name: 'Alpha Squad',
        seed: 1,
        playerIds: ['p1', 'p2', 'p3'],
        userId: 'user_123',
        captainId: 'p1',
      );

      final map = team.toMap();
      expect(map['id'], 'team_alpha');
      expect(map['name'], 'Alpha Squad');
      expect(map['seed'], 1);
      expect(map['playerIds'], ['p1', 'p2', 'p3']);
      expect(map['userId'], 'user_123');
      expect(map['captainId'], 'p1');

      final deserialized = Team.fromMap(map);
      expect(deserialized.id, 'team_alpha');
      expect(deserialized.name, 'Alpha Squad');
      expect(deserialized.seed, 1);
      expect(deserialized.playerIds, ['p1', 'p2', 'p3']);
      expect(deserialized.userId, 'user_123');
      expect(deserialized.captainId, 'p1');
    });

    test('Team.copyWith preserves or updates properties correctly', () {
      final original = Team(
        id: 'team_1',
        name: 'Warriors',
        playerIds: ['p1'],
        userId: 'mgr_1',
      );

      final updated = original.copyWith(
        name: 'Super Warriors',
        playerIds: ['p1', 'p2'],
      );

      expect(updated.id, 'team_1');
      expect(updated.name, 'Super Warriors');
      expect(updated.playerIds, ['p1', 'p2']);
      expect(updated.userId, 'mgr_1');
    });
  });

  group('FirestoreTeamRepository Tests', () {
    test('Saves team and retains properties in fallback and stream', () async {
      final repo = FirestoreTeamRepository();

      final team = Team(
        id: 'team_bravo',
        name: 'Bravo Battalion',
        playerIds: ['p10', 'p20'],
        userId: 'owner_99',
      );

      await repo.saveTeam(team);

      final retrieved = await repo.getTeamById('team_bravo');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Bravo Battalion');
      expect(retrieved.playerIds.length, 2);
      expect(retrieved.userId, 'owner_99');

      final allTeams = await repo.getTeams();
      expect(allTeams.any((t) => t.id == 'team_bravo'), isTrue);
    });
  });

  group('CreateEditTeamScreen UI Widget Tests', () {
    testWidgets('renders team creation form and adds players successfully', (tester) async {
      final mockTeamRepo = MockTeamRepo();
      final mockPlayerRepo = MockPlayerRepo();

      // Seed player repository with an available player
      await mockPlayerRepo.savePlayer(Player(id: 'p1', name: 'John Doe', contact: '555-0100'));

      final testUser = AppUser(
        id: 'test_user_id',
        email: 'test@sportsturf.in',
        displayName: 'Test Manager',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            currentUserProvider.overrideWithValue(testUser),
          ],
          child: const MaterialApp(
            home: CreateEditTeamScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check form fields exist
      expect(find.text('New Team'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Name & Seed
      expect(find.text('SAVE TEAM'), findsOneWidget);
      expect(find.text('MEMBERS (0)'), findsOneWidget);

      // Enter Team Name
      await tester.enterText(find.widgetWithText(TextFormField, 'Team Name'), 'Thunderbolts');
      await tester.enterText(find.widgetWithText(TextFormField, 'Seed Number (Optional)'), '1');

      // Tap Add Member
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Add Team Member'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);

      // Tap John Doe to add
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Member should now be listed
      expect(find.text('MEMBERS (1)'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);

      // Save the team
      await tester.tap(find.text('SAVE TEAM'));
      await tester.pumpAndSettle();

      // Verify the team was saved to repository with correct properties
      expect(mockTeamRepo.teams.length, 1);
      final savedTeam = mockTeamRepo.teams.values.first;
      expect(savedTeam.name, 'Thunderbolts');
      expect(savedTeam.seed, 1);
      expect(savedTeam.playerIds, contains('p1'));
      expect(savedTeam.userId, 'test_user_id');
    });

    testWidgets('allows adding a new player on the fly from the dialog', (tester) async {
      final mockTeamRepo = MockTeamRepo();
      final mockPlayerRepo = MockPlayerRepo();

      final testUser = AppUser(
        id: 'user_456',
        email: 'captain@sportsturf.in',
        displayName: 'Captain',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            currentUserProvider.overrideWithValue(testUser),
          ],
          child: const MaterialApp(
            home: CreateEditTeamScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Team Name'), 'Rising Stars');

      // Tap Add Member
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Enter a new player name not currently in the database
      final searchField = find.widgetWithText(TextField, 'Search or enter new player name');
      await tester.enterText(searchField, 'Alice Wonder');
      await tester.pumpAndSettle();

      // Find the add new player option
      expect(find.text('Add "Alice Wonder"'), findsOneWidget);
      await tester.tap(find.text('Add "Alice Wonder"'));
      await tester.pumpAndSettle();

      // Player should be created in player repo and added to team member list
      expect(mockPlayerRepo.players.values.any((p) => p.name == 'Alice Wonder'), isTrue);
      expect(find.text('MEMBERS (1)'), findsOneWidget);
      expect(find.text('Alice Wonder'), findsOneWidget);

      // Save team
      await tester.tap(find.text('SAVE TEAM'));
      await tester.pumpAndSettle();

      expect(mockTeamRepo.teams.length, 1);
      final savedTeam = mockTeamRepo.teams.values.first;
      expect(savedTeam.name, 'Rising Stars');
      expect(savedTeam.playerIds.length, 1);
    });
  });
}
