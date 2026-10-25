import '../../features/dispute/models/dispute.dart';

abstract class IDisputeRepository {
  Future<List<Dispute>> getDisputes({String? tournamentId, String? leagueId, String? matchId});
  Future<Dispute?> getDisputeById(String id);
  Future<void> saveDispute(Dispute dispute);
  Future<void> resolveDispute(String id, DisputeStatus status, String resolution, String reviewerUserId, String reviewerName);
  Future<void> deleteDispute(String id);
  Stream<List<Dispute>> watchDisputes({String? tournamentId, String? leagueId});
}
