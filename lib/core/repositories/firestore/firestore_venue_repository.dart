import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/venue/models/venue.dart';
import '../venue_repository.dart';

class FirestoreVenueRepository implements IVenueRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Venue> _inMemoryFallback = {};

  FirestoreVenueRepository({FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>>? get _venuesRef =>
      _firestore?.collection('venues');

  @override
  Future<List<Venue>> getVenues({String? leagueId}) async {
    final ref = _venuesRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref;
        if (leagueId != null && leagueId.isNotEmpty) {
          query = query.where('leagueId', isEqualTo: leagueId);
        }
        final snapshot = await query.get();
        final list = snapshot.docs.map((doc) => Venue.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final v in list) {
          _inMemoryFallback[v.id] = v;
        }
        return list;
      } catch (_) {}
    }
    if (leagueId != null && leagueId.isNotEmpty) {
      return _inMemoryFallback.values.where((v) => v.leagueId == leagueId).toList();
    }
    return _inMemoryFallback.values.toList();
  }

  @override
  Future<Venue?> getVenueById(String id) async {
    final ref = _venuesRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final v = Venue.fromMap({'id': doc.id, ...doc.data()!});
          _inMemoryFallback[v.id] = v;
          return v;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> saveVenue(Venue venue) async {
    _inMemoryFallback[venue.id] = venue;
    final ref = _venuesRef;
    if (ref != null) {
      await ref.doc(venue.id).set(venue.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteVenue(String id) async {
    _inMemoryFallback.remove(id);
    final ref = _venuesRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Stream<List<Venue>> watchVenues({String? leagueId}) async* {
    if (leagueId != null && leagueId.isNotEmpty) {
      yield _inMemoryFallback.values.where((v) => v.leagueId == leagueId).toList();
    } else {
      yield _inMemoryFallback.values.toList();
    }

    final ref = _venuesRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref;
      if (leagueId != null && leagueId.isNotEmpty) {
        query = query.where('leagueId', isEqualTo: leagueId);
      }
      yield* query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => Venue.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final v in list) {
          _inMemoryFallback[v.id] = v;
        }
        return list;
      });
    }
  }

  @override
  Stream<Venue?> watchVenue(String id) async* {
    yield _inMemoryFallback[id];
    final ref = _venuesRef;
    if (ref != null) {
      yield* ref.doc(id).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        final v = Venue.fromMap({'id': doc.id, ...doc.data()!});
        _inMemoryFallback[v.id] = v;
        return v;
      });
    }
  }
}
