import '../../features/tournament/models/tournament.dart';
import '../../features/tournament/models/match.dart';

abstract class ITournamentRepository {
  Future<List<Tournament>> getTournaments({String? sport, TournamentStatus? status});
  Future<Tournament?> getTournamentById(String id);
  Future<Tournament?> getTournamentByShareCode(String code);
  Future<List<Tournament>> getPublicTournaments({String? sport});
  Future<void> saveTournament(Tournament tournament);
  Future<void> deleteTournament(String id);
  Future<void> updateMatchScore(String tournamentId, String matchId, int scoreA, int scoreB, String? winnerId);
  Future<void> updateMatchStatus(String tournamentId, String matchId, MatchStatus status);
  Stream<Tournament?> watchTournament(String id);
  Stream<List<Tournament>> watchTournaments({String? sport});
  Stream<List<Tournament>> watchPublicTournaments({String? sport});
  Future<List<Tournament>> getTournamentsByLeague(String leagueId);
  Stream<List<Tournament>> watchTournamentsByLeague(String leagueId);
}
