import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/standing.dart';
import '../models/match.dart';
import '../models/team.dart';

class LeaderboardView extends StatelessWidget {
  final Tournament tournament;

  const LeaderboardView({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    // Generate standings on the fly
    List<Standing> standings = _calculateStandings();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('P')),
          DataColumn(label: Text('W')),
          DataColumn(label: Text('L')),
          DataColumn(label: Text('D')),
          DataColumn(label: Text('Pts')),
        ],
        rows: standings.map((s) {
           Team? team = _getTeam(s.teamId);
           return DataRow(
             color: WidgetStateProperty.resolveWith<Color?>((states) {
               if (s.rank == 1) return Colors.amber.withValues(alpha: 0.1);
               return null;
             }),
             cells: [
               DataCell(Text('#${s.rank}')),
               DataCell(Text(team?.name ?? s.teamId, style: const TextStyle(fontWeight: FontWeight.bold))),
               DataCell(Text('${s.matchesPlayed}')),
               DataCell(Text('${s.wins}')),
               DataCell(Text('${s.losses}')),
               DataCell(Text('${s.draws}')),
               DataCell(Text('${s.points}')),
             ],
           );
        }).toList(),
      ),
    );
  }

  List<Standing> _calculateStandings() {
    Map<String, Standing> stats = {};

    for (var team in tournament.participants) {
      stats[team.id] = Standing(
          teamId: team.id, matchesPlayed: 0, wins: 0, losses: 0, draws: 0, points: 0, rank: 0);
    }

    for (var match in tournament.matches) {
       if (match.status == MatchStatus.completed) {
         if (match.winnerId != null) {
           // Winner
           if (stats.containsKey(match.winnerId)) {
             var w = stats[match.winnerId]!;
             stats[match.winnerId!] = w.copyWith(
               matchesPlayed: w.matchesPlayed + 1,
               wins: w.wins + 1,
               points: w.points + 3, // 3 ponts for win default
             );
           }
           
           // Loser
           String? loserId = (match.participantAId == match.winnerId) 
               ? match.participantBId 
               : match.participantAId;
               
           if (loserId != null && stats.containsKey(loserId)) {
             var l = stats[loserId]!;
             stats[loserId] = l.copyWith(
               matchesPlayed: l.matchesPlayed + 1,
               losses: l.losses + 1,
             );
           }
         } else {
            // Draw
            // Both A and B get draw
            if (match.participantAId != null && stats.containsKey(match.participantAId)) {
               var a = stats[match.participantAId]!;
               stats[match.participantAId!] = a.copyWith(
                 matchesPlayed: a.matchesPlayed + 1,
                 draws: a.draws + 1,
                 points: a.points + 1, // 1 point for draw
               );
            }
            if (match.participantBId != null && stats.containsKey(match.participantBId)) {
               var b = stats[match.participantBId]!;
               stats[match.participantBId!] = b.copyWith(
                 matchesPlayed: b.matchesPlayed + 1,
                 draws: b.draws + 1,
                 points: b.points + 1,
               );
            }
         }
       }
    }

    List<Standing> list = stats.values.toList();
    // Sort
    list.sort((a, b) => b.points.compareTo(a.points));
    
    // Assign rank
    for(int i=0; i<list.length; i++) {
      list[i] = list[i].copyWith(rank: i + 1);
    }
    
    return list;
  }
  
  Team? _getTeam(String id) {
    try {
      return tournament.participants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
