import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/badminton/models/badminton_match_state.dart';
import 'package:sports_turf/features/badminton/logic/badminton_state_machine.dart';

void main() {
  group('Badminton Custom Scoring', () {
    test('Initial state reflects custom configuration', () {
      final machine = BadmintonStateMachine(
        setsToWin: 1,
        pointsPerGame: 31,
      );
      
      expect(machine.state.setsToWin, 1);
      expect(machine.state.pointsPerGame, 31);
    });

    test('Game wins at 31 points', () {
      final machine = BadmintonStateMachine(
        setsToWin: 1,
        pointsPerGame: 31,
      );

      // A scores 30 points
      for (int i = 0; i < 30; i++) {
        machine.scorePoint(BadmintonPlayer.playerA);
      }
      expect(machine.state.scoreA, 30);
      expect(machine.state.isMatchComplete, false);

      // A scores 31st point
      machine.scorePoint(BadmintonPlayer.playerA);
      
      expect(machine.state.scoreA, 31);
      expect(machine.state.gamesWonA, 1);
      expect(machine.state.isMatchComplete, true);
    });
  });
}
