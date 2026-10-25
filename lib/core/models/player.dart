class Player {
  final String? id;
  final String name;
  final String? profilePhotoUrl;
  final String? contact;
  final int? seed;
  final String? userId;

  Player({
    dynamic id,
    required this.name,
    this.profilePhotoUrl,
    this.contact,
    this.seed,
    this.userId,
  }) : id = id?.toString();

  String get idString => id ?? name;

  Player copyWith({
    dynamic id,
    String? name,
    String? profilePhotoUrl,
    String? contact,
    int? seed,
    String? userId,
  }) {
    return Player(
      id: id != null ? id.toString() : this.id,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      contact: contact ?? this.contact,
      seed: seed ?? this.seed,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (contact != null) 'contact': contact,
      if (seed != null) 'seed': seed,
      if (userId != null) 'userId': userId,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      contact: map['contact'],
      seed: map['seed'] is int ? map['seed'] : (int.tryParse(map['seed']?.toString() ?? '')),
      userId: map['userId']?.toString(),
    );
  }
}
