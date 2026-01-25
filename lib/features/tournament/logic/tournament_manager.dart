import '../models/match.dart';
import '../models/tournament.dart';
import '../models/team.dart';

class TournamentManager {
  Tournament tournament;

  TournamentManager(this.tournament);

  // Update match score and possibly advance winner
  Tournament updateMatch(String matchId, int scoreA, int scoreB) {
    // Find absolute match
    int matchIndex = tournament.matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return tournament;

    TournamentMatch match = tournament.matches[matchIndex];
    
    // Determine winner
    String? winnerId;
    if (scoreA > scoreB) {
      if (match.participantAId != null) winnerId = match.participantAId;
    } else if (scoreB > scoreA) {
      if (match.participantBId != null) winnerId = match.participantBId;
    } else {
      // Draw? Logic depends on sport. Elimination must have winner.
      // Round Robin can have draw.
      if (tournament.format == TournamentFormat.roundRobin) {
         winnerId = null; // Draw
      } else {
         // Require winner for elimination
         return tournament; // Or throw error/handle UI validation
      }
    }

    // Update current match
    TournamentMatch updatedMatch = match.copyWith(
      scoreA: scoreA,
      scoreB: scoreB,
      winnerId: winnerId,
      status: MatchStatus.completed,
    );

    List<TournamentMatch> allMatches = List.from(tournament.matches);
    allMatches[matchIndex] = updatedMatch;

    // Advance Winner in Elimination Brackets
    if (tournament.format != TournamentFormat.roundRobin && winnerId != null) {
      if (match.nextMatchId != null) {
        int nextIndex = allMatches.indexWhere((m) => m.id == match.nextMatchId);
        if (nextIndex != -1) {
          TournamentMatch nextMatch = allMatches[nextIndex];
          // Place winner in A or B?
          // This depends on linking logic. Typically:
          // Match 1 -> NextMatch Slot A
          // Match 2 -> NextMatch Slot B
          // We can check if slots are empty or infer from "feed".
          // A simple heuristic: if nextMatch.participantAId is null, put there. Else B.
          
          // More robust: During generation we should have stored "nextMatchSlot".
          // But here, let's assume standard ordering.
          // If matchIndex is even (0, 2, 4), it goes to A. Odd goes to B.
          // Wait, 'matchIndex' is in the whole list.
          // We need 'index within the round'.
          
          // Re-finding context is hard without strict metadata in Match model.
          // Let's fill the first available slot for now, or assume stable sort.
          // Actually, 'participantAId' being null is the check.
          
          if (nextMatch.participantAId == null) {
             // Need to find Team object
             Team? team = _getTeam(winnerId);
             nextMatch = nextMatch.copyWith(participantAId: winnerId, participantA: team);
          } else if (nextMatch.participantBId == null) {
             Team? team = _getTeam(winnerId);
             nextMatch = nextMatch.copyWith(participantBId: winnerId, participantB: team);
          }
          
          allMatches[nextIndex] = nextMatch;
        }
      }
      
      // Handle Loser for Double Elim
      if (tournament.format == TournamentFormat.doubleElimination && match.loserNextMatchId != null) {
         // Logic for dropping loser to loser bracket
         String loserId = (winnerId == match.participantAId) ? match.participantBId! : match.participantAId!;
         // ... Similar logic to populate loser bracket match
      }
    }

    return tournament.copyWith(matches: allMatches);
  }
  
  Team? _getTeam(String id) {
    try {
      return tournament.participants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update match schedule
  Tournament updateMatchSchedule(String matchId, DateTime scheduledTime) {
    int matchIndex = tournament.matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return tournament;

    TournamentMatch match = tournament.matches[matchIndex];
    TournamentMatch updatedMatch = match.copyWith(scheduledTime: scheduledTime);

    List<TournamentMatch> allMatches = List.from(tournament.matches);
    allMatches[matchIndex] = updatedMatch;

    return tournament.copyWith(matches: allMatches);
  }
}
