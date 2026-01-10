import '../models/tennis_match_state.dart';

class TennisStateMachine {
  // Stack for Undo
  final List<TennisMatchState> _history = [];
  
  TennisMatchState _currentState;

  TennisStateMachine({
    int setsToWin = 2,
    MatchType matchType = MatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
  }) : _currentState = TennisMatchState.initial(
          setsToWin: setsToWin,
          matchType: matchType,
          playerA1Name: playerA1Name,
          playerA2Name: playerA2Name,
          playerB1Name: playerB1Name,
          playerB2Name: playerB2Name,
        );

  TennisMatchState get state => _currentState;
  bool get canUndo => _history.isNotEmpty;

  void scorePoint(Player scorer) {
    if (_currentState.isMatchComplete) return;

    // 1. Push current state to history
    _history.add(_currentState);

    // 2. Calculate new state
    _currentState = _nextState(_currentState, scorer);
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }
  
  void reset({Player startingServer = Player.playerA}) {
    _history.clear();
    // Preserve config from current state
    _currentState = TennisMatchState.initial(
      setsToWin: _currentState.setsToWin,
      startingServer: startingServer,
      matchType: _currentState.matchType,
      playerA1Name: _currentState.playerA1Name,
      playerA2Name: _currentState.playerA2Name,
      playerB1Name: _currentState.playerB1Name,
      playerB2Name: _currentState.playerB2Name,
    );
  }

  TennisMatchState _nextState(TennisMatchState current, Player scorer) {
     if (current.isTimBreak) {
       return _resolveTieBreakPoint(current, scorer);
     }
  
    TennisPoint pA = current.pointPlayerA;
    TennisPoint pB = current.pointPlayerB;
    
    // Logic for Standard Game Point Transition
    if (scorer == Player.playerA) {
      return _resolvePointA(current, pA, pB);
    } else {
      return _resolvePointB(current, pA, pB);
    }
  }

  TennisMatchState _resolveTieBreakPoint(TennisMatchState current, Player scorer) {
    int pA = current.tieBreakPointA;
    int pB = current.tieBreakPointB;

    if (scorer == Player.playerA) {
      pA++;
    } else {
      pB++;
    }

    // Toggle Server logic for Tie-Break:
    // 1st point (0->1): Switch.
    // 2nd point (1->2): No Switch.
    // 3rd point (2->3): Switch.
    int totalPoints = pA + pB;
    
    Player nextServer = current.server;
    if (totalPoints % 2 == 1) { 
       nextServer = current.server == Player.playerA ? Player.playerB : Player.playerA;
    } 

    // Check Win
    int target = current.isSuperTieBreak ? 10 : 7;
    bool win = false;
    if (scorer == Player.playerA && pA >= target && (pA - pB) >= 2) win = true;
    if (scorer == Player.playerB && pB >= target && (pB - pA) >= 2) win = true;

    if (win) {
      return _winSet(current, scorer);
    }

    return current.copyWith(
      tieBreakPointA: pA,
      tieBreakPointB: pB,
      server: nextServer
    );
  }

  TennisMatchState _resolvePointA(TennisMatchState current, TennisPoint pA, TennisPoint pB) {
    switch (pA) {
      case TennisPoint.love:
        return current.copyWith(pointPlayerA: TennisPoint.fifteen);
      case TennisPoint.fifteen:
        return current.copyWith(pointPlayerA: TennisPoint.thirty);
      case TennisPoint.thirty:
        return current.copyWith(pointPlayerA: TennisPoint.forty);
      case TennisPoint.forty:
        if (pB == TennisPoint.forty) {
          return current.copyWith(pointPlayerA: TennisPoint.ad); 
        } else if (pB == TennisPoint.ad) {
          return current.copyWith(pointPlayerB: TennisPoint.forty); 
        } else {
          return _winGame(current, Player.playerA);
        }
      case TennisPoint.ad:
        return _winGame(current, Player.playerA);
      default:
        return current;
    }
  }

