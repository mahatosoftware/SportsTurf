import 'package:flutter/material.dart';
import '../models/tennis_match_state.dart' hide Player;
import 'tennis_score_screen.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/player.dart';

class TennisSetupScreen extends StatefulWidget {
  const TennisSetupScreen({super.key});

  @override
  State<TennisSetupScreen> createState() => _TennisSetupScreenState();
}

class _TennisSetupScreenState extends State<TennisSetupScreen> {
  MatchType _matchType = MatchType.singles;
  
  List<Player> _availablePlayers = [];
  bool _isLoadingPlayers = true;

  Player? _selectedA1;
  Player? _selectedA2;
  Player? _selectedB1;
  Player? _selectedB2;

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

  void _startGame() {
    String a1 = _selectedA1?.name.trim().toUpperCase() ?? "PLAYER A";
    String a2 = _selectedA2?.name.trim().toUpperCase() ?? "";
    String b1 = _selectedB1?.name.trim().toUpperCase() ?? "PLAYER B";
    String b2 = _selectedB2?.name.trim().toUpperCase() ?? "";

    if (_matchType == MatchType.singles) {
      if (_selectedA1 == null) a1 = "PLAYER A";
      if (_selectedB1 == null) b1 = "PLAYER B";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TennisScoreScreen(
          matchType: _matchType,
          playerA1: a1,
          playerA2: a2,
          playerB1: b1,
          playerB2: b2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDoubles = _matchType == MatchType.doubles;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Heading
              const Text(
                "Select Players",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // 1. Type Selection Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("MATCH TYPE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SegmentedButton<MatchType>(
                        segments: const [
                          ButtonSegment(
                            value: MatchType.singles,
                            label: Text("SINGLES"),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: MatchType.doubles,
                            label: Text("DOUBLES"),
                            icon: Icon(Icons.group),
                          ),
                        ],
                        selected: {_matchType},
                        onSelectionChanged: (Set<MatchType> newSelection) {
                          setState(() {
                            _matchType = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.green; // Green for selected
                            }
                            return Colors.grey[200]!; // Light grey for unselected
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                             if (states.contains(MaterialState.selected)) {
                               return Colors.white;
                             }
                            return Colors.black87;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  // 2. Team A Setup
                  Text(isDoubles ? "TEAM A (Top Court)" : "PLAYER A (Top Court)", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    isDoubles ? "Player 1 Name" : "Player Name", 
                    _selectedA1, 
                    (Player? newValue) => setState(() => _selectedA1 = newValue),
                    Icons.person
                  ),
                  if (isDoubles) ...[
                    const SizedBox(height: 8),
                    _buildPlayerDropdown(
                      "Player 2 Name", 
                      _selectedA2, 
                      (Player? newValue) => setState(() => _selectedA2 = newValue),
                      Icons.person_outline
                    ),
                  ],
      
                  const SizedBox(height: 24),
      
                  // 3. Team B Setup
                  Text(isDoubles ? "TEAM B (Bottom Court)" : "PLAYER B (Bottom Court)", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    isDoubles ? "Player 1 Name" : "Player Name", 
                    _selectedB1, 
                    (Player? newValue) => setState(() => _selectedB1 = newValue),
                    Icons.person
                  ),
                  if (isDoubles) ...[
                    const SizedBox(height: 8),
                    _buildPlayerDropdown(
                      "Player 2 Name", 
                      _selectedB2, 
                      (Player? newValue) => setState(() => _selectedB2 = newValue),
                      Icons.person_outline
                    ),
                  ],
              ],
  
              const SizedBox(height: 48),
  
              // 4. Start Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_availablePlayers.isNotEmpty) ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text(
                    "START MATCH",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(
    String hint, 
    Player? selectedPlayer, 
    ValueChanged<Player?> onChanged, 
    IconData icon
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Player>(
          value: selectedPlayer,
          hint: Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 8),
              Text(hint, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          isExpanded: true,
          items: _availablePlayers.map((Player player) {
            return DropdownMenuItem<Player>(
              value: player,
              child: Text(player.name),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
