class PlayingArea {
  final String id;
  final String name; // e.g. "Court 1", "Pitch A", "Table 2"
  final String sportType; // Badminton, Tennis, Cricket, etc.
  final bool isAvailable;

  const PlayingArea({
    required this.id,
    required this.name,
    this.sportType = 'All Sports',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'isAvailable': isAvailable,
    };
  }

  factory PlayingArea.fromMap(Map<String, dynamic> map) {
    return PlayingArea(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sportType: map['sportType'] ?? 'All Sports',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}

class Venue {
  final String id;
  final String name;
  final String address;
  final String? leagueId;
  final List<String> facilities; // e.g. ["Floodlights", "Changing Rooms", "Parking"]
  final List<String> supportedSports;
  final List<PlayingArea> playingAreas;
  final List<String> managerUserIds;
  final DateTime createdAt;

  Venue({
    required this.id,
    required this.name,
    this.address = '',
    this.leagueId,
    List<String>? facilities,
    List<String>? supportedSports,
    List<PlayingArea>? playingAreas,
    List<String>? managerUserIds,
    DateTime? createdAt,
  })  : facilities = facilities ?? [],
        supportedSports = supportedSports ?? const ['All Sports'],
        playingAreas = playingAreas ?? [],
        managerUserIds = managerUserIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Venue copyWith({
    String? id,
    String? name,
    String? address,
    String? leagueId,
    List<String>? facilities,
    List<String>? supportedSports,
    List<PlayingArea>? playingAreas,
    List<String>? managerUserIds,
    DateTime? createdAt,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      leagueId: leagueId ?? this.leagueId,
      facilities: facilities ?? this.facilities,
      supportedSports: supportedSports ?? this.supportedSports,
      playingAreas: playingAreas ?? this.playingAreas,
      managerUserIds: managerUserIds ?? this.managerUserIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (leagueId != null) 'leagueId': leagueId,
      'facilities': facilities,
      'supportedSports': supportedSports,
      'playingAreas': playingAreas.map((p) => p.toMap()).toList(),
      'managerUserIds': managerUserIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      leagueId: map['leagueId'],
      facilities: List<String>.from(map['facilities'] ?? []),
      supportedSports: List<String>.from(map['supportedSports'] ?? ['All Sports']),
      playingAreas: (map['playingAreas'] as List<dynamic>?)
              ?.map((p) => PlayingArea.fromMap(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
      managerUserIds: List<String>.from(map['managerUserIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
