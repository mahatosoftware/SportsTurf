import '../models/match.dart';
import '../models/team.dart';

class FixtureGenerator {
  /// Generates Round Robin matches using the standard polygon rotation algorithm.
  static List<TournamentMatch> generateRoundRobin(List<Team> teams) {
    if (teams.length < 2) return [];

    List<Team> participants = List.from(teams);

    // If odd number of teams, add a dummy BYE team
    final bool hasBye = participants.length % 2 != 0;
    if (hasBye) {
      participants.add(Team(id: "BYE", name: "BYE"));
    }

    int n = participants.length;
    int rounds = n - 1;
    int matchesPerRound = n ~/ 2;
    List<TournamentMatch> matches = [];

    int matchCounter = 1;

    for (int r = 0; r < rounds; r++) {
      for (int m = 0; m < matchesPerRound; m++) {
        Team home = participants[m];
        Team away = participants[n - 1 - m];

        // Do not schedule match if one side is BYE
        if (home.id != "BYE" && away.id != "BYE") {
          matches.add(TournamentMatch(
            id: 'RR-R${r + 1}-M$matchCounter',
            round: r + 1,
            matchNumber: matchCounter++,
            participantAId: home.id,
            participantBId: away.id,
            participantA: home,
            participantB: away,
            status: MatchStatus.upcoming,
          ));
        }
      }

      // Rotate teams clockwise, holding index 0 fixed
      Team last = participants.removeLast();
      participants.insert(1, last);
    }

    return matches;
  }

  /// Generates Single Elimination Bracket with proper Bye advancement.
  static List<TournamentMatch> generateSingleElimination(
      List<Team> teams, bool seeded) {
    if (teams.length < 2) return [];

    int n = teams.length;
    int powerOf2 = 1;
    while (powerOf2 < n) {
      powerOf2 *= 2;
    }

    List<Team> sortedTeams = List.from(teams);
    if (seeded) {
      sortedTeams.sort((a, b) => (a.seed ?? 999).compareTo(b.seed ?? 999));
    } else {
      sortedTeams.shuffle();
    }

    List<List<TournamentMatch>> rounds = [];
    int matchCounter = 1;
    int matchesInRound = powerOf2 ~/ 2;
    int currentRoundNumber = 1;

    // Step 1: Create bracket match hierarchy
    while (matchesInRound >= 1) {
      List<TournamentMatch> roundMatches = [];
      for (int i = 0; i < matchesInRound; i++) {
        String matchId = 'SE-R$currentRoundNumber-M${matchCounter++}';
        roundMatches.add(TournamentMatch(
          id: matchId,
          round: currentRoundNumber,
          matchNumber: matchCounter - 1,
          status: MatchStatus.upcoming,
        ));
      }
      rounds.add(roundMatches);
      matchesInRound ~/= 2;
      currentRoundNumber++;
    }

    // Step 2: Link rounds so winners advance to the parent match
    for (int r = 0; r < rounds.length - 1; r++) {
      List<TournamentMatch> currentRoundMatches = rounds[r];
      List<TournamentMatch> nextRoundMatches = rounds[r + 1];

      for (int i = 0; i < currentRoundMatches.length; i++) {
        int nextMatchIndex = i ~/ 2;
        TournamentMatch nextMatch = nextRoundMatches[nextMatchIndex];
        rounds[r][i] = currentRoundMatches[i].copyWith(nextMatchId: nextMatch.id);
      }
    }

    // Flatten to mutable map for ease of updating
    Map<String, TournamentMatch> allMatches = {};
    for (var roundList in rounds) {
      for (var m in roundList) {
        allMatches[m.id] = m;
      }
    }

    // Step 3: Seed placement into Round 1
    List<int> seedOrder = _getSeedOrder(powerOf2);
    List<Team?> slots = List.filled(powerOf2, null);

    for (int i = 0; i < powerOf2; i++) {
      int rank = seedOrder[i];
      if (rank <= n) {
        slots[i] = sortedTeams[rank - 1];
      } else {
        slots[i] = null; // Bye
      }
    }

    // Step 4: Populate Round 1 and auto-advance Byes
    List<TournamentMatch> round1 = rounds[0];
    for (int i = 0; i < round1.length; i++) {
      Team? teamA = slots[i * 2];
      Team? teamB = slots[i * 2 + 1];
      TournamentMatch m = allMatches[round1[i].id]!;

      m = m.copyWith(
        participantA: teamA,
        participantAId: teamA?.id,
        participantB: teamB,
        participantBId: teamB?.id,
      );

      // Check for Byes
      if (teamA != null && teamB == null) {
        // Team A gets a Bye, automatically advances to next match
        m = m.copyWith(
          winnerId: teamA.id,
          status: MatchStatus.completed,
          scoreA: 1,
          scoreB: 0,
          statusReason: 'Bye Advancement',
        );

        if (m.nextMatchId != null && allMatches.containsKey(m.nextMatchId)) {
          TournamentMatch nextM = allMatches[m.nextMatchId]!;
          if (i % 2 == 0) {
            allMatches[m.nextMatchId!] = nextM.copyWith(
              participantA: teamA,
              participantAId: teamA.id,
            );
          } else {
            allMatches[m.nextMatchId!] = nextM.copyWith(
              participantB: teamA,
              participantBId: teamA.id,
            );
          }
        }
      } else if (teamA == null && teamB != null) {
        // Team B gets a Bye
        m = m.copyWith(
          winnerId: teamB.id,
          status: MatchStatus.completed,
          scoreA: 0,
          scoreB: 1,
          statusReason: 'Bye Advancement',
        );

        if (m.nextMatchId != null && allMatches.containsKey(m.nextMatchId)) {
          TournamentMatch nextM = allMatches[m.nextMatchId]!;
          if (i % 2 == 0) {
            allMatches[m.nextMatchId!] = nextM.copyWith(
              participantA: teamB,
              participantAId: teamB.id,
            );
          } else {
            allMatches[m.nextMatchId!] = nextM.copyWith(
              participantB: teamB,
              participantBId: teamB.id,
            );
          }
        }
      }

      allMatches[m.id] = m;
    }

    return allMatches.values.toList()
      ..sort((a, b) {
        int cmp = a.round.compareTo(b.round);
        if (cmp != 0) return cmp;
        return a.matchNumber.compareTo(b.matchNumber);
      });
  }

