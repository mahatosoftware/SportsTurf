class Team {
  final String id;
  final String name;
  final int? seed; // 1 being the highest seed
  final List<String> playerIds;
  final String? logoUrl;
  final String? colorHex;
  final String? captainId;
  final String? userId;

  Team({
    required this.id,
    required this.name,
    this.seed,
    List<String>? playerIds,
    this.logoUrl,
    this.colorHex,
    this.captainId,
    this.userId,
  }) : playerIds = playerIds ?? [];

  Team copyWith({
    String? id,
    String? name,
    int? seed,
    List<String>? playerIds,
    String? logoUrl,
    String? colorHex,
    String? captainId,
    String? userId,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      seed: seed ?? this.seed,
      playerIds: playerIds ?? this.playerIds,
      logoUrl: logoUrl ?? this.logoUrl,
      colorHex: colorHex ?? this.colorHex,
      captainId: captainId ?? this.captainId,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (seed != null) 'seed': seed,
      'playerIds': playerIds,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (colorHex != null) 'colorHex': colorHex,
      if (captainId != null) 'captainId': captainId,
      if (userId != null) 'userId': userId,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      seed: map['seed'] is int ? map['seed'] : (int.tryParse(map['seed']?.toString() ?? '')),
      playerIds: map['playerIds'] != null ? List<String>.from(map['playerIds']) : [],
      logoUrl: map['logoUrl'],
      colorHex: map['colorHex'],
      captainId: map['captainId'],
      userId: map['userId']?.toString(),
    );
  }
}
