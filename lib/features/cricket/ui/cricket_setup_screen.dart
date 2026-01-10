import 'package:flutter/material.dart';
import 'cricket_score_screen.dart';

class CricketSetupScreen extends StatefulWidget {
  const CricketSetupScreen({super.key});

  @override
  State<CricketSetupScreen> createState() => _CricketSetupScreenState();
}

class _CricketSetupScreenState extends State<CricketSetupScreen> {
  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();
  int _overs = 10;
  
  // Squads
  final List<String> _squadA = [];
  final List<String> _squadB = [];
  final TextEditingController _playerAController = TextEditingController();
  final TextEditingController _playerBController = TextEditingController();

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _playerAController.dispose();
    _playerBController.dispose();
    super.dispose();
  }
  
  void _addPlayer(List<String> squad, TextEditingController controller) {
    if (controller.text.trim().isNotEmpty) {
      setState(() {
        squad.add(controller.text.trim());
        controller.clear();
      });
    }
  }
  
  void _removePlayer(List<String> squad, int index) {
    setState(() {
      squad.removeAt(index);
    });
  }

  void _startMatch() {
    String teamA = _teamAController.text.trim();
    String teamB = _teamBController.text.trim();
    if (teamA.isEmpty) teamA = "Team A";
    if (teamB.isEmpty) teamB = "Team B";

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => CricketScoreScreen(
        teamA: teamA,
        teamB: teamB,
        squadA: _squadA,
        squadB: _squadB,
        overs: _overs,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Cricket Setup",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Team A
               _buildTeamSection("TEAM A (Batting First)", _teamAController, _playerAController, _squadA),
               
               const SizedBox(height: 24),
               
               // Team B
               _buildTeamSection("TEAM B (Bowling First)", _teamBController, _playerBController, _squadB),
              
              const SizedBox(height: 32),
              
              // Overs
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("OVERS: $_overs", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Slider(
                        value: _overs.toDouble(),
                        min: 2, max: 50, divisions: 48,
                        label: "$_overs",
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _overs = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamSection(String title, TextEditingController teamNameCtrl, TextEditingController playerCtrl, List<String> squad) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: teamNameCtrl,
              decoration: const InputDecoration(labelText: "Team Name", border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            const Text("Squad Members:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: squad.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  onDeleted: () => _removePlayer(squad, entry.key),
                  backgroundColor: Colors.green[50],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: playerCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: "Add Player Name", border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (_) => _addPlayer(squad, playerCtrl),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: () => _addPlayer(squad, playerCtrl),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
