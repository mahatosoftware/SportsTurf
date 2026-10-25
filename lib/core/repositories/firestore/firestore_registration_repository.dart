import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../features/tournament/models/tournament_registration.dart';
import '../registration_repository.dart';

class FirestoreRegistrationRepository implements IRegistrationRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, TournamentRegistration> _inMemoryFallback = {};

  FirestoreRegistrationRepository({FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>>? get _registrationsRef =>
      _firestore?.collection('registrations');

  @override
  Future<List<TournamentRegistration>> getRegistrations({String? tournamentId, String? leagueId}) async {
    final ref = _registrationsRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref;
        if (tournamentId != null && tournamentId.isNotEmpty) {
          query = query.where('tournamentId', isEqualTo: tournamentId);
        }
        if (leagueId != null && leagueId.isNotEmpty) {
          query = query.where('leagueId', isEqualTo: leagueId);
        }
        final snapshot = await query.get();
        final list = snapshot.docs.map((doc) => TournamentRegistration.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final r in list) {
          _inMemoryFallback[r.id] = r;
        }
        return list;
      } catch (_) {}
    }
    return _inMemoryFallback.values.where((r) {
      if (tournamentId != null && r.tournamentId != tournamentId) return false;
      if (leagueId != null && r.leagueId != leagueId) return false;
      return true;
    }).toList();
  }

  @override
  Future<TournamentRegistration?> getRegistrationById(String id) async {
    final ref = _registrationsRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final r = TournamentRegistration.fromMap({'id': doc.id, ...doc.data()!});
          _inMemoryFallback[r.id] = r;
          return r;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[id];
  }

  @override
  Future<void> saveRegistration(TournamentRegistration registration) async {
    _inMemoryFallback[registration.id] = registration;
    final ref = _registrationsRef;
    if (ref != null) {
      await ref.doc(registration.id).set(registration.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateRegistrationStatus(String id, RegistrationStatus status, {String? reviewedBy, String? notes}) async {
    final existing = await getRegistrationById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        reviewedByUserId: reviewedBy,
        reviewNotes: notes,
        reviewedAt: DateTime.now(),
      );
      await saveRegistration(updated);
    }
  }

  @override
  Future<void> deleteRegistration(String id) async {
    _inMemoryFallback.remove(id);
    final ref = _registrationsRef;
    if (ref != null) {
      await ref.doc(id).delete();
    }
  }

  @override
  Stream<List<TournamentRegistration>> watchRegistrations({String? tournamentId, String? leagueId}) async* {
    yield _inMemoryFallback.values.where((r) {
      if (tournamentId != null && r.tournamentId != tournamentId) return false;
      if (leagueId != null && r.leagueId != leagueId) return false;
      return true;
    }).toList();

    final ref = _registrationsRef;
    if (ref != null) {
      Query<Map<String, dynamic>> query = ref;
      if (tournamentId != null && tournamentId.isNotEmpty) {
        query = query.where('tournamentId', isEqualTo: tournamentId);
      }
      if (leagueId != null && leagueId.isNotEmpty) {
        query = query.where('leagueId', isEqualTo: leagueId);
      }
      yield* query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => TournamentRegistration.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final r in list) {
          _inMemoryFallback[r.id] = r;
        }
        return list;
      });
    }
  }
}
