import '../models/table_tennis_match_state.dart';

class TableTennisStateMachine {
  final List<TableTennisMatchState> _history = [];
  TableTennisMatchState _currentState;

  TableTennisStateMachine({
    TTMatchType matchType = TTMatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
    int gamesToWin = 3,
  }) : _currentState = TableTennisMatchState.initial(
          matchType: matchType,
          playerA1Name: playerA1Name,
          playerA2Name: playerA2Name,
          playerB1Name: playerB1Name,
          playerB2Name: playerB2Name,
          gamesToWin: gamesToWin,
        );

  TableTennisMatchState get state => _currentState;
  bool get canUndo => _history.isNotEmpty;

  void scorePoint(TTPlayer winner) {
    if (_currentState.isMatchComplete) return;
    _history.add(_currentState);

    int newScoreA = _currentState.scoreA;
    int newScoreB = _currentState.scoreB;
    
    if (winner == TTPlayer.playerA) {
      newScoreA++;
    } else {
      newScoreB++;
    }
    
    // Check Game Win
    bool gameWon = false;
    TTPlayer? gameWinner;
    
    int winnerScore = winner == TTPlayer.playerA ? newScoreA : newScoreB;
    int loserScore = winner == TTPlayer.playerA ? newScoreB : newScoreA;
    
    // 11 points, win by 2
    if (winnerScore >= 11 && (winnerScore - loserScore) >= 2) {
      gameWon = true;
      gameWinner = winner;
    }
    
    if (gameWon) {
       _processGameWin(gameWinner!);
    } else {
       _updateScoreAndServer(newScoreA, newScoreB);
    }
  }
  
  void _updateScoreAndServer(int scoreA, int scoreB) {
    int totalPoints = scoreA + scoreB;
    TTPlayer currentServer = _currentState.server;
    TTPlayer nextServer = currentServer;
    
    bool isDeuce = (scoreA >= 10 && scoreB >= 10);
    bool shouldSwitch = false;
    
    if (isDeuce) {
       shouldSwitch = true; // Every point at deuce
    } else {
       if (totalPoints % 2 == 0) {
         shouldSwitch = true;
       }
    }
    
    if (shouldSwitch) {
      nextServer = (currentServer == TTPlayer.playerA) ? TTPlayer.playerB : TTPlayer.playerA;
    }
    
    TTSide nextSide = _currentState.serveSide;
    bool resetManual = false;
    if (currentServer != nextServer) {
      resetManual = true;
      nextSide = TTSide.right; 
    }
    
    _currentState = _currentState.copyWith(
      scoreA: scoreA,
      scoreB: scoreB,
      server: nextServer,
      serveSide: nextSide,
      isManualServeSide: resetManual ? false : _currentState.isManualServeSide,
    );
  }

  void _processGameWin(TTPlayer winner) {
    int newGamesA = _currentState.gamesWonA;
    int newGamesB = _currentState.gamesWonB;
    
    if (winner == TTPlayer.playerA) {
      newGamesA++;
    } else {
      newGamesB++;
    }
    
    if (newGamesA >= _currentState.gamesToWin || newGamesB >= _currentState.gamesToWin) {
      _currentState = _currentState.copyWith(
        scoreA: 0, scoreB: 0, 
        gamesWonA: newGamesA,
        gamesWonB: newGamesB,
        matchWinner: winner,
        isMatchComplete: true,
      );
    } else {
      // Rule: "The player who served first in a game shall receive first in the next game."
      // Simplified: Just toggle starting server for next game relative to match start
      // OR just set to winner serves? 
      // Let's stick to Winner Serves to keep it simple as we don't track detailed history
      _currentState = _currentState.copyWith(
        scoreA: 0,
        scoreB: 0,
        gamesWonA: newGamesA,
        gamesWonB: newGamesB,
        server: winner, 
        serveSide: TTSide.right,
      );
    }
  }

  void toggleServeSide() {
    if (_currentState.isMatchComplete) return;
    
    TTSide newSide = _currentState.serveSide == TTSide.left ? TTSide.right : TTSide.left;
    _currentState = _currentState.copyWith(
      serveSide: newSide,
      isManualServeSide: true, 
    );
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }

  void reset({TTPlayer startingServer = TTPlayer.playerA}) {
    _history.clear();
    _currentState = TableTennisMatchState.initial(
      matchType: _currentState.matchType,
      playerA1Name: _currentState.playerA1Name,
      playerA2Name: _currentState.playerA2Name,
      playerB1Name: _currentState.playerB1Name,
      playerB2Name: _currentState.playerB2Name,
      gamesToWin: _currentState.gamesToWin,
      startingServer: startingServer,
    );
  }
}
