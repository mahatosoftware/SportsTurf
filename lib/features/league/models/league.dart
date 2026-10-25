enum LeagueStatus {
  draft,
  upcoming,
  active,
  completed,
  archived,
}

extension LeagueStatusExt on LeagueStatus {
  String get displayName {
    switch (this) {
      case LeagueStatus.draft:
        return 'Draft';
      case LeagueStatus.upcoming:
        return 'Upcoming';
      case LeagueStatus.active:
        return 'Active';
      case LeagueStatus.completed:
        return 'Completed';
      case LeagueStatus.archived:
        return 'Archived';
    }
  }
}

class League {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String organizerName;
  final String shareCode;
  final String venue;
  final bool isPublic;
  final List<String> sportTypes;
  final List<String> tournamentIds;
  final List<String> seasonIds;
  final List<String> divisions; // e.g. ["Under-19", "Open Category", "Veterans", "Division A"]
  final LeagueStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerUrl;
  final DateTime createdAt;
  final Map<String, dynamic> pointsConfig;
  final String membershipPolicy; // 'Open', 'Approval Required', 'Invite Only'
  final List<String> ownerIds;
  final List<String> adminUserIds;
  final List<String> registrationManagerIds;
  final List<String> financeManagerIds;
  final List<String> mediaManagerIds;
  final List<Map<String, dynamic>> announcements;

  League({
    required this.id,
    required this.name,
    this.description = '',
    this.creatorId = '',
    this.organizerName = '',
    String? shareCode,
    this.venue = '',
    this.isPublic = true,
    List<String>? sportTypes,
    List<String>? tournamentIds,
    List<String>? seasonIds,
    List<String>? divisions,
    this.status = LeagueStatus.draft,
    this.startDate,
    this.endDate,
    this.bannerUrl,
    DateTime? createdAt,
    Map<String, dynamic>? pointsConfig,
    this.membershipPolicy = 'Open',
    List<String>? ownerIds,
    List<String>? adminUserIds,
    List<String>? registrationManagerIds,
    List<String>? financeManagerIds,
    List<String>? mediaManagerIds,
    List<Map<String, dynamic>>? announcements,
  })  : shareCode = (shareCode != null && shareCode.isNotEmpty)
            ? shareCode
            : generateShareCode(id),
        sportTypes = sportTypes ?? const ['All Sports'],
        tournamentIds = tournamentIds ?? const [],
        seasonIds = seasonIds ?? const [],
        divisions = divisions ?? const ['Open Category'],
        createdAt = createdAt ?? DateTime.now(),
        pointsConfig = pointsConfig ?? {},
        ownerIds = ownerIds ?? (creatorId.isNotEmpty ? [creatorId] : []),
        adminUserIds = adminUserIds ?? const [],
        registrationManagerIds = registrationManagerIds ?? const [],
        financeManagerIds = financeManagerIds ?? const [],
        mediaManagerIds = mediaManagerIds ?? const [],
        announcements = announcements ?? const [];

  static String generateShareCode([String? seedId]) {
    if (seedId != null && seedId.length >= 4) {
      final clean = seedId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (clean.length >= 4) {
        return 'LEAGUE-${clean.substring(clean.length - 4)}';
      }
    }
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(4, (i) => chars[(random ~/ (i + 1) * 11) % chars.length]).join();
    return 'LEAGUE-$code';
  }

  int get tournamentsCount => tournamentIds.length;

  bool isOwner(String userId) => creatorId == userId || ownerIds.contains(userId);
  bool isAdmin(String userId) => isOwner(userId) || adminUserIds.contains(userId);
  bool isRegistrationManager(String userId) => isAdmin(userId) || registrationManagerIds.contains(userId);
  bool isFinanceManager(String userId) => isOwner(userId) || financeManagerIds.contains(userId);
  bool isMediaManager(String userId) => isAdmin(userId) || mediaManagerIds.contains(userId);

