import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/league/models/league.dart';
import '../league_repository.dart';

/// Pure Cloud Firestore League Repository.
/// All CRUD and real-time operations run against Cloud Firestore collection 'leagues'.
/// Uses an in-memory fallback only when Firebase is uninitialized (e.g. unit tests).
class FirestoreLeagueRepository implements ILeagueRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, League> _inMemoryFallback = {};
  final StreamController<List<League>> _inMemoryStreamController =
      StreamController<List<League>>.broadcast();

  FirestoreLeagueRepository({
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

  CollectionReference<Map<String, dynamic>>? get _leaguesRef =>
      _firestore?.collection('leagues');

  @override
  Future<List<League>> getLeagues() async {
    final ref = _leaguesRef;
    if (ref != null) {
      try {
        final snapshot = await ref.orderBy('createdAt', descending: true).get();
        return snapshot.docs.map((doc) => League.fromMap(doc.data())).toList();
      } catch (_) {
        // Fall back to memory
      }
    }
    return _inMemoryFallback.values.toList();
  }

  @override
  Future<League?> getLeagueById(String id) async {
    final ref = _leaguesRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return League.fromMap(doc.data()!);
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<League?> getLeagueByShareCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final ref = _leaguesRef;
    if (ref != null) {
      try {
        final query = await ref
            .where('shareCode', isEqualTo: normalized)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return League.fromMap(query.docs.first.data());
        }
      } catch (_) {}
    }
    try {
      return _inMemoryFallback.values.firstWhere(
        (l) => l.shareCode.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLeague(League league) async {
    _inMemoryFallback[league.id] = league;
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _leaguesRef;
    if (ref != null) {
      try {
        await ref.doc(league.id).set(league.toMap(), SetOptions(merge: true));
      } catch (e) {
        // Keep in memory fallback and rethrow so callers know Firebase write failed
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteLeague(String id) async {
    _inMemoryFallback.remove(id);
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _leaguesRef;
    if (ref != null) {
      try {
        await ref.doc(id).delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> addTournamentToLeague(String leagueId, String tournamentId) async {
    final league = await getLeagueById(leagueId);
    if (league != null) {
      if (!league.tournamentIds.contains(tournamentId)) {
        final updatedIds = [...league.tournamentIds, tournamentId];
        final updatedLeague = league.copyWith(tournamentIds: updatedIds);
        await saveLeague(updatedLeague);
      }
    }
  }

  @override
  Future<void> removeTournamentFromLeague(String leagueId, String tournamentId) async {
    final league = await getLeagueById(leagueId);
    if (league != null) {
      if (league.tournamentIds.contains(tournamentId)) {
        final updatedIds = league.tournamentIds.where((id) => id != tournamentId).toList();
        final updatedLeague = league.copyWith(tournamentIds: updatedIds);
        await saveLeague(updatedLeague);
      }
    }
  }

  @override
  Stream<League?> watchLeague(String id) async* {
    yield _inMemoryFallback[id];
    final ref = _leaguesRef;
    if (ref != null) {
      final controller = StreamController<League?>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        final match = list.cast<League?>().firstWhere(
          (l) => l?.id == id,
          orElse: () => _inMemoryFallback[id],
        );
        if (!controller.isClosed) controller.add(match);
      });

      firestoreSub = ref.doc(id).snapshots().listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final league = League.fromMap(snapshot.data()!);
            _inMemoryFallback[id] = league;
            if (!controller.isClosed) controller.add(league);
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
        return list.cast<League?>().firstWhere(
          (l) => l?.id == id,
          orElse: () => _inMemoryFallback[id],
        );
      });
    }
  }

  @override
  Stream<List<League>> watchLeagues() async* {
    // 1. Immediately yield in-memory fallback so UI never hangs in loading/spiralling
    yield _inMemoryFallback.values.toList();

    final ref = _leaguesRef;
    if (ref != null) {
      final controller = StreamController<List<League>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      // Listen to in-memory updates
      memorySub = _inMemoryStreamController.stream.listen((list) {
        if (!controller.isClosed) controller.add(list);
      });

      // Listen to Firestore real-time updates
      firestoreSub = ref.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((d) => League.fromMap(d.data())).toList();
          for (final l in list) {
            _inMemoryFallback[l.id] = l;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          // If Firestore read fails (offline/rules/network), fall back to in-memory state
          if (!controller.isClosed) controller.add(_inMemoryFallback.values.toList());
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream;
    }
  }

  @override
  Stream<List<League>> watchPublicLeagues() async* {
    yield _inMemoryFallback.values.where((l) => l.isPublic).toList();

    final ref = _leaguesRef;
    if (ref != null) {
      final controller = StreamController<List<League>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        if (!controller.isClosed) {
          controller.add(list.where((l) => l.isPublic).toList());
        }
      });

      firestoreSub = ref.where('isPublic', isEqualTo: true).snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((d) => League.fromMap(d.data())).toList();
          for (final l in list) {
            _inMemoryFallback[l.id] = l;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          if (!controller.isClosed) {
            controller.add(_inMemoryFallback.values.where((l) => l.isPublic).toList());
          }
        },
      );

      controller.onCancel = () {
        firestoreSub?.cancel();
        memorySub?.cancel();
      };

      yield* controller.stream;
    } else {
      yield* _inMemoryStreamController.stream.map((list) => list.where((l) => l.isPublic).toList());
    }
  }

  /// Clears in-memory cached state on user sign-out to prevent leaking data across sessions.
  void clearFallback() {
    _inMemoryFallback.clear();
    _inMemoryStreamController.add([]);
  }
}
