import 'package:flutter/material.dart';
import '../models/cricket_match_state.dart';

class CricketStatsScreen extends StatelessWidget {
  final CricketMatchState state;
  const CricketStatsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Match Statistics"),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellowAccent,
            tabs: [
              Tab(text: "SUMMARY"),
              Tab(text: "SCORECARD"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryTab(),
            _buildScorecardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    String winner = state.matchResult ?? "Match in Progress";
    
    // Find Top Scorer
    CricketPlayer? topScorer;
    int maxRuns = -1;
    for (var p in state.playerStats.values) {
      if (p.runs > maxRuns) {
        maxRuns = p.runs;
        topScorer = p;
      }
    }
    
    // Find Best Bowler (Most Wickets, then least runs)
    CricketPlayer? bestBowler;
    // Simple metric: Wickets * 1000 - Runs (to prioritize wickets)
    int bestFig = -99999;
    
    for (var p in state.playerStats.values) {
       if (p.ballsBowled > 0) {
         int score = (p.wickets * 1000) - p.runsConceded;
         if (score > bestFig) {
           bestFig = score;
           bestBowler = p;
         }
       }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Result Card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(winner, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  const SizedBox(height: 12),
                  Text("${state.battingTeamName}: ${state.totalRuns}/${state.wicketsLost} (${state.oversCompleted}.${state.ballsInOver})",
                      style: const TextStyle(fontSize: 18)),
                  if (state.currentInning == 2)
                    Text("Target: ${state.targetRuns}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("Top Performers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPerformerCard("Top Scorer", topScorer?.name ?? "-", "${topScorer?.runs ?? 0} runs", Icons.sports_cricket),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformerCard("Best Bowler", bestBowler?.name ?? "-", "${bestBowler?.wickets ?? 0}-${bestBowler?.runsConceded ?? 0}", Icons.sports_baseball),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          // Team Comparison (Simple)
          _buildTeamStatsTable(),
        ],
      ),
    );
  }
  
  Widget _buildPerformerCard(String title, String name, String stat, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue[800], size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, maxLines: 1),
            Text(stat, style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTeamStatsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Stats Overview", style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow("Total Runs", "${state.totalRuns}"),
            _buildStatRow("Wickets Lost", "${state.wicketsLost}"),
            _buildStatRow("Overs", "${state.oversCompleted}.${state.ballsInOver}"),
            _buildStatRow("Run Rate", _calculateRunRate(state)),
          ],
        ),
      ),
    );
  }

  String _calculateRunRate(CricketMatchState state) {
    double overs = state.oversCompleted + (state.ballsInOver / 6.0);
    if (overs == 0) return "0.00";
    return (state.totalRuns / overs).toStringAsFixed(2);
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScorecardTab() {
    // Separate Batters and Bowlers from playerStats
    List<CricketPlayer> batters = state.playerStats.values.where((p) => p.runs > 0 || p.ballsFaced > 0 || p.isOut).toList();
    List<CricketPlayer> bowlers = state.playerStats.values.where((p) => p.ballsBowled > 0).toList();
    
    // Sort
    batters.sort((a, b) => b.runs.compareTo(a.runs)); // Highest runs first
    bowlers.sort((a, b) => b.wickets.compareTo(a.wickets)); // Most wickets first

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Batting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("Batter")),
                DataColumn(label: Text("R"), numeric: true),
                DataColumn(label: Text("B"), numeric: true),
                DataColumn(label: Text("4s"), numeric: true),
                DataColumn(label: Text("6s"), numeric: true),
                DataColumn(label: Text("SR"), numeric: true),
              ],
              rows: batters.map((p) {
                double sr = p.ballsFaced > 0 ? (p.runs / p.ballsFaced * 100) : 0.0;
                return DataRow(cells: [
                  DataCell(Text(p.name + (p.isOut ? "" : "*"), style: TextStyle(fontWeight: p.isOut ? FontWeight.normal : FontWeight.bold))),
                  DataCell(Text("${p.runs}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text("${p.ballsFaced}")),
                  DataCell(Text("${p.fours}")),
                  DataCell(Text("${p.sixes}")),
                  DataCell(Text(sr.toStringAsFixed(1))),
                ]);
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("Bowling", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("Bowler")),
                DataColumn(label: Text("O"), numeric: true),
                DataColumn(label: Text("M"), numeric: true), // Maidens not strictly tracked yet, putting 0
                DataColumn(label: Text("R"), numeric: true),
                DataColumn(label: Text("W"), numeric: true),
                DataColumn(label: Text("Econ"), numeric: true),
              ],
              rows: bowlers.map((p) {
                double overs = p.ballsBowled / 6;
                double econ = overs > 0 ? (p.runsConceded / overs) : 0.0;
                return DataRow(cells: [
                  DataCell(Text(p.name)),
                  DataCell(Text("${p.ballsBowled ~/ 6}.${p.ballsBowled % 6}")),
                  DataCell(const Text("0")), // Maidens Placeholder
                  DataCell(Text("${p.runsConceded}")),
                  DataCell(Text("${p.wickets}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(econ.toStringAsFixed(1))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
