class AuditLog {
  final String id;
  final String actorId;
  final String actorName;
  final String? actorEmail;
  final String action;
  final String targetType; // 'league', 'tournament', 'match', 'user', 'dispute', 'venue'
  final String targetId;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  })  : metadata = metadata ?? {},
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorId': actorId,
      'actorName': actorName,
      if (actorEmail != null) 'actorEmail': actorEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'System',
      actorEmail: map['actorEmail'],
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? 'general',
      targetId: map['targetId'] ?? '',
      description: map['description'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
