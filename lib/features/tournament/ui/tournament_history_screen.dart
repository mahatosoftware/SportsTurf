import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament.dart';
import '../providers/tournament_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/subscription_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import 'tournament_dashboard_screen.dart';

class TournamentHistoryScreen extends ConsumerStatefulWidget {
  const TournamentHistoryScreen({super.key});

  @override
  ConsumerState<TournamentHistoryScreen> createState() => _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends ConsumerState<TournamentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['My Tournaments', 'Public Explore', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showJoinWithCodeDialog() {
    final codeController = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Enter Share Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the tournament code provided by the organizer to view live matches and standings as a spectator.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tournament Code (e.g. TURF-7A9K)',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                  hintText: 'TURF-XXXX',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSearching ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSearching
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) return;

                      setDialogState(() => isSearching = true);
                      try {
                        final tournament = await ref
                            .read(tournamentControllerProvider.notifier)
                            .findTournamentByCode(code);

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        if (tournament != null) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDashboardScreen(tournament: tournament),
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No tournament found with code "$code"'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSearching = false);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error looking up code: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('JOIN / VIEW'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tournaments Hub'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.vpn_key_outlined, size: 16),
            label: const Text('Enter Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _showJoinWithCodeDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: tournamentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading tournaments: $err')),
              data: (tournaments) {
                final subTournaments = ref.watch(userSubscribedTournamentIdsProvider);
                final myTournaments = currentUser != null
                    ? tournaments.where((t) =>
                        t.creatorId == currentUser.id ||
                        t.managerUserIds.contains(currentUser.id) ||
                        t.participantUserIds.contains(currentUser.id) ||
                        subTournaments.contains(t.id)).toList()
                    : tournaments.where((t) => subTournaments.contains(t.id)).toList();
                final publicTournaments = tournaments.where((t) => t.isPublic).toList();
                final inProgressTournaments = tournaments.where((t) => t.status == TournamentStatus.inProgress).toList();
                final completedTournaments = tournaments.where((t) => t.status == TournamentStatus.completed).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      myTournaments,
                      emptyMessage: currentUser == null
                          ? 'Sign in to view tournaments you manage or subscribe to.'
                          : 'You haven\'t created or subscribed to any tournaments yet.',
                    ),
                    _buildList(publicTournaments, emptyMessage: 'No public tournaments found.'),
                    _buildList(inProgressTournaments, emptyMessage: 'No live tournaments currently in progress.'),
                    _buildList(completedTournaments, emptyMessage: 'No completed tournaments yet.'),
                  ],
                );
              },
            ),
          ),
          _buildAdBannerSlot(),
        ],
      ),
    );
  }

  Widget _buildAdBannerSlot() {
    return Container(
      width: double.infinity,
      height: 50,
      color: Colors.white,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sports Turf Ad Space • Safe & Non-Obstructing',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildList(List<Tournament> tournaments, {required String emptyMessage}) {
    if (tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Enter Code to View Tournament'),
                onPressed: _showJoinWithCodeDialog,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: true),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        final completedMatches = tournament.matches.where((m) => m.status.name == 'completed').length;
        final totalMatches = tournament.matches.length;
        final progress = totalMatches > 0 ? (completedMatches / totalMatches) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDashboardScreen(tournament: tournament),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.sportType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      // Share Code Chip
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: tournament.shareCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code "${tournament.shareCode}" copied to clipboard!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tag, size: 12, color: Colors.blue),
                              const SizedBox(width: 2),
                              Text(
                                tournament.shareCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 11, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tournament.status == TournamentStatus.completed
                                  ? Colors.green.shade100
                                  : tournament.status == TournamentStatus.inProgress
                                      ? Colors.red.shade100
                                      : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tournament.status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tournament.status == TournamentStatus.completed
                                    ? Colors.green.shade900
                                    : tournament.status == TournamentStatus.inProgress
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Consumer(
                            builder: (context, ref, _) {
                              final isSub = ref.watch(userSubscriptionsProvider).subscribedTournamentIds.contains(tournament.id);
                              return InkWell(
                                onTap: () async {
                                  await ref.read(userSubscriptionsProvider.notifier).toggleTournamentSubscription(tournament.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isSub
                                            ? 'Unsubscribed from ${tournament.name}'
                                            : 'Subscribed to ${tournament.name}!'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    isSub ? Icons.bookmark : Icons.bookmark_border,
                                    size: 20,
                                    color: isSub ? const Color(0xFF1B5E20) : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tournament.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tournament.format.displayName} • ${tournament.participants.length} Participants',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  if (tournament.venue.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          tournament.venue,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Matches Completed',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          Text(
                            '$completedMatches / $totalMatches',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
