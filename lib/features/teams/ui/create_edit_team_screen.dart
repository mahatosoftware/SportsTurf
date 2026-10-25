import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/player.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../tournament/models/team.dart';
import '../../players/providers/player_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../providers/team_providers.dart';

class CreateEditTeamScreen extends ConsumerStatefulWidget {
  final Team? team;
  final bool isViewOnly;

  const CreateEditTeamScreen({super.key, this.team, this.isViewOnly = false});

  @override
  ConsumerState<CreateEditTeamScreen> createState() => _CreateEditTeamScreenState();
}

class _CreateEditTeamScreenState extends ConsumerState<CreateEditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seedController = TextEditingController();

  List<Player> _selectedPlayers = [];
  bool _initializedSelection = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _nameController.text = widget.team!.name;
      if (widget.team!.seed != null) {
        _seedController.text = widget.team!.seed.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  void _syncInitialSelection(List<Player> allPlayers) {
    if (_initializedSelection) return;
    if (widget.team != null && widget.team!.playerIds.isNotEmpty) {
      final teamPlayerIds = widget.team!.playerIds.toSet();
      _selectedPlayers = allPlayers
          .where((p) =>
              teamPlayerIds.contains(p.id?.toString()) ||
              teamPlayerIds.contains(p.name))
          .toList();
    }
    _initializedSelection = true;
  }

  Future<void> _saveTeam() async {
    if (_isSubmitting) return;

    final currentUser = ref.read(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isOwnerOrCaptain = widget.team == null ||
        isSuperAdmin ||
        (currentUser != null &&
            (widget.team!.userId == currentUser.id || widget.team!.captainId == currentUser.id));
    if (widget.isViewOnly || !isOwnerOrCaptain) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission Denied: Spectators cannot modify teams.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final seed = int.tryParse(_seedController.text.trim());
    final playerIds = _selectedPlayers.map((p) => p.id?.toString() ?? p.name).toList();

    // Authenticate or resolve user ID for security rules validation
    var currentUserId = widget.team?.userId ?? currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final user = authRepo.currentUser ?? await authRepo.signInAnonymously();
        currentUserId = user.id;
      } catch (_) {}
    }

    final team = Team(
      id: widget.team?.id.isNotEmpty == true ? widget.team!.id : const Uuid().v4(),
      name: name,
      playerIds: playerIds,
      seed: seed,
      userId: currentUserId,
      captainId: widget.team?.captainId ?? currentUserId,
    );

    try {
      if (widget.team != null) {
        await ref.read(teamControllerProvider.notifier).updateTeam(team);
      } else {
        await ref.read(teamControllerProvider.notifier).createTeam(team);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.team != null ? 'Team updated successfully!' : 'Team saved successfully!'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team saved locally (Firebase sync: $e)'),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isOwnerOrCaptain = widget.team == null ||
        isSuperAdmin ||
        (currentUser != null &&
            (widget.team!.userId == currentUser.id || widget.team!.captainId == currentUser.id));
    final isReadOnly = widget.isViewOnly || !isOwnerOrCaptain;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isReadOnly ? 'Team Roster' : (widget.team != null ? 'Edit Team' : 'New Team')),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSubmitting ? null : _saveTeam,
            )
        ],
      ),
      body: SafeArea(
        top: false,
        child: playersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (allPlayers) {
            _syncInitialSelection(allPlayers);

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  if (isReadOnly)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Spectator Mode: View-only team squad & members.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                readOnly: isReadOnly,
                                decoration: const InputDecoration(
                                  labelText: 'Team Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.group),
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _seedController,
                                readOnly: isReadOnly,
                                decoration: const InputDecoration(
                                  labelText: 'Seed Number (Optional)',
                                  hintText: 'e.g. 1 for top seed',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.military_tech_outlined),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MEMBERS (${_selectedPlayers.length})',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isReadOnly)
                              TextButton.icon(
                                onPressed: () => _showAddMemberDialog(allPlayers),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Member'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedPlayers.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            alignment: Alignment.center,
                            child: Text(
                              "No members added yet.\nTap 'Add Member' to pick or add players.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        else
                          ..._selectedPlayers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final player = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1B5E20).withAlpha(30),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                title: Text(player.name),
                                subtitle: player.contact != null ? Text(player.contact!) : null,
                                trailing: isReadOnly
                                    ? null
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedPlayers.removeAt(index);
                                          });
                                        },
                                      ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  if (!isReadOnly)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _saveTeam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isSubmitting
                                  ? 'Saving...'
                                  : (widget.team != null ? 'UPDATE TEAM' : 'SAVE TEAM'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const BottomNavSpacing(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddMemberDialog(List<Player> allPlayers) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedIds = _selectedPlayers.map((p) => p.id?.toString() ?? p.name).toSet();
            final query = searchController.text.trim().toLowerCase();

            final available = allPlayers.where((p) {
              final idMatches = selectedIds.contains(p.id?.toString() ?? p.name);
              if (idMatches) return false;
              if (query.isEmpty) return true;
              return p.name.toLowerCase().contains(query);
            }).toList();

            final bool exactMatch = allPlayers.any((p) => p.name.trim().toLowerCase() == query);
            final bool canAddNew = query.isNotEmpty && !exactMatch && !_selectedPlayers.any((p) => p.name.trim().toLowerCase() == query);

            return AlertDialog(
              title: const Text('Add Team Member'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search or enter new player name',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (canAddNew) ...[
                      ListTile(
                        tileColor: const Color(0xFF1B5E20).withAlpha(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.person_add, size: 20),
                        ),
                        title: Text('Add "${searchController.text.trim()}"'),
                        subtitle: const Text('Create and add as a new player'),
                        onTap: () async {
                          final newName = searchController.text.trim();
                          final newPlayer = Player(
                            id: const Uuid().v4(),
                            name: newName,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          try {
                            await ref.read(playerRepositoryProvider).savePlayer(newPlayer);
                          } catch (_) {}
                          if (mounted) {
                            setState(() {
                              _selectedPlayers.add(newPlayer);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                      child: available.isEmpty && !canAddNew
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                query.isEmpty
                                    ? 'No other players available in database.'
                                    : 'No matching players found.',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: available.length,
                              itemBuilder: (context, index) {
                                final player = available[index];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(player.name),
                                  subtitle: player.contact != null ? Text(player.contact!) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedPlayers.add(player);
                                    });
                                    Navigator.pop(dialogContext);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
