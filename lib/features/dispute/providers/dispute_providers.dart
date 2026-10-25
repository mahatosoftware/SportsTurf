import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispute.dart';
import '../../../core/providers/repository_providers.dart';

final tournamentDisputesProvider = StreamProvider.family<List<Dispute>, String>((ref, tourneyId) {
  final repo = ref.watch(disputeRepositoryProvider);
  return repo.watchDisputes(tournamentId: tourneyId);
});

final leagueDisputesProvider = StreamProvider.family<List<Dispute>, String>((ref, leagueId) {
  final repo = ref.watch(disputeRepositoryProvider);
  return repo.watchDisputes(leagueId: leagueId);
});

class DisputeController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> submitDispute(Dispute dispute) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(disputeRepositoryProvider);
      await repo.saveDispute(dispute);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resolveDispute({
    required String id,
    required DisputeStatus status,
    required String resolution,
    required String reviewerUserId,
    required String reviewerName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(disputeRepositoryProvider);
      await repo.resolveDispute(id, status, resolution, reviewerUserId, reviewerName);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteDispute(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(disputeRepositoryProvider);
      await repo.deleteDispute(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final disputeControllerProvider = NotifierProvider<DisputeController, AsyncValue<void>>(
  DisputeController.new,
);
