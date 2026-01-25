enum CricketExtraType { none, wide, noBall, bye, legBye }
enum WicketType { bowled, caught, lbw, runOut, stumped, hitWicket, other }

class CricketPlayer {
  final String name;
  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isOut;
  
  final int ballsBowled;
  final int runsConceded;
  final int wickets;

  const CricketPlayer({
    required this.name,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
  });
  
  CricketPlayer copyWith({
    String? name,
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    bool? isOut,
    int? ballsBowled,
    int? runsConceded,
    int? wickets,
  }) {
    return CricketPlayer(
      name: name ?? this.name,
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'runs': runs,
      'ballsFaced': ballsFaced,
      'fours': fours,
      'sixes': sixes,
      'isOut': isOut,
      'ballsBowled': ballsBowled,
      'runsConceded': runsConceded,
      'wickets': wickets,
    };
  }

  factory CricketPlayer.fromMap(Map<String, dynamic> map) {
    return CricketPlayer(
      name: map['name'],
      runs: map['runs'] ?? 0,
      ballsFaced: map['ballsFaced'] ?? 0,
      fours: map['fours'] ?? 0,
      sixes: map['sixes'] ?? 0,
      isOut: map['isOut'] ?? false,
      ballsBowled: map['ballsBowled'] ?? 0,
      runsConceded: map['runsConceded'] ?? 0,
      wickets: map['wickets'] ?? 0,
    );
  }
}

class CricketMatchState {
  final String teamAName;
  final String teamBName;
  final List<String> squadA;
  final List<String> squadB;
  final int totalOvers; 
  
  final int currentInning; 
  final String battingTeamName;
  final String bowlingTeamName;
  
  final int totalRuns;
  final int wicketsLost;
  final int oversCompleted;
  final int ballsInOver; 
  
  final CricketPlayer striker;
  final CricketPlayer nonStriker;
  final CricketPlayer bowler;
  
  final int? targetRuns;
  final List<String> ballHistory; 
  final List<String> dismissedPlayers; // Track names of players who are out

  final bool isMatchComplete;
  final String? matchResult;

  final Map<String, CricketPlayer> playerStats; // Registry of ALL players' stats

  const CricketMatchState({
    required this.teamAName,
    required this.teamBName,
    required this.squadA,
    required this.squadB,
    required this.totalOvers,
    required this.currentInning,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.totalRuns,
    required this.wicketsLost,
    required this.oversCompleted,
    required this.ballsInOver,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    this.targetRuns,
    this.ballHistory = const [],
    this.dismissedPlayers = const [],
    this.isMatchComplete = false,
    this.matchResult,
    this.playerStats = const {},
  });

  factory CricketMatchState.initial({
    String teamAName = "Team A",
    String teamBName = "Team B",
    List<String> squadA = const [],
    List<String> squadB = const [],
    int totalOvers = 5,
    String? battingFirst, // Optional: defaults to Team A
  }) {
    // Determine Batting and Bowling Teams
    String battingName = battingFirst ?? teamAName;
    String bowlingName = (battingName == teamAName) ? teamBName : teamAName;
    
    // Determine correct squads for batting and bowling
    List<String> battingSquad = (battingName == teamAName) ? squadA : squadB;
    List<String> bowlingSquad = (battingName == teamAName) ? squadB : squadA;

    // Default initial players
    String s1 = battingSquad.isNotEmpty ? battingSquad[0] : "Striker";
    String s2 = battingSquad.length > 1 ? battingSquad[1] : "Non-Striker";
    String b1 = bowlingSquad.isNotEmpty ? bowlingSquad[0] : "Bowler";
    
    // Initialize stats map
    Map<String, CricketPlayer> stats = {};
    for (var p in squadA) { stats[p] = CricketPlayer(name: p); }
    for (var p in squadB) { stats[p] = CricketPlayer(name: p); }
    
    // Fallbacks if not in squad
    if (!stats.containsKey(s1)) stats[s1] = CricketPlayer(name: s1);
    if (!stats.containsKey(s2)) stats[s2] = CricketPlayer(name: s2);
    if (!stats.containsKey(b1)) stats[b1] = CricketPlayer(name: b1);

    return CricketMatchState(
      teamAName: teamAName,
      teamBName: teamBName,
      squadA: squadA,
      squadB: squadB,
      totalOvers: totalOvers,
      currentInning: 1,
      battingTeamName: battingName,
      bowlingTeamName: bowlingName,
      totalRuns: 0,
      wicketsLost: 0,
      oversCompleted: 0,
      ballsInOver: 0,
      striker: stats[s1]!,
      nonStriker: stats[s2]!,
      bowler: stats[b1]!,
      dismissedPlayers: [],
      playerStats: stats,
    );
  }

