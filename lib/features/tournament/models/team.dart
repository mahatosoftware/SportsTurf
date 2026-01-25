class Team {
  final String id;
  final String name;
  final int? seed; // 1 being the highest seed
  final List<String> playerIds;

  Team({
    required this.id,
    required this.name,
    this.seed,
    List<String>? playerIds,
  }) : playerIds = playerIds ?? [];

  Team copyWith({
    String? id,
    String? name,
    int? seed,
    List<String>? playerIds,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      seed: seed ?? this.seed,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'seed': seed,
      'playerIds': playerIds, // JSON encode handled by caller/wrapper usually, but here simple list OK for jsonEncode
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      seed: map['seed'],
      playerIds: map['playerIds'] != null ? List<String>.from(map['playerIds']) : [],
    );
  }
}
