import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tournament/models/team.dart';
import '../providers/team_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import 'create_edit_team_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isSpectator = currentUser == null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manage Teams'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (isSpectator)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Spectator Mode: View-only club teams & squad rosters.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error loading teams: $error'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.refresh(teamsStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No teams found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSpectator
                              ? 'No club squads registered yet.'
                              : 'Tap "New Team" below to create a squad.',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: !isSpectator),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final canManageThisTeam = isSuperAdmin ||
                        (currentUser != null &&
                            (team.userId == currentUser.id || team.captainId == currentUser.id));

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B5E20).withAlpha(30),
                          child: Text(
                            team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                team.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (team.seed != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  'Seed #${team.seed}',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text('${team.playerIds.length} members'),
                        trailing: canManageThisTeam
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () => _confirmDelete(context, ref, team),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateEditTeamScreen(
                                team: team,
                                isViewOnly: !canManageThisTeam,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !isSpectator
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEditTeamScreen(),
                  ),
                );
              },
              label: const Text('New Team'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Team team) {
    final currentUser = ref.read(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final canManageThisTeam = isSuperAdmin ||
        (currentUser != null &&
            (team.userId == currentUser.id || team.captainId == currentUser.id));

    if (!canManageThisTeam) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Spectators cannot delete teams.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(teamControllerProvider.notifier).deleteTeam(team.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