  TennisMatchState _resolvePointB(TennisMatchState current, TennisPoint pA, TennisPoint pB) {
    switch (pB) {
      case TennisPoint.love:
        return current.copyWith(pointPlayerB: TennisPoint.fifteen);
      case TennisPoint.fifteen:
        return current.copyWith(pointPlayerB: TennisPoint.thirty);
      case TennisPoint.thirty:
        return current.copyWith(pointPlayerB: TennisPoint.forty);
      case TennisPoint.forty:
        if (pA == TennisPoint.forty) {
          return current.copyWith(pointPlayerB: TennisPoint.ad); 
        } else if (pA == TennisPoint.ad) {
          return current.copyWith(pointPlayerA: TennisPoint.forty); 
        } else {
          return _winGame(current, Player.playerB);
        }
      case TennisPoint.ad:
        return _winGame(current, Player.playerB);
      default:
        return current;
    }
  }

  TennisMatchState _winGame(TennisMatchState current, Player winner) {
    int gA = current.gamesPlayerA;
    int gB = current.gamesPlayerB;
    
    if (winner == Player.playerA) {
      gA++;
    } else {
      gB++;
    }

    Player nextServer = current.server == Player.playerA ? Player.playerB : Player.playerA;

    // Standard Set Logic
    bool winSet = false;
    
    // 6-6 Logic
    if (gA == 6 && gB == 6) {
      // Tie Break!
      // Final Set Check
      bool isFinalSet = false;
      if (current.currentSetIndex == (current.setsToWin * 2 - 2)) { 
        isFinalSet = true;
      }
      
      // Super TB if final set
      bool isSuper = isFinalSet; 
      
      return current.copyWith(
        gamesPlayerA: gA,
        gamesPlayerB: gB,
        isTimBreak: true,
        isSuperTieBreak: isSuper,
        tieBreakPointA: 0,
        tieBreakPointB: 0,
        server: nextServer 
      );
    }
    
    // 7-5 Win or 6-x Win
    if (winner == Player.playerA) {
      if (gA == 6 && gB <= 4) winSet = true; 
      if (gA == 7 && gB == 5) winSet = true; 
    } else {
      if (gB == 6 && gA <= 4) winSet = true;
      if (gB == 7 && gA == 5) winSet = true;
    }

    if (winSet) {
      return _winSet(current, winner);
    } else {
      return current.copyWith(
        gamesPlayerA: gA,
        gamesPlayerB: gB,
        pointPlayerA: TennisPoint.love,
        pointPlayerB: TennisPoint.love,
        server: nextServer
      );
    }
  }

  TennisMatchState _winSet(TennisMatchState current, Player winner) {
    int sA = current.setsWonPlayerA;
    int sB = current.setsWonPlayerB;
    
    if (winner == Player.playerA) {
      sA++;
    } else {
      sB++;
    }
    
    Player nextServer = current.server == Player.playerA ? Player.playerB : Player.playerA;
    
    // Record Set Score: "6-3" or "7-6(4)" if tie break logic was fuller, but here "7-6" or "6-2"
    final String setScore = "${current.gamesPlayerA}-${current.gamesPlayerB}";
    final List<String> updatedHistory = List.from(current.setScores)..add(setScore);

    // Check Match Win
    if (sA == current.setsToWin) {
      return current.copyWith(
        setsWonPlayerA: sA,
        gamesPlayerA: 0,
        tieBreakPointA: 0, 
        tieBreakPointB: 0,
        isTimBreak: false,
        isMatchComplete: true,
        matchWinner: Player.playerA,
        setScores: updatedHistory,
      );
    }
    if (sB == current.setsToWin) {
      return current.copyWith(
        setsWonPlayerB: sB,
        gamesPlayerA: 0,
        gamesPlayerB: 0,
        tieBreakPointA: 0,
        tieBreakPointB: 0,
        isTimBreak: false,
        isMatchComplete: true,
        matchWinner: Player.playerB,
        setScores: updatedHistory,
      );
    }

    // Next Set
    return current.copyWith(
      setsWonPlayerA: sA,
      setsWonPlayerB: sB,
      gamesPlayerA: 0,
      gamesPlayerB: 0,
      pointPlayerA: TennisPoint.love,
      pointPlayerB: TennisPoint.love,
      tieBreakPointA: 0,
      tieBreakPointB: 0,
      isTimBreak: false,
      isSuperTieBreak: false,
      currentSetIndex: current.currentSetIndex + 1,
      server: nextServer,
      setScores: updatedHistory,
    );
  }
}
