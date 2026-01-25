import '../models/cricket_match_state.dart';

class CricketStateMachine {
  final List<CricketMatchState> _history = [];
  CricketMatchState _currentState;

  CricketStateMachine({
    String teamAName = "Team A",
    String teamBName = "Team B",
    List<String> squadA = const [],
    List<String> squadB = const [],
    int totalOvers = 5,
    String? battingFirst,
  }) : _currentState = CricketMatchState.initial(
          teamAName: teamAName,
          teamBName: teamBName,
          squadA: squadA,
          squadB: squadB,
          totalOvers: totalOvers,
          battingFirst: battingFirst,
        );

  CricketMatchState get state => _currentState;
  bool get canUndo => _history.isNotEmpty;

  void recordBall({
    int runsScored = 0,
    bool isWide = false,
    bool isNoBall = false,
    bool isBye = false,
    bool isLegBye = false,
    bool isWicket = false,
    bool isStrikerOut = true, // Who is out?
    WicketType? wicketType,
    String? newBatsmanName, 
    String? newBowlerName, 
  }) {
    if (_currentState.isMatchComplete) return;
    _history.add(_currentState);

    int totalBallRuns = runsScored;
    int extras = 0;
    
    if (isWide || isNoBall) {
      extras += 1; 
    }
    
    if (isBye || isLegBye) {
      extras += runsScored; 
      totalBallRuns = runsScored; 
      runsScored = 0; 
    }

    int grandTotalForBall = totalBallRuns + extras; 
    bool isLegalDelivery = !(isWide || isNoBall);

    int newTotalRuns = _currentState.totalRuns + grandTotalForBall;
    
    CricketPlayer newStriker = _currentState.striker;
    CricketPlayer newNonStriker = _currentState.nonStriker;
    CricketPlayer newBowler = _currentState.bowler;
    List<String> newDismissedPlayers = List.from(_currentState.dismissedPlayers);
    
    // Update Battings Stats (Only Striker faces balls and scores runs typically)
    // Non-striker might be out run-out, but didn't face the ball technically? 
    // Simplify: Striker faces ball unless Wide.
    if (!isWide) {
       newStriker = newStriker.copyWith(ballsFaced: newStriker.ballsFaced + 1);
       if (!isBye && !isLegBye) {
         newStriker = newStriker.copyWith(
           runs: newStriker.runs + runsScored,
           fours: runsScored == 4 ? newStriker.fours + 1 : newStriker.fours,
           sixes: runsScored == 6 ? newStriker.sixes + 1 : newStriker.sixes,
         );
       }
    }
    
    // Update Bowler
    if (isLegalDelivery) {
      newBowler = newBowler.copyWith(ballsBowled: newBowler.ballsBowled + 1);
    }
    newBowler = newBowler.copyWith(
      runsConceded: newBowler.runsConceded + grandTotalForBall - (isBye || isLegBye ? grandTotalForBall : 0),
    );

    // Wicket Handling
    int newWickets = _currentState.wicketsLost;
    if (isWicket) {
      newWickets++;
      newBowler = newBowler.copyWith(wickets: newBowler.wickets + 1);
      
      String outPlayerName;
      if (isStrikerOut) {
        newStriker = newStriker.copyWith(isOut: true);
        outPlayerName = newStriker.name;
        
        // Save Outgoing Striker Stats
        _currentState.playerStats[outPlayerName] = newStriker;

        // Replace Striker
        String nextName = newBatsmanName ?? "Batsman ${newWickets + 2}";
        newStriker = _currentState.playerStats[nextName] ?? CricketPlayer(name: nextName);
      } else {
        newNonStriker = newNonStriker.copyWith(isOut: true);
        outPlayerName = newNonStriker.name;

        // Save Outgoing Non-Striker Stats
        _currentState.playerStats[outPlayerName] = newNonStriker;

        // Replace Non-Striker
        String nextName = newBatsmanName ?? "Batsman ${newWickets + 2}";
        newNonStriker = _currentState.playerStats[nextName] ?? CricketPlayer(name: nextName);
      }
      
      newDismissedPlayers.add(outPlayerName);
    }
    
    // Over Progression
    int newBallsInOver = _currentState.ballsInOver;
    if (isLegalDelivery) {
      newBallsInOver++;
    }
    
    int newOversCompleted = _currentState.oversCompleted;
    bool overCompleted = false;
    
    if (newBallsInOver >= 6) {
      overCompleted = true;
      newOversCompleted++;
      newBallsInOver = 0;
    }
    
    // Update Stats Map for Current Active Players
    Map<String, CricketPlayer> updatedStats = Map.from(_currentState.playerStats);
    updatedStats[newStriker.name] = newStriker;
    updatedStats[newNonStriker.name] = newNonStriker;
    updatedStats[newBowler.name] = newBowler;

    // Innings Check
    if (newWickets >= 10 || newOversCompleted >= _currentState.totalOvers) { 
      // Update state temporarily to pass correct stats to innings end
      _currentState = _currentState.copyWith(
          striker: newStriker, nonStriker: newNonStriker, bowler: newBowler, 
          playerStats: updatedStats, wicketsLost: newWickets, totalRuns: newTotalRuns,
          oversCompleted: newOversCompleted, ballsInOver: newBallsInOver
      );
      _handleInningsEnd(newTotalRuns, newWickets, newOversCompleted, newBallsInOver, newDismissedPlayers, updatedStats);
      return;
    }
    
    // Chase Check
    if (_currentState.currentInning == 2 && _currentState.targetRuns != null) {
      if (newTotalRuns >= _currentState.targetRuns!) {
         _currentState = _currentState.copyWith(
           totalRuns: newTotalRuns,
           isMatchComplete: true,
           matchResult: "${_currentState.battingTeamName} Wins!",
           striker: newStriker,
           nonStriker: newNonStriker,
           bowler: newBowler,
           dismissedPlayers: newDismissedPlayers,
           playerStats: updatedStats,
         );
         return;
      }
    }

    // Strike Rotation
    CricketPlayer tempStriker = newStriker;
    CricketPlayer tempNonStriker = newNonStriker;
    
    bool isBoundary = (runsScored == 4 || runsScored == 6);
    // Swap if runs are odd
    if (!isBoundary && grandTotalForBall % 2 != 0) { 
         var t = tempStriker;
         tempStriker = tempNonStriker;
         tempNonStriker = t;
    }
    
    // Swap if Over Completed
    if (overCompleted) {
        var t = tempStriker;
        tempStriker = tempNonStriker;
        tempNonStriker = t;
        
        // Save partial over stats before switch
        updatedStats[newBowler.name] = newBowler;
        
        // Change Bowler
        String nextBowler = newBowlerName ?? "New Bowler";
        newBowler = updatedStats[nextBowler] ?? CricketPlayer(name: nextBowler); 
    }

    _currentState = _currentState.copyWith(
      totalRuns: newTotalRuns,
      wicketsLost: newWickets,
      ballsInOver: newBallsInOver,
      oversCompleted: newOversCompleted,
      striker: tempStriker,
      nonStriker: tempNonStriker,
      bowler: newBowler,
      dismissedPlayers: newDismissedPlayers,
      playerStats: updatedStats,
    );
  }
  
