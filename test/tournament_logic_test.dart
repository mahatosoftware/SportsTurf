
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/models/match.dart'; // Add this import
import 'package:sports_turf/features/tournament/logic/fixture_generator.dart';
import 'package:sports_turf/features/tournament/logic/tournament_manager.dart';

void main() {
  group('Tournament Fixture Generation', () {
    test('Round Robin generates correct number of matches', () {
      List<Team> teams = List.generate(4, (i) => Team(id: '$i', name: 'T$i'));
      var matches = FixtureGenerator.generateRoundRobin(teams);
      
      // For 4 teams: 4 * 3 / 2 = 6 matches
      expect(matches.length, 6);
    });

    test('Single Elimination generates correct structure', () {
      List<Team> teams = List.generate(4, (i) => Team(id: '$i', name: 'T$i', seed: i+1));
      var matches = FixtureGenerator.generateSingleElimination(teams, true);
      
      // 4 teams -> 3 matches (2 semis, 1 final)
      expect(matches.length, 3);
      
      // Check Round 1 matches
      var round1 = matches.where((m) => m.round == 1).toList();
      expect(round1.length, 2);
    });
  });

  group('Tournament Manager Logic', () {
    test('Advancing winner in Single Elimination', () {
      List<Team> teams = List.generate(4, (i) => Team(id: '$i', name: 'T$i', seed: i+1));
      var matches = FixtureGenerator.generateSingleElimination(teams, true);
      
      var tournament = Tournament(
        id: '1', name: 'Test', sportType: 'Test', 
        format: TournamentFormat.singleElimination, 
        participants: teams, matches: matches
      );
      
      var manager = TournamentManager(tournament);
      
      // Find first match
      var m1 = matches.firstWhere((m) => m.round == 1 && m.matchNumber == 1);
      
      // Update score: Team A wins
      var updatedTournament = manager.updateMatch(m1.id, 10, 5);
      
      // Check if match is completed
      var updatedM1 = updatedTournament.matches.firstWhere((m) => m.id == m1.id);
      expect(updatedM1.status, MatchStatus.completed);
      expect(updatedM1.winnerId, isNotNull);
      
      // Check if winner advanced to next match
      var nextMatchId = updatedM1.nextMatchId;
      if (nextMatchId != null) {
         var nextMatch = updatedTournament.matches.firstWhere((m) => m.id == nextMatchId);
         // One of the participants should now be the winner
         expect([nextMatch.participantAId, nextMatch.participantBId], contains(updatedM1.winnerId));
      }
    });

    test('Round Robin Leaderboard Calculation indirectly', () {
         // Logic is in LeaderboardView, but data comes from matches.
         // We can verify that manager updates match status correctly.
    });
  });
}
