import 'package:flutter/material.dart';
import 'volleyball_score_screen.dart';

class VolleyballSetupScreen extends StatefulWidget {
  const VolleyballSetupScreen({super.key});

  @override
  State<VolleyballSetupScreen> createState() => _VolleyballSetupScreenState();
}

class _VolleyballSetupScreenState extends State<VolleyballSetupScreen> {
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();
  
  int _setsToWin = 3; 

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _startGame() {
    String teamA = _teamAController.text.trim();
    String teamB = _teamBController.text.trim();
    
    if (teamA.isEmpty) teamA = "Team A";
    if (teamB.isEmpty) teamB = "Team B";

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => VolleyballScoreScreen(
        teamAName: teamA,
        teamBName: teamB,
        setsToWin: _setsToWin,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.amber, // Volleyball Theme
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Text("Volleyball Setup",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              
              // Team A
              Text("TEAM A (Top Side)", 
                  style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildTextField(_teamAController, "Team Name"),
               
               const SizedBox(height: 24),
               
               // Team B
              Text("TEAM B (Bottom Side)", 
                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildTextField(_teamBController, "Team Name"),
               
               const SizedBox(height: 32),
               const Text("SETS TO WIN MATCH", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               SegmentedButton<int>(
                 segments: const [
                   ButtonSegment(value: 3, label: Text("Best of 5")), // 3 sets to win
                   ButtonSegment(value: 2, label: Text("Best of 3")), // 2 sets to win
                 ],
                 selected: {_setsToWin},
                 onSelectionChanged: (s) => setState(() => _setsToWin = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.amber;
                      return Colors.grey[200]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                       if (states.contains(WidgetState.selected)) return Colors.black87;
                      return Colors.black87;
                    }),
                  ),
               ),
               
               const SizedBox(height: 48),
               SizedBox(
                 height: 56,
                 child: ElevatedButton(
                   onPressed: _startGame,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                   child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
