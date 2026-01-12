import 'package:flutter/material.dart';
import '../models/badminton_match_state.dart';
import 'badminton_score_screen.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/player.dart';

class BadmintonSetupScreen extends StatefulWidget {
  const BadmintonSetupScreen({super.key});

  @override
  State<BadmintonSetupScreen> createState() => _BadmintonSetupScreenState();
}

class _BadmintonSetupScreenState extends State<BadmintonSetupScreen> {
  BadmintonMatchType _matchType = BadmintonMatchType.singles;
  
  List<Player> _availablePlayers = [];
  bool _isLoadingPlayers = true;

  Player? _selectedA1;
  Player? _selectedA2;
  Player? _selectedB1;
  Player? _selectedB2;
  
  int _pointsPerGame = 21;
  int _setsToWin = 2; // Default to 2 sets to win (Best of 3)

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await DatabaseHelper.instance.getPlayers();
    setState(() {
      _availablePlayers = players;
      _isLoadingPlayers = false; // Add default selections if needed
    });
  }

  void _startGame() {
    String a1 = _selectedA1?.name.trim().toUpperCase() ?? "PLAYER A";
    String a2 = _selectedA2?.name.trim().toUpperCase() ?? "";
    String b1 = _selectedB1?.name.trim().toUpperCase() ?? "PLAYER B";
    String b2 = _selectedB2?.name.trim().toUpperCase() ?? "";

    if (_matchType == BadmintonMatchType.singles) {
      if (_selectedA1 == null) a1 = "PLAYER A";
      if (_selectedB1 == null) b1 = "PLAYER B";
    } else {
       // Doubles validation references could be added here if stricter rules are needed
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadmintonScoreScreen(
          matchType: _matchType,
          playerA1: a1,
          playerA2: a2,
          playerB1: b1,
          playerB2: b2,
          setsToWin: _setsToWin,
          pointsPerGame: _pointsPerGame,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDoubles = _matchType == BadmintonMatchType.doubles;

    return Scaffold(
      backgroundColor: Colors.grey[100], 
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
            const Text(
              "Badminton Setup",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Match Type
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("MATCH TYPE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<BadmintonMatchType>(
                      segments: const [
                        ButtonSegment(value: BadmintonMatchType.singles, label: Text("SINGLES"), icon: Icon(Icons.person)),
                        ButtonSegment(value: BadmintonMatchType.doubles, label: Text("DOUBLES"), icon: Icon(Icons.group)),
                      ],
                      selected: {_matchType},
                      onSelectionChanged: (Set<BadmintonMatchType> newSelection) {
                        setState(() { _matchType = newSelection.first; });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) return Colors.green;
                          return Colors.grey[200]!; 
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                           if (states.contains(MaterialState.selected)) return Colors.white;
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
                // Team A
                Text(isDoubles ? "TEAM A" : "PLAYER A", 
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildPlayerDropdown(
                  "Player 1", 
                  _selectedA1, 
                  (Player? newValue) => setState(() => _selectedA1 = newValue),
                  Icons.person
                ),
                if (isDoubles) ...[
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    "Player 2", 
                    _selectedA2, 
                    (Player? newValue) => setState(() => _selectedA2 = newValue),
                    Icons.person_outline
                  ),
                ],

                const SizedBox(height: 24),

                // Team B
                Text(isDoubles ? "TEAM B" : "PLAYER B", 
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                 _buildPlayerDropdown(
                  "Player 1", 
                  _selectedB1, 
                  (Player? newValue) => setState(() => _selectedB1 = newValue),
                  Icons.person
                ),
                 if (isDoubles) ...[
                   const SizedBox(height: 8),
                   _buildPlayerDropdown(
                    "Player 2", 
                    _selectedB2, 
                    (Player? newValue) => setState(() => _selectedB2 = newValue),
                    Icons.person_outline
                  ),
                 ],
            ],
 
             const SizedBox(height: 32),
             
             // Points Configuration
             const Text("POINTS PER GAME", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             SegmentedButton<int>(
               segments: const [
                 ButtonSegment(value: 11, label: Text("11"), icon: Icon(Icons.flash_on)),
                 ButtonSegment(value: 15, label: Text("15")),
                 ButtonSegment(value: 21, label: Text("21")),
                 ButtonSegment(value: 31, label: Text("31")),
               ],
               selected: {_pointsPerGame},
               onSelectionChanged: (Set<int> newSelection) {
                 setState(() { _pointsPerGame = newSelection.first; });
               },
               style: ButtonStyle(
                 backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                   if (states.contains(MaterialState.selected)) return Colors.green;
                   return Colors.grey[200]!; 
                 }),
                 foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) return Colors.white;
                   return Colors.black87;
                 }),
               ),
             ),
             
             const SizedBox(height: 24),

             // Sets Configuration
             const Text("SETS TO WIN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             SegmentedButton<int>(
               segments: const [
                 ButtonSegment(value: 1, label: Text("Best of 1")),
                 ButtonSegment(value: 2, label: Text("Best of 3")),
                 ButtonSegment(value: 3, label: Text("Best of 5")),
               ],
               selected: {_setsToWin},
               onSelectionChanged: (Set<int> newSelection) {
                 setState(() { _setsToWin = newSelection.first; });
               },
               style: ButtonStyle(
                 backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                   if (states.contains(MaterialState.selected)) return Colors.green;
                   return Colors.grey[200]!; 
                 }),
                 foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) return Colors.white;
                   return Colors.black87;
                 }),
               ),
             ),

            const SizedBox(height: 48),

            // Start
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
                child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
