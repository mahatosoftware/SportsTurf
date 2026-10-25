import 'team.dart';

enum MatchStatus {
  upcoming,
  live,
  completed,
  ready,
  postponed,
  cancelled,
  walkover,
  paused,
}

extension MatchStatusExt on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.upcoming:
        return 'Scheduled';
      case MatchStatus.ready:
        return 'Ready';
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.paused:
        return 'Paused';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.postponed:
        return 'Postponed';
      case MatchStatus.cancelled:
        return 'Cancelled';
      case MatchStatus.walkover:
        return 'Walkover';
    }
  }
}

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
  final String? venueCourt; // Court 1, Pitch A, Table 2, etc.
  final String? venueId;
  final String? playingAreaId;
  final int durationMinutes;
  final String? assignedScorerId; // Scorer UID
  final String? assignedRefereeId; // Referee UID
  final String? statusReason; // Reason for postponement, walkover, or cancellation
  final Map<String, dynamic>? liveMatchData; // In-progress sport scoring snapshot
  final List<Map<String, dynamic>> eventHistory; // Chronological score & correction events

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
    this.venueCourt,
    this.venueId,
    this.playingAreaId,
    this.durationMinutes = 60,
    this.assignedScorerId,
    this.assignedRefereeId,
    this.statusReason,
    this.liveMatchData,
    List<Map<String, dynamic>>? eventHistory,
  }) : eventHistory = eventHistory ?? [];

  bool canScore(String? userId) {
    if (userId == null) return false;
    return assignedScorerId != null && assignedScorerId == userId;
  }

  bool isAssignedReferee(String? userId) {
    if (userId == null) return false;
    return assignedRefereeId == userId;
  }

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
    String? venueCourt,
    String? venueId,
    String? playingAreaId,
    int? durationMinutes,
    String? assignedScorerId,
    String? assignedRefereeId,
    String? statusReason,
    Map<String, dynamic>? liveMatchData,
    List<Map<String, dynamic>>? eventHistory,
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
      venueCourt: venueCourt ?? this.venueCourt,
      venueId: venueId ?? this.venueId,
      playingAreaId: playingAreaId ?? this.playingAreaId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignedScorerId: assignedScorerId ?? this.assignedScorerId,
      assignedRefereeId: assignedRefereeId ?? this.assignedRefereeId,
      statusReason: statusReason ?? this.statusReason,
      liveMatchData: liveMatchData ?? this.liveMatchData,
      eventHistory: eventHistory ?? this.eventHistory,
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
      'statusName': status.name,
      'nextMatchId': nextMatchId,
      'loserNextMatchId': loserNextMatchId,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'venueCourt': venueCourt,
      if (venueId != null) 'venueId': venueId,
      if (playingAreaId != null) 'playingAreaId': playingAreaId,
      'durationMinutes': durationMinutes,
      'assignedScorerId': assignedScorerId,
      if (assignedRefereeId != null) 'assignedRefereeId': assignedRefereeId,
      'statusReason': statusReason,
      'liveMatchData': liveMatchData,
      'eventHistory': eventHistory,
      'participantA': participantA?.toMap(),
      'participantB': participantB?.toMap(),
    };
  }

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    MatchStatus parseStatus() {
      if (map['statusName'] is String) {
        return MatchStatus.values.firstWhere(
          (e) => e.name == map['statusName'],
          orElse: () => MatchStatus.upcoming,
        );
      }
      final idx = map['status'];
      if (idx is int && idx >= 0 && idx < MatchStatus.values.length) {
        return MatchStatus.values[idx];
      }
      return MatchStatus.upcoming;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        final dynamic t = val;
        return t.toDate();
      } catch (_) {}
      return null;
    }

    return TournamentMatch(
      id: map['id'] ?? '',
      round: map['round'] ?? 1,
      matchNumber: map['matchNumber'] ?? 1,
      participantAId: map['participantAId'],
      participantBId: map['participantBId'],
      scoreA: map['scoreA'],
      scoreB: map['scoreB'],
      winnerId: map['winnerId'],
      status: parseStatus(),
      nextMatchId: map['nextMatchId'],
      loserNextMatchId: map['loserNextMatchId'],
      scheduledTime: parseDate(map['scheduledTime']),
      venueCourt: map['venueCourt'],
      venueId: map['venueId'],
      playingAreaId: map['playingAreaId'],
      durationMinutes: map['durationMinutes'] ?? 60,
      assignedScorerId: map['assignedScorerId'],
      assignedRefereeId: map['assignedRefereeId'],
      statusReason: map['statusReason'],
      liveMatchData: map['liveMatchData'] is Map ? Map<String, dynamic>.from(map['liveMatchData']) : null,
      eventHistory: (map['eventHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      participantA: map['participantA'] != null ? Team.fromMap(Map<String, dynamic>.from(map['participantA'])) : null,
      participantB: map['participantB'] != null ? Team.fromMap(Map<String, dynamic>.from(map['participantB'])) : null,
    );
  }
}
