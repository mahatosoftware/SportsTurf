import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/player_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/tournament_repository.dart';
import '../repositories/league_repository.dart';
import '../repositories/match_repository.dart';
import '../repositories/venue_repository.dart';
import '../repositories/registration_repository.dart';
import '../repositories/dispute_repository.dart';
import '../repositories/season_repository.dart';
import '../repositories/audit_repository.dart';

import '../repositories/firestore/firestore_player_repository.dart';
import '../repositories/firestore/firestore_team_repository.dart';
import '../repositories/firestore/firestore_tournament_repository.dart';
import '../repositories/firestore/firestore_league_repository.dart';
import '../repositories/firestore/firestore_match_repository.dart';
import '../repositories/firestore/firestore_venue_repository.dart';
import '../repositories/firestore/firestore_registration_repository.dart';
import '../repositories/firestore/firestore_dispute_repository.dart';
import '../repositories/firestore/firestore_season_repository.dart';
import '../repositories/firestore/firestore_audit_repository.dart';

final playerRepositoryProvider = Provider<IPlayerRepository>((ref) {
  return FirestorePlayerRepository();
});

final teamRepositoryProvider = Provider<ITeamRepository>((ref) {
  return FirestoreTeamRepository();
});

final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return FirestoreTournamentRepository();
});

final matchRepositoryProvider = Provider<IMatchRepository>((ref) {
  return FirestoreMatchRepository();
});

final leagueRepositoryProvider = Provider<ILeagueRepository>((ref) {
  return FirestoreLeagueRepository();
});

final venueRepositoryProvider = Provider<IVenueRepository>((ref) {
  return FirestoreVenueRepository();
});

final registrationRepositoryProvider = Provider<IRegistrationRepository>((ref) {
  return FirestoreRegistrationRepository();
});

final disputeRepositoryProvider = Provider<IDisputeRepository>((ref) {
  return FirestoreDisputeRepository();
});

final seasonRepositoryProvider = Provider<ISeasonRepository>((ref) {
  return FirestoreSeasonRepository();
});

final auditRepositoryProvider = Provider<IAuditRepository>((ref) {
  return FirestoreAuditRepository();
});
