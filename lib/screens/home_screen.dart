import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/coin_toss/coin_toss_screen.dart';
import '../features/tennis/ui/tennis_setup_screen.dart';
import '../features/badminton/ui/badminton_setup_screen.dart';
import '../features/table_tennis/ui/table_tennis_setup_screen.dart';
import '../features/cricket/ui/cricket_setup_screen.dart';
import '../features/volleyball/ui/volleyball_setup_screen.dart';
import '../features/players/players_screen.dart';
import '../features/teams/ui/teams_screen.dart';
import '../features/tournament/models/tournament.dart';
import '../features/tournament/providers/tournament_providers.dart';
import '../features/tournament/ui/tournament_setup_screen.dart';
import '../features/tournament/ui/tournament_dashboard_screen.dart';
import '../features/tournament/ui/tournament_history_screen.dart';
import '../features/league/models/league.dart';
import '../features/league/providers/league_providers.dart';
import '../features/league/ui/league_setup_screen.dart';
import '../features/league/ui/league_dashboard_screen.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/profile_screen.dart';
import '../core/providers/auth_providers.dart';
import '../core/providers/subscription_providers.dart';
import '../core/widgets/bottom_navigation_padding.dart';
import 'scorecard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _leagueFilterIndex = 0; // 0: My Leagues, 1: Discover Public
  int _tournamentFilterIndex = 0; // 0: My Tournaments, 1: Live & Explore

  void _showJoinCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Enter Share Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter tournament code (e.g. TURF-7A9K) or league code (e.g. LEAGUE-8X2M) to view live matches, brackets, and standings.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Code (Tournament or League)',
                  hintText: 'TURF-XXXX or LEAGUE-XXXX',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSearching
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) return;

                      setDialogState(() => isSearching = true);
                      try {
                        // First check tournaments
                        final tournament = await ref
                            .read(tournamentControllerProvider.notifier)
                            .findTournamentByCode(code);

                        if (tournament != null) {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDashboardScreen(tournament: tournament),
                            ),
                          );
                          return;
                        }

                        // Then check leagues
                        final league = await ref
                            .read(leagueControllerProvider.notifier)
                            .findLeagueByCode(code);

                        if (league != null) {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeagueDashboardScreen(league: league),
                            ),
                          );
                          return;
                        }

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No tournament or league found with code "$code"'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSearching = false);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('VIEW HUB'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, size: 20, color: Color(0xFFFFD54F)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sports Turf',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: user == null
                ? TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.initials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              user.displayTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTournamentDashboardTab(context),
          _buildQuickScoringTab(context),
          _buildTeamsAndPlayersTab(context),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events, color: Color(0xFF2E7D32)),
            label: 'Tournaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_score_outlined),
            selectedIcon: Icon(Icons.sports_score, color: Color(0xFF2E7D32)),
            label: 'Quick Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: Color(0xFF2E7D32)),
            label: 'Rosters',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: Modern Tournament Dashboard
  // ---------------------------------------------------------------------------
  Widget _buildTournamentDashboardTab(BuildContext context) {
    final myTournamentsAsync = ref.watch(myTournamentsProvider);
    final allTournamentsAsync = ref.watch(tournamentsListProvider);
    final tournamentsAsync = _tournamentFilterIndex == 0 ? myTournamentsAsync : allTournamentsAsync;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner & Quick Actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tournament Management Hub',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Organize, Compete & Spectate Live',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Hero Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20), size: 18),
                        label: const Text(
                          'Tournament',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TournamentSetupScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                        label: const Text(
                          'Host League',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white54, width: 1.2),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LeagueSetupScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.vpn_key_outlined, color: Colors.white, size: 16),
                        label: const Text(
                          'Code',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showJoinCodeDialog(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Leagues Section
          _buildLeaguesSection(context),

          const SizedBox(height: 20),

          // Tournaments Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tournaments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TournamentHistoryScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          // Segmented filter chips: "My Tournaments" vs "Live & Explore"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('My Tournaments'),
                  selected: _tournamentFilterIndex == 0,
                  selectedColor: const Color(0xFF1B5E20),
                  labelStyle: TextStyle(
                    color: _tournamentFilterIndex == 0 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _tournamentFilterIndex = 0);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Live & Explore'),
                  selected: _tournamentFilterIndex == 1,
                  selectedColor: const Color(0xFF1B5E20),
                  labelStyle: TextStyle(
                    color: _tournamentFilterIndex == 1 ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _tournamentFilterIndex = 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          tournamentsAsync.when(
            loading: () {
              final existing = tournamentsAsync.value;
              if (existing != null && existing.isNotEmpty) {
                final active = _tournamentFilterIndex == 0
                    ? existing.where((t) => t.status != TournamentStatus.completed && t.status != TournamentStatus.archived).toList()
                    : existing.where((t) => t.status == TournamentStatus.inProgress || t.status == TournamentStatus.draft || t.status == TournamentStatus.registrationOpen).toList();
                if (active.isNotEmpty) {
                  return SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: active.length,
                      itemBuilder: (context, index) => _buildTournamentCarouselCard(context, active[index]),
                    ),
                  );
                }
              }
              return _buildEmptyTournamentsCard(context, isMyTournaments: _tournamentFilterIndex == 0);
            },
            error: (err, _) {
              final existing = tournamentsAsync.value;
              if (existing != null && existing.isNotEmpty) {
                final active = _tournamentFilterIndex == 0
                    ? existing.where((t) => t.status != TournamentStatus.completed && t.status != TournamentStatus.archived).toList()
                    : existing.where((t) => t.status == TournamentStatus.inProgress || t.status == TournamentStatus.draft || t.status == TournamentStatus.registrationOpen).toList();
                if (active.isNotEmpty) {
                  return SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: active.length,
                      itemBuilder: (context, index) => _buildTournamentCarouselCard(context, active[index]),
                    ),
                  );
                }
              }
              return _buildEmptyTournamentsCard(context, isMyTournaments: _tournamentFilterIndex == 0);
            },
            data: (tournaments) {
              final activeTournaments = _tournamentFilterIndex == 0
                  ? tournaments.where((t) => t.status != TournamentStatus.completed && t.status != TournamentStatus.archived).toList()
                  : tournaments.where((t) => t.status == TournamentStatus.inProgress || t.status == TournamentStatus.draft || t.status == TournamentStatus.registrationOpen).toList();

              if (activeTournaments.isEmpty) {
                return _buildEmptyTournamentsCard(context, isMyTournaments: _tournamentFilterIndex == 0);
              }

              return SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeTournaments.length,
                  itemBuilder: (context, index) {
                    final t = activeTournaments[index];
                    return _buildTournamentCarouselCard(context, t);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Match Setup Shortcuts (Preserving existing sport scorings)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Match Scorers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('All Sports'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    title: 'Badminton',
                    subtitle: '21-pt rally score',
                    icon: Icons.sports_tennis_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BadmintonSetupScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    title: 'Tennis Score',
                    subtitle: 'Sets, games & adv',
                    icon: Icons.sports_tennis,
                    color: Colors.lightGreen.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TennisSetupScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    title: 'Cricket Scorer',
                    subtitle: 'Runs, overs & wickets',
                    icon: Icons.sports_cricket,
                    color: Colors.blue.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CricketSetupScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    title: 'Coin Toss',
                    subtitle: 'Heads or Tails',
                    icon: Icons.monetization_on,
                    color: Colors.amber.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CoinTossScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildAdBannerSlot(),
          const BottomNavSpacing.scroll(),
        ],
      ),
    );
  }

  Widget _buildLeaguesSection(BuildContext context) {
    final myLeaguesAsync = ref.watch(myLeaguesProvider);
    final publicLeaguesAsync = ref.watch(publicLeaguesProvider);
    final leaguesAsync = _leagueFilterIndex == 0 ? myLeaguesAsync : publicLeaguesAsync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium, size: 22, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Text(
                    'Multi-Sport Leagues',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Setup League'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeagueSetupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        // Segmented filter chips: "My Leagues" vs "Discover Public"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('My Leagues'),
                selected: _leagueFilterIndex == 0,
                selectedColor: const Color(0xFF1B5E20),
                labelStyle: TextStyle(
                  color: _leagueFilterIndex == 0 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) setState(() => _leagueFilterIndex = 0);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Discover Public'),
                selected: _leagueFilterIndex == 1,
                selectedColor: const Color(0xFF1B5E20),
                labelStyle: TextStyle(
                  color: _leagueFilterIndex == 1 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) setState(() => _leagueFilterIndex = 1);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        leaguesAsync.when(
          loading: () {
            final existing = leaguesAsync.value;
            if (existing != null && existing.isNotEmpty) {
              return SizedBox(
                height: 168,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: existing.length,
                  itemBuilder: (context, index) {
                    final league = existing[index];
                    return _buildLeagueCard(context, league);
                  },
                ),
              );
            }
            return _buildEmptyLeaguesCard(context, isMyLeagues: _leagueFilterIndex == 0);
          },
          error: (err, _) {
            final existing = leaguesAsync.value;
            if (existing != null && existing.isNotEmpty) {
              return SizedBox(
                height: 168,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: existing.length,
                  itemBuilder: (context, index) {
                    final league = existing[index];
                    return _buildLeagueCard(context, league);
                  },
                ),
              );
            }
            return _buildEmptyLeaguesCard(context, isMyLeagues: _leagueFilterIndex == 0);
          },
          data: (leagues) {
            if (leagues.isEmpty) {
              return _buildEmptyLeaguesCard(context, isMyLeagues: _leagueFilterIndex == 0);
            }

            return SizedBox(
              height: 168,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: leagues.length,
                itemBuilder: (context, index) {
                  final league = leagues[index];
                  return _buildLeagueCard(context, league);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyLeaguesCard(BuildContext context, {bool isMyLeagues = false}) {
    if (isMyLeagues) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.workspace_premium_outlined, color: Colors.amber.shade800, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No Subscribed Leagues Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You are not participating in or subscribed to any leagues.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showJoinCodeDialog(context),
                  icon: const Icon(Icons.vpn_key_outlined, size: 14),
                  label: const Text('Join Code', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _leagueFilterIndex = 1),
                  child: const Text('Explore Public', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeagueSetupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Host League', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium_outlined, color: Colors.amber.shade800, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No Leagues Hosted Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Group individual tournaments under one umbrella league.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeagueSetupScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Setup', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueCard(BuildContext context, League league) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Card(
        elevation: 2.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeagueDashboardScreen(league: league)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 12, color: Colors.amber.shade900),
                          const SizedBox(width: 4),
                          Text(
                            'LEAGUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            league.shareCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            final isSub = ref.read(userSubscriptionsProvider).subscribedLeagueIds.contains(league.id);
                            await ref.read(userSubscriptionsProvider.notifier).toggleLeagueSubscription(league.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isSub
                                      ? 'Unsubscribed from ${league.name}'
                                      : 'Subscribed to ${league.name}!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Consumer(
                            builder: (context, ref, _) {
                              final isSub = ref.watch(userSubscriptionsProvider).subscribedLeagueIds.contains(league.id);
                              return Icon(
                                isSub ? Icons.bookmark : Icons.bookmark_border,
                                size: 18,
                                color: isSub ? Colors.amber.shade900 : Colors.grey.shade500,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  league.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  league.sportTypes.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_outlined, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${league.tournamentsCount} Tournaments',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Hub',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 14, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTournamentsCard(BuildContext context, {bool isMyTournaments = false}) {
    if (isMyTournaments) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No Subscribed Tournaments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'You have not joined, managed, or subscribed to any tournaments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.vpn_key_outlined, size: 16),
                  label: const Text('Enter Code'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showJoinCodeDialog(context),
                ),
                TextButton(
                  onPressed: () => setState(() => _tournamentFilterIndex = 1),
                  child: const Text('Explore Live Matches'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TournamentSetupScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No Active Tournaments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first tournament or join with a share code to follow matches.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TournamentSetupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCarouselCard(BuildContext context, Tournament t) {
    final completed = t.matches.where((m) => m.status.name == 'completed').length;
    final total = t.matches.length;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TournamentDashboardScreen(tournament: t)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.sportType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Share Code Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            t.shareCode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            final isSub = ref.read(userSubscriptionsProvider).subscribedTournamentIds.contains(t.id);
                            await ref.read(userSubscriptionsProvider.notifier).toggleTournamentSubscription(t.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isSub
                                      ? 'Unsubscribed from ${t.name}'
                                      : 'Subscribed to ${t.name}!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Consumer(
                            builder: (context, ref, _) {
                              final isSub = ref.watch(userSubscriptionsProvider).subscribedTournamentIds.contains(t.id);
                              return Icon(
                                isSub ? Icons.bookmark : Icons.bookmark_border,
                                size: 18,
                                color: isSub ? const Color(0xFF1B5E20) : Colors.grey.shade500,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (t.isUnderLeague)
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, size: 11, color: Colors.amber.shade900),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            t.leagueName ?? 'League Tournament',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '${t.format.displayName} • ${t.participants.length} Teams',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('$completed/$total Matches', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Standalone Scoring Utilities
  // ---------------------------------------------------------------------------
  Widget _buildQuickScoringTab(BuildContext context) {
    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
      children: [
        const Text(
          'Individual Match Scorers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Score standalone friendly matches without setting up a full tournament.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),

        _buildScoringCard(
          context,
          title: 'Badminton',
          description: 'Official 21-point rally scoring, deuce detection, and court change tracker.',
          icon: Icons.sports_tennis_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BadmintonSetupScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Tennis Score',
          description: 'Full tennis scoring system with sets, games, tie-breaks, and server rotation.',
          icon: Icons.sports_tennis,
          color: Colors.lightGreen.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TennisSetupScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Cricket Scorer',
          description: 'Comprehensive ball-by-ball cricket scoring with overs, wickets, and extras.',
          icon: Icons.sports_cricket,
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CricketSetupScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Table Tennis',
          description: '11-point table tennis scoring with 2-serve rotation and expediting system.',
          icon: Icons.sports_baseball,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TableTennisSetupScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Volleyball',
          description: '25-point set scoring with rotation tracking, deuces, and substitutions.',
          icon: Icons.sports_volleyball,
          color: Colors.amber.shade800,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VolleyballSetupScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Coin Toss',
          description: 'Fair digital coin toss for match start decision.',
          icon: Icons.monetization_on,
          color: Colors.orange.shade800,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoinTossScreen()),
          ),
        ),
        _buildScoringCard(
          context,
          title: 'Scorecard History',
          description: 'Review saved scorecards and match archives.',
          icon: Icons.assignment_outlined,
          color: Colors.blueGrey,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScorecardScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildScoringCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Rosters (Teams & Players)
  // ---------------------------------------------------------------------------
  Widget _buildTeamsAndPlayersTab(BuildContext context) {
    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 20, top: 20),
      children: [
        const Text(
          'Roster & Participant Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage teams, squad members, seedings, and individual player profiles.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.groups, color: Colors.indigo.shade700, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Teams & Squads',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create and manage club teams, squads, and member rosters.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayersScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_alt, color: Colors.teal.shade700, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Players Database',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Register individual players, contact info, and assign seed numbers.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
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
}