  void _handleInningsEnd(int runs, int wickets, int overs, int balls, List<String> dismissed, Map<String, CricketPlayer> stats) {
    if (_currentState.currentInning == 1) {
      // Switch Innings
      List<String> battingSquad = _currentState.squadB;
      List<String> bowlingSquad = _currentState.squadA;
      
      String s1 = battingSquad.isNotEmpty ? battingSquad[0] : "Striker 1";
      String s2 = battingSquad.length > 1 ? battingSquad[1] : "Striker 2";
      String b1 = bowlingSquad.isNotEmpty ? bowlingSquad[0] : "Bowler 1";

      // Initialize new players from stats if they exist, or create new
      // But ensure we keep the OLD stats for the players who just played
      
      CricketPlayer pStriker = stats[s1] ?? CricketPlayer(name: s1);
      CricketPlayer pNonStriker = stats[s2] ?? CricketPlayer(name: s2);
      CricketPlayer pBowler = stats[b1] ?? CricketPlayer(name: b1);
      
      // Update map for new starting players
      stats[s1] = pStriker;
      stats[s2] = pNonStriker;
      stats[b1] = pBowler;

      _currentState = CricketMatchState(
        teamAName: _currentState.teamAName,
        teamBName: _currentState.teamBName,
        squadA: _currentState.squadA,
        squadB: _currentState.squadB,
        totalOvers: _currentState.totalOvers,
        currentInning: 2,
        battingTeamName: _currentState.bowlingTeamName,
        bowlingTeamName: _currentState.battingTeamName,
        totalRuns: 0,
        wicketsLost: 0,
        oversCompleted: 0,
        ballsInOver: 0,
        striker: pStriker,
        nonStriker: pNonStriker,
        bowler: pBowler,
        targetRuns: runs + 1, 
        dismissedPlayers: [], // Reset for new innings
        playerStats: stats,
      );
    } else {
      int score2 = runs;
      int target = _currentState.targetRuns ?? 0;
      
      String result;
      if (score2 >= target) {
         result = "${_currentState.battingTeamName} Wins!";
      } else if (score2 == target - 1) {
         result = "Match Tied!";
      } else {
         result = "${_currentState.bowlingTeamName} Wins!";
      }
      
      _currentState = _currentState.copyWith(
        totalRuns: runs,
        wicketsLost: wickets,
        oversCompleted: overs,
        ballsInOver: balls,
        isMatchComplete: true,
        matchResult: result,
        dismissedPlayers: dismissed,
        playerStats: stats,
      );
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }

  void updatePlayers({String? striker, String? nonStriker, String? bowler}) {
    _history.add(_currentState); 
    
    // Load stats from registry if present
    CricketPlayer? newStriker = striker != null ? (_currentState.playerStats[striker] ?? CricketPlayer(name: striker)) : null;
    CricketPlayer? newNonStriker = nonStriker != null ? (_currentState.playerStats[nonStriker] ?? CricketPlayer(name: nonStriker)) : null;
    CricketPlayer? newBowler = bowler != null ? (_currentState.playerStats[bowler] ?? CricketPlayer(name: bowler)) : null;
    
    Map<String, CricketPlayer> updated = Map.from(_currentState.playerStats);
    if (newStriker != null) updated[newStriker.name] = newStriker;
    if (newNonStriker != null) updated[newNonStriker.name] = newNonStriker;
    if (newBowler != null) updated[newBowler.name] = newBowler;

    _currentState = _currentState.copyWith(
      striker: newStriker,
      nonStriker: newNonStriker,
      bowler: newBowler,
      playerStats: updated
    );
  }
}
