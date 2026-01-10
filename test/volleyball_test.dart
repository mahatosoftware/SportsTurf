import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/volleyball/logic/volleyball_state_machine.dart';
import 'package:sports_turf/features/volleyball/models/volleyball_match_state.dart';

void main() {
  group('VolleyballStateMachine', () {
    late VolleyballStateMachine sm;

    setUp(() {
      sm = VolleyballStateMachine();
    });

    test('Initial state is correct', () {
      expect(sm.state.scoreA, 0);
      expect(sm.state.scoreB, 0);
      expect(sm.state.setsWonA, 0);
      expect(sm.state.setsWonB, 0);
      expect(sm.state.currentSet, 1);
      expect(sm.state.servingTeam, VolleyballTeam.teamA);
    });

    test('Rally scoring updates score and server', () {
      // Team A serves, Team A wins rally
      sm.scorePoint(VolleyballTeam.teamA);
      expect(sm.state.scoreA, 1);
      expect(sm.state.servingTeam, VolleyballTeam.teamA); // Winner serves

      // Team A serves, Team B wins rally (side-out)
      sm.scorePoint(VolleyballTeam.teamB);
      expect(sm.state.scoreB, 1);
      expect(sm.state.servingTeam, VolleyballTeam.teamB);
    });

    test('Set win logic (25 pts)', () {
      // Advance to 24-0
      for (int i = 0; i < 24; i++) {
        sm.scorePoint(VolleyballTeam.teamA);
      }
      expect(sm.state.scoreA, 24);
      expect(sm.state.setsWonA, 0);

      // Win set
      sm.scorePoint(VolleyballTeam.teamA);
      expect(sm.state.scoreA, 0); // Reset for next set
      expect(sm.state.setsWonA, 1);
      expect(sm.state.currentSet, 2);
    });

    test('Deuce logic (must win by 2)', () {
      // Advance to 24-24
      for (int i = 0; i < 24; i++) {
        sm.scorePoint(VolleyballTeam.teamA);
        sm.scorePoint(VolleyballTeam.teamB);
      }
      expect(sm.state.scoreA, 24);
      expect(sm.state.scoreB, 24);

      // 25-24 (Advantage A)
      sm.scorePoint(VolleyballTeam.teamA);
      expect(sm.state.scoreA, 25);
      expect(sm.state.setsWonA, 0); // Not won yet

      // 25-25 (Deuce)
      sm.scorePoint(VolleyballTeam.teamB);
      expect(sm.state.scoreA, 25);
      expect(sm.state.scoreB, 25);

      // 26-25 (Advantage A)
      sm.scorePoint(VolleyballTeam.teamA);
      
      // 27-25 (Set Win A)
      sm.scorePoint(VolleyballTeam.teamA);
      expect(sm.state.setsWonA, 1);
    });
  });
}
