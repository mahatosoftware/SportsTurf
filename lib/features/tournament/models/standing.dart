class Standing {
  final String teamId;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int points;
  final int rank;

  Standing({
    required this.teamId,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.points,
    required this.rank,
  });

   Standing copyWith({
    String? teamId,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? points,
    int? rank,
  }) {
    return Standing(
      teamId: teamId ?? this.teamId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      points: points ?? this.points,
      rank: rank ?? this.rank,
    );
  }
}
