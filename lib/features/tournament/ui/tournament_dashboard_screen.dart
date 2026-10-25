import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tournament.dart';
import '../models/match.dart';
import '../providers/tournament_providers.dart';
import '../../league/providers/league_providers.dart';
import '../../league/ui/league_dashboard_screen.dart';
import '../../venue/ui/venue_management_screen.dart';
import '../../dispute/ui/disputes_screen.dart';
import '../../reports/services/report_export_service.dart';
import 'registration_management_screen.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/subscription_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import 'bracket_view.dart';
import 'leaderboard_view.dart';
import '../../cricket/ui/cricket_setup_screen.dart';
import '../../volleyball/ui/volleyball_setup_screen.dart';

class TournamentDashboardScreen extends ConsumerStatefulWidget {
  final Tournament tournament;

  const TournamentDashboardScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentDashboardScreen> createState() => _TournamentDashboardScreenState();
}

class _TournamentDashboardScreenState extends ConsumerState<TournamentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int tabCount = widget.tournament.format == TournamentFormat.roundRobin ? 3 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _checkIsOrganizer(Tournament tournament, dynamic user) {
    if (user == null) return false;
    final uid = user.id.toString();
    if (tournament.creatorId.isNotEmpty && tournament.creatorId == uid) return true;
    if (tournament.isManager(uid)) return true;
    return false;
  }

  bool _canScoreMatch(Tournament tournament, TournamentMatch match, dynamic user, bool isOrganizer) {
    if (user == null) return false;
    if (isOrganizer) return true;

    final uid = user.id.toString();
    // 1. If assigned as specific match scorer
    if (match.assignedScorerId != null && match.assignedScorerId!.isNotEmpty) {
      return match.assignedScorerId == uid;
    }

    // 2. If appointed as tournament scorer and no match-level scorer is assigned
    if (tournament.isScorer(uid)) {
      return true;
    }

    // Spectators and unassigned participants cannot score
    return false;
  }

  bool _isMatchReferee(Tournament tournament, TournamentMatch match, dynamic user, bool isOrganizer) {
    if (user == null) return false;
    if (isOrganizer) return true;

    final uid = user.id.toString();
    if (match.assignedRefereeId != null && match.assignedRefereeId!.isNotEmpty) {
      return match.assignedRefereeId == uid;
    }
    return tournament.isReferee(uid);
  }

  Future<void> _updateScore(String tournamentId, String matchId, int scoreA, int scoreB) async {
    final currentUser = ref.read(currentUserProvider);
    final tournament = ref.read(singleTournamentProvider(tournamentId)).value ?? widget.tournament;
    final match = tournament.matches.firstWhere((m) => m.id == matchId);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);

    if (!_canScoreMatch(tournament, match, currentUser, isOrganizer)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission Denied: Only assigned scorers or managers can update scores.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await ref.read(tournamentControllerProvider.notifier).updateMatchScore(
          tournamentId: tournamentId,
          matchId: matchId,
          scoreA: scoreA,
          scoreB: scoreB,
        );
  }

  void _showShareDialog(Tournament tournament) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Share Tournament'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tournament.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${tournament.sportType} • ${tournament.format.displayName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Code for Spectators & Players:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tournament.shareCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tournament.shareCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Share code "${tournament.shareCode}" copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anyone with Sports Turf can enter this code in Tournaments Hub to follow live match scores in real time.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_all),
            label: const Text('Copy Full Invitation'),
            onPressed: () {
              final inviteText = 'Follow live matches for "${tournament.name}" on Sports Turf!\n'
                  'Sport: ${tournament.sportType}\n'
                  'Tournament Code: ${tournament.shareCode}\n'
                  'Open Sports Turf and enter the code to spectate live!';
              Clipboard.setData(ClipboardData(text: inviteText));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tournament invite copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveTournamentAsync = ref.watch(singleTournamentProvider(widget.tournament.id));
    final tournament = liveTournamentAsync.value ?? widget.tournament;

    final currentUser = ref.watch(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tournament.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${tournament.sportType} • ${tournament.format.displayName}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isSub = ref.watch(userSubscriptionsProvider).subscribedTournamentIds.contains(tournament.id);
              return IconButton(
                icon: Icon(isSub ? Icons.bookmark : Icons.bookmark_border),
                tooltip: isSub ? 'Subscribed (Tap to unfollow)' : 'Subscribe to Tournament',
                onPressed: () async {
                  await ref.read(userSubscriptionsProvider.notifier).toggleTournamentSubscription(tournament.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSub
                            ? 'Unsubscribed from ${tournament.name}'
                            : 'Subscribed to ${tournament.name}! It will now appear on your Home dashboard.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Tournament Code',
            onPressed: () => _showShareDialog(tournament),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tournament Operations',
            onSelected: (val) {
              if (val == 'registrations') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegistrationManagementScreen(tournament: tournament)),
                );
              } else if (val == 'disputes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DisputesScreen(tournamentId: tournament.id, tournamentName: tournament.name)),
                );
              } else if (val == 'venues') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VenueManagementScreen(leagueId: tournament.leagueId, leagueName: tournament.leagueName)),
                );
              } else if (val == 'export_fixtures') {
                final csv = ReportExportService.exportFixturesCsv(tournament);
                Share.share(csv, subject: '${tournament.name} Fixtures.csv');
              } else if (val == 'export_participants') {
                final csv = ReportExportService.exportParticipantsCsv(tournament);
                Share.share(csv, subject: '${tournament.name} Participants.csv');
              }
            },
            itemBuilder: (_) => [
              if (isOrganizer) ...[
                const PopupMenuItem(
                  value: 'registrations',
                  child: ListTile(
                    leading: Icon(Icons.people_outline),
                    title: Text('Registrations & Waitlist'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'disputes',
                  child: ListTile(
                    leading: Icon(Icons.gavel_outlined),
                    title: Text('Protests & Disputes'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'venues',
                  child: ListTile(
                    leading: Icon(Icons.stadium_outlined),
                    title: Text('Venues & Courts'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: 'export_fixtures',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Export Fixtures (CSV)'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export_participants',
                child: ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Export Roster (CSV)'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            const Tab(icon: Icon(Icons.list_alt), text: 'Matches'),
            if (tournament.format != TournamentFormat.roundRobin)
              const Tab(icon: Icon(Icons.account_tree), text: 'Bracket'),
            const Tab(icon: Icon(Icons.leaderboard), text: 'Standings'),
            const Tab(icon: Icon(Icons.people_alt_outlined), text: 'Participants'),
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
                        ? 'Organizer Mode: You have full scoring & fixture management rights.'
                        : 'Spectator Mode: Real-time live scoreboard. Scores update automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOrganizer ? Colors.green.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showShareDialog(tournament),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOrganizer ? Colors.green.shade300 : Colors.blue.shade300,
                      ),
                    ),
                    child: Text(
                      tournament.shareCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isOrganizer ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (tournament.isUnderLeague)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'League: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tournament.leagueName ?? 'Multi-Sport League',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final leagueId = tournament.leagueId!;
                      final league = await ref.read(leagueControllerProvider.notifier).findLeagueByCode(leagueId) ??
                          await ref.read(leagueRepositoryProvider).getLeagueById(leagueId);
                      if (league != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeagueDashboardScreen(league: league),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View League Hub',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 14, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(tournament, isOrganizer),
                if (tournament.format != TournamentFormat.roundRobin)
                  BracketView(tournament: tournament),
                LeaderboardView(tournament: tournament),
                _buildParticipantsTab(tournament, isOrganizer),
              ],
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
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 50,
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
        ),
      ),
    );
  }

  Widget _buildMatchList(Tournament tournament, bool isOrganizer) {
    if (tournament.matches.isEmpty) {
      return const Center(child: Text('No matches generated yet.'));
    }

    // Group matches by round
    final rounds = <int, List<TournamentMatch>>{};
    for (var m in tournament.matches) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }

    final sortedRounds = rounds.keys.toList()..sort();

    return ListView.builder(
      padding: NavigationPadding.listInsets(context, horizontal: 12, top: 12),
      itemCount: sortedRounds.length,
      itemBuilder: (context, index) {
        final roundNum = sortedRounds[index];
        final matches = rounds[roundNum]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                _getRoundTitle(tournament.format, roundNum, sortedRounds.length),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ),
            ...matches.map((m) => _buildMatchCard(tournament, m, isOrganizer)),
          ],
        );
      },
    );
  }

  String _getRoundTitle(TournamentFormat format, int round, int totalRounds) {
    if (format == TournamentFormat.roundRobin) {
      return 'Round $round';
    }
    if (round == totalRounds) return 'Final';
    if (round == totalRounds - 1) return 'Semi-Finals';
    if (round == totalRounds - 2) return 'Quarter-Finals';
    return 'Round $round';
  }

  Widget _buildMatchCard(Tournament tournament, TournamentMatch m, bool isOrganizer) {
    final currentUser = ref.watch(currentUserProvider);
    final bool canScore = _canScoreMatch(tournament, m, currentUser, isOrganizer);
    final bool isReferee = _isMatchReferee(tournament, m, currentUser, isOrganizer);
    final bool isCompleted = m.status == MatchStatus.completed;
    final bool isParticipant = currentUser != null && tournament.participantUserIds.contains(currentUser.id);

    Color statusColor;
    switch (m.status) {
      case MatchStatus.completed:
        statusColor = Colors.green;
        break;
      case MatchStatus.live:
        statusColor = Colors.redAccent;
        break;
      case MatchStatus.paused:
        statusColor = Colors.orange;
        break;
      case MatchStatus.walkover:
        statusColor = Colors.purple;
        break;
      case MatchStatus.ready:
        statusColor = Colors.amber.shade800;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Match #${m.matchNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                    ),
                    if (m.assignedScorerId != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text('Scorer Assigned', style: TextStyle(fontSize: 9, color: Colors.blue)),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.status == MatchStatus.live) ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            m.status.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      tooltip: 'Match Actions',
                      onSelected: (val) {
                        if (val == 'score') _showScoreDialog(tournament, m);
                        if (val == 'live_score') _openLiveScorer(tournament, m);
                        if (val == 'pause') _showPauseResumeDialog(tournament, m);
                        if (val == 'walkover') _showWalkoverDialog(tournament, m);
                        if (val == 'officials') _showAssignOfficialsDialog(tournament, m);
                        if (val == 'verify') _showVerifyResultDialog(tournament, m);
                        if (val == 'report') _showMatchReportDialog(tournament, m);
                        if (val == 'protest') _showFileProtestDialog(tournament, m);
                      },
                      itemBuilder: (_) => [
                        if (canScore && !isCompleted)
                          const PopupMenuItem(
                            value: 'score',
                            child: ListTile(
                              leading: Icon(Icons.edit_note),
                              title: Text('Update Score'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (canScore && !isCompleted && (tournament.sportType.toLowerCase() == 'cricket' || tournament.sportType.toLowerCase() == 'volleyball'))
                          PopupMenuItem(
                            value: 'live_score',
                            child: ListTile(
                              leading: const Icon(Icons.scoreboard_outlined, color: Colors.green),
                              title: Text('Live ${tournament.sportType} Scorer'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (canScore && (m.status == MatchStatus.live || m.status == MatchStatus.paused))
                          PopupMenuItem(
                            value: 'pause',
                            child: ListTile(
                              leading: Icon(m.status == MatchStatus.paused ? Icons.play_arrow : Icons.pause),
                              title: Text(m.status == MatchStatus.paused ? 'Resume Match' : 'Pause Match'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (isOrganizer && !isCompleted)
                          const PopupMenuItem(
                            value: 'walkover',
                            child: ListTile(
                              leading: Icon(Icons.flag, color: Colors.purple),
                              title: Text('Record Walkover / Forfeit'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (isOrganizer)
                          const PopupMenuItem(
                            value: 'officials',
                            child: ListTile(
                              leading: Icon(Icons.person_pin),
                              title: Text('Assign Scorer & Referee'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (isReferee && isCompleted)
                          const PopupMenuItem(
                            value: 'verify',
                            child: ListTile(
                              leading: Icon(Icons.verified, color: Colors.green),
                              title: Text('Verify Official Result'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(
                            leading: Icon(Icons.description_outlined),
                            title: Text('Match Report'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (isOrganizer || isParticipant)
                          const PopupMenuItem(
                            value: 'protest',
                            child: ListTile(
                              leading: Icon(Icons.flag_outlined, color: Colors.red),
                              title: Text('File Protest / Dispute'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTeamRow(
                        name: m.participantA?.name ?? 'TBD',
                        score: m.scoreA,
                        isWinner: m.winnerId != null && m.winnerId == m.participantAId,
                        seed: m.participantA?.seed,
                      ),
                      const SizedBox(height: 8),
                      _buildTeamRow(
                        name: m.participantB?.name ?? 'TBD',
                        score: m.scoreB,
                        isWinner: m.winnerId != null && m.winnerId == m.participantBId,
                        seed: m.participantB?.seed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (!isCompleted) ...[
                      if (canScore)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.edit_note),
                          tooltip: 'Quick Score',
                          onPressed: () => _showScoreDialog(tournament, m),
                        )
                      else if (m.status == MatchStatus.live)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        )
                      else
                        const Icon(Icons.schedule, color: Colors.grey, size: 24),
                    ] else
                      const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  ],
                ),
              ],
            ),
            if (m.statusReason != null && m.statusReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: ${m.statusReason}',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                ),
              ),
            ],
            if (m.scheduledTime != null || m.venueCourt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (m.scheduledTime != null) ...[
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(m.scheduledTime!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (m.venueCourt != null) ...[
                    const Icon(Icons.place, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      m.venueCourt!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required int? score,
    required bool isWinner,
    int? seed,
  }) {
    return Row(
      children: [
        if (seed != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$seed',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: isWinner ? Colors.green.shade800 : Colors.black87,
            ),
          ),
        ),
        if (score != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isWinner ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isWinner ? Colors.green.shade900 : Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showScoreDialog(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    final canScore = _canScoreMatch(tournament, match, currentUser, isOrganizer);

    if (!canScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Spectators cannot update match scores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (match.participantAId == null || match.participantBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for both participants to be determined')),
      );
      return;
    }

    final scoreAController = TextEditingController(text: match.scoreA?.toString() ?? '0');
    final scoreBController = TextEditingController(text: match.scoreB?.toString() ?? '0');

    final isTeamGame = tournament.sportType.toLowerCase() == 'cricket' || tournament.sportType.toLowerCase() == 'volleyball';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Match Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreAController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${match.participantA?.name ?? "Participant A"} Score'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scoreBController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${match.participantB?.name ?? "Participant B"} Score'),
            ),
            if (isTeamGame) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.scoreboard_outlined, size: 16),
                label: Text('Open Live ${tournament.sportType} Scorer'),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _openLiveScorer(tournament, match);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sA = int.tryParse(scoreAController.text) ?? 0;
              final sB = int.tryParse(scoreBController.text) ?? 0;
              _updateScore(tournament.id, match.id, sA, sB);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save Score'),
          ),
        ],
      ),
    );
  }

  void _openLiveScorer(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    final canScore = _canScoreMatch(tournament, match, currentUser, isOrganizer);

    if (!canScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Spectators cannot operate live scorer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final sport = tournament.sportType.toLowerCase();
    final teamA = match.participantA?.name ?? 'Team A';
    final teamB = match.participantB?.name ?? 'Team B';

    if (sport == 'cricket') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CricketSetupScreen(
            initialTeamA: teamA,
            initialTeamB: teamB,
            tournamentId: tournament.id,
            matchId: match.id,
          ),
        ),
      );
    } else if (sport == 'volleyball') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VolleyballSetupScreen(
            initialTeamA: teamA,
            initialTeamB: teamB,
            tournamentId: tournament.id,
            matchId: match.id,
          ),
        ),
      );
    }
  }

  void _showPauseResumeDialog(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    if (!_canScoreMatch(tournament, match, currentUser, isOrganizer) && !_isMatchReferee(tournament, match, currentUser, isOrganizer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only assigned scorers, referees, or organizers can pause or resume matches.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isPaused = match.status == MatchStatus.paused;
    final reasonCtrl = TextEditingController(text: match.statusReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPaused ? 'Resume Match #${match.matchNumber}' : 'Pause Match #${match.matchNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isPaused ? 'Resume official match clock and live scoring.' : 'Pause play temporarily for weather, injury, or official review.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: isPaused ? 'Resume Notes (Optional)' : 'Pause Reason *',
                hintText: isPaused ? 'e.g. Weather cleared' : 'e.g. Rain delay, Medical timeout',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedMatches = tournament.matches.map((m) {
                if (m.id == match.id) {
                  return m.copyWith(
                    status: isPaused ? MatchStatus.live : MatchStatus.paused,
                    statusReason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                  );
                }
                return m;
              }).toList();

              await ref.read(tournamentControllerProvider.notifier).updateTournament(
                    tournament.copyWith(matches: updatedMatches),
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isPaused ? 'Match resumed' : 'Match paused')),
                );
              }
            },
            child: Text(isPaused ? 'Resume Play' : 'Pause Play'),
          ),
        ],
      ),
    );
  }

  void _showWalkoverDialog(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    if (!isOrganizer && !_isMatchReferee(tournament, match, currentUser, isOrganizer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only referees and organizers can record walkovers.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (match.participantAId == null || match.participantBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both participants must be determined to record walkover')),
      );
      return;
    }

    String? selectedWinnerId = match.participantAId;
    final reasonCtrl = TextEditingController(text: 'Opponent forfeit / no-show');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (builderCtx, setDialogState) => AlertDialog(
          title: Text('Record Walkover: Match #${match.matchNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select awarded winner:'),
              RadioListTile<String>(
                title: Text(match.participantA?.name ?? 'Team A'),
                value: match.participantAId!,
                groupValue: selectedWinnerId,
                onChanged: (val) => setDialogState(() => selectedWinnerId = val),
              ),
              RadioListTile<String>(
                title: Text(match.participantB?.name ?? 'Team B'),
                value: match.participantBId!,
                groupValue: selectedWinnerId,
                onChanged: (val) => setDialogState(() => selectedWinnerId = val),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Official Reason *',
                  hintText: 'e.g. Failure to field required roster, disqualification',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () async {
                Navigator.pop(ctx);
                final updatedMatches = tournament.matches.map((m) {
                  if (m.id == match.id) {
                    return m.copyWith(
                      status: MatchStatus.walkover,
                      winnerId: selectedWinnerId,
                      statusReason: reasonCtrl.text.trim(),
                    );
                  }
                  return m;
                }).toList();

                await ref.read(tournamentControllerProvider.notifier).updateTournament(
                      tournament.copyWith(matches: updatedMatches),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Walkover recorded and tournament advanced')),
                  );
                }
              },
              child: const Text('Record Walkover'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignOfficialsDialog(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    if (!isOrganizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only tournament organizers can assign officials.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scorerCtrl = TextEditingController(text: match.assignedScorerId ?? '');
    final refereeCtrl = TextEditingController(text: match.assignedRefereeId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Match Officials (#${match.matchNumber})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scorerCtrl,
              decoration: const InputDecoration(
                labelText: 'Scorer User ID / Email',
                hintText: 'UID authorized to operate live scoreboard',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refereeCtrl,
              decoration: const InputDecoration(
                labelText: 'Referee User ID / Email',
                hintText: 'UID authorized to verify outcome & rule disputes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedMatches = tournament.matches.map((m) {
                if (m.id == match.id) {
                  return m.copyWith(
                    assignedScorerId: scorerCtrl.text.trim().isNotEmpty ? scorerCtrl.text.trim() : null,
                    assignedRefereeId: refereeCtrl.text.trim().isNotEmpty ? refereeCtrl.text.trim() : null,
                  );
                }
                return m;
              }).toList();

              await ref.read(tournamentControllerProvider.notifier).updateTournament(
                    tournament.copyWith(matches: updatedMatches),
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Officials assigned to match')),
                );
              }
            },
            child: const Text('Save Officials'),
          ),
        ],
      ),
    );
  }

  void _showVerifyResultDialog(Tournament tournament, TournamentMatch match) {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = _checkIsOrganizer(tournament, currentUser);
    if (!isOrganizer && !_isMatchReferee(tournament, match, currentUser, isOrganizer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only referees and organizers can verify official results.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verify Match #${match.matchNumber} Official Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Score: ${match.participantA?.name ?? "A"} (${match.scoreA ?? 0}) vs ${match.participantB?.name ?? "B"} (${match.scoreB ?? 0})'),
            const SizedBox(height: 8),
            Text('Winner: ${match.winnerId != null ? (tournament.participants.where((p) => p.id == match.winnerId).map((p) => p.name).firstOrNull ?? match.winnerId) : "Pending"}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Referee Sign-off Notes',
                hintText: 'e.g. Conduct verified, scores confirmed by captains',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedMatches = tournament.matches.map((m) {
                if (m.id == match.id) {
                  return m.copyWith(
                    statusReason: 'Verified by official. ${notesCtrl.text.trim()}',
                  );
                }
                return m;
              }).toList();

              await ref.read(tournamentControllerProvider.notifier).updateTournament(
                    tournament.copyWith(matches: updatedMatches),
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Match result officially verified')),
                );
              }
            },
            child: const Text('Verify Result'),
          ),
        ],
      ),
    );
  }

  void _showMatchReportDialog(Tournament tournament, TournamentMatch match) {
    final report = ReportExportService.generateMatchReport(tournament, match);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Match #${match.matchNumber} Official Report'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share Report'),
            onPressed: () {
              Navigator.pop(ctx);
              Share.share(report, subject: '${tournament.name} - Match #${match.matchNumber} Report');
            },
          ),
        ],
      ),
    );
  }

  void _showFileProtestDialog(Tournament tournament, TournamentMatch match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DisputesScreen(
          tournamentId: tournament.id,
          tournamentName: tournament.name,
          leagueId: tournament.leagueId,
          leagueName: tournament.leagueName,
        ),
      ),
    );
  }

  Widget _buildParticipantsTab(Tournament tournament, bool isOrganizer) {
    if (tournament.participants.isEmpty) {
      return const Center(child: Text('No participants found for this tournament.'));
    }

    // Calculate match stats per participant in this tournament
    final Map<String, int> matchesPlayed = {};
    final Map<String, int> wins = {};
    final Map<String, int> losses = {};

    for (final p in tournament.participants) {
      matchesPlayed[p.id] = 0;
      wins[p.id] = 0;
      losses[p.id] = 0;
    }

    for (final m in tournament.matches) {
      if (m.status == MatchStatus.completed) {
        if (m.participantAId != null && matchesPlayed.containsKey(m.participantAId)) {
          matchesPlayed[m.participantAId!] = (matchesPlayed[m.participantAId!] ?? 0) + 1;
        }
        if (m.participantBId != null && matchesPlayed.containsKey(m.participantBId)) {
          matchesPlayed[m.participantBId!] = (matchesPlayed[m.participantBId!] ?? 0) + 1;
        }
        if (m.winnerId != null) {
          wins[m.winnerId!] = (wins[m.winnerId!] ?? 0) + 1;
          final loserId = m.winnerId == m.participantAId ? m.participantBId : m.participantAId;
          if (loserId != null && losses.containsKey(loserId)) {
            losses[loserId] = (losses[loserId] ?? 0) + 1;
          }
        }
      }
    }

    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 12, top: 12),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  tournament.isTeamTournament ? Icons.groups : Icons.person_pin,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tournament.participants.length} Active Participants',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Selected for this ${tournament.sportType} tournament from club & league rosters.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...tournament.participants.map((p) {
          final mp = matchesPlayed[p.id] ?? 0;
          final w = wins[p.id] ?? 0;
          final l = losses[p.id] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '#${p.seed ?? "-"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                'Seed #${p.seed ?? "-"} • $mp Played ($w Won, $l Lost)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: w > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: w > 0 ? Colors.green.shade300 : Colors.grey.shade300),
                ),
                child: Text(
                  '$w W - $l L',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: w > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
