import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_registration.dart';
import '../../../core/providers/repository_providers.dart';

final tournamentRegistrationsProvider = StreamProvider.family<List<TournamentRegistration>, String>((ref, tourneyId) {
  final repo = ref.watch(registrationRepositoryProvider);
  return repo.watchRegistrations(tournamentId: tourneyId);
});

final leagueRegistrationsProvider = StreamProvider.family<List<TournamentRegistration>, String>((ref, leagueId) {
  final repo = ref.watch(registrationRepositoryProvider);
  return repo.watchRegistrations(leagueId: leagueId);
});

class RegistrationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> submitRegistration(TournamentRegistration registration) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.saveRegistration(registration);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> approveRegistration(String id, {String? reviewerId, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.updateRegistrationStatus(
        id,
        RegistrationStatus.approved,
        reviewedBy: reviewerId,
        notes: notes ?? 'Registration approved.',
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> waitlistRegistration(String id, {String? reviewerId, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.updateRegistrationStatus(
        id,
        RegistrationStatus.waitlisted,
        reviewedBy: reviewerId,
        notes: notes ?? 'Added to waitlist as tournament capacity is reached.',
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> rejectRegistration(String id, {String? reviewerId, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.updateRegistrationStatus(
        id,
        RegistrationStatus.rejected,
        reviewedBy: reviewerId,
        notes: notes ?? 'Registration rejected.',
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> withdrawRegistration(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.updateRegistrationStatus(
        id,
        RegistrationStatus.withdrawn,
        notes: 'Withdrawn by participant.',
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final registrationControllerProvider = NotifierProvider<RegistrationController, AsyncValue<void>>(
  RegistrationController.new,
);
