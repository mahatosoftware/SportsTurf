import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season.dart';
import '../../../core/providers/repository_providers.dart';

final leagueSeasonsProvider = StreamProvider.family<List<Season>, String>((ref, leagueId) {
  final repo = ref.watch(seasonRepositoryProvider);
  return repo.watchSeasons(leagueId);
});

class SeasonController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createSeason(Season season) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(seasonRepositoryProvider);
      await repo.saveSeason(season);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateSeason(Season season) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(seasonRepositoryProvider);
      await repo.saveSeason(season);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSeason(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(seasonRepositoryProvider);
      await repo.deleteSeason(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final seasonControllerProvider = NotifierProvider<SeasonController, AsyncValue<void>>(
  SeasonController.new,
);
