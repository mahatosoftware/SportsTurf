class MatchResult {
  final String? id;
  final String sport;
  final DateTime date;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final String winner;
  final String details; // JSON string for extra details like set scores
  final String? userId;

  MatchResult({
    dynamic id,
    required this.sport,
    required this.date,
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.winner,
    this.details = "{}",
    this.userId,
  }) : id = id?.toString();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sport': sport,
      'date': date.toIso8601String(),
      'teamA': teamA,
      'teamB': teamB,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'winner': winner,
      'details': details,
      if (userId != null) 'userId': userId,
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      id: map['id']?.toString(),
      sport: map['sport'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      teamA: map['teamA'] ?? '',
      teamB: map['teamB'] ?? '',
      scoreA: map['scoreA'] is int ? map['scoreA'] : (int.tryParse(map['scoreA']?.toString() ?? '0') ?? 0),
      scoreB: map['scoreB'] is int ? map['scoreB'] : (int.tryParse(map['scoreB']?.toString() ?? '0') ?? 0),
      winner: map['winner'] ?? '',
      details: map['details'] ?? "{}",
      userId: map['userId']?.toString(),
    );
  }

  MatchResult copyWith({
    dynamic id,
    String? sport,
    DateTime? date,
    String? teamA,
    String? teamB,
    int? scoreA,
    int? scoreB,
    String? winner,
    String? details,
    String? userId,
  }) {
    return MatchResult(
      id: id != null ? id.toString() : this.id,
      sport: sport ?? this.sport,
      date: date ?? this.date,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      winner: winner ?? this.winner,
      details: details ?? this.details,
      userId: userId ?? this.userId,
    );
  }
}
