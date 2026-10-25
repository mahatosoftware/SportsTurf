import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/tournament/models/tournament.dart';
import '../../../features/tournament/models/match.dart';
import '../../../features/tournament/logic/tournament_manager.dart';
import '../tournament_repository.dart';

/// Pure Cloud Firestore Tournament Repository.
/// All CRUD and real-time operations run against Cloud Firestore.
/// Uses an in-memory fallback only when Firebase is completely uninitialized (e.g. headless unit tests).
class FirestoreTournamentRepository implements ITournamentRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Tournament> _inMemoryFallback = {};
  final StreamController<List<Tournament>> _inMemoryStreamController =
      StreamController<List<Tournament>>.broadcast();

  FirestoreTournamentRepository({
    FirebaseFirestore? firestore,
  }) : _injectedFirestore = firestore;

  bool get _isFirebaseInitialized =>
      _injectedFirestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    if (_isFirebaseInitialized) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _tournamentsRef =>
      _firestore?.collection('tournaments');

  @override
  Future<List<Tournament>> getTournaments({String? sport, TournamentStatus? status}) async {
    final ref = _tournamentsRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref;
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          query = query.where('sportType', isEqualTo: sport);
        }
        if (status != null) {
          query = query.where('statusName', isEqualTo: status.name);
        }
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => Tournament.fromMap(doc.data()))
            .toList();
      } catch (_) {
        // Fall back to memory if network error / offline
      }
    }

    var list = _inMemoryFallback.values.toList();
    if (sport != null && sport.isNotEmpty && sport != 'All') {
      list = list.where((t) => t.sportType == sport).toList();
    }
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    return list;
  }

  @override
  Future<Tournament?> getTournamentById(String id) async {
    final ref = _tournamentsRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return Tournament.fromMap(doc.data()!);
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<Tournament?> getTournamentByShareCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final ref = _tournamentsRef;
    if (ref != null) {
      try {
        var snapshot = await ref
            .where('shareCode', isEqualTo: normalized)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          snapshot = await ref
              .where('id', isEqualTo: code.trim())
              .limit(1)
              .get();
        }

        if (snapshot.docs.isNotEmpty) {
          return Tournament.fromMap(snapshot.docs.first.data());
        }
      } catch (_) {}
    }

    return _inMemoryFallback.values.cast<Tournament?>().firstWhere(
      (t) => t?.shareCode.toUpperCase() == normalized || t?.id == code.trim(),
      orElse: () => null,
    );
  }

  @override
  Future<List<Tournament>> getPublicTournaments({String? sport}) async {
    final ref = _tournamentsRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref.where('isPublic', isEqualTo: true);
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          query = query.where('sportType', isEqualTo: sport);
        }
        final snapshot = await query.get();
        return snapshot.docs.map((d) => Tournament.fromMap(d.data())).toList();
      } catch (_) {}
    }

    return _inMemoryFallback.values
        .where((t) => t.isPublic && (sport == null || sport == 'All' || t.sportType == sport))
        .toList();
  }

  @override
  Future<void> saveTournament(Tournament tournament) async {
    _inMemoryFallback[tournament.id] = tournament;
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _tournamentsRef;
    if (ref != null) {
      await ref.doc(tournament.id).set(
        tournament.toMap(),
        SetOptions(merge: true),
      );
    }
  }

  @override
  Future<void> deleteTournament(String id) async {
    _inMemoryFallback.remove(id);
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _tournamentsRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Future<void> updateMatchScore(
    String tournamentId,
    String matchId,
    int scoreA,
    int scoreB,
    String? winnerId,
  ) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return;

    final manager = TournamentManager(tournament);
    final updated = manager.updateMatch(matchId, scoreA, scoreB);
    await saveTournament(updated);
  }

  @override
  Future<void> updateMatchStatus(
    String tournamentId,
    String matchId,
    MatchStatus status,
  ) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return;

    final matches = tournament.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(status: status);
      }
      return m;
    }).toList();

    await saveTournament(tournament.copyWith(matches: matches));
  }

  @override
  Stream<Tournament?> watchTournament(String id) async* {
    yield _inMemoryFallback[id];
    final ref = _tournamentsRef;
    if (ref != null) {
      final controller = StreamController<Tournament?>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        final match = list.cast<Tournament?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => _inMemoryFallback[id],
        );
        if (!controller.isClosed) controller.add(match);
      });

      firestoreSub = ref.doc(id).snapshots().listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final t = Tournament.fromMap(snapshot.data()!);
            _inMemoryFallback[id] = t;
            if (!controller.isClosed) controller.add(t);
          } else {
            if (!controller.isClosed) controller.add(_inMemoryFallback[id]);
          }
        },
        onError: (_) {
          if (!controller.isClosed) controller.add(_inMemoryFallback[id]);
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream.map((list) {
        return list.cast<Tournament?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => _inMemoryFallback[id],
        );
      });
    }
  }

  @override
  Stream<List<Tournament>> watchTournaments({String? sport}) async* {
    var initialList = _inMemoryFallback.values.toList();
    if (sport != null && sport.isNotEmpty && sport != 'All') {
      initialList = initialList.where((t) => t.sportType == sport).toList();
    }
    yield initialList;

    final ref = _tournamentsRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref;
      if (sport != null && sport.isNotEmpty && sport != 'All') {
        query = query.where('sportType', isEqualTo: sport);
      }

      final controller = StreamController<List<Tournament>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        var filtered = list;
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          filtered = filtered.where((t) => t.sportType == sport).toList();
        }
        if (!controller.isClosed) controller.add(filtered);
      });

      firestoreSub = query.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((d) => Tournament.fromMap(d.data())).toList();
          for (final t in list) {
            _inMemoryFallback[t.id] = t;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          var fallback = _inMemoryFallback.values.toList();
          if (sport != null && sport.isNotEmpty && sport != 'All') {
            fallback = fallback.where((t) => t.sportType == sport).toList();
          }
          if (!controller.isClosed) controller.add(fallback);
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream.map((list) {
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          return list.where((t) => t.sportType == sport).toList();
        }
        return list;
      });
    }
  }

  @override
  Stream<List<Tournament>> watchPublicTournaments({String? sport}) async* {
    var initialList = _inMemoryFallback.values.where((t) => t.isPublic).toList();
    if (sport != null && sport.isNotEmpty && sport != 'All') {
      initialList = initialList.where((t) => t.sportType == sport).toList();
    }
    yield initialList;

    final ref = _tournamentsRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref.where('isPublic', isEqualTo: true);
      if (sport != null && sport.isNotEmpty && sport != 'All') {
        query = query.where('sportType', isEqualTo: sport);
      }

      final controller = StreamController<List<Tournament>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        var filtered = list.where((t) => t.isPublic).toList();
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          filtered = filtered.where((t) => t.sportType == sport).toList();
        }
        if (!controller.isClosed) controller.add(filtered);
      });

      firestoreSub = query.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((d) => Tournament.fromMap(d.data())).toList();
          for (final t in list) {
            _inMemoryFallback[t.id] = t;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          var fallback = _inMemoryFallback.values.where((t) => t.isPublic).toList();
          if (sport != null && sport.isNotEmpty && sport != 'All') {
            fallback = fallback.where((t) => t.sportType == sport).toList();
          }
          if (!controller.isClosed) controller.add(fallback);
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream.map((list) {
        return list.where((t) => t.isPublic && (sport == null || sport == 'All' || t.sportType == sport)).toList();
      });
    }
  }

  @override
  Future<List<Tournament>> getTournamentsByLeague(String leagueId) async {
    final ref = _tournamentsRef;
    if (ref != null) {
      try {
        final snapshot = await ref.where('leagueId', isEqualTo: leagueId).get();
        return snapshot.docs.map((d) => Tournament.fromMap(d.data())).toList();
      } catch (_) {}
    }
    return _inMemoryFallback.values.where((t) => t.leagueId == leagueId).toList();
  }

  @override
  Stream<List<Tournament>> watchTournamentsByLeague(String leagueId) async* {
    yield _inMemoryFallback.values.where((t) => t.leagueId == leagueId).toList();

    final ref = _tournamentsRef;
    if (ref != null) {
      final controller = StreamController<List<Tournament>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        if (!controller.isClosed) {
          controller.add(list.where((t) => t.leagueId == leagueId).toList());
        }
      });

      firestoreSub = ref.where('leagueId', isEqualTo: leagueId).snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((d) => Tournament.fromMap(d.data())).toList();
          for (final t in list) {
            _inMemoryFallback[t.id] = t;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          if (!controller.isClosed) {
            controller.add(_inMemoryFallback.values.where((t) => t.leagueId == leagueId).toList());
          }
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream.map((list) {
        return list.where((t) => t.leagueId == leagueId).toList();
      });
    }
  }

  /// Clears in-memory cached state on user sign-out to prevent leaking data across sessions.
  void clearFallback() {
    _inMemoryFallback.clear();
    _inMemoryStreamController.add([]);
  }
}
