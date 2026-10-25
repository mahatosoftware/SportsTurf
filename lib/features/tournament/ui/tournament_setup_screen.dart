import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/tournament.dart';
import '../models/team.dart';
import '../logic/fixture_generator.dart';
import '../providers/tournament_providers.dart';
import '../../league/providers/league_providers.dart';
import '../../league/ui/league_setup_screen.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../../core/models/player.dart';
import 'tournament_dashboard_screen.dart';

class TournamentSetupScreen extends ConsumerStatefulWidget {
  final String? initialLeagueId;
  final String? initialLeagueName;

  const TournamentSetupScreen({
    super.key,
    this.initialLeagueId,
    this.initialLeagueName,
  });

  @override
  ConsumerState<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends ConsumerState<TournamentSetupScreen> {
  int _currentStep = 0;

  // Step 1: Basic Information
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _organizerController = TextEditingController();
  final _venueController = TextEditingController();
  String _sport = 'Badminton';
  final List<String> _sports = ['Badminton', 'Tennis', 'Table Tennis', 'Cricket', 'Volleyball'];
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  DateTime? _registrationDeadline;
  bool _isPublic = true;

  // League Association
  String? _selectedLeagueId;
  String? _selectedLeagueName;

  // Step 2: Participants
  bool _isTeamMode = false;
  final List<Team> _participants = [];
  final _participantInputController = TextEditingController();
  bool _seeded = false;
  bool _saveNewParticipantToDb = true;

  // Master Lists & Selection State
  List<Player> _availablePlayers = [];
  List<Team> _availableTeams = [];
  Set<String> _leagueParticipantNames = {};
  bool _isLoadingRoster = true;

  // Step 3: Format & Rules
  TournamentFormat _format = TournamentFormat.singleElimination;
  final _oversController = TextEditingController(text: '10');
  final _setsToWinController = TextEditingController(text: '2');
  final _pointsPerSetController = TextEditingController(text: '21');

  @override
  void initState() {
    super.initState();
    _selectedLeagueId = widget.initialLeagueId;
    _selectedLeagueName = widget.initialLeagueName;
    _registrationDeadline = DateTime.now();
    final user = ref.read(currentUserProvider);
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      _organizerController.text = user.displayName!;
    }
    _loadAvailableRoster();
  }

