enum VolleyballTeam { teamA, teamB }

class VolleyballMatchState {
  final int scoreA;
  final int scoreB;
  final int setsWonA;
  final int setsWonB;
  final int currentSet; // 1-indexed: 1, 2, 3, 4, 5
  final VolleyballTeam servingTeam;
  final VolleyballTeam? matchWinner;
  final bool isMatchComplete;

  // Configuration
  final int setsToWin; // Usually 3 (best of 5)
  final String teamAName;
  final String teamBName;
  
  const VolleyballMatchState({
    required this.scoreA,
    required this.scoreB,
    required this.setsWonA,
    required this.setsWonB,
    required this.currentSet,
    required this.servingTeam,
    this.matchWinner,
    this.isMatchComplete = false,
    this.setsToWin = 3,
    required this.teamAName,
    required this.teamBName,
  });

  factory VolleyballMatchState.initial({
    VolleyballTeam startingServer = VolleyballTeam.teamA,
    int setsToWin = 3,
    String teamAName = "Team A",
    String teamBName = "Team B",
  }) {
    return VolleyballMatchState(
      scoreA: 0,
      scoreB: 0,
      setsWonA: 0,
      setsWonB: 0,
      currentSet: 1,
      servingTeam: startingServer,
      setsToWin: setsToWin,
      teamAName: teamAName,
      teamBName: teamBName,
    );
  }

  VolleyballMatchState copyWith({
    int? scoreA,
    int? scoreB,
    int? setsWonA,
    int? setsWonB,
    int? currentSet,
    VolleyballTeam? servingTeam,
    VolleyballTeam? matchWinner,
    bool? isMatchComplete,
    int? setsToWin,
    String? teamAName,
    String? teamBName,
  }) {
    return VolleyballMatchState(
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      setsWonA: setsWonA ?? this.setsWonA,
      setsWonB: setsWonB ?? this.setsWonB,
      currentSet: currentSet ?? this.currentSet,
      servingTeam: servingTeam ?? this.servingTeam,
      matchWinner: matchWinner ?? this.matchWinner,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      setsToWin: setsToWin ?? this.setsToWin,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
    );
  }
}
