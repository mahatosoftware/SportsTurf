import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/league/models/season.dart';
import '../season_repository.dart';

class FirestoreSeasonRepository implements ISeasonRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Season> _inMemoryFallback = {};

  FirestoreSeasonRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _seasonsRef =>
      _firestore?.collection('seasons');

  @override
  Future<List<Season>> getSeasons(String leagueId) async {
    final ref = _seasonsRef;
    if (ref != null) {
      try {
        final snapshot = await ref.where('leagueId', isEqualTo: leagueId).get();
        final list = snapshot.docs.map((doc) => Season.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final s in list) {
          _inMemoryFallback[s.id] = s;
        }
        return list;
      } catch (_) {}
    }
    return _inMemoryFallback.values.where((s) => s.leagueId == leagueId).toList();
  }

  @override
  Future<Season?> getSeasonById(String id) async {
    final ref = _seasonsRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final s = Season.fromMap({'id': doc.id, ...doc.data()!});
          _inMemoryFallback[s.id] = s;
          return s;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> saveSeason(Season season) async {
    _inMemoryFallback[season.id] = season;
    final ref = _seasonsRef;
    if (ref != null) {
      await ref.doc(season.id).set(season.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteSeason(String id) async {
    _inMemoryFallback.remove(id);
    final ref = _seasonsRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Stream<List<Season>> watchSeasons(String leagueId) async* {
    yield _inMemoryFallback.values.where((s) => s.leagueId == leagueId).toList();

    final ref = _seasonsRef;
    if (ref != null) {
      yield* ref.where('leagueId', isEqualTo: leagueId).snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => Season.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final s in list) {
          _inMemoryFallback[s.id] = s;
        }
        return list;
      });
    }
  }
}
