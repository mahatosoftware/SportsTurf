import 'dart:async';
import '../../database/database_helper.dart';
import '../../models/match_result.dart';
import '../match_repository.dart';

class SqliteMatchRepository implements IMatchRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<List<MatchResult>> _matchesStream = StreamController<List<MatchResult>>.broadcast();

  SqliteMatchRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<MatchResult>> getMatches({String? sport}) async {
    final matches = await _dbHelper.getMatches(sport: sport);
    _matchesStream.add(matches);
    return matches;
  }

  @override
  Future<void> saveMatch(MatchResult match) async {
    await _dbHelper.insertMatch(match);
    await getMatches(sport: match.sport);
  }

  @override
  Future<void> deleteMatch(dynamic id) async {
    final intId = id is int ? id : (int.tryParse(id?.toString() ?? '0') ?? 0);
    await _dbHelper.deleteMatch(intId);
    await getMatches();
  }

  @override
  Future<void> deleteAllMatches() async {
    await _dbHelper.deleteAllMatches();
    _matchesStream.add([]);
  }

  @override
  Stream<List<MatchResult>> watchMatches({String? sport}) {
    getMatches(sport: sport);
    return _matchesStream.stream;
  }
}
