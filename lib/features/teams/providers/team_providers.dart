import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tournament/models/team.dart';
import '../../../core/providers/repository_providers.dart';

final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.watchTeams();
});

final teamsListProvider = FutureProvider<List<Team>>((ref) {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getTeams();
});

final singleTeamProvider = FutureProvider.family<Team?, String>((ref, id) {
  final repository = ref.watch(teamRepositoryProvider);
  return repository.getTeamById(id);
});

class TeamController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createTeam(Team team) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(teamRepositoryProvider);
      await repository.saveTeam(team);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTeam(Team team) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(teamRepositoryProvider);
      await repository.saveTeam(team);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTeam(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(teamRepositoryProvider);
      await repository.deleteTeam(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final teamControllerProvider =
    NotifierProvider<TeamController, AsyncValue<void>>(TeamController.new);
