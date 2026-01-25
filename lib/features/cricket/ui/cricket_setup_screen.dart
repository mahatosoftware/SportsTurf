import 'package:flutter/material.dart';
import 'cricket_score_screen.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/player.dart';

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
  
  // Available Players
  List<Player> _availablePlayers = [];
  bool _isLoadingPlayers = true;
  
  // Selection State
  Player? _selectedPlayerA;
  Player? _selectedPlayerB;
  
  String _battingFirst = 'A'; // 'A' or 'B'

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await DatabaseHelper.instance.getPlayers();
    setState(() {
      _availablePlayers = players;
      _isLoadingPlayers = false; 
    });
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }
  
  void _addPlayerToSquad(List<String> squad, Player? player) {
    if (player != null) {
      if (!squad.contains(player.name)) {
        setState(() {
          squad.add(player.name);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${player.name} is already in the squad!"))
        );
      }
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

    if (_squadA.isEmpty || _squadB.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one player to each squad."))
        );
        return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => CricketScoreScreen(
        teamA: teamA,
        teamB: teamB,
        squadA: _squadA,
        squadB: _squadB,
        overs: _overs,
        battingFirst: _battingFirst == 'A' ? teamA : teamB,
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
              
              if (_isLoadingPlayers)
                 const Center(child: CircularProgressIndicator())
              else if (_availablePlayers.isEmpty)
                const Card(
                  color: Colors.orangeAccent,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No players found. Please add players from the Home Screen > Players.", textAlign: TextAlign.center),
                  ),
                )
              else ...[
                   // Team A
                   _buildTeamSection(
                     "TEAM A", 
                     _teamAController, 
                     _squadA, 
                     _selectedPlayerA, 
                     (p) => setState(() => _selectedPlayerA = p),
                     () => _addPlayerToSquad(_squadA, _selectedPlayerA)
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Team B
                   _buildTeamSection(
                     "TEAM B", 
                     _teamBController, 
                     _squadB, 
                     _selectedPlayerB, 
                     (p) => setState(() => _selectedPlayerB = p),
                     () => _addPlayerToSquad(_squadB, _selectedPlayerB)
                   ),

                   const SizedBox(height: 24),
                   
                   // Toss / Batting Choice
                   const Text("Who Bats First?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                   const SizedBox(height: 8),
                   SegmentedButton<String>(
                     segments: const [
                       ButtonSegment(value: 'A', label: Text('Team A')),
                       ButtonSegment(value: 'B', label: Text('Team B')),
                     ],
                     selected: {_battingFirst},
                     onSelectionChanged: (Set<String> newSelection) {
                       setState(() {
                         _battingFirst = newSelection.first;
                       });
                     },
                     style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.green;
                          }
                          return Colors.grey[200]!;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.black;
                        }),
                     ),
                   ),
              ],
              
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
                  onPressed: (_availablePlayers.isNotEmpty) ? _startMatch : null,
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
  
  Widget _buildTeamSection(
    String title, 
    TextEditingController teamNameCtrl, 
    List<String> squad,
    Player? selectedPlayer,
    ValueChanged<Player?> onPlayerChanged,
    VoidCallback onAddPlayer
  ) {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Player>(
                        value: selectedPlayer,
                        hint: const Text("Select Player"),
                        isExpanded: true,
                        items: _availablePlayers.map((Player player) {
                          return DropdownMenuItem<Player>(
                            value: player,
                            child: Text(player.name),
                          );
                        }).toList(),
                        onChanged: onPlayerChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: onAddPlayer,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
