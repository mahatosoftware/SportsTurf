import 'team.dart';
import 'match.dart';

enum TournamentFormat {
  singleElimination,
  doubleElimination,
  roundRobin,
  leagueKnockout,
  groupStage,
  friendly,
}

extension TournamentFormatExt on TournamentFormat {
  String get displayName {
    switch (this) {
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.leagueKnockout:
        return 'League + Knockout';
      case TournamentFormat.groupStage:
        return 'Group Stage';
      case TournamentFormat.friendly:
        return 'Friendly Matches';
    }
  }
}

enum TournamentStatus {
  draft,
  registrationOpen,
  registrationClosed,
  fixturesPublished,
  inProgress,
  completed,
  archived,
}

extension TournamentStatusExt on TournamentStatus {
  String get displayName {
    switch (this) {
      case TournamentStatus.draft:
        return 'Draft';
      case TournamentStatus.registrationOpen:
        return 'Registration Open';
      case TournamentStatus.registrationClosed:
        return 'Registration Closed';
      case TournamentStatus.fixturesPublished:
        return 'Fixtures Published';
      case TournamentStatus.inProgress:
        return 'In Progress';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.archived:
        return 'Archived';
    }
  }
}

class Tournament {
  final String id;
  final String name;
  final String sportType;
  final TournamentFormat format;
  final List<Team> participants;
  final List<TournamentMatch> matches;
  final TournamentStatus status;
  final bool seeded;
  final DateTime createdAt;

  // Cloud & Multi-User Fields
  final String creatorId;
  final String shareCode;
  final List<String> participantUserIds;

  // Rich Tournament Management Fields
  final String description;
  final String organizerName;
  final String venue;
  final String? venueId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerUrl;
  final bool isPublic;
  final DateTime? registrationDeadline;
  final bool isTeamTournament;
  final int maxSquadSize;
  final int minParticipants;
  final int maxParticipants;
  final double entryFee;
  final String currency;
  final String? division;
  final String? seasonId;
  final Map<String, dynamic> ruleConfig;

  // League Association (Optional - Tournament can be Standalone or hosted under a League)
  final String? leagueId;
  final String? leagueName;

  // Scoped Officials
  final List<String> managerUserIds;
  final List<String> refereeUserIds;
  final List<String> scorerUserIds;
  final List<String> venueManagerIds;

  bool get isUnderLeague => leagueId != null && leagueId!.isNotEmpty;

