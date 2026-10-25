enum ScopedRoleType {
  superAdmin,
  leagueOwner,
  leagueAdmin,
  tournamentManager,
  registrationManager,
  venueManager,
  referee,
  scorer,
  teamManager,
  player,
  spectator,
  financeManager,
  mediaManager,
  sponsor,
}

extension ScopedRoleTypeExt on ScopedRoleType {
  String get displayName {
    switch (this) {
      case ScopedRoleType.superAdmin:
        return 'Platform Super Admin';
      case ScopedRoleType.leagueOwner:
        return 'League Owner';
      case ScopedRoleType.leagueAdmin:
        return 'League Administrator';
      case ScopedRoleType.tournamentManager:
        return 'Tournament Manager';
      case ScopedRoleType.registrationManager:
        return 'Registration Manager';
      case ScopedRoleType.venueManager:
        return 'Venue Manager';
      case ScopedRoleType.referee:
        return 'Referee / Match Official';
      case ScopedRoleType.scorer:
        return 'Scorer';
      case ScopedRoleType.teamManager:
        return 'Team Manager / Captain';
      case ScopedRoleType.player:
        return 'Player / Participant';
      case ScopedRoleType.spectator:
        return 'Spectator / Viewer';
      case ScopedRoleType.financeManager:
        return 'Finance Manager';
      case ScopedRoleType.mediaManager:
        return 'Media Manager';
      case ScopedRoleType.sponsor:
        return 'Sponsor / Partner';
    }
  }

  String get scopeDescription {
    switch (this) {
      case ScopedRoleType.superAdmin:
        return 'Platform-wide authority over all resources and settings.';
      case ScopedRoleType.leagueOwner:
        return 'Full ownership over league configuration, branding, and administrators.';
      case ScopedRoleType.leagueAdmin:
        return 'Manages day-to-day league operations, seasons, and tournaments.';
      case ScopedRoleType.tournamentManager:
        return 'Configures rules, draws brackets, and manages matches for a tournament.';
      case ScopedRoleType.registrationManager:
        return 'Reviews, approves, and manages team and player registrations & waitlists.';
      case ScopedRoleType.venueManager:
        return 'Manages courts, grounds, pitches, and schedule conflict resolution.';
      case ScopedRoleType.referee:
        return 'Oversees match conduct, verifies scores, and validates official outcomes.';
      case ScopedRoleType.scorer:
        return 'Operates the live scoreboard for assigned matches.';
      case ScopedRoleType.teamManager:
        return 'Manages team registrations, rosters, and match submissions.';
      case ScopedRoleType.player:
        return 'Participates in competitions and tracks personal performance.';
      case ScopedRoleType.spectator:
        return 'Read-only access to view public matches, brackets, and standings.';
      case ScopedRoleType.financeManager:
        return 'Manages entry fees, payments, refunds, and financial reporting.';
      case ScopedRoleType.mediaManager:
        return 'Publishes notices, announcements, and media updates.';
      case ScopedRoleType.sponsor:
        return 'Authorized access to partner visibility and sponsorship metrics.';
    }
  }
}

/// A scoped role binding a user to a specific resource (league, tournament, match, or team).
class ScopedRole {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userEmail;
  final ScopedRoleType role;
  final String? leagueId;
  final String? tournamentId;
  final String? matchId;
  final String? teamId;
  final DateTime assignedAt;
  final String assignedBy;

  const ScopedRole({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userEmail,
    required this.role,
    this.leagueId,
    this.tournamentId,
    this.matchId,
    this.teamId,
    required this.assignedAt,
    required this.assignedBy,
  });

  bool matchesScope({
    String? leagueId,
    String? tournamentId,
    String? matchId,
    String? teamId,
  }) {
    if (role == ScopedRoleType.superAdmin) return true;
    if (this.leagueId != null && this.leagueId == leagueId) return true;
    if (this.tournamentId != null && this.tournamentId == tournamentId) return true;
    if (this.matchId != null && this.matchId == matchId) return true;
    if (this.teamId != null && this.teamId == teamId) return true;
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      if (userEmail != null) 'userEmail': userEmail,
      'role': role.name,
      if (leagueId != null) 'leagueId': leagueId,
      if (tournamentId != null) 'tournamentId': tournamentId,
      if (matchId != null) 'matchId': matchId,
      if (teamId != null) 'teamId': teamId,
      'assignedAt': assignedAt.toIso8601String(),
      'assignedBy': assignedBy,
    };
  }

  factory ScopedRole.fromMap(Map<String, dynamic> map) {
    return ScopedRole(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? 'User',
      userEmail: map['userEmail'],
      role: ScopedRoleType.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => ScopedRoleType.spectator,
      ),
      leagueId: map['leagueId'],
      tournamentId: map['tournamentId'],
      matchId: map['matchId'],
      teamId: map['teamId'],
      assignedAt: map['assignedAt'] != null
          ? DateTime.tryParse(map['assignedAt']) ?? DateTime.now()
          : DateTime.now(),
      assignedBy: map['assignedBy'] ?? '',
    );
  }
}
