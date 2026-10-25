import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import 'repository_providers.dart';

final recentAuditLogsProvider = StreamProvider<List<AuditLog>>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.watchRecentLogs();
});

class AuditController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> log({
    required String actorId,
    required String actorName,
    String? actorEmail,
    required String action,
    required String targetType,
    required String targetId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final repo = ref.read(auditRepositoryProvider);
      final logEntry = AuditLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_${actorId.hashCode}',
        actorId: actorId,
        actorName: actorName,
        actorEmail: actorEmail,
        action: action,
        targetType: targetType,
        targetId: targetId,
        description: description,
        metadata: metadata,
      );
      await repo.logAction(logEntry);
    } catch (_) {}
  }
}

final auditControllerProvider = NotifierProvider<AuditController, AsyncValue<void>>(
  AuditController.new,
);
