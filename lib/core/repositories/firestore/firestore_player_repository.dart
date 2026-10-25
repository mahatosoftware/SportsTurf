import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/player.dart';
import '../player_repository.dart';

/// Cloud Firestore implementation of [IPlayerRepository].
/// Handles CRUD and real-time streaming of players.
class FirestorePlayerRepository implements IPlayerRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Player> _inMemoryFallback = {};
  final StreamController<List<Player>> _inMemoryStreamController =
      StreamController<List<Player>>.broadcast();

  FirestorePlayerRepository({
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

  CollectionReference<Map<String, dynamic>>? get _playersRef =>
      _firestore?.collection('players');

  @override
  Future<List<Player>> getPlayers() async {
    final ref = _playersRef;
    if (ref != null) {
      try {
        final snapshot = await ref.orderBy('name').get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return Player.fromMap({'id': doc.id, ...data});
        }).toList();
        return list;
      } catch (_) {}
    }
    return _inMemoryFallback.values.toList();
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    final ref = _playersRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return Player.fromMap({'id': doc.id, ...doc.data()!});
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> savePlayer(Player player) async {
    final ref = _playersRef;
    String id = player.id ?? '';
    if (id.isEmpty) {
      id = ref != null ? ref.doc().id : 'player_${DateTime.now().microsecondsSinceEpoch}';
    }
    final toSave = player.copyWith(id: id);
    _inMemoryFallback[id] = toSave;
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    if (ref != null) {
      await ref.doc(id).set(toSave.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deletePlayer(String id) async {
    _inMemoryFallback.remove(id);
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _playersRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Stream<List<Player>> watchPlayers() async* {
    yield _inMemoryFallback.values.toList();
    final ref = _playersRef;
    if (ref != null) {
      final controller = StreamController<List<Player>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        if (!controller.isClosed) controller.add(list);
      });

      firestoreSub = ref.orderBy('name').snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((doc) {
            return Player.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
          for (final p in list) {
            if (p.id != null) _inMemoryFallback[p.id!] = p;
          }
          if (!controller.isClosed) controller.add(list);
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
}
