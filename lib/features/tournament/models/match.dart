import 'team.dart';

enum MatchStatus { upcoming, live, completed }

class TournamentMatch {
  final String id;
  final int round; // Round number (1, 2, 3...)
  final int matchNumber; // Unique number within the tournament
  final String? participantAId; // Can be null if TBD
  final String? participantBId; // Can be null if TBD
  final int? scoreA;
  final int? scoreB;
  final String? winnerId;
  final MatchStatus status;
  
  // Pointers for tournament progression
  final String? nextMatchId; // ID of the match the winner goes to
  final String? loserNextMatchId; // ID of the match the loser goes to (for Double Elimination)
  
  final DateTime? scheduledTime; // Scheduled Date and Time

  // Virtual Team objects for UI convenience (populated at runtime)
  Team? participantA;
  Team? participantB;

  TournamentMatch({
    required this.id,
    required this.round,
    required this.matchNumber,
    this.participantAId,
    this.participantBId,
    this.scoreA,
    this.scoreB,
    this.winnerId,
    this.status = MatchStatus.upcoming,
    this.nextMatchId,
    this.loserNextMatchId,
    this.participantA,
    this.participantB,
    this.scheduledTime,
  });

  TournamentMatch copyWith({
    String? id,
    int? round,
    int? matchNumber,
    String? participantAId,
    String? participantBId,
    int? scoreA,
    int? scoreB,
    String? winnerId,
    MatchStatus? status,
    String? nextMatchId,
    String? loserNextMatchId,
    Team? participantA,
    Team? participantB,
    DateTime? scheduledTime,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      participantAId: participantAId ?? this.participantAId,
      participantBId: participantBId ?? this.participantBId,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      loserNextMatchId: loserNextMatchId ?? this.loserNextMatchId,
      participantA: participantA ?? this.participantA,
      participantB: participantB ?? this.participantB,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'round': round,
      'matchNumber': matchNumber,
      'participantAId': participantAId,
      'participantBId': participantBId,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'winnerId': winnerId,
      'status': status.index,
      'nextMatchId': nextMatchId,
      'loserNextMatchId': loserNextMatchId,
      'scheduledTime': scheduledTime?.toIso8601String(),
      // We don't necessarily need to serialize the full Team objects here if they are in the Tournament participants list,
      // but it makes UI rendering easier if we include them or re-hydrate them.
      // For now, let's Serialize them to be safe and self-contained.
      'participantA': participantA?.toMap(),
      'participantB': participantB?.toMap(),
    };
  }

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    return TournamentMatch(
      id: map['id'],
      round: map['round'],
      matchNumber: map['matchNumber'],
      participantAId: map['participantAId'],
      participantBId: map['participantBId'],
      scoreA: map['scoreA'],
      scoreB: map['scoreB'],
      winnerId: map['winnerId'],
      status: MatchStatus.values[map['status'] ?? 0],
      nextMatchId: map['nextMatchId'],
      loserNextMatchId: map['loserNextMatchId'],
      participantA: map['participantA'] != null ? Team.fromMap(map['participantA']) : null,
      participantB: map['participantB'] != null ? Team.fromMap(map['participantB']) : null,
      scheduledTime: map['scheduledTime'] != null ? DateTime.parse(map['scheduledTime']) : null,
    );
  }
}