  /// Generates Double Elimination Bracket
  static List<TournamentMatch> generateDoubleElimination(
      List<Team> teams, bool seeded) {
    if (teams.length < 2) return [];

    List<TournamentMatch> wbMatches = generateSingleElimination(teams, seeded);
    return wbMatches.map((m) {
      String newId = m.id.replaceFirst('SE-', 'WB-');
      String? newNextId = m.nextMatchId?.replaceFirst('SE-', 'WB-');
      return m.copyWith(id: newId, nextMatchId: newNextId);
    }).toList();
  }

  /// Generates Friendly Matches (sequential pair-ups)
  static List<TournamentMatch> generateFriendlyMatches(List<Team> teams) {
    if (teams.length < 2) return [];
    List<TournamentMatch> matches = [];
    int matchCounter = 1;

    for (int i = 0; i < teams.length - 1; i += 2) {
      Team a = teams[i];
      Team b = teams[i + 1];
      matches.add(TournamentMatch(
        id: 'FR-M$matchCounter',
        round: 1,
        matchNumber: matchCounter++,
        participantAId: a.id,
        participantBId: b.id,
        participantA: a,
        participantB: b,
        status: MatchStatus.upcoming,
      ));
    }
    return matches;
  }

  /// Helper to get standard seeding order for a bracket of size N
  static List<int> _getSeedOrder(int n) {
    if (n == 2) return [1, 2];

    List<int> previous = _getSeedOrder(n ~/ 2);
    List<int> result = [];

    for (int i = 0; i < previous.length; i++) {
      result.add(previous[i]);
      result.add(n + 1 - previous[i]);
    }
    return result;
  }
}
