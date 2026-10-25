import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../../core/providers/repository_providers.dart';
import '../../tournament/models/team.dart';
import 'volleyball_score_screen.dart';

class VolleyballSetupScreen extends ConsumerStatefulWidget {
  final String? initialTeamA;
  final String? initialTeamB;
  final String? tournamentId;
  final String? matchId;

  const VolleyballSetupScreen({
    super.key,
    this.initialTeamA,
    this.initialTeamB,
    this.tournamentId,
    this.matchId,
  });

  @override
  ConsumerState<VolleyballSetupScreen> createState() => _VolleyballSetupScreenState();
}

class _VolleyballSetupScreenState extends ConsumerState<VolleyballSetupScreen> {
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();

  List<Team> _availableTeams = [];
  bool _isLoading = true;

  Team? _selectedTeamA;
  Team? _selectedTeamB;

  int _setsToWin = 3;
  int _pointsPerSet = 25;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeamA != null) {
      _teamAController.text = widget.initialTeamA!;
    }
    if (widget.initialTeamB != null) {
      _teamBController.text = widget.initialTeamB!;
    }
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await ref.read(teamRepositoryProvider).getTeams();
      if (mounted) {
        Team? foundA;
        Team? foundB;
        if (widget.initialTeamA != null) {
          foundA = teams.cast<Team?>().firstWhere(
            (t) => t?.name.toLowerCase() == widget.initialTeamA!.toLowerCase(),
            orElse: () => null,
          );
        }
        if (widget.initialTeamB != null) {
          foundB = teams.cast<Team?>().firstWhere(
            (t) => t?.name.toLowerCase() == widget.initialTeamB!.toLowerCase(),
            orElse: () => null,
          );
        }

        setState(() {
          _availableTeams = teams;
          _selectedTeamA = foundA;
          _selectedTeamB = foundB;
          _isLoading = false;
        });
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

  void _startGame() {
    String teamA = _teamAController.text.trim();
    String teamB = _teamBController.text.trim();

    if (teamA.isEmpty) teamA = _selectedTeamA?.name ?? "Team A";
    if (teamB.isEmpty) teamB = _selectedTeamB?.name ?? "Team B";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VolleyballScoreScreen(
          teamAName: teamA,
          teamBName: teamB,
          setsToWin: _setsToWin,
          pointsPerSet: _pointsPerSet,
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
                "Volleyball Setup",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Team A Card
                _buildTeamCard(
                  title: "TEAM A (Top Side)",
                  controller: _teamAController,
                  selectedTeam: _selectedTeamA,
                  onTeamChanged: (team) {
                    setState(() {
                      _selectedTeamA = team;
                      if (team != null) {
                        _teamAController.text = team.name;
                      }
                    });
                  },
                  otherTeam: _selectedTeamB,
                ),

                const SizedBox(height: 20),

                // Team B Card
                _buildTeamCard(
                  title: "TEAM B (Bottom Side)",
                  controller: _teamBController,
                  selectedTeam: _selectedTeamB,
                  onTeamChanged: (team) {
                    setState(() {
                      _selectedTeamB = team;
                      if (team != null) {
                        _teamBController.text = team.name;
                      }
                    });
                  },
                  otherTeam: _selectedTeamA,
                ),

                const SizedBox(height: 32),
                const Text("POINTS PER SET", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 15, label: Text("15 Points")),
                    ButtonSegment(value: 25, label: Text("25 Points")),
                  ],
                  selected: {_pointsPerSet},
                  onSelectionChanged: (s) => setState(() => _pointsPerSet = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.green;
                      return Colors.grey[200]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return Colors.black87;
                    }),
                  ),
                ),

                const SizedBox(height: 24),
                const Text("SETS TO WIN MATCH", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text("Best of 1")),
                    ButtonSegment(value: 2, label: Text("Best of 3")),
                    ButtonSegment(value: 3, label: Text("Best of 5")),
                  ],
                  selected: {_setsToWin},
                  onSelectionChanged: (s) => setState(() => _setsToWin = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.green;
                      return Colors.grey[200]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return Colors.black87;
                    }),
                  ),
                ),

                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
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

  Widget _buildTeamCard({
    required String title,
    required TextEditingController controller,
    required Team? selectedTeam,
    required ValueChanged<Team?> onTeamChanged,
    Team? otherTeam,
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
              children: [
                const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                    final isOther = otherTeam?.id == team.id;
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
              controller: controller,
              textCapitalization: TextCapitalization.words,
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
              onChanged: (_) => setState(() {}),
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
                        'Linked to team "${selectedTeam.name}" • ${selectedTeam.playerIds.length} players',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
