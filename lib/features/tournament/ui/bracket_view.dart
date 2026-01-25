import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/match.dart';

class BracketView extends StatelessWidget {
  final Tournament tournament;

  const BracketView({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    // Basic visualization: Horizontal scroll of Rounds columns
    
    // Group by Round
    Map<int, List<TournamentMatch>> byRound = {};
    for (var m in tournament.matches) {
      // Filter out Losers Bracket if separate visualization needed
      // For now show all.
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    
    List<int> rounds = byRound.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rounds.map((r) {
          List<TournamentMatch> matches = byRound[r]!;
          // Sort matches by matchNumber or visual order?
          // Default order usually fine if generated correctly.
          
          return Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Round $r', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 32),
                    itemBuilder: (ctx, i) {
                      var m = matches[i];
                      return _buildBracketNode(context, m);
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBracketNode(BuildContext context, TournamentMatch match) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTeamLine(match.participantA?.name ?? 'TBD', match.scoreA, 
             match.winnerId == match.participantAId && match.participantAId != null),
          const Divider(height: 1),
          _buildTeamLine(match.participantB?.name ?? 'TBD', match.scoreB,
             match.winnerId == match.participantBId && match.participantBId != null),
        ],
      ),
    );
  }

  Widget _buildTeamLine(String name, int? score, bool isWinner) {
    return Container(
      color: isWinner ? Colors.green.withOpacity(0.1) : null,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          Text(score?.toString() ?? '-'),
        ],
      ),
    );
  }
}
