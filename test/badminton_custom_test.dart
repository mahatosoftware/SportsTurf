import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/badminton/models/badminton_match_state.dart';
import 'package:sports_turf/features/badminton/logic/badminton_state_machine.dart';

void main() {
  group('Badminton Custom Scoring', () {
    test('Initial state reflects custom configuration', () {
      final machine = BadmintonStateMachine(
        setsToWin: 1,
        pointsPerGame: 11,
      );
      
      expect(machine.state.setsToWin, 1);
      expect(machine.state.pointsPerGame, 11);
    });

    test('Game wins at 11 points', () {
      final machine = BadmintonStateMachine(
        setsToWin: 1,
        pointsPerGame: 11,
      );

      // A scores 10 points
      for (int i = 0; i < 10; i++) {
        machine.scorePoint(BadmintonPlayer.playerA);
      }
      expect(machine.state.scoreA, 10);
      expect(machine.state.isMatchComplete, false);

      // A scores 11th point
      machine.scorePoint(BadmintonPlayer.playerA);
      
      expect(machine.state.scoreA, 11);
      expect(machine.state.gamesWonA, 1);
      expect(machine.state.isMatchComplete, true); // Best of 1
    });

    test('Deuce logic with custom points (11)', () {
      final machine = BadmintonStateMachine(
         setsToWin: 1,
         pointsPerGame: 11, 
      );
      
      // 10-10
      for(int i=0; i<10; i++) {
        machine.scorePoint(BadmintonPlayer.playerA);
        machine.scorePoint(BadmintonPlayer.playerB);
      }
      
      // A scores 11 (11-10) -> No win yet (need by 2)
      machine.scorePoint(BadmintonPlayer.playerA);
      expect(machine.state.scoreA, 11);
      expect(machine.state.gamesWonA, 0);
      
      // A scores 12 (12-10) -> Win
      machine.scorePoint(BadmintonPlayer.playerA);
      expect(machine.state.scoreA, 12);
      expect(machine.state.gamesWonA, 1);
    });
  });
}
