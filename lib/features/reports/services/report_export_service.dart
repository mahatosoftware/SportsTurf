import '../../tournament/models/tournament.dart';
import '../../tournament/models/match.dart';
import '../../league/models/league.dart';

class ReportExportService {
  /// UC-183 & UC-184: Export tournament fixtures to CSV format
  static String exportFixturesCsv(Tournament tournament) {
    final buffer = StringBuffer();
    buffer.writeln('Match #,Round,Status,Team A,Team B,Score A,Score B,Winner,Court / Venue,Scheduled Time');

    for (final m in tournament.matches) {
      final teamAName = tournament.participants
          .where((p) => p.id == m.participantAId)
          .map((p) => p.name)
          .firstOrNull ?? m.participantA?.name ?? 'TBD';
      final teamBName = tournament.participants
          .where((p) => p.id == m.participantBId)
          .map((p) => p.name)
          .firstOrNull ?? m.participantB?.name ?? 'TBD';
      final winnerName = m.winnerId != null
          ? (tournament.participants.where((p) => p.id == m.winnerId).map((p) => p.name).firstOrNull ?? m.winnerId!)
          : '';

      buffer.writeln(
        '${m.matchNumber},${m.round},"${m.status.displayName}","${_escape(teamAName)}","${_escape(teamBName)}",'
        '${m.scoreA ?? ""},${m.scoreB ?? ""},"${_escape(winnerName)}",'
        '"${_escape(m.venueCourt ?? tournament.venue)}","${m.scheduledTime?.toIso8601String() ?? ""}"',
      );
    }

    return buffer.toString();
  }

  /// UC-057: Export tournament participants and seeds to CSV format
  static String exportParticipantsCsv(Tournament tournament) {
    final buffer = StringBuffer();
    buffer.writeln('Seed,Participant Name,Type,Player Count');

    for (int i = 0; i < tournament.participants.length; i++) {
      final p = tournament.participants[i];
      buffer.writeln(
        '${p.seed ?? (i + 1)},"${_escape(p.name)}",'
        '${tournament.isTeamTournament ? "Team" : "Individual"},${p.playerIds.length}',
      );
    }

    return buffer.toString();
  }

  /// UC-027: Export league overall standings to CSV format
  static String exportLeagueStandingsCsv(League league, List<Map<String, dynamic>> standings) {
    final buffer = StringBuffer();
    buffer.writeln('Rank,Participant Name,Played,Won,Lost,Points');

    for (int i = 0; i < standings.length; i++) {
      final s = standings[i];
      buffer.writeln(
        '${i + 1},"${_escape(s["name"]?.toString() ?? "")}",'
        '${s["played"] ?? 0},${s["wins"] ?? 0},${s["losses"] ?? 0},${s["points"] ?? 0}',
      );
    }

    return buffer.toString();
  }

  /// UC-185: Generate printable text match report
  static String generateMatchReport(Tournament tournament, TournamentMatch match) {
    final teamAName = tournament.participants
        .where((p) => p.id == match.participantAId)
        .map((p) => p.name)
        .firstOrNull ?? match.participantA?.name ?? 'TBD';
    final teamBName = tournament.participants
        .where((p) => p.id == match.participantBId)
        .map((p) => p.name)
        .firstOrNull ?? match.participantB?.name ?? 'TBD';
    final winner = match.winnerId != null
        ? (tournament.participants.where((p) => p.id == match.winnerId).map((p) => p.name).firstOrNull ?? match.winnerId!)
        : 'Pending';

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('         SPORTS TURF MATCH REPORT       ');
    buffer.writeln('========================================');
    buffer.writeln('Tournament: ${tournament.name}');
    buffer.writeln('Sport: ${tournament.sportType}');
    buffer.writeln('Match Number: #${match.matchNumber} (Round ${match.round})');
    buffer.writeln('Venue / Court: ${match.venueCourt ?? tournament.venue}');
    buffer.writeln('Date & Time: ${match.scheduledTime ?? "Scheduled"}');
    buffer.writeln('Status: ${match.status.displayName}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('COMPETITORS:');
    buffer.writeln('Team A: $teamAName (${match.scoreA ?? 0})');
    buffer.writeln('Team B: $teamBName (${match.scoreB ?? 0})');
    buffer.writeln('WINNER: $winner');
    buffer.writeln('----------------------------------------');
    if (match.statusReason != null && match.statusReason!.isNotEmpty) {
      buffer.writeln('Official Notes: ${match.statusReason}');
    }
    buffer.writeln('Report Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  static String _escape(String value) {
    return value.replaceAll('"', '""');
  }
}
