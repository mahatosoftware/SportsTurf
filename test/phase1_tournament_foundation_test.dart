import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/models/match.dart';
import 'package:sports_turf/features/tournament/logic/fixture_generator.dart';

void main() {
  group('Phase 1 - Fixture Generator & Byes', () {
    test('Odd participants in Single Elimination receive automatic Byes', () {
      final teams = [
        Team(id: 't1', name: 'Alpha', seed: 1),
        Team(id: 't2', name: 'Bravo', seed: 2),
        Team(id: 't3', name: 'Charlie', seed: 3),
      ];

      final matches = FixtureGenerator.generateSingleElimination(teams, true);

      // Bracket power of 2 is 4 -> 3 total matches (2 semi-finals, 1 final)
      expect(matches.length, 3);

      // Check that top seed gets a Bye and advances to final
      final byeMatches = matches.where((m) => m.statusReason == 'Bye Advancement').toList();
      expect(byeMatches.isNotEmpty, isTrue);

      final byeMatch = byeMatches.first;
      expect(byeMatch.status, MatchStatus.completed);
      expect(byeMatch.winnerId, 't1');

      // The final match should already have Alpha in slot A or B
      final finalMatch = matches.firstWhere((m) => m.id == byeMatch.nextMatchId);
      expect([finalMatch.participantAId, finalMatch.participantBId], contains('t1'));
    });

    test('Round Robin with odd participants adds BYE and excludes self-play', () {
      final teams = [
        Team(id: '1', name: 'Team 1'),
        Team(id: '2', name: 'Team 2'),
        Team(id: '3', name: 'Team 3'),
      ];

      final matches = FixtureGenerator.generateRoundRobin(teams);

      // 3 teams in Round Robin: 3 rounds, each team plays 2 matches (3 matches total)
      expect(matches.length, 3);

      // Verify no match has same participant on both sides
      for (final m in matches) {
        expect(m.participantAId, isNot(equals(m.participantBId)));
        expect(m.participantAId, isNot(equals('BYE')));
        expect(m.participantBId, isNot(equals('BYE')));
      }
    });

    test('Friendly match generator pairs teams pairwise', () {
      final teams = [
        Team(id: '1', name: 'T1'),
        Team(id: '2', name: 'T2'),
        Team(id: '3', name: 'T3'),
        Team(id: '4', name: 'T4'),
      ];

      final matches = FixtureGenerator.generateFriendlyMatches(teams);
      expect(matches.length, 2);
      expect(matches[0].participantAId, '1');
      expect(matches[0].participantBId, '2');
      expect(matches[1].participantAId, '3');
      expect(matches[1].participantBId, '4');
    });

    test('Tournament lifecycle and rich metadata serialization', () {
      final tournament = Tournament(
        id: 'tourn-1',
        name: 'Open Badminton Cup',
        sportType: 'Badminton',
        format: TournamentFormat.singleElimination,
        participants: [Team(id: 't1', name: 'Player 1'), Team(id: 't2', name: 'Player 2')],
        matches: [],
        status: TournamentStatus.inProgress,
        venue: 'Court 1',
        organizerName: 'Sports Turf',
        ruleConfig: {'pointsPerSet': 21, 'setsToWin': 2},
      );

      final map = tournament.toMap();
      expect(map['venue'], 'Court 1');
      expect(map['ruleConfig']['pointsPerSet'], 21);

      final restored = Tournament.fromMap(map);
      expect(restored.name, 'Open Badminton Cup');
      expect(restored.venue, 'Court 1');
      expect(restored.format, TournamentFormat.singleElimination);
      expect(restored.status, TournamentStatus.inProgress);
    });

    test('Tournament generates share code and stores creator and participants', () {
      final code = Tournament.generateShareCode('unique-tourn-id-9988');
      expect(code.startsWith('TURF-'), isTrue);

      final tournament = Tournament(
        id: 'c-tourn-1',
        creatorId: 'user_admin_123',
        shareCode: 'TURF-9988',
        name: 'Metro Badminton',
        sportType: 'Badminton',
        format: TournamentFormat.roundRobin,
        participants: [],
        matches: [],
        participantUserIds: ['user_p1', 'user_p2'],
      );

      final map = tournament.toMap();
      expect(map['creatorId'], 'user_admin_123');
      expect(map['shareCode'], 'TURF-9988');
      expect(map['participantUserIds'], contains('user_p1'));

      final fromMap = Tournament.fromMap(map);
      expect(fromMap.creatorId, 'user_admin_123');
      expect(fromMap.shareCode, 'TURF-9988');
      expect(fromMap.participantUserIds.length, 2);
    });
  });
}
