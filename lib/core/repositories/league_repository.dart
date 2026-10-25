import '../../features/league/models/league.dart';

abstract class ILeagueRepository {
  Future<List<League>> getLeagues();
  Future<League?> getLeagueById(String id);
  Future<League?> getLeagueByShareCode(String code);
  Future<void> saveLeague(League league);
  Future<void> deleteLeague(String id);
  Future<void> addTournamentToLeague(String leagueId, String tournamentId);
  Future<void> removeTournamentFromLeague(String leagueId, String tournamentId);
  Stream<League?> watchLeague(String id);
  Stream<List<League>> watchLeagues();
  Stream<List<League>> watchPublicLeagues();
}