  Tournament({
    required this.id,
    required this.name,
    required this.sportType,
    required this.format,
    required this.participants,
    required this.matches,
    this.status = TournamentStatus.draft,
    this.seeded = false,
    DateTime? createdAt,
    this.creatorId = '',
    String? shareCode,
    List<String>? participantUserIds,
    this.description = '',
    this.organizerName = '',
    this.venue = '',
    this.venueId,
    this.startDate,
    this.endDate,
    this.bannerUrl,
    this.isPublic = true,
    this.registrationDeadline,
    this.isTeamTournament = true,
    this.maxSquadSize = 15,
    this.minParticipants = 2,
    this.maxParticipants = 64,
    this.entryFee = 0.0,
    this.currency = 'USD',
    this.division,
    this.seasonId,
    Map<String, dynamic>? ruleConfig,
    this.leagueId,
    this.leagueName,
    List<String>? managerUserIds,
    List<String>? refereeUserIds,
    List<String>? scorerUserIds,
    List<String>? venueManagerIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        shareCode = (shareCode != null && shareCode.isNotEmpty) ? shareCode : generateShareCode(id),
        participantUserIds = participantUserIds ?? const [],
        ruleConfig = ruleConfig ?? {},
        managerUserIds = managerUserIds ?? (creatorId.isNotEmpty ? [creatorId] : []),
        refereeUserIds = refereeUserIds ?? const [],
        scorerUserIds = scorerUserIds ?? const [],
        venueManagerIds = venueManagerIds ?? const [];

  static String generateShareCode([String? seedId]) {
    if (seedId != null && seedId.length >= 4) {
      final clean = seedId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (clean.length >= 4) {
        return 'TURF-${clean.substring(clean.length - 4)}';
      }
    }
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(4, (i) => chars[(random ~/ (i + 1) * 7) % chars.length]).join();
    return 'TURF-$code';
  }

  bool isManager(String userId) => creatorId == userId || managerUserIds.contains(userId);
  bool isReferee(String userId) => isManager(userId) || refereeUserIds.contains(userId);
  bool isScorer(String userId) => isManager(userId) || scorerUserIds.contains(userId);
  bool isVenueManager(String userId) => isManager(userId) || venueManagerIds.contains(userId);

  Tournament copyWith({
    String? id,
    String? name,
    String? sportType,
    TournamentFormat? format,
    List<Team>? participants,
    List<TournamentMatch>? matches,
    TournamentStatus? status,
    bool? seeded,
    DateTime? createdAt,
    String? creatorId,
    String? shareCode,
    List<String>? participantUserIds,
    String? description,
    String? organizerName,
    String? venue,
    String? venueId,
    DateTime? startDate,
    DateTime? endDate,
    String? bannerUrl,
    bool? isPublic,
    DateTime? registrationDeadline,
    bool? isTeamTournament,
    int? maxSquadSize,
    int? minParticipants,
    int? maxParticipants,
    double? entryFee,
    String? currency,
    String? division,
    String? seasonId,
    Map<String, dynamic>? ruleConfig,
    String? leagueId,
    String? leagueName,
    List<String>? managerUserIds,
    List<String>? refereeUserIds,
    List<String>? scorerUserIds,
    List<String>? venueManagerIds,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      format: format ?? this.format,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      status: status ?? this.status,
      seeded: seeded ?? this.seeded,
      createdAt: createdAt ?? this.createdAt,
      creatorId: creatorId ?? this.creatorId,
      shareCode: shareCode ?? this.shareCode,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      description: description ?? this.description,
      organizerName: organizerName ?? this.organizerName,
      venue: venue ?? this.venue,
      venueId: venueId ?? this.venueId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isPublic: isPublic ?? this.isPublic,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      isTeamTournament: isTeamTournament ?? this.isTeamTournament,
      maxSquadSize: maxSquadSize ?? this.maxSquadSize,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
      division: division ?? this.division,
      seasonId: seasonId ?? this.seasonId,
      ruleConfig: ruleConfig ?? this.ruleConfig,
      leagueId: leagueId ?? this.leagueId,
      leagueName: leagueName ?? this.leagueName,
      managerUserIds: managerUserIds ?? this.managerUserIds,
      refereeUserIds: refereeUserIds ?? this.refereeUserIds,
      scorerUserIds: scorerUserIds ?? this.scorerUserIds,
      venueManagerIds: venueManagerIds ?? this.venueManagerIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'format': format.index,
      'formatName': format.name,
      'participants': participants.map((x) => x.toMap()).toList(),
      'matches': matches.map((x) => x.toMap()).toList(),
      'status': status.index,
      'statusName': status.name,
      'seeded': seeded,
      'createdAt': createdAt.toIso8601String(),
      'creatorId': creatorId,
      'shareCode': shareCode,
      'participantUserIds': participantUserIds,
      'description': description,
      'organizerName': organizerName,
      'venue': venue,
      if (venueId != null) 'venueId': venueId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'bannerUrl': bannerUrl,
      'isPublic': isPublic,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'isTeamTournament': isTeamTournament,
      'maxSquadSize': maxSquadSize,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'entryFee': entryFee,
      'currency': currency,
      if (division != null) 'division': division,
      if (seasonId != null) 'seasonId': seasonId,
      'ruleConfig': ruleConfig,
      'leagueId': leagueId,
      'leagueName': leagueName,
      'managerUserIds': managerUserIds,
      'refereeUserIds': refereeUserIds,
      'scorerUserIds': scorerUserIds,
      'venueManagerIds': venueManagerIds,
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    TournamentFormat parseFormat() {
      if (map['formatName'] is String) {
        return TournamentFormat.values.firstWhere(
          (e) => e.name == map['formatName'],
          orElse: () => TournamentFormat.singleElimination,
        );
      }
      final idx = map['format'];
      if (idx is int && idx >= 0 && idx < TournamentFormat.values.length) {
        return TournamentFormat.values[idx];
      }
      return TournamentFormat.singleElimination;
    }

    TournamentStatus parseStatus() {
      if (map['statusName'] is String) {
        return TournamentStatus.values.firstWhere(
          (e) => e.name == map['statusName'],
          orElse: () => TournamentStatus.draft,
        );
      }
      final idx = map['status'];
      if (idx is int && idx >= 0 && idx < TournamentStatus.values.length) {
        return TournamentStatus.values[idx];
      }
      return TournamentStatus.draft;
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

    return Tournament(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sportType: map['sportType'] ?? 'Badminton',
      format: parseFormat(),
      participants: List<Team>.from(map['participants']?.map((x) => Team.fromMap(x)) ?? []),
      matches: List<TournamentMatch>.from(map['matches']?.map((x) => TournamentMatch.fromMap(x)) ?? []),
      status: parseStatus(),
      seeded: map['seeded'] ?? false,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      creatorId: map['creatorId'] ?? '',
      shareCode: map['shareCode'] ?? '',
      participantUserIds: List<String>.from(map['participantUserIds'] ?? []),
      description: map['description'] ?? '',
      organizerName: map['organizerName'] ?? '',
      venue: map['venue'] ?? '',
      venueId: map['venueId'],
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      bannerUrl: map['bannerUrl'],
      isPublic: map['isPublic'] ?? true,
      registrationDeadline: parseDate(map['registrationDeadline']),
      isTeamTournament: map['isTeamTournament'] ?? true,
      maxSquadSize: map['maxSquadSize'] ?? 15,
      minParticipants: map['minParticipants'] ?? 2,
      maxParticipants: map['maxParticipants'] ?? 64,
      entryFee: (map['entryFee'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      division: map['division'],
      seasonId: map['seasonId'],
      ruleConfig: map['ruleConfig'] is Map ? Map<String, dynamic>.from(map['ruleConfig']) : {},
      leagueId: map['leagueId'],
      leagueName: map['leagueName'],
      managerUserIds: List<String>.from(map['managerUserIds'] ?? []),
      refereeUserIds: List<String>.from(map['refereeUserIds'] ?? []),
      scorerUserIds: List<String>.from(map['scorerUserIds'] ?? []),
      venueManagerIds: List<String>.from(map['venueManagerIds'] ?? []),
    );
  }
}
