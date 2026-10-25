enum SeasonStatus {
  upcoming,
  active,
  completed,
  archived,
}

extension SeasonStatusExt on SeasonStatus {
  String get displayName {
    switch (this) {
      case SeasonStatus.upcoming:
        return 'Upcoming';
      case SeasonStatus.active:
        return 'Active';
      case SeasonStatus.completed:
        return 'Completed';
      case SeasonStatus.archived:
        return 'Archived';
    }
  }
}

class Season {
  final String id;
  final String leagueId;
  final String name; // e.g. "Spring 2026", "Season 1"
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final SeasonStatus status;
  final List<String> tournamentIds;
  final Map<String, dynamic> rulesConfig;
  final DateTime createdAt;

  Season({
    required this.id,
    required this.leagueId,
    required this.name,
    this.startDate,
    this.endDate,
    this.registrationStart,
    this.registrationEnd,
    this.status = SeasonStatus.active,
    List<String>? tournamentIds,
    Map<String, dynamic>? rulesConfig,
    DateTime? createdAt,
  })  : tournamentIds = tournamentIds ?? [],
        rulesConfig = rulesConfig ?? {},
        createdAt = createdAt ?? DateTime.now();

  Season copyWith({
    String? id,
    String? leagueId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationStart,
    DateTime? registrationEnd,
    SeasonStatus? status,
    List<String>? tournamentIds,
    Map<String, dynamic>? rulesConfig,
    DateTime? createdAt,
  }) {
    return Season(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationStart: registrationStart ?? this.registrationStart,
      registrationEnd: registrationEnd ?? this.registrationEnd,
      status: status ?? this.status,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      rulesConfig: rulesConfig ?? this.rulesConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leagueId': leagueId,
      'name': name,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (registrationStart != null) 'registrationStart': registrationStart!.toIso8601String(),
      if (registrationEnd != null) 'registrationEnd': registrationEnd!.toIso8601String(),
      'status': status.name,
      'tournamentIds': tournamentIds,
      'rulesConfig': rulesConfig,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Season.fromMap(Map<String, dynamic> map) {
    return Season(
      id: map['id'] ?? '',
      leagueId: map['leagueId'] ?? '',
      name: map['name'] ?? '',
      startDate: map['startDate'] != null ? DateTime.tryParse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      registrationStart: map['registrationStart'] != null ? DateTime.tryParse(map['registrationStart']) : null,
      registrationEnd: map['registrationEnd'] != null ? DateTime.tryParse(map['registrationEnd']) : null,
      status: SeasonStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SeasonStatus.active,
      ),
      tournamentIds: List<String>.from(map['tournamentIds'] ?? []),
      rulesConfig: Map<String, dynamic>.from(map['rulesConfig'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
