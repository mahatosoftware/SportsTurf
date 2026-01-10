enum BadmintonPlayer { playerA, playerB }
enum BadmintonMatchType { singles, doubles }

class BadmintonMatchState {
  final BadmintonMatchType matchType;
  final String playerA1Name;
  final String playerA2Name;
  final String playerB1Name;
  final String playerB2Name;

  final int scoreA;
  final int scoreB;
  final int gamesWonA;
  final int gamesWonB;
  
  final BadmintonPlayer server; // Current server (Team A or B context)
  
  final int setsToWin; // Usually 2 (Best of 3)
  final bool isMatchComplete;
  final BadmintonPlayer? matchWinner;

  const BadmintonMatchState({
    required this.matchType,
    required this.playerA1Name,
    this.playerA2Name = "",
    required this.playerB1Name,
    this.playerB2Name = "",
    required this.scoreA,
    required this.scoreB,
    required this.gamesWonA,
    required this.gamesWonB,
    required this.server,
    required this.setsToWin,
    this.isMatchComplete = false,
    this.matchWinner,
  });

  factory BadmintonMatchState.initial({
    BadmintonMatchType matchType = BadmintonMatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
    int setsToWin = 2,
    BadmintonPlayer startingServer = BadmintonPlayer.playerA,
  }) {
    return BadmintonMatchState(
      matchType: matchType,
      playerA1Name: playerA1Name,
      playerA2Name: playerA2Name,
      playerB1Name: playerB1Name,
      playerB2Name: playerB2Name,
      scoreA: 0,
      scoreB: 0,
      gamesWonA: 0,
      gamesWonB: 0,
      server: startingServer,
      setsToWin: setsToWin,
    );
  }

  BadmintonMatchState copyWith({
    int? scoreA,
    int? scoreB,
    int? gamesWonA,
    int? gamesWonB,
    BadmintonPlayer? server,
    bool? isMatchComplete,
    BadmintonPlayer? matchWinner,
  }) {
    return BadmintonMatchState(
      matchType: matchType,
      playerA1Name: playerA1Name,
      playerA2Name: playerA2Name,
      playerB1Name: playerB1Name,
      playerB2Name: playerB2Name,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      gamesWonA: gamesWonA ?? this.gamesWonA,
      gamesWonB: gamesWonB ?? this.gamesWonB,
      server: server ?? this.server,
      setsToWin: setsToWin,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      matchWinner: matchWinner ?? this.matchWinner,
    );
  }
}
