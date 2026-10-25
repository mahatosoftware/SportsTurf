import '../../features/tournament/models/tournament_registration.dart';

abstract class IRegistrationRepository {
  Future<List<TournamentRegistration>> getRegistrations({String? tournamentId, String? leagueId});
  Future<TournamentRegistration?> getRegistrationById(String id);
  Future<void> saveRegistration(TournamentRegistration registration);
  Future<void> updateRegistrationStatus(String id, RegistrationStatus status, {String? reviewedBy, String? notes});
  Future<void> deleteRegistration(String id);
  Stream<List<TournamentRegistration>> watchRegistrations({String? tournamentId, String? leagueId});
}
