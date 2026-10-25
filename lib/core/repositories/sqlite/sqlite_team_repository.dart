import 'dart:async';
import '../../database/database_helper.dart';
import '../../../features/tournament/models/team.dart';
import '../team_repository.dart';

class SqliteTeamRepository implements ITeamRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<List<Team>> _streamController = StreamController<List<Team>>.broadcast();

  SqliteTeamRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Team>> getTeams() async {
    final teams = await _dbHelper.getTeams();
    _streamController.add(teams);
    return teams;
  }

  @override
  Future<Team?> getTeamById(String id) async {
    final teams = await getTeams();
    try {
      return teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTeam(Team team) async {
    await _dbHelper.insertTeam(team);
    await getTeams(); // Notify listeners
  }

  @override
  Future<void> deleteTeam(String id) async {
    await _dbHelper.deleteTeam(id);
    await getTeams();
  }

  @override
  Stream<List<Team>> watchTeams() {
    getTeams();
    return _streamController.stream;
  }
}