  League copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? organizerName,
    String? shareCode,
    String? venue,
    bool? isPublic,
    List<String>? sportTypes,
    List<String>? tournamentIds,
    List<String>? seasonIds,
    List<String>? divisions,
    LeagueStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? bannerUrl,
    DateTime? createdAt,
    Map<String, dynamic>? pointsConfig,
    String? membershipPolicy,
    List<String>? ownerIds,
    List<String>? adminUserIds,
    List<String>? registrationManagerIds,
    List<String>? financeManagerIds,
    List<String>? mediaManagerIds,
    List<Map<String, dynamic>>? announcements,
  }) {
    return League(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      organizerName: organizerName ?? this.organizerName,
      shareCode: shareCode ?? this.shareCode,
      venue: venue ?? this.venue,
      isPublic: isPublic ?? this.isPublic,
      sportTypes: sportTypes ?? this.sportTypes,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      seasonIds: seasonIds ?? this.seasonIds,
      divisions: divisions ?? this.divisions,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdAt: createdAt ?? this.createdAt,
      pointsConfig: pointsConfig ?? this.pointsConfig,
      membershipPolicy: membershipPolicy ?? this.membershipPolicy,
      ownerIds: ownerIds ?? this.ownerIds,
      adminUserIds: adminUserIds ?? this.adminUserIds,
      registrationManagerIds: registrationManagerIds ?? this.registrationManagerIds,
      financeManagerIds: financeManagerIds ?? this.financeManagerIds,
      mediaManagerIds: mediaManagerIds ?? this.mediaManagerIds,
      announcements: announcements ?? this.announcements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'organizerName': organizerName,
      'shareCode': shareCode,
      'venue': venue,
      'isPublic': isPublic,
      'sportTypes': sportTypes,
      'tournamentIds': tournamentIds,
      'seasonIds': seasonIds,
      'divisions': divisions,
      'status': status.index,
      'statusName': status.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'bannerUrl': bannerUrl,
      'createdAt': createdAt.toIso8601String(),
      'pointsConfig': pointsConfig,
      'membershipPolicy': membershipPolicy,
      'ownerIds': ownerIds,
      'adminUserIds': adminUserIds,
      'registrationManagerIds': registrationManagerIds,
      'financeManagerIds': financeManagerIds,
      'mediaManagerIds': mediaManagerIds,
      'announcements': announcements,
    };
  }

  factory League.fromMap(Map<String, dynamic> map) {
    LeagueStatus parseStatus() {
      if (map['statusName'] is String) {
        return LeagueStatus.values.firstWhere(
          (e) => e.name == map['statusName'],
          orElse: () => LeagueStatus.draft,
        );
      }
      final idx = map['status'];
      if (idx is int && idx >= 0 && idx < LeagueStatus.values.length) {
        return LeagueStatus.values[idx];
      }
      return LeagueStatus.draft;
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

    return League(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      shareCode: map['shareCode'] ?? '',
      venue: map['venue'] ?? '',
      isPublic: map['isPublic'] ?? true,
      sportTypes: List<String>.from(map['sportTypes'] ?? ['All Sports']),
      tournamentIds: List<String>.from(map['tournamentIds'] ?? []),
      seasonIds: List<String>.from(map['seasonIds'] ?? []),
      divisions: List<String>.from(map['divisions'] ?? ['Open Category']),
      status: parseStatus(),
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      bannerUrl: map['bannerUrl'],
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      pointsConfig: map['pointsConfig'] is Map ? Map<String, dynamic>.from(map['pointsConfig']) : {},
      membershipPolicy: map['membershipPolicy'] ?? 'Open',
      ownerIds: List<String>.from(map['ownerIds'] ?? []),
      adminUserIds: List<String>.from(map['adminUserIds'] ?? []),
      registrationManagerIds: List<String>.from(map['registrationManagerIds'] ?? []),
      financeManagerIds: List<String>.from(map['financeManagerIds'] ?? []),
      mediaManagerIds: List<String>.from(map['mediaManagerIds'] ?? []),
      announcements: (map['announcements'] as List<dynamic>?)
              ?.map((a) => Map<String, dynamic>.from(a))
              .toList() ??
          [],
    );
  }
}