  Future<void> _loadAvailableRoster() async {
    setState(() => _isLoadingRoster = true);
    try {
      final playerRepo = ref.read(playerRepositoryProvider);
      final teamRepo = ref.read(teamRepositoryProvider);
      final players = await playerRepo.getPlayers();
      final teams = await teamRepo.getTeams();

      Set<String> leagueParticipants = {};
      if (_selectedLeagueId != null && _selectedLeagueId!.isNotEmpty) {
        try {
          final tourneyRepo = ref.read(tournamentRepositoryProvider);
          final leagueTourneys = await tourneyRepo.getTournamentsByLeague(_selectedLeagueId!);
          for (final lt in leagueTourneys) {
            for (final p in lt.participants) {
              leagueParticipants.add(p.name.trim().toLowerCase());
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _availablePlayers = players;
          _availableTeams = teams;
          _leagueParticipantNames = leagueParticipants;
          _isLoadingRoster = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoster = false);
      }
    }
  }

  Future<void> _refreshLeagueParticipants() async {
    if (_selectedLeagueId == null || _selectedLeagueId!.isEmpty) {
      setState(() {
        _leagueParticipantNames = {};
      });
      return;
    }
    try {
      final tourneyRepo = ref.read(tournamentRepositoryProvider);
      final leagueTourneys = await tourneyRepo.getTournamentsByLeague(_selectedLeagueId!);
      final Set<String> leagueParticipants = {};
      for (final lt in leagueTourneys) {
        for (final p in lt.participants) {
          leagueParticipants.add(p.name.trim().toLowerCase());
        }
      }
      if (mounted) {
        setState(() {
          _leagueParticipantNames = leagueParticipants;
        });
      }
    } catch (_) {}
  }

  bool _isPlayerSelected(Player player) {
    final pName = player.name.trim().toLowerCase();
    final pId = player.idString;
    return _participants.any((t) =>
        t.name.trim().toLowerCase() == pName ||
        (t.playerIds.isNotEmpty && t.playerIds.contains(pId)));
  }

  bool _isTeamSelected(Team team) {
    final tName = team.name.trim().toLowerCase();
    return _participants.any((t) =>
        t.name.trim().toLowerCase() == tName ||
        (team.id.isNotEmpty && t.id == team.id));
  }

  void _togglePlayer(Player player) {
    setState(() {
      final isSelected = _isPlayerSelected(player);
      if (isSelected) {
        _participants.removeWhere((t) =>
            t.name.trim().toLowerCase() == player.name.trim().toLowerCase() ||
            (t.playerIds.isNotEmpty && t.playerIds.contains(player.idString)));
      } else {
        _participants.add(Team(
          id: player.id ?? const Uuid().v4(),
          name: player.name,
          seed: _participants.length + 1,
          playerIds: [player.idString],
        ));
      }
      _reindexSeeds();
    });
  }

  void _toggleTeam(Team team) {
    setState(() {
      final isSelected = _isTeamSelected(team);
      if (isSelected) {
        _participants.removeWhere((t) =>
            t.name.trim().toLowerCase() == team.name.trim().toLowerCase() ||
            (team.id.isNotEmpty && t.id == team.id));
      } else {
        _participants.add(Team(
          id: team.id.isNotEmpty ? team.id : const Uuid().v4(),
          name: team.name,
          seed: _participants.length + 1,
          playerIds: team.playerIds,
          logoUrl: team.logoUrl,
          colorHex: team.colorHex,
        ));
      }
      _reindexSeeds();
    });
  }

  void _reindexSeeds() {
    for (int i = 0; i < _participants.length; i++) {
      _participants[i] = _participants[i].copyWith(seed: i + 1);
    }
  }

  void _selectAllAvailable() {
    setState(() {
      if (_isTeamMode) {
        for (final t in _availableTeams) {
          if (!_isTeamSelected(t)) {
            _participants.add(Team(
              id: t.id.isNotEmpty ? t.id : const Uuid().v4(),
              name: t.name,
              seed: _participants.length + 1,
              playerIds: t.playerIds,
              logoUrl: t.logoUrl,
              colorHex: t.colorHex,
            ));
          }
        }
      } else {
        for (final p in _availablePlayers) {
          if (!_isPlayerSelected(p)) {
            _participants.add(Team(
              id: p.id ?? const Uuid().v4(),
              name: p.name,
              seed: _participants.length + 1,
              playerIds: [p.idString],
            ));
          }
        }
      }
      _reindexSeeds();
    });
  }

  void _clearAllParticipants() {
    setState(() {
      _participants.clear();
    });
  }

  Future<void> _createAndAddParticipant(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final exists = _participants.any((p) => p.name.trim().toLowerCase() == clean.toLowerCase());
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant with this name already added to this tournament.')),
        );
      }
      return;
    }

    final newTeam = Team(
      id: const Uuid().v4(),
      name: clean,
      seed: _participants.length + 1,
    );

    setState(() {
      _participants.add(newTeam);
      _participantInputController.clear();
    });

