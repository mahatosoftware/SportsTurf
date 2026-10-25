import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tennis_match_state.dart' hide Player;
import 'tennis_score_screen.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../../core/models/player.dart';
import '../../tournament/models/team.dart';

class TennisSetupScreen extends ConsumerStatefulWidget {
  const TennisSetupScreen({super.key});

  @override
  ConsumerState<TennisSetupScreen> createState() => _TennisSetupScreenState();
}

class _TennisSetupScreenState extends ConsumerState<TennisSetupScreen> {
  MatchType _matchType = MatchType.singles;
  
  List<Player> _availablePlayers = [];
  List<Team> _availableTeams = [];
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
    final playersFuture = ref.read(playerRepositoryProvider).getPlayers();
    final teamsFuture = ref.read(teamRepositoryProvider).getTeams();
    final results = await Future.wait([playersFuture, teamsFuture]);
    if (mounted) {
      setState(() {
        _availablePlayers = results[0] as List<Player>;
        _availableTeams = results[1] as List<Team>;
        _isLoadingPlayers = false; 
      });
    }
  }

  void _selectTeamForDoubles(Team team, bool isSideA) {
    final teamPlayerIds = team.playerIds.toSet();
    final matchedPlayers = _availablePlayers.where((p) =>
      teamPlayerIds.contains(p.id?.toString()) || teamPlayerIds.contains(p.name)).toList();
    if (matchedPlayers.isNotEmpty) {
      setState(() {
        if (isSideA) {
          _selectedA1 = matchedPlayers.isNotEmpty ? matchedPlayers[0] : null;
          _selectedA2 = matchedPlayers.length > 1 ? matchedPlayers[1] : null;
        } else {
          _selectedB1 = matchedPlayers.isNotEmpty ? matchedPlayers[0] : null;
          _selectedB2 = matchedPlayers.length > 1 ? matchedPlayers[1] : null;
        }
      });
    }
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
          padding: NavigationPadding.listInsets(context, horizontal: 24, top: 24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isDoubles ? "TEAM A (Top Court)" : "PLAYER A (Top Court)", 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isDoubles && _availableTeams.isNotEmpty)
                      PopupMenuButton<Team>(
                        tooltip: 'Select Team for Team A',
                        child: const Row(
                          children: [
                            Icon(Icons.groups_outlined, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Pick Team', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onSelected: (team) => _selectTeamForDoubles(team, true),
                        itemBuilder: (_) => _availableTeams.map((team) => PopupMenuItem(
                          value: team,
                          child: Text('${team.name} (${team.playerIds.length} players)'),
                        )).toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPlayerDropdown(
                  isDoubles ? "Player 1 Name" : "Player Name", 
                  _selectedA1, 
                  (Player? newValue) => setState(() => _selectedA1 = newValue),
                  Icons.person,
                  excludedPlayers: [_selectedA2, _selectedB1, _selectedB2],
                ),
                if (isDoubles) ...[
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    "Player 2 Name", 
                    _selectedA2, 
                    (Player? newValue) => setState(() => _selectedA2 = newValue),
                    Icons.person_outline,
                    excludedPlayers: [_selectedA1, _selectedB1, _selectedB2],
                  ),
                ],
    
                const SizedBox(height: 24),
    
                // 3. Team B Setup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isDoubles ? "TEAM B (Bottom Court)" : "PLAYER B (Bottom Court)", 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isDoubles && _availableTeams.isNotEmpty)
                      PopupMenuButton<Team>(
                        tooltip: 'Select Team for Team B',
                        child: const Row(
                          children: [
                            Icon(Icons.groups_outlined, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Pick Team', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onSelected: (team) => _selectTeamForDoubles(team, false),
                        itemBuilder: (_) => _availableTeams.map((team) => PopupMenuItem(
                          value: team,
                          child: Text('${team.name} (${team.playerIds.length} players)'),
                        )).toList(),
                      ),
                  ],
                ),
                 const SizedBox(height: 8),
                _buildPlayerDropdown(
                  isDoubles ? "Player 1 Name" : "Player Name", 
                  _selectedB1, 
                  (Player? newValue) => setState(() => _selectedB1 = newValue),
                  Icons.person,
                  excludedPlayers: [_selectedA1, _selectedA2, _selectedB2],
                ),
                if (isDoubles) ...[
                  const SizedBox(height: 8),
                  _buildPlayerDropdown(
                    "Player 2 Name", 
                    _selectedB2, 
                    (Player? newValue) => setState(() => _selectedB2 = newValue),
                    Icons.person_outline,
                    excludedPlayers: [_selectedA1, _selectedA2, _selectedB1],
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
            const BottomNavSpacing(),
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
    IconData icon, {
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
