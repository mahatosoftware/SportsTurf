enum TTPlayer { playerA, playerB }
enum TTSide { left, right }
enum TTMatchType { singles, doubles }

class TableTennisMatchState {
  final TTMatchType matchType;
  final String playerA1Name;
  final String playerA2Name;
  final String playerB1Name;
  final String playerB2Name;

  final int scoreA;
  final int scoreB;
  
  final int gamesWonA;
  final int gamesWonB;
  
  // Game Configuration
  final int gamesToWin; 
  
  // Service
  final TTPlayer server;
  final TTSide serveSide; 
  final bool isManualServeSide; 
  
  final bool isMatchComplete;
  final TTPlayer? matchWinner;

  const TableTennisMatchState({
    required this.matchType,
    required this.playerA1Name,
    required this.playerA2Name,
    required this.playerB1Name,
    required this.playerB2Name,
    required this.scoreA,
    required this.scoreB,
    required this.gamesWonA,
    required this.gamesWonB,
    required this.gamesToWin,
    required this.server,
    required this.serveSide,
    required this.isManualServeSide,
    this.isMatchComplete = false,
    this.matchWinner,
  });

  factory TableTennisMatchState.initial({
    TTMatchType matchType = TTMatchType.singles,
    String playerA1Name = "Player A",
    String playerA2Name = "",
    String playerB1Name = "Player B",
    String playerB2Name = "",
    int gamesToWin = 3,
    TTPlayer startingServer = TTPlayer.playerA,
  }) {
    return TableTennisMatchState(
      matchType: matchType,
      playerA1Name: playerA1Name,
      playerA2Name: playerA2Name,
      playerB1Name: playerB1Name,
      playerB2Name: playerB2Name,
      scoreA: 0,
      scoreB: 0,
      gamesWonA: 0,
      gamesWonB: 0,
      gamesToWin: gamesToWin,
      server: startingServer,
      serveSide: TTSide.right, 
      isManualServeSide: false,
    );
  }

  TableTennisMatchState copyWith({
    TTMatchType? matchType,
    String? playerA1Name,
    String? playerA2Name,
    String? playerB1Name,
    String? playerB2Name,
    int? scoreA,
    int? scoreB,
    int? gamesWonA,
    int? gamesWonB,
    TTPlayer? server,
    TTSide? serveSide,
    bool? isManualServeSide,
    bool? isMatchComplete,
    TTPlayer? matchWinner,
  }) {
    return TableTennisMatchState(
      matchType: matchType ?? this.matchType,
      playerA1Name: playerA1Name ?? this.playerA1Name,
      playerA2Name: playerA2Name ?? this.playerA2Name,
      playerB1Name: playerB1Name ?? this.playerB1Name,
      playerB2Name: playerB2Name ?? this.playerB2Name,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      gamesWonA: gamesWonA ?? this.gamesWonA,
      gamesWonB: gamesWonB ?? this.gamesWonB,
      gamesToWin: gamesToWin,
      server: server ?? this.server,
      serveSide: serveSide ?? this.serveSide,
      isManualServeSide: isManualServeSide ?? this.isManualServeSide,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      matchWinner: matchWinner ?? this.matchWinner,
    );
  }
}