  CricketMatchState copyWith({
    String? teamAName,
    String? teamBName,
    List<String>? squadA,
    List<String>? squadB,
    int? totalOvers,
    int? currentInning,
    String? battingTeamName,
    String? bowlingTeamName,
    int? totalRuns,
    int? wicketsLost,
    int? oversCompleted,
    int? ballsInOver,
    CricketPlayer? striker,
    CricketPlayer? nonStriker,
    CricketPlayer? bowler,
    int? targetRuns,
    List<String>? ballHistory,
    List<String>? dismissedPlayers,
    bool? isMatchComplete,
    String? matchResult,
    Map<String, CricketPlayer>? playerStats,
  }) {
    return CricketMatchState(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      squadA: squadA ?? this.squadA,
      squadB: squadB ?? this.squadB,
      totalOvers: totalOvers ?? this.totalOvers,
      currentInning: currentInning ?? this.currentInning,
      battingTeamName: battingTeamName ?? this.battingTeamName,
      bowlingTeamName: bowlingTeamName ?? this.bowlingTeamName,
      totalRuns: totalRuns ?? this.totalRuns,
      wicketsLost: wicketsLost ?? this.wicketsLost,
      oversCompleted: oversCompleted ?? this.oversCompleted,
      ballsInOver: ballsInOver ?? this.ballsInOver,
      striker: striker ?? this.striker,
      nonStriker: nonStriker ?? this.nonStriker,
      bowler: bowler ?? this.bowler,
      targetRuns: targetRuns ?? this.targetRuns,
      ballHistory: ballHistory ?? this.ballHistory,
      dismissedPlayers: dismissedPlayers ?? this.dismissedPlayers,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      matchResult: matchResult ?? this.matchResult,
      playerStats: playerStats ?? this.playerStats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamAName': teamAName,
      'teamBName': teamBName,
      'squadA': squadA,
      'squadB': squadB,
      'totalOvers': totalOvers,
      'currentInning': currentInning,
      'battingTeamName': battingTeamName,
      'bowlingTeamName': bowlingTeamName,
      'totalRuns': totalRuns,
      'wicketsLost': wicketsLost,
      'oversCompleted': oversCompleted,
      'ballsInOver': ballsInOver,
      'striker': striker.toMap(),
      'nonStriker': nonStriker.toMap(),
      'bowler': bowler.toMap(),
      'targetRuns': targetRuns,
      'ballHistory': ballHistory,
      'dismissedPlayers': dismissedPlayers,
      'isMatchComplete': isMatchComplete,
      'matchResult': matchResult,
      'playerStats': playerStats.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory CricketMatchState.fromMap(Map<String, dynamic> map) {
    return CricketMatchState(
      teamAName: map['teamAName'] ?? "Team A",
      teamBName: map['teamBName'] ?? "Team B",
      squadA: List<String>.from(map['squadA'] ?? []),
      squadB: List<String>.from(map['squadB'] ?? []),
      totalOvers: map['totalOvers'] ?? 5,
      currentInning: map['currentInning'] ?? 1,
      battingTeamName: map['battingTeamName'] ?? "Team A",
      bowlingTeamName: map['bowlingTeamName'] ?? "Team B",
      totalRuns: map['totalRuns'] ?? 0,
      wicketsLost: map['wicketsLost'] ?? 0,
      oversCompleted: map['oversCompleted'] ?? 0,
      ballsInOver: map['ballsInOver'] ?? 0,
      striker: CricketPlayer.fromMap(map['striker']),
      nonStriker: CricketPlayer.fromMap(map['nonStriker']),
      bowler: CricketPlayer.fromMap(map['bowler']),
      targetRuns: map['targetRuns'],
      ballHistory: List<String>.from(map['ballHistory'] ?? []),
      dismissedPlayers: List<String>.from(map['dismissedPlayers'] ?? []),
      isMatchComplete: map['isMatchComplete'] ?? false,
      matchResult: map['matchResult'],
      playerStats: (map['playerStats'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, CricketPlayer.fromMap(v)),
      ) ?? {},
    );
  }
}
