import '../models/audit_log.dart';

abstract class IAuditRepository {
  Future<List<AuditLog>> getLogs({String? targetType, String? targetId, int limit = 100});
  Future<void> logAction(AuditLog log);
  Stream<List<AuditLog>> watchRecentLogs({int limit = 50});
}
