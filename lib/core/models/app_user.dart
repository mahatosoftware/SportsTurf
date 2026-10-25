class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final bool isAnonymous;
  final bool isSuperAdmin;
  final String status; // 'active', 'suspended'
  final List<String> preferredSports;
  final String authProvider; // 'google', 'password', 'anonymous'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.isAnonymous = false,
    this.isSuperAdmin = false,
    this.status = 'active',
    this.preferredSports = const ['Badminton', 'Tennis', 'Cricket'],
    this.authProvider = 'password',
    required this.createdAt,
  });

  String get initials {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length > 1) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    if (isAnonymous) {
      return 'G';
    }
    return id.isNotEmpty ? id[0].toUpperCase() : 'U';
  }

  String get displayTitle {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    if (isAnonymous) {
      return 'Guest User';
    }
    return 'Sports Enthusiast';
  }

  String get name => displayTitle;

  bool get isActive => status == 'active';

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isAnonymous,
    bool? isSuperAdmin,
    String? status,
    List<String>? preferredSports,
    String? authProvider,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      status: status ?? this.status,
      preferredSports: preferredSports ?? this.preferredSports,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      'isAnonymous': isAnonymous,
      'isSuperAdmin': isSuperAdmin,
      'status': status,
      'preferredSports': preferredSports,
      'authProvider': authProvider,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      isAnonymous: map['isAnonymous'] ?? false,
      isSuperAdmin: map['isSuperAdmin'] ?? (map['role'] == 'super_admin' || map['admin'] == true),
      status: map['status'] ?? 'active',
      preferredSports: List<String>.from(map['preferredSports'] ?? ['Badminton', 'Tennis', 'Cricket']),
      authProvider: map['authProvider'] ?? 'password',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
