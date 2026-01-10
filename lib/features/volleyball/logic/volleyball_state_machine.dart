import '../models/volleyball_match_state.dart';

class VolleyballStateMachine {
  final List<VolleyballMatchState> _history = [];
  VolleyballMatchState _currentState;

  VolleyballStateMachine({
    VolleyballTeam startingServer = VolleyballTeam.teamA,
    int setsToWin = 3,
    String teamAName = "Team A",
    String teamBName = "Team B",
  }) : _currentState = VolleyballMatchState.initial(
          startingServer: startingServer,
          setsToWin: setsToWin,
          teamAName: teamAName,
          teamBName: teamBName,
        );

  VolleyballMatchState get state => _currentState;
  bool get canUndo => _history.isNotEmpty;

  void scorePoint(VolleyballTeam winner) {
    if (_currentState.isMatchComplete) return;
    _history.add(_currentState);

    int newScoreA = _currentState.scoreA;
    int newScoreB = _currentState.scoreB;
    VolleyballTeam currentServer = _currentState.servingTeam;

    // Rally scoring: Point awarded to winner of rally regardless of who served
    if (winner == VolleyballTeam.teamA) {
      newScoreA++;
    } else {
      newScoreB++;
    }

    // Determine next server
    // Rule: The team that wins the rally serves.
    // If the receiving team wins the rally, they gain the serve (side-out).
    VolleyballTeam nextServer = winner;

    bool setWon = false;
    // Standard set: 25 pts, win by 2
    // Deciding set (5th set): 15 pts, win by 2
    int pointsToWinSet = 25;
    if (_currentState.currentSet == 5) {
      pointsToWinSet = 15;
    }

    int winnerScore = winner == VolleyballTeam.teamA ? newScoreA : newScoreB;
    int loserScore = winner == VolleyballTeam.teamA ? newScoreB : newScoreA;

    if (winnerScore >= pointsToWinSet && (winnerScore - loserScore) >= 2) {
      setWon = true;
    }

    if (setWon) {
      _processSetWin(winner);
    } else {
      _currentState = _currentState.copyWith(
        scoreA: newScoreA,
        scoreB: newScoreB,
        servingTeam: nextServer,
      );
    }
  }

  void _processSetWin(VolleyballTeam winner) {
    int newSetsA = _currentState.setsWonA;
    int newSetsB = _currentState.setsWonB;

    if (winner == VolleyballTeam.teamA) {
      newSetsA++;
    } else {
      newSetsB++;
    }

    // Check Match Win
    if (newSetsA >= _currentState.setsToWin || newSetsB >= _currentState.setsToWin) {
      _currentState = _currentState.copyWith(
        scoreA: 0, scoreB: 0,
        setsWonA: newSetsA,
        setsWonB: newSetsB,
        matchWinner: winner,
        isMatchComplete: true,
      );
    } else {
      // Start next set
      // Rule: Teams change courts (not tracked in state but implied visual),
      // First serve of new set is usually trailing team or alternating?
      // Simplified: Loser of previous set serves, or alternate.
      // Standard: The team that did not serve first in the previous set serves first in the next set.
      // We need to track who served first in current set.
      // For simplicity in this v1: Let's assume alternating first serve.
      // Since we don't track who served first, let's just default to loser serves or similar.
      // Better: Reset scores, increment set count.
      
      _currentState = _currentState.copyWith(
        scoreA: 0, 
        scoreB: 0,
        setsWonA: newSetsA,
        setsWonB: newSetsB,
        currentSet: _currentState.currentSet + 1,
        // Defaulting to rally winner serves the next point (standard flow)
        // Or if strictly following set rules, we might need a dedicated var.
        // Let's keep it simple: Winner of the set serves first in next? 
        // Actually, normally it alternates or is coin-tossed. 
        // Let user manually override if needed, but default to winner serves.
        servingTeam: winner, 
      );
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }

  void reset() {
    _history.clear();
    _currentState = VolleyballMatchState.initial(
      setsToWin: _currentState.setsToWin,
      teamAName: _currentState.teamAName,
      teamBName: _currentState.teamBName,
    );
  }
}
