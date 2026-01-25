import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/player.dart';
import '../../tournament/models/team.dart';

class CreateEditTeamScreen extends StatefulWidget {
  final Team? team;

  const CreateEditTeamScreen({super.key, this.team});

  @override
  State<CreateEditTeamScreen> createState() => _CreateEditTeamScreenState();
}

class _CreateEditTeamScreenState extends State<CreateEditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  List<Player> _allPlayers = [];
  List<Player> _selectedPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _nameController.text = widget.team!.name;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final players = await DatabaseHelper.instance.getPlayers();
    
    List<Player> selected = [];
    if (widget.team != null && widget.team!.playerIds.isNotEmpty) {
      selected = players.where((p) => widget.team!.playerIds.contains(p.id.toString()) || widget.team!.playerIds.contains(p.name)).toList();
      // Note: id in Player is int?, but playerIds is List<String>. 
      // If we stored names previously, it might match name. Ideally we store IDs.
      // DatabaseHelper insertPlayer uses auto-increment ID.
      // So assuming we store ID as string.
      
      // Let's matching stricter:
      selected = players.where((p) => widget.team!.playerIds.contains(p.id.toString())).toList();
    }

    if (mounted) {
      setState(() {
        _allPlayers = players;
        _selectedPlayers = selected;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text;
    final playerIds = _selectedPlayers.map((p) => p.id.toString()).toList();

    final team = Team(
      id: widget.team?.id ?? const Uuid().v4(),
      name: name,
      playerIds: playerIds,
      seed: widget.team?.seed,
    );

    await DatabaseHelper.instance.insertTeam(team);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team Saved')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.team != null ? 'Edit Team' : 'New Team'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTeam,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MEMBERS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showAddMemberDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Member'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedPlayers.isEmpty
                        ? Center(child: Text("No members added yet", style: TextStyle(color: Colors.grey[500])))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _selectedPlayers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final player = _selectedPlayers[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: Colors.green),
                                  ),
                                  title: Text(player.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedPlayers.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddMemberDialog() {
    // Filter out already selected
    final available = _allPlayers.where((p) => !_selectedPlayers.contains(p)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: available.isEmpty
              ? const Text("No other players available in database.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final player = available[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(player.name),
                      onTap: () {
                        setState(() {
                          _selectedPlayers.add(player);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
