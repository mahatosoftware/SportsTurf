import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/league.dart';
import '../models/season.dart';
import '../providers/league_providers.dart';
import '../providers/season_providers.dart';
import '../../tournament/models/tournament.dart';
import '../../tournament/models/match.dart';
import '../../tournament/ui/tournament_dashboard_screen.dart';
import '../../tournament/ui/tournament_setup_screen.dart';
import '../../venue/ui/venue_management_screen.dart';
import '../../dispute/ui/disputes_screen.dart';
import '../../reports/services/report_export_service.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/subscription_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import 'league_setup_screen.dart';

class LeagueDashboardScreen extends ConsumerStatefulWidget {
  final League league;

  const LeagueDashboardScreen({super.key, required this.league});

  @override
  ConsumerState<LeagueDashboardScreen> createState() => _LeagueDashboardScreenState();
}

class _LeagueDashboardScreenState extends ConsumerState<LeagueDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareLeague(League currentLeague) {
    Share.share(
      'Follow the "${currentLeague.name}" on Sports Turf!\n'
      'League Code: ${currentLeague.shareCode}\n'
      'Track live fixtures, multi-sport tournaments, and standings.',
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('League Code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket;
      case 'badminton':
        return Icons.sports_tennis;
      case 'tennis':
        return Icons.sports_tennis;
      case 'table tennis':
        return Icons.table_restaurant;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Colors.red.shade700;
      case 'badminton':
        return Colors.teal.shade700;
      case 'tennis':
        return Colors.green.shade700;
      case 'table tennis':
        return Colors.deepOrange.shade700;
      case 'volleyball':
        return Colors.orange.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leagueStream = ref.watch(singleLeagueProvider(widget.league.id));
    final currentLeague = leagueStream.value ?? widget.league;
    final tournamentsStream = ref.watch(leagueTournamentsProvider(currentLeague.id));
    final tournaments = tournamentsStream.value ?? [];

    final currentUser = ref.watch(currentUserProvider);
    final isOrganizer = currentUser != null &&
        (currentUser.isSuperAdmin ||
         (currentLeague.creatorId.isNotEmpty && currentLeague.isAdmin(currentUser.id)));
    final isSubscribed = ref.watch(userSubscriptionsProvider).subscribedLeagueIds.contains(currentLeague.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLeague.name),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isSubscribed ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isSubscribed ? 'Subscribed (Tap to unfollow)' : 'Subscribe to League',
            onPressed: () async {
              await ref.read(userSubscriptionsProvider.notifier).toggleLeagueSubscription(currentLeague.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isSubscribed
                        ? 'Unsubscribed from ${currentLeague.name}'
                        : 'Subscribed to ${currentLeague.name}! It will now appear on your Home dashboard.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share League',
            onPressed: () => _shareLeague(currentLeague),
          ),
          if (isOrganizer)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) async {
                if (val == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeagueSetupScreen(existingLeague: currentLeague),
                    ),
                  );
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete League?'),
                      content: const Text(
                        'This will delete the league. Tournaments created under this league will remain as standalone tournaments.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(leagueControllerProvider.notifier).deleteLeague(currentLeague.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit League Details')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete League', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.emoji_events),
              text: 'Tournaments (${tournaments.length})',
            ),
            const Tab(
              icon: const Icon(Icons.leaderboard),
              text: 'Standings',
            ),
            const Tab(
              icon: const Icon(Icons.info_outline),
              text: 'Overview',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Role & Mode Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isOrganizer ? Colors.green.shade50 : Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  isOrganizer ? Icons.admin_panel_settings : Icons.remove_red_eye_outlined,
                  size: 18,
                  color: isOrganizer ? Colors.green.shade800 : Colors.blue.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOrganizer
                        ? 'League Admin Mode: You have full league & tournament management rights.'
                        : 'Spectator Mode: Real-time live scoreboard. Scores & standings update automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOrganizer ? Colors.green.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // League Header Card
          _buildLeagueHeader(theme, currentLeague, tournaments.length),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentsTab(theme, currentLeague, tournaments, isOrganizer),
                _buildStandingsTab(theme, currentLeague, tournaments, isOrganizer),
                _buildOverviewTab(theme, currentLeague, isOrganizer),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentSetupScreen(
                      initialLeagueId: currentLeague.id,
                      initialLeagueName: currentLeague.name,
                    ),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Host Tournament in League'),
            )
          : null,
    );
  }

  Widget _buildLeagueHeader(ThemeData theme, League currentLeague, int tournamentsCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'LEAGUE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  currentLeague.status.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const Spacer(),
              // Share Code Chip
              InkWell(
                onTap: () => _copyCode(currentLeague.shareCode),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.key, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        currentLeague.shareCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (currentLeague.organizerName.isNotEmpty) ...[
                Icon(Icons.business, size: 14, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(
                  currentLeague.organizerName,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
              ],
              if (currentLeague.venue.isNotEmpty) ...[
                Icon(Icons.location_on, size: 14, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currentLeague.venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsTab(
    ThemeData theme,
    League currentLeague,
    List<Tournament> tournaments,
    bool isOrganizer,
  ) {
    if (tournaments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_outlined, size: 56, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No Tournaments in this League Yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Host different sports tournaments under this league (e.g. Cricket Trophy, Badminton Open, Tennis Cup) to accumulate overall league points.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              if (isOrganizer)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentSetupScreen(
                          initialLeagueId: currentLeague.id,
                          initialLeagueName: currentLeague.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Host First Tournament in League'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: isOrganizer),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        final sportColor = _getSportColor(t.sportType);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDashboardScreen(tournament: t),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sportColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getSportIcon(t.sportType), color: sportColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${t.sportType} • ${t.format.displayName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.status == TournamentStatus.completed
                              ? Colors.green.withOpacity(0.12)
                              : Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: t.status == TournamentStatus.completed
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${t.participants.length} Teams/Players',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.sports_score_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${t.matches.length} Matches',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'View Fixtures',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
                        ],
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

  Widget _buildStandingsTab(ThemeData theme, League currentLeague, List<Tournament> tournaments, bool isOrganizer) {
    if (tournaments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Host tournaments in this league to view team leaderboard and cross-sport standings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Aggregate team stats across all tournaments under this league
    final Map<String, _LeagueTeamStats> teamStats = {};

    for (final t in tournaments) {
      for (final team in t.participants) {
        teamStats.putIfAbsent(team.name, () => _LeagueTeamStats(name: team.name));
      }

      for (final m in t.matches) {
        if (m.status == MatchStatus.completed && m.winnerId != null) {
          final winner = t.participants.firstWhere(
            (p) => p.id == m.winnerId,
            orElse: () => t.participants.first,
          );
          final loser = t.participants.firstWhere(
            (p) => p.id != m.winnerId && (p.id == m.participantAId || p.id == m.participantBId),
            orElse: () => t.participants.last,
          );

          teamStats.putIfAbsent(winner.name, () => _LeagueTeamStats(name: winner.name)).wins += 1;
          teamStats.putIfAbsent(winner.name, () => _LeagueTeamStats(name: winner.name)).played += 1;
          teamStats.putIfAbsent(winner.name, () => _LeagueTeamStats(name: winner.name)).points += 2;

          teamStats.putIfAbsent(loser.name, () => _LeagueTeamStats(name: loser.name)).losses += 1;
          teamStats.putIfAbsent(loser.name, () => _LeagueTeamStats(name: loser.name)).played += 1;
        }
      }
    }

    final sortedStats = teamStats.values.toList()
      ..sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        return b.wins.compareTo(a.wins);
      });

    if (sortedStats.isEmpty) {
      return const Center(
        child: Text('No match results recorded yet in this league.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: isOrganizer),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall League Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aggregated performance across all tournaments.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export CSV'),
              onPressed: () {
                final standingsData = sortedStats.map((s) => {
                  'name': s.name,
                  'played': s.played,
                  'wins': s.wins,
                  'losses': s.losses,
                  'points': s.points,
                }).toList();
                final csv = ReportExportService.exportLeagueStandingsCsv(currentLeague, standingsData);
                Share.share(csv, subject: '${currentLeague.name} Standings.csv');
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(3),
              2: FixedColumnWidth(40),
              3: FixedColumnWidth(40),
              4: FixedColumnWidth(40),
              5: FixedColumnWidth(55),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                children: const [
                  Padding(padding: EdgeInsets.all(10), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Team / Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('P', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepPurple))),
                ],
              ),
              ...List.generate(sortedStats.length, (idx) {
                final stat = sortedStats[idx];
                final isTop3 = idx < 3;
                return TableRow(
                  decoration: BoxDecoration(
                    color: idx % 2 == 1 ? theme.colorScheme.surfaceVariant.withOpacity(0.15) : null,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                          color: idx == 0 ? Colors.amber.shade800 : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        stat.name,
                        style: TextStyle(
                          fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(10), child: Text('${stat.played}')),
                    Padding(padding: const EdgeInsets.all(10), child: Text('${stat.wins}', style: const TextStyle(color: Colors.green))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('${stat.losses}', style: const TextStyle(color: Colors.red))),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${stat.points}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme, League currentLeague, bool isOrganizer) {
    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: isOrganizer),
      children: [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About the League',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  currentLeague.description.isEmpty
                      ? 'No description provided for this league.'
                      : currentLeague.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.business, 'Organizer', currentLeague.organizerName),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Primary Venue', currentLeague.venue),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Schedule',
                  '${DateFormat('MMM d, y').format(currentLeague.startDate ?? DateTime.now())} - ${DateFormat('MMM d, y').format(currentLeague.endDate ?? DateTime.now())}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.sports,
                  'Sports',
                  currentLeague.sportTypes.join(', '),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.visibility,
                  'Visibility',
                  currentLeague.isPublic ? 'Public League (Open Discovery)' : 'Private (Code Only)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spectator & Member Access',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this League Code with players, coaches, and fans to let them follow all tournaments hosted under this league.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Text(
                          currentLeague.shareCode,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _copyCode(currentLeague.shareCode),
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Code',
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: () => _shareLeague(currentLeague),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Operations & Governance Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations & Integrity',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage competition grounds, courts, time conflict rules, and resolve participant protests.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VenueManagementScreen(
                              leagueId: currentLeague.id,
                              leagueName: currentLeague.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.stadium_outlined, size: 18),
                      label: const Text('Venues & Courts'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DisputesScreen(
                              leagueId: currentLeague.id,
                              leagueName: currentLeague.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel_outlined, size: 18),
                      label: const Text('Protests & Integrity'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Seasons Card (UC-022, UC-023)
        _buildSeasonsCard(theme, currentLeague, isOrganizer),
        const SizedBox(height: 16),
        // Divisions Card (UC-020)
        _buildDivisionsCard(theme, currentLeague, isOrganizer),
        const SizedBox(height: 16),
        // Announcements Card (UC-025)
        _buildAnnouncementsCard(theme, currentLeague, isOrganizer),
      ],
    );
  }

  Widget _buildSeasonsCard(ThemeData theme, League currentLeague, bool isOrganizer) {
    final seasonsAsync = ref.watch(leagueSeasonsProvider(currentLeague.id));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seasons',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isOrganizer)
                  TextButton.icon(
                    onPressed: () => _openCreateSeasonDialog(currentLeague),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Season'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            seasonsAsync.when(
              data: (seasons) {
                if (seasons.isEmpty) {
                  return Text(
                    'No seasons created yet. Tournaments will run under the general league schedule.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  );
                }
                return Column(
                  children: seasons.map((s) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.calendar_month, size: 14, color: theme.colorScheme.primary),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        'Status: ${s.status.displayName} • ${s.startDate != null ? DateFormat("MMM y").format(s.startDate!) : "Ongoing"}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading seasons', style: TextStyle(fontSize: 12, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionsCard(ThemeData theme, League currentLeague, bool isOrganizer) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Divisions & Categories',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isOrganizer)
                  TextButton.icon(
                    onPressed: () => _openAddDivisionDialog(currentLeague),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Division'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (currentLeague.divisions.isEmpty)
              Text(
                'No specific divisions created yet (e.g. Under-19, Open, Division 1).',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: currentLeague.divisions.map((div) {
                  return Chip(
                    label: Text(div, style: const TextStyle(fontSize: 12)),
                    onDeleted: isOrganizer
                        ? () {
                            final updated = List<String>.from(currentLeague.divisions)..remove(div);
                            ref.read(leagueControllerProvider.notifier).updateLeague(
                                  currentLeague.copyWith(divisions: updated),
                                );
                          }
                        : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsCard(ThemeData theme, League currentLeague, bool isOrganizer) {
    final notices = currentLeague.announcements;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Announcements',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isOrganizer)
                  TextButton.icon(
                    onPressed: () => _openPostAnnouncementDialog(currentLeague),
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Post Notice'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (notices.isEmpty)
              Text(
                'No official announcements posted yet.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              )
            else
              Column(
                children: notices.map((n) {
                  final title = n['title'] ?? 'Notice';
                  final body = n['body'] ?? '';
                  final date = n['date'] != null ? DateFormat('MMM d, y').format(DateTime.tryParse(n['date']) ?? DateTime.now()) : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(body, style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _openCreateSeasonDialog(League currentLeague) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Season'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Season Name *',
            hintText: 'e.g. 2026 Spring Season',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final text = nameCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final season = Season(
                id: const Uuid().v4(),
                leagueId: currentLeague.id,
                name: text,
                startDate: DateTime.now(),
                status: SeasonStatus.active,
              );
              await ref.read(seasonControllerProvider.notifier).createSeason(season);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Season "$text" created')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openAddDivisionDialog(League currentLeague) {
    final divCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Division / Category'),
        content: TextField(
          controller: divCtrl,
          decoration: const InputDecoration(
            labelText: 'Division Name *',
            hintText: 'e.g. Under-19, Division A, Women\'s Open',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final text = divCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final updated = List<String>.from(currentLeague.divisions)..add(text);
              await ref.read(leagueControllerProvider.notifier).updateLeague(
                    currentLeague.copyWith(divisions: updated),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Division "$text" added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openPostAnnouncementDialog(League currentLeague) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post League Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Notice Title *',
                hintText: 'e.g. Schedule Update or Weather Notice',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              final newNotice = {
                'title': title,
                'body': bodyCtrl.text.trim(),
                'date': DateTime.now().toIso8601String(),
              };
              final updated = List<Map<String, dynamic>>.from(currentLeague.announcements)..insert(0, newNotice);
              await ref.read(leagueControllerProvider.notifier).updateLeague(
                    currentLeague.copyWith(announcements: updated),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notice posted to league members')),
                );
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not specified' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _LeagueTeamStats {
  final String name;
  int played = 0;
  int wins = 0;
  int losses = 0;
  int points = 0;

  _LeagueTeamStats({required this.name});
}
