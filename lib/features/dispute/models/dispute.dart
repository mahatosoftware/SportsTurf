enum DisputeType {
  scoreCorrection,
  matchProtest,
  playerEligibility,
  misconductIncident,
  walkoverDispute,
  officialDecisionAppeal,
}

extension DisputeTypeExt on DisputeType {
  String get displayName {
    switch (this) {
      case DisputeType.scoreCorrection:
        return 'Score Correction Request';
      case DisputeType.matchProtest:
        return 'Match Protest';
      case DisputeType.playerEligibility:
        return 'Player Eligibility Dispute';
      case DisputeType.misconductIncident:
        return 'Misconduct / Incident Report';
      case DisputeType.walkoverDispute:
        return 'Walkover Dispute';
      case DisputeType.officialDecisionAppeal:
        return 'Official Decision Appeal';
    }
  }
}

enum DisputeStatus {
  pending,
  underReview,
  resolved,
  rejected,
  appealed,
}

extension DisputeStatusExt on DisputeStatus {
  String get displayName {
    switch (this) {
      case DisputeStatus.pending:
        return 'Pending Review';
      case DisputeStatus.underReview:
        return 'Under Investigation';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.rejected:
        return 'Rejected';
      case DisputeStatus.appealed:
        return 'Under Appeal';
    }
  }
}

class Dispute {
  final String id;
  final String title;
  final String description;
  final DisputeType type;
  final DisputeStatus status;
  final String tournamentId;
  final String? matchId;
  final String? leagueId;
  final String submittedByUserId;
  final String submittedByName;
  final String? againstParticipantName;
  final String? reviewerUserId;
  final String? reviewerName;
  final String? resolution;
  final List<String> evidenceUrls;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Dispute({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = DisputeStatus.pending,
    required this.tournamentId,
    this.matchId,
    this.leagueId,
    required this.submittedByUserId,
    required this.submittedByName,
    this.againstParticipantName,
    this.reviewerUserId,
    this.reviewerName,
    this.resolution,
    List<String>? evidenceUrls,
    DateTime? createdAt,
    this.resolvedAt,
  })  : evidenceUrls = evidenceUrls ?? [],
        createdAt = createdAt ?? DateTime.now();

  String get filedByName => submittedByName;
  String get filedByUserId => submittedByUserId;
  String? get resolvedByName => reviewerName;

  Dispute copyWith({
    String? id,
    String? title,
    String? description,
    DisputeType? type,
    DisputeStatus? status,
    String? tournamentId,
    String? matchId,
    String? leagueId,
    String? submittedByUserId,
    String? submittedByName,
    String? againstParticipantName,
    String? reviewerUserId,
    String? reviewerName,
    String? resolution,
    List<String>? evidenceUrls,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Dispute(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      tournamentId: tournamentId ?? this.tournamentId,
      matchId: matchId ?? this.matchId,
      leagueId: leagueId ?? this.leagueId,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      submittedByName: submittedByName ?? this.submittedByName,
      againstParticipantName: againstParticipantName ?? this.againstParticipantName,
      reviewerUserId: reviewerUserId ?? this.reviewerUserId,
      reviewerName: reviewerName ?? this.reviewerName,
      resolution: resolution ?? this.resolution,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'tournamentId': tournamentId,
      if (matchId != null) 'matchId': matchId,
      if (leagueId != null) 'leagueId': leagueId,
      'submittedByUserId': submittedByUserId,
      'submittedByName': submittedByName,
      if (againstParticipantName != null) 'againstParticipantName': againstParticipantName,
      if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
      if (reviewerName != null) 'reviewerName': reviewerName,
      if (resolution != null) 'resolution': resolution,
      'evidenceUrls': evidenceUrls,
      'createdAt': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  factory Dispute.fromMap(Map<String, dynamic> map) {
    return Dispute(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: DisputeType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => DisputeType.matchProtest,
      ),
      status: DisputeStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DisputeStatus.pending,
      ),
      tournamentId: map['tournamentId'] ?? '',
      matchId: map['matchId'],
      leagueId: map['leagueId'],
      submittedByUserId: map['submittedByUserId'] ?? '',
      submittedByName: map['submittedByName'] ?? 'User',
      againstParticipantName: map['againstParticipantName'],
      reviewerUserId: map['reviewerUserId'],
      reviewerName: map['reviewerName'],
      resolution: map['resolution'],
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null ? DateTime.tryParse(map['resolvedAt']) : null,
    );
  }
}
