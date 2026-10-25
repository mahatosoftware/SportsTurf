import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/features/league/models/league.dart';
import 'package:sports_turf/features/tournament/models/tournament.dart';
import 'package:sports_turf/features/tournament/models/team.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_league_repository.dart';
import 'package:sports_turf/core/repositories/firestore/firestore_tournament_repository.dart';

void main() {
  group('League Domain Model Tests', () {
    test('League model serializes and deserializes correctly', () {
      final now = DateTime(2026, 5, 10);
      final league = League(
        id: 'league-uuid-1234',
        name: 'Corporate Sports Championship 2026',
        description: 'Multi-sport corporate league for tech companies',
        creatorId: 'user-777',
        organizerName: 'Sports Club Committee',
        venue: 'Metro Arena',
        shareCode: 'LEAGUE-7777',
        isPublic: true,
        sportTypes: ['Badminton', 'Cricket', 'Tennis'],
        tournamentIds: ['tourney-1', 'tourney-2'],
        status: LeagueStatus.active,
        startDate: now,
        endDate: now.add(const Duration(days: 14)),
        createdAt: now,
        pointsConfig: {'win': 2, 'draw': 1, 'loss': 0},
      );

      expect(league.tournamentsCount, 2);
      expect(league.shareCode, 'LEAGUE-7777');
      expect(league.status, LeagueStatus.active);

      final map = league.toMap();
      expect(map['name'], 'Corporate Sports Championship 2026');
      expect(map['sportTypes'], ['Badminton', 'Cricket', 'Tennis']);
      expect(map['tournamentIds'], ['tourney-1', 'tourney-2']);
      expect(map['statusName'], 'active');

      final deserialized = League.fromMap(map);
      expect(deserialized.id, league.id);
      expect(deserialized.name, league.name);
      expect(deserialized.creatorId, league.creatorId);
      expect(deserialized.shareCode, league.shareCode);
      expect(deserialized.sportTypes, ['Badminton', 'Cricket', 'Tennis']);
      expect(deserialized.tournamentIds, ['tourney-1', 'tourney-2']);
      expect(deserialized.status, LeagueStatus.active);
      expect(deserialized.tournamentsCount, 2);
    });

    test('League model auto-generates share code when none provided', () {
      final league = League(
        id: '12345678-abcd-ef01',
        name: 'Open Badminton League',
      );
      expect(league.shareCode, isNotEmpty);
      expect(league.shareCode.startsWith('LEAGUE-'), isTrue);
    });

    test('Tournament model supports optional League and standalone mode', () {
      // Standalone Tournament
      final standalone = Tournament(
        id: 'tourney-standalone-1',
        name: 'Weekend Friendly Badminton',
        sportType: 'Badminton',
        format: TournamentFormat.singleElimination,
        participants: [
          Team(id: 't1', name: 'Team Alpha'),
          Team(id: 't2', name: 'Team Beta'),
        ],
        matches: [],
      );

      expect(standalone.isUnderLeague, isFalse);
      expect(standalone.leagueId, isNull);
      expect(standalone.leagueName, isNull);

      final standaloneMap = standalone.toMap();
      expect(standaloneMap['leagueId'], isNull);
      expect(standaloneMap['leagueName'], isNull);

      final parsedStandalone = Tournament.fromMap(standaloneMap);
      expect(parsedStandalone.isUnderLeague, isFalse);
      expect(parsedStandalone.leagueId, isNull);

      // Tournament Under a League
      final leagueTournament = standalone.copyWith(
        leagueId: 'league-999',
        leagueName: 'Corporate League 2026',
      );

      expect(leagueTournament.isUnderLeague, isTrue);
      expect(leagueTournament.leagueId, 'league-999');
      expect(leagueTournament.leagueName, 'Corporate League 2026');

      final leagueMap = leagueTournament.toMap();
      expect(leagueMap['leagueId'], 'league-999');
      expect(leagueMap['leagueName'], 'Corporate League 2026');

      final parsedLeagueTournament = Tournament.fromMap(leagueMap);
      expect(parsedLeagueTournament.isUnderLeague, isTrue);
      expect(parsedLeagueTournament.leagueId, 'league-999');
      expect(parsedLeagueTournament.leagueName, 'Corporate League 2026');
    });
  });

  group('Firestore League & Tournament Linking Tests', () {
    test('FirestoreLeagueRepository handles full lifecycle and tournament linking', () async {
      final leagueRepo = FirestoreLeagueRepository();
      final tournamentRepo = FirestoreTournamentRepository();

      // 1. Create a League
      final league = League(
        id: 'league-corp-100',
        name: 'Metro Champions League',
        creatorId: 'user-organizer',
        shareCode: 'LEAGUE-MCL1',
        venue: 'Metro Sports Hub',
        sportTypes: ['Badminton', 'Cricket'],
      );
      await leagueRepo.saveLeague(league);

      // Verify league exists
      final fetched = await leagueRepo.getLeagueById('league-corp-100');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Metro Champions League');
      expect(fetched.tournamentsCount, 0);

      // Search by share code
      final foundByCode = await leagueRepo.getLeagueByShareCode('LEAGUE-MCL1');
      expect(foundByCode?.id, 'league-corp-100');

      // 2. Host Tournament 1 in this league (Badminton)
      final tourney1 = Tournament(
        id: 'tourney-badminton-1',
        name: 'Badminton Singles Championship',
        sportType: 'Badminton',
        format: TournamentFormat.singleElimination,
        participants: [
          Team(id: 'tm1', name: 'Player A'),
          Team(id: 'tm2', name: 'Player B'),
        ],
        matches: [],
        leagueId: league.id,
        leagueName: league.name,
      );
      await tournamentRepo.saveTournament(tourney1);
      await leagueRepo.addTournamentToLeague(league.id, tourney1.id);

      // 3. Host Tournament 2 in this league (Cricket)
      final tourney2 = Tournament(
        id: 'tourney-cricket-1',
        name: 'Cricket T20 Trophy',
        sportType: 'Cricket',
        format: TournamentFormat.roundRobin,
        participants: [
          Team(id: 'c1', name: 'Strikers'),
          Team(id: 'c2', name: 'Warriors'),
        ],
        matches: [],
        leagueId: league.id,
        leagueName: league.name,
      );
      await tournamentRepo.saveTournament(tourney2);
      await leagueRepo.addTournamentToLeague(league.id, tourney2.id);

      // 4. Create a standalone tournament (NOT under any league)
      final standaloneTourney = Tournament(
        id: 'tourney-standalone-99',
        name: 'Independent Tennis Open',
        sportType: 'Tennis',
        format: TournamentFormat.singleElimination,
        participants: [
          Team(id: 'tn1', name: 'Tennis Player 1'),
          Team(id: 'tn2', name: 'Tennis Player 2'),
        ],
        matches: [],
      );
      await tournamentRepo.saveTournament(standaloneTourney);

      // 5. Verify League now contains both tournaments
      final updatedLeague = await leagueRepo.getLeagueById(league.id);
      expect(updatedLeague!.tournamentsCount, 2);
      expect(updatedLeague.tournamentIds, contains('tourney-badminton-1'));
      expect(updatedLeague.tournamentIds, contains('tourney-cricket-1'));
      expect(updatedLeague.tournamentIds, isNot(contains('tourney-standalone-99')));

      // 6. Query tournaments by League ID via Tournament Repository
      final leagueTournaments = await tournamentRepo.getTournamentsByLeague(league.id);
      expect(leagueTournaments.length, 2);
      expect(leagueTournaments.map((t) => t.id), containsAll(['tourney-badminton-1', 'tourney-cricket-1']));
      expect(leagueTournaments.map((t) => t.id), isNot(contains('tourney-standalone-99')));

      // 7. Verify watchTournamentsByLeague stream returns matching tournaments
      final streamResult = await tournamentRepo.watchTournamentsByLeague(league.id).first;
      expect(streamResult.length, 2);

      // 8. Test removing a tournament from league
      await leagueRepo.removeTournamentFromLeague(league.id, 'tourney-badminton-1');
      final leagueAfterRemoval = await leagueRepo.getLeagueById(league.id);
      expect(leagueAfterRemoval!.tournamentsCount, 1);
      expect(leagueAfterRemoval.tournamentIds, ['tourney-cricket-1']);

      // 9. Verify watchLeagues emits immediately without hanging
      final initialLeagues = await leagueRepo.watchLeagues().first;
      expect(initialLeagues.any((l) => l.id == league.id), isTrue);

      // 10. Delete League
      await leagueRepo.deleteLeague(league.id);
      expect(await leagueRepo.getLeagueById(league.id), isNull);
    });
  });
}
