import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/tournament/models/team.dart';
import '../team_repository.dart';

/// Cloud Firestore implementation of [ITeamRepository].
/// Handles CRUD and real-time streaming of teams and squads.
class FirestoreTeamRepository implements ITeamRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Team> _inMemoryFallback = {};
  final StreamController<List<Team>> _inMemoryStreamController =
      StreamController<List<Team>>.broadcast();

  FirestoreTeamRepository({
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

  CollectionReference<Map<String, dynamic>>? get _teamsRef =>
      _firestore?.collection('teams');

  @override
  Future<List<Team>> getTeams() async {
    final ref = _teamsRef;
    if (ref != null) {
      try {
        final snapshot = await ref.orderBy('name').get();
        final cloudList = snapshot.docs.map((doc) {
          return Team.fromMap({'id': doc.id, ...doc.data()});
        }).toList();
        for (final t in cloudList) {
          _inMemoryFallback[t.id] = t;
        }
        final combined = {..._inMemoryFallback};
        for (final t in cloudList) {
          combined[t.id] = t;
        }
        return combined.values.toList();
      } catch (_) {}
    }
    return _inMemoryFallback.values.toList();
  }

  @override
  Future<Team?> getTeamById(String id) async {
    final ref = _teamsRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final team = Team.fromMap({'id': doc.id, ...doc.data()!});
          _inMemoryFallback[id] = team;
          return team;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> saveTeam(Team team) async {
    final ref = _teamsRef;
    String id = team.id;
    if (id.isEmpty) {
      id = ref != null ? ref.doc().id : 'team_${DateTime.now().microsecondsSinceEpoch}';
    }
    String? userId = team.userId;
    if ((userId == null || userId.isEmpty) && _isFirebaseInitialized) {
      try {
        userId = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
    }
    final toSave = team.copyWith(id: id, userId: userId);
    _inMemoryFallback[id] = toSave;
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    if (ref != null) {
      try {
        await ref.doc(id).set(toSave.toMap(), SetOptions(merge: true));
      } catch (e) {
        // Keep in-memory fallback and rethrow so UI can handle feedback gracefully
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    _inMemoryFallback.remove(id);
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _teamsRef;
    if (ref != null) {
      try {
        await ref.doc(id).delete();
      } catch (_) {}
    }
  }

  @override
  Stream<List<Team>> watchTeams() async* {
    yield _inMemoryFallback.values.toList();
    final ref = _teamsRef;
    if (ref != null) {
      final controller = StreamController<List<Team>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        if (!controller.isClosed) controller.add(list);
      });

      firestoreSub = ref.orderBy('name').snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((doc) {
            return Team.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
          for (final t in list) {
            _inMemoryFallback[t.id] = t;
          }
          final combined = {..._inMemoryFallback};
          for (final t in list) {
            combined[t.id] = t;
          }
          if (!controller.isClosed) controller.add(combined.values.toList());
        },
        onError: (_) {
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

  /// Clears in-memory cached state on user sign-out to prevent leaking data across sessions.
  void clearFallback() {
    _inMemoryFallback.clear();
    _inMemoryStreamController.add([]);
  }
}
