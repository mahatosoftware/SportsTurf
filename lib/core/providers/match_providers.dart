import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_result.dart';
import 'repository_providers.dart';

final matchesStreamProvider =
    StreamProvider.family<List<MatchResult>, String?>((ref, sport) {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.watchMatches(sport: sport);
});

final matchesListProvider =
    FutureProvider.family<List<MatchResult>, String?>((ref, sport) {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getMatches(sport: sport);
});

class MatchController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveMatch(MatchResult match) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(matchRepositoryProvider);
      await repository.saveMatch(match);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteMatch(dynamic id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(matchRepositoryProvider);
      await repository.deleteMatch(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAllMatches() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(matchRepositoryProvider);
      await repository.deleteAllMatches();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final matchControllerProvider =
    NotifierProvider<MatchController, AsyncValue<void>>(MatchController.new);
