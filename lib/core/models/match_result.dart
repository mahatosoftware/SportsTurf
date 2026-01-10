class MatchResult {
  final int? id;
  final String sport;
  final DateTime date;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final String winner;
  final String details; // JSON string for extra details like set scores

  MatchResult({
    this.id,
    required this.sport,
    required this.date,
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.winner,
    this.details = "{}",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sport': sport,
      'date': date.toIso8601String(),
      'teamA': teamA,
      'teamB': teamB,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'winner': winner,
      'details': details,
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      id: map['id'],
      sport: map['sport'],
      date: DateTime.parse(map['date']),
      teamA: map['teamA'],
      teamB: map['teamB'],
      scoreA: map['scoreA'],
      scoreB: map['scoreB'],
      winner: map['winner'],
      details: map['details'],
    );
  }
}
