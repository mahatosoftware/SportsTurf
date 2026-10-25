import '../models/player.dart';

abstract class IPlayerRepository {
  Future<List<Player>> getPlayers();
  Future<Player?> getPlayerById(String id);
  Future<void> savePlayer(Player player);
  Future<void> deletePlayer(String id);
  Stream<List<Player>> watchPlayers();
}
