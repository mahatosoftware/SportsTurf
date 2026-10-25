import 'dart:async';
import '../../database/database_helper.dart';
import '../../../features/tournament/models/tournament.dart';
import '../../../features/tournament/models/match.dart';
import '../../../features/tournament/logic/tournament_manager.dart';
import '../tournament_repository.dart';

class SqliteTournamentRepository implements ITournamentRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<List<Tournament>> _tournamentsStream = StreamController<List<Tournament>>.broadcast();
  final Map<String, StreamController<Tournament?>> _singleTournamentStreams = {};

  SqliteTournamentRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Tournament>> getTournaments({String? sport, TournamentStatus? status}) async {
    final list = await _dbHelper.getTournaments(sport: sport);
    List<Tournament> filtered = list;
    if (status != null) {
      filtered = filtered.where((t) => t.status == status).toList();
    }
    _tournamentsStream.add(filtered);
    return filtered;
  }

  @override
  Future<Tournament?> getTournamentById(String id) async {
    final list = await _dbHelper.getTournaments();
    try {
      final match = list.firstWhere((t) => t.id == id);
      _notifySingle(match);
      return match;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Tournament?> getTournamentByShareCode(String code) async {
    final list = await _dbHelper.getTournaments();
    final normalized = code.trim().toUpperCase();
    try {
      final match = list.firstWhere(
        (t) => t.shareCode.toUpperCase() == normalized || t.id == code.trim(),
      );
      _notifySingle(match);
      return match;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Tournament>> getPublicTournaments({String? sport}) async {
    final list = await getTournaments(sport: sport);
    return list.where((t) => t.isPublic).toList();
  }

  @override
  Future<void> saveTournament(Tournament tournament) async {
    await _dbHelper.insertTournament(tournament);
    _notifySingle(tournament);
    await getTournaments();
  }

  @override
  Future<void> deleteTournament(String id) async {
    await _dbHelper.deleteTournament(id);
    if (_singleTournamentStreams.containsKey(id)) {
      _singleTournamentStreams[id]?.add(null);
    }
    await getTournaments();
  }

  @override
  Future<void> updateMatchScore(String tournamentId, String matchId, int scoreA, int scoreB, String? winnerId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return;

    final manager = TournamentManager(tournament);
    final updated = manager.updateMatch(matchId, scoreA, scoreB);
    await saveTournament(updated);
  }

  @override
  Future<void> updateMatchStatus(String tournamentId, String matchId, MatchStatus status) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return;

    final matches = tournament.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(status: status);
      }
      return m;
    }).toList();

    await saveTournament(tournament.copyWith(matches: matches));
  }

  @override
  Stream<Tournament?> watchTournament(String id) {
    if (!_singleTournamentStreams.containsKey(id)) {
      _singleTournamentStreams[id] = StreamController<Tournament?>.broadcast();
    }
    getTournamentById(id);
    return _singleTournamentStreams[id]!.stream;
  }

  @override
  Stream<List<Tournament>> watchTournaments({String? sport}) {
    getTournaments(sport: sport);
    return _tournamentsStream.stream;
  }

  @override
  Stream<List<Tournament>> watchPublicTournaments({String? sport}) {
    return watchTournaments(sport: sport).map((list) => list.where((t) => t.isPublic).toList());
  }

  @override
  Future<List<Tournament>> getTournamentsByLeague(String leagueId) async {
    final list = await _dbHelper.getTournaments();
    return list.where((t) => t.leagueId == leagueId).toList();
  }

  @override
  Stream<List<Tournament>> watchTournamentsByLeague(String leagueId) {
    return watchTournaments().map((list) => list.where((t) => t.leagueId == leagueId).toList());
  }

  void _notifySingle(Tournament tournament) {
    if (_singleTournamentStreams.containsKey(tournament.id)) {
      _singleTournamentStreams[tournament.id]?.add(tournament);
    }
  }
}
