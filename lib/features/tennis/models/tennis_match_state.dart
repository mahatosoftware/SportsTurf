enum TennisPoint {
  love,
  fifteen,
  thirty,
  forty,
  ad, // Advantage
  game
}

enum Player {
  playerA,
  playerB
}

enum MatchType {
  singles,
  doubles
}

class TennisMatchState {
  // Config
  final MatchType matchType;
  final String playerA1Name;
  final String playerA2Name; // For doubles
  final String playerB1Name;
  final String playerB2Name; // For doubles
  
  // Current Points (Standard Game)
  final TennisPoint pointPlayerA;
  final TennisPoint pointPlayerB;
  
  // Tie-Break Points
  final int tieBreakPointA;
  final int tieBreakPointB;
  
  // Games in Current Set
  final int gamesPlayerA;
  final int gamesPlayerB;
  
  // Sets Won
  final int setsWonPlayerA;
  final int setsWonPlayerB;
  
  // Current Set Index (0-based)
  final int currentSetIndex;
  
  // Who is serving?
  final Player server;
  
  // Match Config
  final int setsToWin; // 2 for Bo3, 3 for Bo5
  
  // Status Flags
  final bool isTimBreak; 
  final bool isSuperTieBreak; 
  final bool isMatchComplete;
  final Player? matchWinner;

  const TennisMatchState({
    required this.matchType,
    required this.playerA1Name,
    this.playerA2Name = "",
    required this.playerB1Name,
    this.playerB2Name = "",
    required this.pointPlayerA,
    required this.pointPlayerB,
    required this.tieBreakPointA,
    required this.tieBreakPointB,
    required this.gamesPlayerA,
    required this.gamesPlayerB,
    required this.setsWonPlayerA,
    required this.setsWonPlayerB,
    required this.currentSetIndex,
    required this.server,
    required this.setsToWin,
    this.isTimBreak = false,
    this.isSuperTieBreak = false,
    this.isMatchComplete = false,
    this.matchWinner,
  });

  factory TennisMatchState.initial({
    int setsToWin = 2, 
    Player startingServer = Player.playerA,
    MatchType matchType = MatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
  }) {
    return TennisMatchState(
      matchType: matchType,
      playerA1Name: playerA1Name,
      playerA2Name: playerA2Name,
      playerB1Name: playerB1Name,
      playerB2Name: playerB2Name,
      pointPlayerA: TennisPoint.love,
      pointPlayerB: TennisPoint.love,
      tieBreakPointA: 0,
      tieBreakPointB: 0,
      gamesPlayerA: 0,
      gamesPlayerB: 0,
      setsWonPlayerA: 0,
      setsWonPlayerB: 0,
      currentSetIndex: 0,
      server: startingServer,
      setsToWin: setsToWin,
    );
  }

  TennisMatchState copyWith({
    MatchType? matchType,
    String? playerA1Name,
    String? playerA2Name,
    String? playerB1Name,
    String? playerB2Name,
    TennisPoint? pointPlayerA,
    TennisPoint? pointPlayerB,
    int? tieBreakPointA,
    int? tieBreakPointB,
    int? gamesPlayerA,
    int? gamesPlayerB,
    int? setsWonPlayerA,
    int? setsWonPlayerB,
    int? currentSetIndex,
    Player? server,
    bool? isTimBreak,
    bool? isSuperTieBreak,
    bool? isMatchComplete,
    Player? matchWinner,
  }) {
    return TennisMatchState(
      matchType: matchType ?? this.matchType,
      playerA1Name: playerA1Name ?? this.playerA1Name,
      playerA2Name: playerA2Name ?? this.playerA2Name,
      playerB1Name: playerB1Name ?? this.playerB1Name,
      playerB2Name: playerB2Name ?? this.playerB2Name,
      pointPlayerA: pointPlayerA ?? this.pointPlayerA,
      pointPlayerB: pointPlayerB ?? this.pointPlayerB,
      tieBreakPointA: tieBreakPointA ?? this.tieBreakPointA,
      tieBreakPointB: tieBreakPointB ?? this.tieBreakPointB,
      gamesPlayerA: gamesPlayerA ?? this.gamesPlayerA,
      gamesPlayerB: gamesPlayerB ?? this.gamesPlayerB,
      setsWonPlayerA: setsWonPlayerA ?? this.setsWonPlayerA,
      setsWonPlayerB: setsWonPlayerB ?? this.setsWonPlayerB,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      server: server ?? this.server,
      setsToWin: setsToWin, 
      isTimBreak: isTimBreak ?? this.isTimBreak,
      isSuperTieBreak: isSuperTieBreak ?? this.isSuperTieBreak,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      matchWinner: matchWinner ?? this.matchWinner,
    );
  }
}
