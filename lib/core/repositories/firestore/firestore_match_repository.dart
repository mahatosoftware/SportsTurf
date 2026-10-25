import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/match_result.dart';
import '../match_repository.dart';

/// Cloud Firestore implementation of [IMatchRepository].
/// Handles CRUD and real-time streaming of quick match scorecards.
class FirestoreMatchRepository implements IMatchRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, MatchResult> _inMemoryFallback = {};
  final StreamController<List<MatchResult>> _inMemoryStreamController =
      StreamController<List<MatchResult>>.broadcast();

  FirestoreMatchRepository({
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

  CollectionReference<Map<String, dynamic>>? get _matchesRef =>
      _firestore?.collection('matches');

  @override
  Future<List<MatchResult>> getMatches({String? sport}) async {
    final ref = _matchesRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref.orderBy('date', descending: true);
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          query = query.where('sport', isEqualTo: sport);
        }
        final snapshot = await query.get();
        return snapshot.docs.map((doc) {
          return MatchResult.fromMap({'id': doc.id, ...doc.data()});
        }).toList();
      } catch (_) {}
    }

    var list = _inMemoryFallback.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    if (sport != null && sport.isNotEmpty && sport != 'All') {
      list = list.where((m) => m.sport == sport).toList();
    }
    return list;
  }

  @override
  Future<void> saveMatch(MatchResult match) async {
    final ref = _matchesRef;
    String id = match.id ?? '';
    if (id.isEmpty) {
      id = ref != null ? ref.doc().id : 'match_${DateTime.now().microsecondsSinceEpoch}';
    }
    final toSave = match.copyWith(id: id);
    _inMemoryFallback[id] = toSave;
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    if (ref != null) {
      await ref.doc(id).set(toSave.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteMatch(dynamic id) async {
    final strId = id?.toString() ?? '';
    if (strId.isEmpty) return;

    _inMemoryFallback.remove(strId);
    _inMemoryStreamController.add(_inMemoryFallback.values.toList());

    final ref = _matchesRef;
    if (ref != null) {
      await ref.doc(strId).delete();
    }
  }

  @override
  Future<void> deleteAllMatches() async {
    _inMemoryFallback.clear();
    _inMemoryStreamController.add([]);

    final ref = _matchesRef;
    if (ref != null) {
      final snapshot = await ref.get();
      final batch = _firestore!.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<MatchResult>> watchMatches({String? sport}) async* {
    var initialList = _inMemoryFallback.values.toList();
    initialList.sort((a, b) => b.date.compareTo(a.date));
    if (sport != null && sport.isNotEmpty && sport != 'All') {
      initialList = initialList.where((m) => m.sport == sport).toList();
    }
    yield initialList;

    final ref = _matchesRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref.orderBy('date', descending: true);
      if (sport != null && sport.isNotEmpty && sport != 'All') {
        query = query.where('sport', isEqualTo: sport);
      }

      final controller = StreamController<List<MatchResult>>();
      StreamSubscription? firestoreSub;
      StreamSubscription? memorySub;

      memorySub = _inMemoryStreamController.stream.listen((list) {
        var filtered = List<MatchResult>.from(list);
        filtered.sort((a, b) => b.date.compareTo(a.date));
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          filtered = filtered.where((m) => m.sport == sport).toList();
        }
        if (!controller.isClosed) controller.add(filtered);
      });

      firestoreSub = query.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs.map((doc) {
            return MatchResult.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
          for (final m in list) {
            if (m.id != null) _inMemoryFallback[m.id!] = m;
          }
          if (!controller.isClosed) controller.add(list);
        },
        onError: (_) {
          var fallback = _inMemoryFallback.values.toList();
          fallback.sort((a, b) => b.date.compareTo(a.date));
          if (sport != null && sport.isNotEmpty && sport != 'All') {
            fallback = fallback.where((m) => m.sport == sport).toList();
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
        var filtered = List<MatchResult>.from(list);
        filtered.sort((a, b) => b.date.compareTo(a.date));
        if (sport != null && sport.isNotEmpty && sport != 'All') {
          filtered = filtered.where((m) => m.sport == sport).toList();
        }
        return filtered;
      });
    }
  }
}
