import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/tournament/models/tournament_registration.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_registration_repository.dart';
import 'package:sports_turf/features/dispute/models/dispute.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_dispute_repository.dart';
import 'package:sports_turf/features/reports/services/report_export_service.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/features/tournament/models/match.dart';

void main() {
  group('Tournament Registration & Waitlist Tests (UC-044 - UC-054)', () {
    test('TournamentRegistration serialization and status lifecycle', () {
      final reg = TournamentRegistration(
        id: 'reg-001',
        tournamentId: 'tourney-1',
        leagueId: 'league-1',
        participantId: 'team-red',
        participantName: 'Red Phoenix',
        isTeam: true,
        rosterPlayerIds: ['p1', 'p2', 'p3'],
        submittedByUserId: 'user-cap-1',
        status: RegistrationStatus.pending,
        entryFee: 50.0,
      );

      final map = reg.toMap();
      expect(map['id'], 'reg-001');
      expect(map['status'], 'pending');
      expect(map['isTeam'], isTrue);
      expect(map['entryFee'], 50.0);

      final restored = TournamentRegistration.fromMap(map);
      expect(restored.id, reg.id);
      expect(restored.participantName, 'Red Phoenix');
      expect(restored.status, RegistrationStatus.pending);

      // Transition to approved
      final approved = restored.copyWith(
        status: RegistrationStatus.approved,
        reviewedByUserId: 'admin-1',
        reviewNotes: 'Verified',
      );
      expect(approved.status, RegistrationStatus.approved);
      expect(approved.reviewNotes, 'Verified');

      // Transition to waitlisted
      final waitlisted = restored.copyWith(status: RegistrationStatus.waitlisted);
      expect(waitlisted.status, RegistrationStatus.waitlisted);
    });

    test('InMemory / Offline FirestoreRegistrationRepository handles save and status filtering', () async {
      final repo = FirestoreRegistrationRepository();
      final reg1 = TournamentRegistration(
        id: 'r1',
        tournamentId: 't1',
        participantId: 'p1',
        participantName: 'Player One',
        submittedByUserId: 'u1',
        status: RegistrationStatus.pending,
      );
      final reg2 = TournamentRegistration(
        id: 'r2',
        tournamentId: 't1',
        participantId: 'p2',
        participantName: 'Player Two',
        submittedByUserId: 'u2',
        status: RegistrationStatus.approved,
      );

      await repo.saveRegistration(reg1);
      await repo.saveRegistration(reg2);

      final list = await repo.getRegistrations(tournamentId: 't1');
      expect(list.length, 2);

      await repo.updateRegistrationStatus('r1', RegistrationStatus.approved, notes: 'Accepted');
      final updated = await repo.getRegistrationById('r1');
      expect(updated?.status, RegistrationStatus.approved);
      expect(updated?.reviewNotes, 'Accepted');
    });
  });

  group('Dispute & Protest Management Tests (UC-167 - UC-175)', () {
    test('Dispute serialization and ruling lifecycle', () {
      final dispute = Dispute(
        id: 'disp-001',
        title: 'Incorrect Score in Set 2',
        description: 'Scorekeeper entered 21-19 instead of 21-18',
        type: DisputeType.scoreCorrection,
        status: DisputeStatus.pending,
        tournamentId: 'tourney-1',
        matchId: 'match-5',
        submittedByUserId: 'captain-1',
        submittedByName: 'Alex Captain',
      );

      final map = dispute.toMap();
      expect(map['title'], 'Incorrect Score in Set 2');
      expect(map['type'], 'scoreCorrection');
      expect(map['status'], 'pending');

      final restored = Dispute.fromMap(map);
      expect(restored.id, dispute.id);
      expect(restored.type, DisputeType.scoreCorrection);
      expect(restored.status, DisputeStatus.pending);

      final resolved = restored.copyWith(
        status: DisputeStatus.resolved,
        resolution: 'Official video reviewed. Score corrected to 21-18.',
        reviewerUserId: 'referee-1',
        reviewerName: 'Chief Official',
      );
      expect(resolved.status, DisputeStatus.resolved);
      expect(resolved.resolution, contains('21-18'));
      expect(resolved.reviewerName, 'Chief Official');
    });

    test('InMemory / Offline FirestoreDisputeRepository handles save, resolve and deletion', () async {
      final repo = FirestoreDisputeRepository();
      final d = Dispute(
        id: 'd1',
        title: 'Eligibility Protest',
        description: 'Unregistered player fielded',
        type: DisputeType.playerEligibility,
        tournamentId: 't1',
        submittedByUserId: 'u1',
        submittedByName: 'Team Lead',
      );

      await repo.saveDispute(d);
      var fetched = await repo.getDisputeById('d1');
      expect(fetched?.title, 'Eligibility Protest');

      await repo.resolveDispute('d1', DisputeStatus.resolved, 'Sanction issued', 'ref-1', 'Ref Bob');
      fetched = await repo.getDisputeById('d1');
      expect(fetched?.status, DisputeStatus.resolved);
      expect(fetched?.resolution, 'Sanction issued');

      await repo.deleteDispute('d1');
      fetched = await repo.getDisputeById('d1');
      expect(fetched, isNull);
    });
  });

  group('Report Export Service Tests (UC-027, UC-057, UC-183, UC-185)', () {
    test('CSV and match report generation produces correct formats', () {
      final teamA = Team(id: 'tA', name: 'Alpha Strikers');
      final teamB = Team(id: 'tB', name: 'Beta Blasters');
      final match = TournamentMatch(
        id: 'm1',
        round: 1,
        matchNumber: 1,
        participantAId: 'tA',
        participantBId: 'tB',
        scoreA: 21,
        scoreB: 19,
        winnerId: 'tA',
        status: MatchStatus.completed,
        venueCourt: 'Court 1',
        scheduledTime: DateTime(2026, 6, 1, 10, 0),
      );

      final tourney = Tournament(
        id: 'tourney-test',
        name: 'Summer Open 2026',
        sportType: 'Badminton',
        format: TournamentFormat.singleElimination,
        participants: [teamA, teamB],
        matches: [match],
        venue: 'Turf Stadium',
      );

      // Test 1: Fixtures CSV
      final fixturesCsv = ReportExportService.exportFixturesCsv(tourney);
      expect(fixturesCsv, contains('Match #,Round,Status,Team A,Team B'));
      expect(fixturesCsv, contains('Alpha Strikers'));
      expect(fixturesCsv, contains('Beta Blasters'));
      expect(fixturesCsv, contains('Court 1'));

      // Test 2: Participants CSV
      final participantsCsv = ReportExportService.exportParticipantsCsv(tourney);
      expect(participantsCsv, contains('Seed,Participant Name,Type,Player Count'));
      expect(participantsCsv, contains('Alpha Strikers'));

      // Test 3: Printable Match Report
      final report = ReportExportService.generateMatchReport(tourney, match);
      expect(report, contains('SPORTS TURF MATCH REPORT'));
      expect(report, contains('Summer Open 2026'));
      expect(report, contains('Alpha Strikers (21)'));
      expect(report, contains('Beta Blasters (19)'));
      expect(report, contains('WINNER: Alpha Strikers'));
    });
  });
}
