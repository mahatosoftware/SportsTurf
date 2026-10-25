import '../../features/tournament/models/team.dart';

abstract class ITeamRepository {
  Future<List<Team>> getTeams();
  Future<Team?> getTeamById(String id);
  Future<void> saveTeam(Team team);
  Future<void> deleteTeam(String id);
  Stream<List<Team>> watchTeams();
}
