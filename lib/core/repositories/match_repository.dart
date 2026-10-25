import '../models/match_result.dart';

abstract class IMatchRepository {
  Future<List<MatchResult>> getMatches({String? sport});
  Future<void> saveMatch(MatchResult match);
  Future<void> deleteMatch(dynamic id);
  Future<void> deleteAllMatches();
  Stream<List<MatchResult>> watchMatches({String? sport});
}
