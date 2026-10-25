import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venue.dart';
import '../../tournament/models/match.dart';
import '../../../core/providers/repository_providers.dart';

final venuesStreamProvider = StreamProvider<List<Venue>>((ref) {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.watchVenues();
});

final leagueVenuesProvider = StreamProvider.family<List<Venue>, String>((ref, leagueId) {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.watchVenues(leagueId: leagueId);
});

final singleVenueProvider = StreamProvider.family<Venue?, String>((ref, id) {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.watchVenue(id);
});

class VenueController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createVenue(Venue venue) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(venueRepositoryProvider);
      await repo.saveVenue(venue);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateVenue(Venue venue) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(venueRepositoryProvider);
      await repo.saveVenue(venue);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteVenue(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(venueRepositoryProvider);
      await repo.deleteVenue(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// UC-071 & UC-140: Detect schedule conflicts for a proposed match on a court/area.
  bool detectConflict({
    required List<TournamentMatch> existingMatches,
    required String? courtName,
    required DateTime proposedTime,
    required int durationMinutes,
    String? excludeMatchId,
  }) {
    if (courtName == null || courtName.trim().isEmpty) return false;

    final proposedEnd = proposedTime.add(Duration(minutes: durationMinutes));

    for (final m in existingMatches) {
      if (m.id == excludeMatchId) continue;
      if (m.venueCourt == null || m.venueCourt!.trim().toLowerCase() != courtName.trim().toLowerCase()) {
        continue;
      }
      if (m.scheduledTime == null) continue;

      final matchStart = m.scheduledTime!;
      final matchEnd = matchStart.add(Duration(minutes: m.durationMinutes));

      // Overlap check: (StartA < EndB) and (EndA > StartB)
      if (proposedTime.isBefore(matchEnd) && proposedEnd.isAfter(matchStart)) {
        return true; // Conflict detected!
      }
    }
    return false;
  }
}

final venueControllerProvider = NotifierProvider<VenueController, AsyncValue<void>>(
  VenueController.new,
);
