import 'match.dart';
import 'team.dart';

enum TournamentFormat { roundRobin, singleElimination, doubleElimination }
enum TournamentStatus { setup, ongoing, completed }

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

  Tournament({
    required this.id,
    required this.name,
    required this.sportType,
    required this.format,
    required this.participants,
    required this.matches,
    this.status = TournamentStatus.setup,
    this.seeded = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'format': format.index,
      'participants': participants.map((x) => x.toMap()).toList(),
      'matches': matches.map((x) => x.toMap()).toList(),
      'status': status.index,
      'seeded': seeded,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'],
      name: map['name'],
      sportType: map['sportType'],
      format: TournamentFormat.values[map['format'] ?? 0],
      participants: List<Team>.from(map['participants']?.map((x) => Team.fromMap(x)) ?? []),
      matches: List<TournamentMatch>.from(map['matches']?.map((x) => TournamentMatch.fromMap(x)) ?? []),
      status: TournamentStatus.values[map['status'] ?? 0],
      seeded: map['seeded'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
