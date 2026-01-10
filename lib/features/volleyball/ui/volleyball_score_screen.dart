import 'package:flutter/material.dart';
import '../logic/volleyball_state_machine.dart';
import '../models/volleyball_match_state.dart';
import 'volleyball_court_painter.dart';

class VolleyballScoreScreen extends StatefulWidget {
  final String teamAName;
  final String teamBName;
  final int setsToWin;

  const VolleyballScoreScreen({
    super.key,
    this.teamAName = "Team A",
    this.teamBName = "Team B",
    this.setsToWin = 3,
  });

  @override
  State<VolleyballScoreScreen> createState() => _VolleyballScoreScreenState();
}

class _VolleyballScoreScreenState extends State<VolleyballScoreScreen> {
  late VolleyballStateMachine _stateMachine;

  @override
  void initState() {
    super.initState();
    _stateMachine = VolleyballStateMachine(
      teamAName: widget.teamAName,
      teamBName: widget.teamBName,
      setsToWin: widget.setsToWin,
    );
  }

  void _scorePoint(VolleyballTeam team) {
    setState(() {
      _stateMachine.scorePoint(team);
    });
  }

  void _undo() {
    setState(() {
      _stateMachine.undo();
    });
  }

  void _reset() {
    setState(() {
      _stateMachine.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _stateMachine.state;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Volleyball Scorer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _stateMachine.canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Confirm reset
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Reset Match?'),
                  content: const Text('This will clear all scores.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _reset();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Court Background
              Center(
                child: CustomPaint(
                  size: Size(w, h),
                  painter: VolleyballCourtPainter(
                    isTeamAServing: state.servingTeam == VolleyballTeam.teamA,
                    isTeamBServing: state.servingTeam == VolleyballTeam.teamB,
                  ),
                ),
              ),

              // 2. Team A Zone (Top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h / 2,
                child: _buildTeamZone(
                  teamName: widget.teamAName,
                  score: state.scoreA,
                  sets: state.setsWonA,
                  isServing: state.servingTeam == VolleyballTeam.teamA,
                  onTap: () => _scorePoint(VolleyballTeam.teamA),
                  isRotated: true,
                  color: Colors.redAccent,
                ),
              ),

              // 3. Team B Zone (Bottom)
              Positioned(
                top: h / 2,
                left: 0,
                right: 0,
                height: h / 2,
                child: _buildTeamZone(
                  teamName: widget.teamBName,
                  score: state.scoreB,
                  sets: state.setsWonB,
                  isServing: state.servingTeam == VolleyballTeam.teamB,
                  onTap: () => _scorePoint(VolleyballTeam.teamB),
                  isRotated: false,
                  color: Colors.blueAccent,
                ),
              ),

              // 4. Set Info (Centered)
              Positioned(
                top: h / 2 - 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Set ${state.currentSet}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              // 5. Match Winner Overlay
              if (state.isMatchComplete)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${state.matchWinner == VolleyballTeam.teamA ? widget.teamAName : widget.teamBName} Wins!",
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reset,
                          child: const Text("New Match"),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamZone({
    required String teamName,
    required int score,
    required int sets,
    required bool isServing,
    required VoidCallback onTap,
    required bool isRotated,
    required Color color,
  }) {
    // If rotated (Team A/Top), rotate 180 degrees so they can read it from across table? 
    // Or just Keep it upright if it's a mobile app for one person to score.
    // The requirement says "Court should immediately look like a volleyball court".
    // Usually standard mobile scoring apps keep text upright. 
    // Let's keep it upright for accessibility, unless user asked for 2-player mode.
    // User said: "Display centered, top-down volleyball court".
    // "Team A on top or left".
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRotated) ...[
                 // Top Section (Team A)
                 _buildScoreRow(teamName, score, sets, isServing, color),
              ] else ...[
                 // Bottom Section (Team B)
                 _buildScoreRow(teamName, score, sets, isServing, color),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String name, int score, int sets, bool isServing, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Serve Indicator
        if (isServing) 
           const Padding(
             padding: EdgeInsets.only(right: 12),
             child: Icon(Icons.sports_volleyball, color: Colors.yellow, size: 32),
           )
        else
           const SizedBox(width: 44), // Placeholder

        Column(
          children: [
            Text(
              name,
              style: TextStyle(color: color.withOpacity(0.9), fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              "$score",
              style: TextStyle(color: color, fontSize: 80, fontWeight: FontWeight.bold),
            ),
            Text(
              "Sets: $sets",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        
         const SizedBox(width: 44), // Symmetry
      ],
    );
  }
}
