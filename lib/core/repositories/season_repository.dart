import '../../features/league/models/season.dart';

abstract class ISeasonRepository {
  Future<List<Season>> getSeasons(String leagueId);
  Future<Season?> getSeasonById(String id);
  Future<void> saveSeason(Season season);
  Future<void> deleteSeason(String id);
  Stream<List<Season>> watchSeasons(String leagueId);
}
