import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../logic/fixture_generator.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/player.dart' as db_player;
import 'tournament_dashboard_screen.dart';

class SeedAssignmentScreen extends StatefulWidget {
  final String tournamentName;
  final String sport;
  final TournamentFormat format;
  final bool seeded;
  final List<Team> initialTeams;

  const SeedAssignmentScreen({
    super.key,
    required this.tournamentName,
    required this.sport,
    required this.format,
    required this.seeded,
    required this.initialTeams,
  });

  @override
  State<SeedAssignmentScreen> createState() => _SeedAssignmentScreenState();
}

class _SeedAssignmentScreenState extends State<SeedAssignmentScreen> {
  late List<Team> _teams;
  List<db_player.Player> _availablePlayers = [];
  bool _isLoadingPlayers = true;
  bool _usePlayers = false; // Toggle state

  List<Team> _availableTeams = [];

  @override
  void initState() {
    super.initState();
    _teams = List.from(widget.initialTeams);
    _loadData();
  }

  Future<void> _loadData() async {
    final players = await DatabaseHelper.instance.getPlayers();
    final teams = await DatabaseHelper.instance.getTeams();
    setState(() {
      _availablePlayers = players;
      _availableTeams = teams;
      _isLoadingPlayers = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.seeded ? 'Assign Seeds' : 'Review Teams'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createTournament,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildModeToggle(),
          ),
          Expanded(
            child: widget.seeded
                ? ReorderableListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    header: const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'DRAG TO REORDER SEEDS (Top is Seed 1)',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    children: [
                      for (int i = 0; i < _teams.length; i++)
                        Card(
                          key: ValueKey(_teams[i].id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: Text('${i + 1}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                            title: _buildNameInput(i),
                            trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                        ),
                    ],
                    onReorder: (oldIndex, newIndex) {
                       setState(() {
                         if (oldIndex < newIndex) {
                           newIndex -= 1;
                         }
                         final Team item = _teams.removeAt(oldIndex);
                         _teams.insert(newIndex, item);
                         
                         // Re-assign seeds
                         for(int j=0; j<_teams.length; j++) {
                           _teams[j] = _teams[j].copyWith(seed: j + 1);
                         }
                       });
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.green),
                          title: _buildNameInput(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTournament,
        label: const Text('Start Tournament', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.play_arrow),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildListItem(int index) {
     return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.person, color: Colors.green),
          title: _buildNameInput(index),
        ),
      );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _usePlayers = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_usePlayers ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Select Team',
                  style: TextStyle(
                    color: !_usePlayers ? Colors.white : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _usePlayers = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _usePlayers ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Select Players',
                  style: TextStyle(
                    color: _usePlayers ? Colors.white : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(int index) {
    if (_usePlayers) {
      // Find current selected player if name matches
      db_player.Player? selected;
      if (_availablePlayers.isNotEmpty) {
        try {
          selected = _availablePlayers.firstWhere((p) => p.name == _teams[index].name);
        } catch (e) {
          selected = null;
        }
      }

      if (_availablePlayers.isEmpty) {
         return Container(
           padding: const EdgeInsets.symmetric(vertical: 12),
           child: const Text("No players found in database", style: TextStyle(color: Colors.red)),
         );
      }

      return DropdownButtonHideUnderline(
        child: DropdownButton<db_player.Player>(
          value: selected,
          hint: const Text('Select a player'),
          isExpanded: true,
          items: _availablePlayers.map((p) {
             return DropdownMenuItem(
               value: p,
               child: Text(p.name),
             );
          }).toList(),
          onChanged: (val) {
             if (val != null) {
               setState(() {
                 _teams[index] = _teams[index].copyWith(name: val.name);
               });
             }
          },
        ),
      );
    } else {
      // Team Selection Dropdown
      Team? selectedTeam;
      // Try to match by name or ID if possible.
      // Currently `name` is used.
      if (_availableTeams.isNotEmpty) {
         try {
           selectedTeam = _availableTeams.firstWhere((t) => t.name == _teams[index].name);
         } catch (e) {
           selectedTeam = null;
         }
      }
      
      if (_availableTeams.isEmpty) {
        // Fallback to text input if no teams exist
        return TextFormField(
          initialValue: _teams[index].name,
          decoration: const InputDecoration(
            hintText: 'Enter Team Name (or create teams first)',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            _teams[index] = _teams[index].copyWith(name: val);
          },
        );
      }
      
      return DropdownButtonHideUnderline(
        child: DropdownButton<Team>(
          value: selectedTeam,
          hint: const Text('Select a Team'),
          isExpanded: true,
          items: _availableTeams.map((t) {
             return DropdownMenuItem(
               value: t,
               child: Text(t.name),
             );
          }).toList(),
          onChanged: (val) {
             if (val != null) {
               setState(() {
                 // Copy name, ID and playerIds
                 _teams[index] = _teams[index].copyWith(
                   id: val.id,
                   name: val.name,
                   playerIds: val.playerIds,
                 );
               });
             }
          },
        ),
      );
    }
  }

  Future<void> _createTournament() async {
    // Generate Fixtures
    var matches = <dynamic>[]; 
    // Fix dynamic type issue
    
    if (widget.format == TournamentFormat.roundRobin) {
      matches = FixtureGenerator.generateRoundRobin(_teams);
    } else if (widget.format == TournamentFormat.singleElimination) {
      matches = FixtureGenerator.generateSingleElimination(_teams, widget.seeded);
    } else {
      matches = FixtureGenerator.generateDoubleElimination(_teams, widget.seeded);
    }

    final tournament = Tournament(
      id: DateTime.now().toIso8601String(),
      name: widget.tournamentName,
      sportType: widget.sport,
      format: widget.format,
      participants: _teams,
      matches: matches.cast<TournamentMatch>(),
      status: TournamentStatus.ongoing,
      seeded: widget.seeded,
    );
    
    // Save to DB
    await DatabaseHelper.instance.insertTournament(tournament);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDashboardScreen(tournament: tournament),
      ),
      (route) => false,
    );
  }
}
