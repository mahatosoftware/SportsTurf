import 'dart:async';
import '../../database/database_helper.dart';
import '../../models/player.dart';
import '../player_repository.dart';

class SqlitePlayerRepository implements IPlayerRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<List<Player>> _streamController = StreamController<List<Player>>.broadcast();

  SqlitePlayerRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Player>> getPlayers() async {
    final players = await _dbHelper.getPlayers();
    _streamController.add(players);
    return players;
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    final players = await getPlayers();
    try {
      return players.firstWhere((p) => p.id?.toString() == id || p.name == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlayer(Player player) async {
    if (player.id == null) {
      await _dbHelper.insertPlayer(player);
    } else {
      await _dbHelper.updatePlayer(player);
    }
    await getPlayers(); // Notify listeners
  }

  @override
  Future<void> deletePlayer(String id) async {
    final intId = int.tryParse(id);
    if (intId != null) {
      await _dbHelper.deletePlayer(intId);
      await getPlayers();
    }
  }

  @override
  Stream<List<Player>> watchPlayers() {
    getPlayers(); // Initial fetch
    return _streamController.stream;
  }
}