    if (_saveNewParticipantToDb) {
      try {
        if (_isTeamMode) {
          final teamRepo = ref.read(teamRepositoryProvider);
          await teamRepo.saveTeam(newTeam);
          setState(() {
            _availableTeams.add(newTeam);
          });
        } else {
          final playerRepo = ref.read(playerRepositoryProvider);
          final newPlayer = Player(name: clean, seed: _participants.length);
          await playerRepo.savePlayer(newPlayer);
          setState(() {
            _availablePlayers.add(newPlayer);
          });
        }
      } catch (_) {}
    }
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
      _reindexSeeds();
    });
  }

  void _handleModeSwitch(bool teamMode) async {
    if (_participants.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch Participant Mode?'),
          content: Text(
            teamMode
                ? 'Switching to Teams mode will clear currently selected individual players for this tournament.'
                : 'Switching to Individual Players mode will clear currently selected teams for this tournament.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Switch & Clear'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() {
      _isTeamMode = teamMode;
      _participants.clear();
    });
  }

  void _openParticipantSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _ParticipantSelectorSheet(
              isTeamMode: _isTeamMode,
              availablePlayers: _availablePlayers,
              availableTeams: _availableTeams,
              leagueParticipantNames: _leagueParticipantNames,
              isUnderLeague: _selectedLeagueId != null && _selectedLeagueId!.isNotEmpty,
              selectedParticipants: _participants,
              onTogglePlayer: (p) {
                _togglePlayer(p);
                setModalState(() {});
              },
              onToggleTeam: (t) {
                _toggleTeam(t);
                setModalState(() {});
              },
              onSelectAll: () {
                _selectAllAvailable();
                setModalState(() {});
              },
              onClearAll: () {
                _clearAllParticipants();
                setModalState(() {});
              },
              onAddNewParticipant: (name) async {
                await _createAndAddParticipant(name);
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initial = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createAndLaunchTournament() async {
    if (_participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 participants are required to create fixtures.')),
      );
      return;
    }

    // Generate Fixtures based on selected format
    List<dynamic> generatedMatches;
    if (_format == TournamentFormat.roundRobin) {
      generatedMatches = FixtureGenerator.generateRoundRobin(_participants);
    } else if (_format == TournamentFormat.doubleElimination) {
      generatedMatches = FixtureGenerator.generateDoubleElimination(_participants, _seeded);
    } else if (_format == TournamentFormat.friendly) {
      generatedMatches = FixtureGenerator.generateFriendlyMatches(_participants);
    } else {
      // Default to Single Elimination
      generatedMatches = FixtureGenerator.generateSingleElimination(_participants, _seeded);
    }

    final currentUser = ref.read(currentUserProvider);

    if (_selectedLeagueId != null) {
      final leagueRepo = ref.read(leagueRepositoryProvider);
      final league = await leagueRepo.getLeagueById(_selectedLeagueId!);
      final isLeagueAdmin = currentUser != null && league != null && league.isAdmin(currentUser.id);
      final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
      if (!isSuperAdmin && !isLeagueAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission Denied: Only league administrators can host tournaments under this league.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    var creatorId = currentUser?.id;
    if (creatorId == null || creatorId.isEmpty) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final user = authRepo.currentUser;
        if (user != null) {
          creatorId = user.id;
        } else {
          final anon = await authRepo.signInAnonymously();
          creatorId = anon.id;
        }
      } catch (_) {
        creatorId = 'organizer_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final tournamentId = const Uuid().v4();
    final shareCode = Tournament.generateShareCode(tournamentId);

    final tournament = Tournament(
      id: tournamentId,
      creatorId: creatorId,
      shareCode: shareCode,
      name: _nameController.text.trim().isEmpty ? '$_sport Championship' : _nameController.text.trim(),
      sportType: _sport,
      format: _format,
      participants: _participants,
      matches: generatedMatches.cast(),
      status: TournamentStatus.inProgress,
      seeded: _seeded,
      description: _descController.text.trim(),
      organizerName: _organizerController.text.trim().isEmpty ? 'Tournament Organizer' : _organizerController.text.trim(),
      venue: _venueController.text.trim().isEmpty ? 'Main Arena' : _venueController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      isPublic: _isPublic,
      registrationDeadline: _registrationDeadline,
      isTeamTournament: _isTeamMode,
      ruleConfig: {
        'overs': int.tryParse(_oversController.text) ?? 10,
        'setsToWin': int.tryParse(_setsToWinController.text) ?? 2,
        'pointsPerSet': int.tryParse(_pointsPerSetController.text) ?? 21,
      },
      leagueId: _selectedLeagueId,
      leagueName: _selectedLeagueName,
    );

    try {
      await ref.read(tournamentControllerProvider.notifier).createTournament(tournament);

      if (_selectedLeagueId != null && _selectedLeagueId!.isNotEmpty) {
        await ref.read(leagueControllerProvider.notifier).addTournamentToLeague(_selectedLeagueId!, tournamentId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament & Fixtures Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDashboardScreen(tournament: tournament),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating tournament: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament Wizard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter tournament name')),
              );
              return;
            }
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            if (_participants.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add at least 2 participants before proceeding')),
              );
              return;
            }
            setState(() => _currentStep = 2);
          } else {
            _createAndLaunchTournament();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLast ? 'GENERATE FIXTURES & START' : 'NEXT STEP',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('BACK'),
                      ),
                    ]
                  ],
                ),
                const BottomNavSpacing(),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Info'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildStep1Info(),
          ),
          Step(
            title: const Text('Participants'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildStep2Participants(),
          ),
          Step(
            title: const Text('Format'),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: _buildStep3Format(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStep1Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tournament Name *',
            hintText: 'e.g. Summer Open 2026',
            prefixIcon: Icon(Icons.emoji_events),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _sport,
          decoration: const InputDecoration(
            labelText: 'Sport *',
            prefixIcon: Icon(Icons.sports),
            border: OutlineInputBorder(),
          ),
          items: _sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _sport = val!),
        ),
        const SizedBox(height: 16),
        _buildLeagueSelector(Theme.of(context)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _organizerController,
          decoration: const InputDecoration(
            labelText: 'Organizer / Club Name',
            hintText: 'e.g. Sports Turf Academy',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _venueController,
          decoration: const InputDecoration(
            labelText: 'Venue / Ground / Turf',
            hintText: 'e.g. Court 1 & 2, Sports Turf Complex',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Start: ${DateFormat('MMM d, y').format(_startDate)}'),
                onPressed: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text('End: ${DateFormat('MMM d, y').format(_endDate)}'),
                onPressed: () => _pickDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Public Tournament'),
          subtitle: const Text('Allow spectators to view fixtures and live scores'),
          value: _isPublic,
          onChanged: (v) => setState(() => _isPublic = v),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description / Rules Summary',
            hintText: 'Special rules, reporting time, equipment notes...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSelector(ThemeData theme) {
    final leaguesAsync = ref.watch(leaguesListProvider);
    final leagues = leaguesAsync.value ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedLeagueId != null
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedLeagueId != null
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                size: 20,
                color: _selectedLeagueId != null
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLeagueId != null
                      ? 'Hosted Under League'
                      : 'League Association (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _selectedLeagueId != null
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (_selectedLeagueId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedLeagueId = null;
                      _selectedLeagueName = null;
                      _leagueParticipantNames = {};
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade600,
                  ),
                  child: const Text('Make Standalone'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedLeagueId != null) ...[
            Text(
              _selectedLeagueName ?? 'Selected League',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Matches & points will count toward this league leaderboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ] else ...[
            DropdownButtonFormField<String?>(
              value: _selectedLeagueId,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              hint: const Text('Standalone (No League)'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Standalone / Individual Tournament'),
                ),
                ...leagues.map((l) {
                  return DropdownMenuItem<String?>(
                    value: l.id,
                    child: Text('${l.name} (${l.sportTypes.join(", ")})'),
                  );
                }),
              ],
              onChanged: (leagueId) {
                setState(() {
                  _selectedLeagueId = leagueId;
                  if (leagueId == null) {
                    _selectedLeagueName = null;
                  } else {
                    final found = leagues.firstWhere((l) => l.id == leagueId);
                    _selectedLeagueName = found.name;
                  }
                });
                _refreshLeagueParticipants();
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Setup New League First', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeagueSetupScreen()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Participants() {
    final theme = Theme.of(context);
    final availableCount = _isTeamMode ? _availableTeams.length : _availablePlayers.length;
    final selectedCount = _participants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingRoster) const LinearProgressIndicator(),
        // Mode Switch
        Row(
          children: [
            ChoiceChip(
              label: const Text('Individual Players'),
              selected: !_isTeamMode,
              avatar: const Icon(Icons.person, size: 18),
              onSelected: (val) {
                if (val && _isTeamMode) {
                  _handleModeSwitch(false);
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Teams / Squads'),
              selected: _isTeamMode,
              avatar: const Icon(Icons.groups, size: 18),
              onSelected: (val) {
                if (val && !_isTeamMode) {
                  _handleModeSwitch(true);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Roster Selection Hero Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.secondary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isTeamMode ? Icons.groups : Icons.people_outline,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTeamMode ? 'Tournament Team Roster' : 'Tournament Player Roster',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Select who is playing. All players & teams may not play all tournaments.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.storage, size: 16),
                    label: Text(
                      '$availableCount Available in Roster',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                  ),
                  Chip(
                    avatar: Icon(
                      selectedCount >= 2 ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 16,
                      color: selectedCount >= 2 ? Colors.green : Colors.orange,
                    ),
                    label: Text(
                      '$selectedCount Selected for Tournament',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: selectedCount >= 2 ? Colors.green.shade800 : Colors.orange.shade900,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: selectedCount >= 2 ? Colors.green.shade50 : Colors.orange.shade50,
                  ),
                  if (_selectedLeagueId != null && _leagueParticipantNames.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.workspace_premium, size: 16, color: Colors.indigo),
                      label: Text(
                        '${_leagueParticipantNames.length} in League Roster',
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.indigo.shade50,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.playlist_add_check, size: 20),
                      label: Text(
                        _isTeamMode ? 'SELECT FROM TEAM LIST' : 'SELECT FROM PLAYER LIST',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openParticipantSelectorSheet,
                    ),
                  ),
                  if (availableCount > 0) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _selectAllAvailable,
                      child: const Text('Select All'),
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                        onPressed: _clearAllParticipants,
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick-Pick Chips
        if (availableCount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTeamMode ? 'Quick-Pick Teams for this Tournament:' : 'Quick-Pick Players for this Tournament:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'Tap to toggle',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickPickChips(theme),
          const SizedBox(height: 16),
        ],

        // Manual / Guest Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _participantInputController,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: _isTeamMode ? 'Add New / Guest Team' : 'Add New / Guest Player',
                        hintText: _isTeamMode ? 'e.g. Phoenix Titans' : 'e.g. Alex Morgan',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _createAndAddParticipant(_participantInputController.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Participant',
                    onPressed: () => _createAndAddParticipant(_participantInputController.text),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: Checkbox(
                      value: _saveNewParticipantToDb,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => _saveNewParticipantToDb = v ?? true),
                    ),
                  ),
                  Text(
                    _isTeamMode
                        ? 'Save to team list for future tournaments'
                        : 'Save to player list for future tournaments',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Seeding Draw Switch
        SwitchListTile(
          title: const Text('Enable Seeding Draw'),
          subtitle: const Text('Use assigned seeds (#1, #2, #3...) to balance knockout brackets'),
          value: _seeded,
          onChanged: (v) => setState(() => _seeded = v),
        ),
        const Divider(),

        // Confirmed Participants List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Participants (${_participants.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_participants.length >= 2)
              Text(
                'Drag to reorder seeds',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_participants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No participants selected for this tournament yet.',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose from the player list above or type names to add.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _participants.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _participants.removeAt(oldIndex);
                _participants.insert(newIndex, item);
                _reindexSeeds();
              });
            },
            itemBuilder: (context, index) {
              final p = _participants[index];
              return Card(
                key: ValueKey(p.id),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '#${p.seed ?? (index + 1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_isTeamMode ? 'Team Participant' : 'Individual Player'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remove from this tournament',
                        onPressed: () => _removeParticipant(index),
                      ),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickPickChips(ThemeData theme) {
    if (_isTeamMode) {
      final teams = _availableTeams.take(12).toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...teams.map((t) {
            final isSelected = _isTeamSelected(t);
            return FilterChip(
              label: Text(t.name),
              selected: isSelected,
              avatar: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : const Icon(Icons.add, size: 16),
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _toggleTeam(t),
            );
          }),
          if (_availableTeams.length > 12)
            ActionChip(
              label: Text('+${_availableTeams.length - 12} more...'),
              avatar: const Icon(Icons.more_horiz, size: 16),
              onPressed: _openParticipantSelectorSheet,
            ),
        ],
      );
    } else {
      final players = _availablePlayers.take(16).toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...players.map((p) {
            final isSelected = _isPlayerSelected(p);
            return FilterChip(
              label: Text(p.name),
              selected: isSelected,
              avatar: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _togglePlayer(p),
            );
          }),
          if (_availablePlayers.length > 16)
            ActionChip(
              label: Text('+${_availablePlayers.length - 16} more...'),
              avatar: const Icon(Icons.more_horiz, size: 16),
              onPressed: _openParticipantSelectorSheet,
            ),
        ],
      );
    }
  }

  Widget _buildStep3Format() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<TournamentFormat>(
          initialValue: _format,
          decoration: const InputDecoration(
            labelText: 'Tournament Format *',
            border: OutlineInputBorder(),
          ),
          items: TournamentFormat.values.map((f) {
            return DropdownMenuItem(
              value: f,
              child: Text(f.displayName),
            );
          }).toList(),
          onChanged: (val) => setState(() => _format = val!),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _format.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_getFormatDescription(_format)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_sport == 'Cricket') ...[
          TextFormField(
            controller: _oversController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Overs Per Innings',
              border: OutlineInputBorder(),
            ),
          ),
        ] else if (_sport == 'Badminton' || _sport == 'Table Tennis' || _sport == 'Tennis' || _sport == 'Volleyball') ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _setsToWinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sets to Win',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _pointsPerSetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points Per Set',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_participants.length} participants registered. Ready to generate automatic fixtures.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getFormatDescription(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return 'Loser is immediately knocked out. Winners advance round-by-round until the Final.';
      case TournamentFormat.doubleElimination:
        return 'Teams get a second chance in the losers bracket before being eliminated.';
      case TournamentFormat.roundRobin:
        return 'Every participant plays against every other participant. Standings are ranked by points and differential.';
      case TournamentFormat.leagueKnockout:
        return 'Group league stage followed by top qualifiers entering a knockout semi-final and final.';
      case TournamentFormat.groupStage:
        return 'Round-robin group stages dividing participants into qualifying brackets.';
      case TournamentFormat.friendly:
        return 'Exhibition matches scheduled pairwise without knockout pressure.';
    }
  }
}

class _ParticipantSelectorSheet extends StatefulWidget {
  final bool isTeamMode;
  final List<Player> availablePlayers;
  final List<Team> availableTeams;
  final Set<String> leagueParticipantNames;
  final bool isUnderLeague;
  final List<Team> selectedParticipants;
  final ValueChanged<Player> onTogglePlayer;
  final ValueChanged<Team> onToggleTeam;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final Future<void> Function(String) onAddNewParticipant;

  const _ParticipantSelectorSheet({
    required this.isTeamMode,
    required this.availablePlayers,
    required this.availableTeams,
    required this.leagueParticipantNames,
    required this.isUnderLeague,
    required this.selectedParticipants,
    required this.onTogglePlayer,
    required this.onToggleTeam,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onAddNewParticipant,
  });

  @override
  State<_ParticipantSelectorSheet> createState() => _ParticipantSelectorSheetState();
}

class _ParticipantSelectorSheetState extends State<_ParticipantSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickAddController = TextEditingController();
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all', 'league', 'selected', 'unselected'

  @override
  void dispose() {
    _searchController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  bool _isPlayerInTournament(Player player) {
    final pName = player.name.trim().toLowerCase();
    final pId = player.idString;
    return widget.selectedParticipants.any((t) =>
        t.name.trim().toLowerCase() == pName ||
        (t.playerIds.isNotEmpty && t.playerIds.contains(pId)));
  }

  bool _isTeamInTournament(Team team) {
    final tName = team.name.trim().toLowerCase();
    return widget.selectedParticipants.any((t) =>
        t.name.trim().toLowerCase() == tName ||
        (team.id.isNotEmpty && t.id == team.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = widget.isTeamMode ? widget.availableTeams.length : widget.availablePlayers.length;
    final selectedCount = widget.selectedParticipants.length;

    // Filter items
    List<dynamic> filteredItems = [];
    if (widget.isTeamMode) {
      filteredItems = widget.availableTeams.where((t) {
        final matchesQuery = _searchQuery.isEmpty ||
            t.name.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;

        final isSelected = _isTeamInTournament(t);
        if (_filterMode == 'selected') return isSelected;
        if (_filterMode == 'unselected') return !isSelected;
        if (_filterMode == 'league') {
          return widget.leagueParticipantNames.contains(t.name.trim().toLowerCase());
        }
        return true;
      }).toList();
    } else {
      filteredItems = widget.availablePlayers.where((p) {
        final matchesQuery = _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.contact != null && p.contact!.contains(_searchQuery));
        if (!matchesQuery) return false;

        final isSelected = _isPlayerInTournament(p);
        if (_filterMode == 'selected') return isSelected;
        if (_filterMode == 'unselected') return !isSelected;
        if (_filterMode == 'league') {
          return widget.leagueParticipantNames.contains(p.name.trim().toLowerCase());
        }
        return true;
      }).toList();
    }

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  widget.isTeamMode ? Icons.groups : Icons.person_search,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTeamMode ? 'Select Teams for Tournament' : 'Select Players for Tournament',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        'Choose who will compete. $selectedCount selected for this draw.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.isTeamMode ? 'Search teams...' : 'Search players by name, phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Filter Chips & Bulk Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All ($totalCount)'),
                          selected: _filterMode == 'all',
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _filterMode = 'all'),
                        ),
                        if (widget.isUnderLeague && widget.leagueParticipantNames.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text('League (${widget.leagueParticipantNames.length})'),
                            selected: _filterMode == 'league',
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => setState(() => _filterMode = 'league'),
                          ),
                        ],
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('Selected ($selectedCount)'),
                          selected: _filterMode == 'selected',
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _filterMode = 'selected'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('Unselected (${totalCount - selectedCount < 0 ? 0 : totalCount - selectedCount})'),
                          selected: _filterMode == 'unselected',
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _filterMode = 'unselected'),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSelectAll();
                    setState(() {});
                  },
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onClearAll();
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade700,
                  ),
                  child: const Text('None'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List of Items
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results matching "$_searchQuery"'
                                : 'No participants in this category',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add them using the quick add field below.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      if (widget.isTeamMode) {
                        final team = item as Team;
                        final isSelected = _isTeamInTournament(team);
                        final isLeagueMember = widget.leagueParticipantNames.contains(team.name.trim().toLowerCase());

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (_) {
                            widget.onToggleTeam(team);
                            setState(() {});
                          },
                          secondary: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.groups,
                              color: isSelected ? Colors.white : theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isLeagueMember)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Text(
                                    'League',
                                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            team.playerIds.isNotEmpty
                                ? '${team.playerIds.length} Squad Members'
                                : 'Registered Team',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        );
                      } else {
                        final player = item as Player;
                        final isSelected = _isPlayerInTournament(player);
                        final isLeagueMember = widget.leagueParticipantNames.contains(player.name.trim().toLowerCase());

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (_) {
                            widget.onTogglePlayer(player);
                            setState(() {});
                          },
                          secondary: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isLeagueMember)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Text(
                                    'League',
                                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            player.seed != null
                                ? 'Club Seed #${player.seed}${player.contact != null ? " • ${player.contact}" : ""}'
                                : (player.contact ?? 'Club Player'),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        );
                      }
                    },
                  ),
          ),

          // Quick Add inline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickAddController,
                    decoration: InputDecoration(
                      hintText: widget.isTeamMode ? 'Add new team to roster...' : 'Add new player to roster...',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (name) async {
                      if (name.trim().isNotEmpty) {
                        await widget.onAddNewParticipant(name);
                        _quickAddController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add & Select',
                  onPressed: () async {
                    final name = _quickAddController.text.trim();
                    if (name.isNotEmpty) {
                      await widget.onAddNewParticipant(name);
                      _quickAddController.clear();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CONFIRM SELECTION ($selectedCount PARTICIPANTS)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
