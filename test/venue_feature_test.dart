import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/venue/models/venue.dart';
import 'package:sports_turf/features/venue/providers/venue_providers.dart';
import 'package:sports_turf/features/tournament/models/match.dart';

void main() {
  group('Venue & Court Operations Tests', () {
    test('Venue model serializes and deserializes correctly', () {
      final venue = Venue(
        id: 'venue-101',
        name: 'Turf Central Arena',
        address: '42 Sports Way, Sector 12',
        leagueId: 'league-001',
        facilities: ['Floodlights', 'Locker Room', 'Parking'],
        supportedSports: ['Badminton', 'Tennis'],
        playingAreas: [
          const PlayingArea(id: 'c1', name: 'Court 1', sportType: 'Badminton', isAvailable: true),
          const PlayingArea(id: 'c2', name: 'Court 2', sportType: 'Badminton', isAvailable: false),
        ],
        managerUserIds: ['user-admin-1'],
      );

      final map = venue.toMap();
      expect(map['id'], 'venue-101');
      expect(map['name'], 'Turf Central Arena');
      expect(map['facilities'], contains('Floodlights'));
      expect(map['playingAreas'], hasLength(2));

      final restored = Venue.fromMap(map);
      expect(restored.id, venue.id);
      expect(restored.name, venue.name);
      expect(restored.playingAreas.first.name, 'Court 1');
      expect(restored.playingAreas.first.isAvailable, isTrue);
      expect(restored.playingAreas.last.isAvailable, isFalse);
    });

    test('Conflict detection accurately flags overlapping court fixtures (UC-071 & UC-140)', () {
      final controller = VenueController();
      final baseTime = DateTime(2026, 6, 1, 10, 0); // 10:00 AM

      final existingMatches = [
        TournamentMatch(
          id: 'match-1',
          round: 1,
          matchNumber: 1,
          venueCourt: 'Court 1',
          scheduledTime: baseTime,
          durationMinutes: 60, // 10:00 - 11:00
        ),
        TournamentMatch(
          id: 'match-2',
          round: 1,
          matchNumber: 2,
          venueCourt: 'Court 2',
          scheduledTime: baseTime,
          durationMinutes: 60, // 10:00 - 11:00 on Court 2
        ),
      ];

      // Test 1: Exact overlap on Court 1 (10:15 - 11:15)
      final overlap = controller.detectConflict(
        existingMatches: existingMatches,
        courtName: 'Court 1',
        proposedTime: baseTime.add(const Duration(minutes: 15)),
        durationMinutes: 60,
      );
      expect(overlap, isTrue, reason: 'Should detect overlap on Court 1 from 10:15 to 11:15');

      // Test 2: Match scheduled after existing match finishes (11:00 - 12:00)
      final afterMatch = controller.detectConflict(
        existingMatches: existingMatches,
        courtName: 'Court 1',
        proposedTime: baseTime.add(const Duration(minutes: 60)),
        durationMinutes: 60,
      );
      expect(afterMatch, isFalse, reason: 'Should not detect conflict once previous match has ended');

      // Test 3: Same time slot but on Court 3 (free court)
      final differentCourt = controller.detectConflict(
        existingMatches: existingMatches,
        courtName: 'Court 3',
        proposedTime: baseTime,
        durationMinutes: 60,
      );
      expect(differentCourt, isFalse, reason: 'Should not detect conflict on unassigned court');

      // Test 4: Excluding current match being rescheduled
      final selfReschedule = controller.detectConflict(
        existingMatches: existingMatches,
        courtName: 'Court 1',
        proposedTime: baseTime,
        durationMinutes: 60,
        excludeMatchId: 'match-1',
      );
      expect(selfReschedule, isFalse, reason: 'Should ignore the match being rescheduled itself');
    });
  });
}
