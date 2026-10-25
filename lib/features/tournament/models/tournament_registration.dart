enum RegistrationStatus {
  pending,
  approved,
  waitlisted,
  rejected,
  withdrawn,
}

extension RegistrationStatusExt on RegistrationStatus {
  String get displayName {
    switch (this) {
      case RegistrationStatus.pending:
        return 'Pending Review';
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.waitlisted:
        return 'Waitlisted';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String? leagueId;
  final String participantId;
  final String participantName;
  final bool isTeam;
  final List<String> rosterPlayerIds;
  final String submittedByUserId;
  final RegistrationStatus status;
  final String? reviewedByUserId;
  final String? reviewNotes;
  final double entryFee;
  final String paymentStatus; // 'unpaid', 'paid', 'refunded', 'exempt'
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  TournamentRegistration({
    required this.id,
    required this.tournamentId,
    this.leagueId,
    required this.participantId,
    required this.participantName,
    this.isTeam = false,
    List<String>? rosterPlayerIds,
    required this.submittedByUserId,
    this.status = RegistrationStatus.pending,
    this.reviewedByUserId,
    this.reviewNotes,
    this.entryFee = 0.0,
    this.paymentStatus = 'unpaid',
    DateTime? submittedAt,
    this.reviewedAt,
  })  : rosterPlayerIds = rosterPlayerIds ?? [],
        submittedAt = submittedAt ?? DateTime.now();

  TournamentRegistration copyWith({
    String? id,
    String? tournamentId,
    String? leagueId,
    String? participantId,
    String? participantName,
    bool? isTeam,
    List<String>? rosterPlayerIds,
    String? submittedByUserId,
    RegistrationStatus? status,
    String? reviewedByUserId,
    String? reviewNotes,
    double? entryFee,
    String? paymentStatus,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return TournamentRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      leagueId: leagueId ?? this.leagueId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      isTeam: isTeam ?? this.isTeam,
      rosterPlayerIds: rosterPlayerIds ?? this.rosterPlayerIds,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      status: status ?? this.status,
      reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      entryFee: entryFee ?? this.entryFee,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      if (leagueId != null) 'leagueId': leagueId,
      'participantId': participantId,
      'participantName': participantName,
      'isTeam': isTeam,
      'rosterPlayerIds': rosterPlayerIds,
      'submittedByUserId': submittedByUserId,
      'status': status.name,
      if (reviewedByUserId != null) 'reviewedByUserId': reviewedByUserId,
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
      'entryFee': entryFee,
      'paymentStatus': paymentStatus,
      'submittedAt': submittedAt.toIso8601String(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
    };
  }

  factory TournamentRegistration.fromMap(Map<String, dynamic> map) {
    return TournamentRegistration(
      id: map['id'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      leagueId: map['leagueId'],
      participantId: map['participantId'] ?? '',
      participantName: map['participantName'] ?? '',
      isTeam: map['isTeam'] ?? false,
      rosterPlayerIds: List<String>.from(map['rosterPlayerIds'] ?? []),
      submittedByUserId: map['submittedByUserId'] ?? '',
      status: RegistrationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      reviewedByUserId: map['reviewedByUserId'],
      reviewNotes: map['reviewNotes'],
      entryFee: (map['entryFee'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      submittedAt: map['submittedAt'] != null
          ? DateTime.tryParse(map['submittedAt']) ?? DateTime.now()
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt']) : null,
    );
  }
}
