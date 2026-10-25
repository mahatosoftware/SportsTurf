import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/player.dart';
import 'package:sports_turf/core/models/match_result.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_player_repository.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_team_repository.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_match_repository.dart';

void main() {
  group('Firestore Repositories CRUD Tests', () {
    test('FirestorePlayerRepository performs full CRUD', () async {
      final repo = FirestorePlayerRepository();

      // Initially empty
      expect(await repo.getPlayers(), isEmpty);

      // Create
      final p1 = Player(name: 'Virat Kohli', contact: '9999999999', seed: 1);
      await repo.savePlayer(p1);

      final players = await repo.getPlayers();
      expect(players.length, 1);
      expect(players.first.name, 'Virat Kohli');
      expect(players.first.seed, 1);
      expect(players.first.contact, '9999999999');
      final assignedId = players.first.id;
      expect(assignedId, isNotNull);

      // Read by ID
      final fetched = await repo.getPlayerById(assignedId!);
      expect(fetched?.name, 'Virat Kohli');

      // Update
      final updated = fetched!.copyWith(name: 'King Kohli', seed: 2);
      await repo.savePlayer(updated);
      final refetched = await repo.getPlayerById(assignedId);
      expect(refetched?.name, 'King Kohli');
      expect(refetched?.seed, 2);

      // Delete
      await repo.deletePlayer(assignedId);
      expect(await repo.getPlayerById(assignedId), isNull);
      expect(await repo.getPlayers(), isEmpty);
    });

    test('FirestoreTeamRepository performs full CRUD', () async {
      final repo = FirestoreTeamRepository();

      expect(await repo.getTeams(), isEmpty);

      // Create
      final t1 = Team(id: 'team_ind', name: 'India', playerIds: ['p1', 'p2'], seed: 1);
      await repo.saveTeam(t1);

      final teams = await repo.getTeams();
      expect(teams.length, 1);
      expect(teams.first.name, 'India');
      expect(teams.first.playerIds, ['p1', 'p2']);

      // Read by ID
      final fetched = await repo.getTeamById('team_ind');
      expect(fetched?.name, 'India');

      // Update
      final updated = fetched!.copyWith(name: 'Team India (Champions)', seed: 1);
      await repo.saveTeam(updated);
      final refetched = await repo.getTeamById('team_ind');
      expect(refetched?.name, 'Team India (Champions)');

      // Delete
      await repo.deleteTeam('team_ind');
      expect(await repo.getTeamById('team_ind'), isNull);
      expect(await repo.getTeams(), isEmpty);
    });

    test('FirestoreMatchRepository performs full CRUD and filters', () async {
      final repo = FirestoreMatchRepository();

      expect(await repo.getMatches(), isEmpty);

      // Create matches
      final m1 = MatchResult(
        sport: 'Badminton',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        teamA: 'Player 1',
        teamB: 'Player 2',
        scoreA: 21,
        scoreB: 19,
        winner: 'Player 1',
      );
      final m2 = MatchResult(
        sport: 'Cricket',
        date: DateTime.now(),
        teamA: 'Team A',
        teamB: 'Team B',
        scoreA: 150,
        scoreB: 140,
        winner: 'Team A',
      );

      await repo.saveMatch(m1);
      await repo.saveMatch(m2);

      final allMatches = await repo.getMatches();
      expect(allMatches.length, 2);

      // Filter by sport
      final badmintonOnly = await repo.getMatches(sport: 'Badminton');
      expect(badmintonOnly.length, 1);
      expect(badmintonOnly.first.sport, 'Badminton');

      final cricketOnly = await repo.getMatches(sport: 'Cricket');
      expect(cricketOnly.length, 1);
      expect(cricketOnly.first.sport, 'Cricket');

      // Delete single match
      final matchToDeleteId = badmintonOnly.first.id;
      expect(matchToDeleteId, isNotNull);
      await repo.deleteMatch(matchToDeleteId!);
      expect((await repo.getMatches(sport: 'Badminton')), isEmpty);
      expect((await repo.getMatches()).length, 1);

      // Delete all
      await repo.deleteAllMatches();
      expect(await repo.getMatches(), isEmpty);
    });
  });
}
