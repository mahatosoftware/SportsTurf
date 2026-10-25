import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/audit_log.dart';
import '../audit_repository.dart';

class FirestoreAuditRepository implements IAuditRepository {
  final FirebaseFirestore? _injectedFirestore;
  final List<AuditLog> _inMemoryFallback = [];

  FirestoreAuditRepository({FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>>? get _auditRef =>
      _firestore?.collection('audit_logs');

  @override
  Future<List<AuditLog>> getLogs({String? targetType, String? targetId, int limit = 100}) async {
    final ref = _auditRef;
    if (ref != null) {
      try {
        Query<Map<String, dynamic>> query = ref.orderBy('timestamp', descending: true).limit(limit);
        if (targetType != null) {
          query = query.where('targetType', isEqualTo: targetType);
        }
        if (targetId != null) {
          query = query.where('targetId', isEqualTo: targetId);
        }
        final snapshot = await query.get();
        final list = snapshot.docs.map((doc) => AuditLog.fromMap({'id': doc.id, ...doc.data()})).toList();
        for (final l in list) {
          if (!_inMemoryFallback.any((item) => item.id == l.id)) {
            _inMemoryFallback.insert(0, l);
          }
        }
        return list;
      } catch (_) {}
    }
    return _inMemoryFallback.take(limit).toList();
  }

  @override
  Future<void> logAction(AuditLog log) async {
    _inMemoryFallback.insert(0, log);
    final ref = _auditRef;
    if (ref != null) {
      try {
        await ref.doc(log.id).set(log.toMap());
      } catch (_) {}
    }
  }

  @override
  Stream<List<AuditLog>> watchRecentLogs({int limit = 50}) async* {
    yield _inMemoryFallback.take(limit).toList();

    final ref = _auditRef;
    if (ref != null) {
      yield* ref.orderBy('timestamp', descending: true).limit(limit).snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => AuditLog.fromMap({'id': doc.id, ...doc.data()})).toList();
        return list;
      });
    }
  }
}
