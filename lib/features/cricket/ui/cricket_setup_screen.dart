import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cricket_score_screen.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../../core/models/player.dart';
import '../../tournament/models/team.dart';

class CricketSetupScreen extends ConsumerStatefulWidget {
  final String? initialTeamA;
  final String? initialTeamB;
  final List<String>? initialSquadA;
  final List<String>? initialSquadB;
  final String? tournamentId;
  final String? matchId;

  const CricketSetupScreen({
    super.key,
    this.initialTeamA,
    this.initialTeamB,
    this.initialSquadA,
    this.initialSquadB,
    this.tournamentId,
    this.matchId,
  });

  @override
  ConsumerState<CricketSetupScreen> createState() => _CricketSetupScreenState();
}

class _CricketSetupScreenState extends ConsumerState<CricketSetupScreen> {
  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();
  int _overs = 10;

  // Squads
  final List<String> _squadA = [];
  final List<String> _squadB = [];

  // Available Players & Teams
  List<Player> _availablePlayers = [];
  List<Team> _availableTeams = [];
  bool _isLoading = true;

  // Selected Team Objects
  Team? _selectedTeamA;
  Team? _selectedTeamB;

  // Selection State for Player Dropdown
  Player? _selectedPlayerA;
  Player? _selectedPlayerB;

  String _battingFirst = 'A'; // 'A' or 'B'

