import '../models/badminton_match_state.dart';

class BadmintonStateMachine {
  final List<BadmintonMatchState> _history = [];
  BadmintonMatchState _currentState;

  BadmintonStateMachine({
    BadmintonMatchType matchType = BadmintonMatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
    int setsToWin = 2,
  }) : _currentState = BadmintonMatchState.initial(
          matchType: matchType,
          playerA1Name: playerA1Name,
          playerA2Name: playerA2Name,
          playerB1Name: playerB1Name,
          playerB2Name: playerB2Name,
          setsToWin: setsToWin,
        );

  BadmintonMatchState get state => _currentState;
  bool get canUndo => _history.isNotEmpty;

  void scorePoint(BadmintonPlayer winner) {
    if (_currentState.isMatchComplete) return;

    _history.add(_currentState);

    int newScoreA = _currentState.scoreA;
    int newScoreB = _currentState.scoreB;
    BadmintonPlayer nextServer = _currentState.server;

    // Rally Scoring
    if (winner == BadmintonPlayer.playerA) {
      newScoreA++;
      nextServer = BadmintonPlayer.playerA; 
    } else {
      newScoreB++;
      nextServer = BadmintonPlayer.playerB; 
    }

    if (_checkGameWin(newScoreA, newScoreB, winner == BadmintonPlayer.playerA)) {
       _processGameWin(winner, newScoreA, newScoreB);
    } else {
       _currentState = _currentState.copyWith(
         scoreA: newScoreA,
         scoreB: newScoreB,
         server: nextServer
       );
    }
  }

  bool _checkGameWin(int scoreA, int scoreB, bool winnerIsA) {
    int winnerScore = winnerIsA ? scoreA : scoreB;
    int loserScore = winnerIsA ? scoreB : scoreA;

    if (winnerScore >= 21 && (winnerScore - loserScore) >= 2) {
      return true;
    }
    if (winnerScore >= 30) {
      return true;
    }
    return false;
  }

  void _processGameWin(BadmintonPlayer winner, int finalScoreA, int finalScoreB) {
    int newGamesA = _currentState.gamesWonA;
    int newGamesB = _currentState.gamesWonB;

    if (winner == BadmintonPlayer.playerA) {
      newGamesA++;
    } else {
      newGamesB++;
    }
    
    // Record History
    final currentHistory = List<Map<String, int>>.from(_currentState.setHistory);
    currentHistory.add({'A': finalScoreA, 'B': finalScoreB});

    if (newGamesA >= _currentState.setsToWin || newGamesB >= _currentState.setsToWin) {
      _currentState = _currentState.copyWith(
        scoreA: finalScoreA, // Freeze final score
        scoreB: finalScoreB,
        gamesWonA: newGamesA,
        gamesWonB: newGamesB,
        setHistory: currentHistory,
        isMatchComplete: true,
        matchWinner: newGamesA > newGamesB ? BadmintonPlayer.playerA : BadmintonPlayer.playerB,
      );
    } else {
      // New Set
      _currentState = _currentState.copyWith(
        gamesWonA: newGamesA,
        gamesWonB: newGamesB,
        scoreA: 0,
        scoreB: 0,
        setHistory: currentHistory,
        server: winner,
      );
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }

  void reset({BadmintonPlayer startingServer = BadmintonPlayer.playerA}) {
    _history.clear();
    _currentState = BadmintonMatchState.initial(
      matchType: _currentState.matchType,
      playerA1Name: _currentState.playerA1Name,
      playerA2Name: _currentState.playerA2Name,
      playerB1Name: _currentState.playerB1Name,
      playerB2Name: _currentState.playerB2Name,
      setsToWin: _currentState.setsToWin,
      startingServer: startingServer,
    );
  }
}
