import 'package:flutter/material.dart';
import '../models/table_tennis_match_state.dart';
import 'table_tennis_score_screen.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/player.dart';

class TableTennisSetupScreen extends StatefulWidget {
  const TableTennisSetupScreen({super.key});

  @override
  State<TableTennisSetupScreen> createState() => _TableTennisSetupScreenState();
}

class _TableTennisSetupScreenState extends State<TableTennisSetupScreen> {
  TTMatchType _matchType = TTMatchType.singles;
  
  List<Player> _availablePlayers = [];
  bool _isLoadingPlayers = true;

  Player? _selectedA1;
  Player? _selectedA2;
  Player? _selectedB1;
  Player? _selectedB2;
  
  int _setsToWin = 3; 

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
    
    if (_matchType == TTMatchType.singles) {
      if (_selectedA1 == null) a1 = "PLAYER A";
      if (_selectedB1 == null) b1 = "PLAYER B";
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => TableTennisScoreScreen(
        matchType: _matchType,
        playerA1: a1,
        playerA2: a2,
        playerB1: b1,
        playerB2: b2,
        setsToWin: _setsToWin,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isDoubles = _matchType == TTMatchType.doubles;
    
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
               const Text("Table Tennis Setup",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                      SegmentedButton<TTMatchType>(
                        segments: const [
                          ButtonSegment(value: TTMatchType.singles, label: Text("SINGLES"), icon: Icon(Icons.person)),
                          ButtonSegment(value: TTMatchType.doubles, label: Text("DOUBLES"), icon: Icon(Icons.group)),
                        ],
                        selected: {_matchType},
                        onSelectionChanged: (Set<TTMatchType> newSelection) {
                          setState(() {
                            _matchType = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.green; 
                            }
                            return Colors.grey[200]!; 
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
                  // Team A
                  Text(isDoubles ? "TEAM A (Top)" : "PLAYER A (Top)", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    isDoubles ? "Player 1 Name" : "Player Name", 
                    _selectedA1, 
                    (Player? newValue) => setState(() => _selectedA1 = newValue),
                    excludedPlayers: [_selectedA2, _selectedB1, _selectedB2],
                  ),
                  if (isDoubles) ...[
                    const SizedBox(height: 8),
                    _buildPlayerDropdown(
                      "Player 2 Name", 
                      _selectedA2, 
                      (Player? newValue) => setState(() => _selectedA2 = newValue),
                      excludedPlayers: [_selectedA1, _selectedB1, _selectedB2],
                    ),
                  ],
                   
                   const SizedBox(height: 24),
                   
                   // Team B
                  Text(isDoubles ? "TEAM B (Bottom)" : "PLAYER B (Bottom)", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    isDoubles ? "Player 1 Name" : "Player Name", 
                    _selectedB1, 
                    (Player? newValue) => setState(() => _selectedB1 = newValue),
                    excludedPlayers: [_selectedA1, _selectedA2, _selectedB2],
                  ),
                  if (isDoubles) ...[
                    const SizedBox(height: 8),
                    _buildPlayerDropdown(
                      "Player 2 Name", 
                      _selectedB2, 
                      (Player? newValue) => setState(() => _selectedB2 = newValue),
                      excludedPlayers: [_selectedA1, _selectedA2, _selectedB1],
                    ),
                  ],
              ],
               
               const SizedBox(height: 32),
               const Text("SETS TO WIN MATCH", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               SegmentedButton<int>(
                 segments: const [
                   ButtonSegment(value: 2, label: Text("Best of 3")),
                   ButtonSegment(value: 3, label: Text("Best of 5")),
                   ButtonSegment(value: 4, label: Text("Best of 7")),
                 ],
                 selected: {_setsToWin},
                 onSelectionChanged: (s) => setState(() => _setsToWin = s.first),
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
               SizedBox(
                 height: 56,
                 child: ElevatedButton(
                   onPressed: (_availablePlayers.isNotEmpty) ? _startGame : null,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                   child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(
    String hint, 
    Player? selectedPlayer, 
    ValueChanged<Player?> onChanged, {
    List<Player?> excludedPlayers = const [],
  }) {
    // Filter available players
    final available = _availablePlayers.where((p) {
      if (excludedPlayers.any((excluded) => excluded?.id == p.id)) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Player>(
          value: selectedPlayer,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          isExpanded: true,
          items: available.map((Player player) {
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