  @override
  void initState() {
    super.initState();
    if (widget.initialTeamA != null) {
      _teamAController.text = widget.initialTeamA!;
    }
    if (widget.initialTeamB != null) {
      _teamBController.text = widget.initialTeamB!;
    }
    if (widget.initialSquadA != null) {
      _squadA.addAll(widget.initialSquadA!);
    }
    if (widget.initialSquadB != null) {
      _squadB.addAll(widget.initialSquadB!);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final playersFuture = ref.read(playerRepositoryProvider).getPlayers();
      final teamsFuture = ref.read(teamRepositoryProvider).getTeams();
      final results = await Future.wait([playersFuture, teamsFuture]);

      if (mounted) {
        final players = results[0] as List<Player>;
        final teams = results[1] as List<Team>;

        Team? matchedTeamA;
        Team? matchedTeamB;
        if (widget.initialTeamA != null) {
          matchedTeamA = teams.cast<Team?>().firstWhere(
            (t) => t?.name.toLowerCase() == widget.initialTeamA!.toLowerCase(),
            orElse: () => null,
          );
        }
        if (widget.initialTeamB != null) {
          matchedTeamB = teams.cast<Team?>().firstWhere(
            (t) => t?.name.toLowerCase() == widget.initialTeamB!.toLowerCase(),
            orElse: () => null,
          );
        }

        setState(() {
          _availablePlayers = players;
          _availableTeams = teams;
          _selectedTeamA = matchedTeamA;
          _selectedTeamB = matchedTeamB;
          _isLoading = false;
        });

        // If squads were empty and teams matched, import rosters
        if (_squadA.isEmpty && matchedTeamA != null) {
          _importTeamRoster(matchedTeamA, _squadA, showToast: false);
        }
        if (_squadB.isEmpty && matchedTeamB != null) {
          _importTeamRoster(matchedTeamB, _squadB, showToast: false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _importTeamRoster(Team team, List<String> squad, {bool showToast = true}) {
    final playerIds = team.playerIds.toSet();
    final namesToAdd = <String>[];

    final knownPlayerIds = _availablePlayers.map((p) => p.id?.toString()).whereType<String>().toSet();

    for (final p in _availablePlayers) {
      if (playerIds.contains(p.id?.toString()) || playerIds.contains(p.name)) {
        if (!squad.contains(p.name) && !namesToAdd.contains(p.name)) {
          namesToAdd.add(p.name);
        }
      }
    }

    // Also support raw string player names saved in playerIds (that are not known player IDs)
    for (final idOrName in team.playerIds) {
      if (!knownPlayerIds.contains(idOrName) &&
          !squad.contains(idOrName) &&
          !namesToAdd.contains(idOrName)) {
        namesToAdd.add(idOrName);
      }
    }

    if (namesToAdd.isNotEmpty) {
      setState(() {
        squad.addAll(namesToAdd);
      });
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Loaded ${namesToAdd.length} player(s) from ${team.name}"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${team.name} has no players registered yet."),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _addPlayerToSquad(List<String> squad, Player? player) {
    if (player != null) {
      if (!squad.contains(player.name)) {
        setState(() {
          squad.add(player.name);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${player.name} is already in the squad!")),
        );
      }
    }
  }

  void _showAddCustomPlayerDialog(List<String> squad) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Player to Squad'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Player Name',
            hintText: 'e.g. Rahul Sharma',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                if (!squad.contains(name)) {
                  setState(() => squad.add(name));
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$name is already in the squad!")),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removePlayer(List<String> squad, int index) {
    setState(() {
      squad.removeAt(index);
    });
  }

  void _startMatch() {
    String teamA = _teamAController.text.trim();
    String teamB = _teamBController.text.trim();
    if (teamA.isEmpty) teamA = _selectedTeamA?.name ?? "Team A";
    if (teamB.isEmpty) teamB = _selectedTeamB?.name ?? "Team B";

    if (_squadA.isEmpty || _squadB.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one player to each squad.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CricketScoreScreen(
          teamA: teamA,
          teamB: teamB,
          squadA: _squadA,
          squadB: _squadB,
          overs: _overs,
          battingFirst: _battingFirst == 'A' ? teamA : teamB,
          tournamentId: widget.tournamentId,
          matchId: widget.matchId,
        ),
      ),
    );
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
          padding: NavigationPadding.listInsets(context, horizontal: 24, top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Cricket Setup",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_availablePlayers.isEmpty && _availableTeams.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Tip: You can select saved teams, pick registered players, or type player names directly.",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Team A
                _buildTeamSection(
                  title: "TEAM A",
                  side: 'A',
                  teamNameCtrl: _teamAController,
                  selectedTeam: _selectedTeamA,
                  onTeamChanged: (team) {
                    setState(() {
                      _selectedTeamA = team;
                      if (team != null) {
                        _teamAController.text = team.name;
                        _squadA.clear();
                        _importTeamRoster(team, _squadA, showToast: true);
                      }
                    });
                  },
                  squad: _squadA,
                  selectedPlayer: _selectedPlayerA,
                  onPlayerChanged: (p) => setState(() => _selectedPlayerA = p),
                  onAddPlayer: () => _addPlayerToSquad(_squadA, _selectedPlayerA),
                  onAddCustomPlayer: () => _showAddCustomPlayerDialog(_squadA),
                  otherSelectedTeam: _selectedTeamB,
                ),

                const SizedBox(height: 24),

                // Team B
                _buildTeamSection(
                  title: "TEAM B",
                  side: 'B',
                  teamNameCtrl: _teamBController,
                  selectedTeam: _selectedTeamB,
                  onTeamChanged: (team) {
                    setState(() {
                      _selectedTeamB = team;
                      if (team != null) {
                        _teamBController.text = team.name;
                        _squadB.clear();
                        _importTeamRoster(team, _squadB, showToast: true);
                      }
                    });
                  },
                  squad: _squadB,
                  selectedPlayer: _selectedPlayerB,
                  onPlayerChanged: (p) => setState(() => _selectedPlayerB = p),
                  onAddPlayer: () => _addPlayerToSquad(_squadB, _selectedPlayerB),
                  onAddCustomPlayer: () => _showAddCustomPlayerDialog(_squadB),
                  otherSelectedTeam: _selectedTeamA,
                ),

                const SizedBox(height: 24),

                // Toss / Batting Choice
                const Text("Who Bats First?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'A',
                      label: Text(_teamAController.text.trim().isNotEmpty ? _teamAController.text.trim() : 'Team A'),
                    ),
                    ButtonSegment(
                      value: 'B',
                      label: Text(_teamBController.text.trim().isNotEmpty ? _teamBController.text.trim() : 'Team B'),
                    ),
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
                          min: 2,
                          max: 50,
                          divisions: 48,
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
                ),
              ],
              const BottomNavSpacing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String title,
    required String side,
    required TextEditingController teamNameCtrl,
    required Team? selectedTeam,
    required ValueChanged<Team?> onTeamChanged,
    required List<String> squad,
    required Player? selectedPlayer,
    required ValueChanged<Player?> onPlayerChanged,
    required VoidCallback onAddPlayer,
    required VoidCallback onAddCustomPlayer,
    Team? otherSelectedTeam,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (selectedTeam != null)
                  TextButton.icon(
                    icon: const Icon(Icons.group_outlined, size: 14),
                    label: const Text('Re-import Roster', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _importTeamRoster(selectedTeam, squad, showToast: true),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Select Team Dropdown (if teams exist)
            if (_availableTeams.isNotEmpty) ...[
              DropdownButtonFormField<Team?>(
                isExpanded: true,
                value: selectedTeam,
                decoration: const InputDecoration(
                  labelText: 'Select Registered Team',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.groups_outlined, color: Colors.green, size: 20),
                ),
                items: [
                  const DropdownMenuItem<Team?>(
                    value: null,
                    child: Text('Custom Team (Enter Name)'),
                  ),
                  ..._availableTeams.map((team) {
                    final isOther = otherSelectedTeam?.id == team.id;
                    return DropdownMenuItem<Team?>(
                      value: team,
                      enabled: !isOther,
                      child: Text(
                        '${team.name} (${team.playerIds.length} players${team.seed != null ? ' • #${team.seed}' : ''})${isOther ? ' (Selected)' : ''}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOther ? Colors.grey : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onTeamChanged,
              ),
              const SizedBox(height: 10),
            ],

            TextField(
              controller: teamNameCtrl,
              decoration: InputDecoration(
                labelText: "Team Name",
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: selectedTeam != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear team selection',
                        onPressed: () => onTeamChanged(null),
                      )
                    : null,
              ),
              onChanged: (_) {
                // If user customizes name away from team name, keep text
                setState(() {});
              },
            ),

            if (selectedTeam != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Linked to team "${selectedTeam.name}" • ${selectedTeam.playerIds.length} roster players',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Squad Members (${squad.length}):", style: const TextStyle(fontWeight: FontWeight.bold)),
                if (squad.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => squad.clear()),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Clear Squad', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
            if (squad.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  selectedTeam != null
                      ? 'No players loaded yet. Tap "Re-import Roster" or add players below.'
                      : 'No players in squad. Select a team above or add players below.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: squad.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removePlayer(squad, entry.key),
                    backgroundColor: Colors.green[50],
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Player>(
                        value: selectedPlayer,
                        hint: Text(_availablePlayers.isEmpty ? "No saved players" : "Select Player"),
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
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                  tooltip: 'Add Selected Player',
                  onPressed: onAddPlayer,
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF1B5E20), size: 26),
                  tooltip: 'Add Guest / Custom Player',
                  onPressed: onAddCustomPlayer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
