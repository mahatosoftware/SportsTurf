import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/player.dart';
import '../../../core/providers/repository_providers.dart';

final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return repository.watchPlayers();
});

final playersListProvider = FutureProvider<List<Player>>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return repository.getPlayers();
});

class PlayerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addPlayer(Player player) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(playerRepositoryProvider);
      await repository.savePlayer(player);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePlayer(Player player) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(playerRepositoryProvider);
      await repository.savePlayer(player);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePlayer(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(playerRepositoryProvider);
      await repository.deletePlayer(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<int> bulkAddPlayers(List<Player> players) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(playerRepositoryProvider);
      int added = 0;
      for (final p in players) {
        await repository.savePlayer(p);
        added++;
      }
      state = const AsyncValue.data(null);
      return added;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, AsyncValue<void>>(PlayerController.new);
