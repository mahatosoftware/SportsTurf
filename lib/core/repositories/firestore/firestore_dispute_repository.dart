import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/dispute/models/dispute.dart';
import '../dispute_repository.dart';

class FirestoreDisputeRepository implements IDisputeRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, Dispute> _inMemoryFallback = {};

  FirestoreDisputeRepository({FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>>? get _disputesRef =>
      _firestore?.collection('disputes');

  @override
  Future<List<Dispute>> getDisputes({String? tournamentId, String? leagueId, String? matchId}) async {
    final ref = _disputesRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref;
        if (tournamentId != null && tournamentId.isNotEmpty) {
          query = query.where('tournamentId', isEqualTo: tournamentId);
        }
        if (leagueId != null && leagueId.isNotEmpty) {
          query = query.where('leagueId', isEqualTo: leagueId);
        }
        if (matchId != null && matchId.isNotEmpty) {
          query = query.where('matchId', isEqualTo: matchId);
        }
        final snapshot = await query.get();
        final list = snapshot.docs.map((doc) => Dispute.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final d in list) {
          _inMemoryFallback[d.id] = d;
        }
        return list;
      } catch (_) {}
    }
    return _inMemoryFallback.values.where((d) {
      if (tournamentId != null && d.tournamentId != tournamentId) return false;
      if (leagueId != null && d.leagueId != leagueId) return false;
      if (matchId != null && d.matchId != matchId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Dispute?> getDisputeById(String id) async {
    final ref = _disputesRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final d = Dispute.fromMap({'id': doc.id, ...doc.data()!});
          _inMemoryFallback[d.id] = d;
          return d;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> saveDispute(Dispute dispute) async {
    _inMemoryFallback[dispute.id] = dispute;
    final ref = _disputesRef;
    if (ref != null) {
      await ref.doc(dispute.id).set(dispute.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> resolveDispute(
    String id,
    DisputeStatus status,
    String resolution,
    String reviewerUserId,
    String reviewerName,
  ) async {
    final existing = await getDisputeById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        resolution: resolution,
        reviewerUserId: reviewerUserId,
        reviewerName: reviewerName,
        resolvedAt: DateTime.now(),
      );
      await saveDispute(updated);
    }
  }

  @override
  Future<void> deleteDispute(String id) async {
    _inMemoryFallback.remove(id);
    final ref = _disputesRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Stream<List<Dispute>> watchDisputes({String? tournamentId, String? leagueId}) async* {
    yield _inMemoryFallback.values.where((d) {
      if (tournamentId != null && d.tournamentId != tournamentId) return false;
      if (leagueId != null && d.leagueId != leagueId) return false;
      return true;
    }).toList();

    final ref = _disputesRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref;
      if (tournamentId != null && tournamentId.isNotEmpty) {
        query = query.where('tournamentId', isEqualTo: tournamentId);
      }
      if (leagueId != null && leagueId.isNotEmpty) {
        query = query.where('leagueId', isEqualTo: leagueId);
      }
      yield* query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => Dispute.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final d in list) {
          _inMemoryFallback[d.id] = d;
        }
        return list;
      });
    }
  }
}
