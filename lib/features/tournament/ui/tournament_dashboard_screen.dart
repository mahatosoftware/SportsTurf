import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tournament.dart';
import '../models/match.dart';
import '../logic/tournament_manager.dart';
import 'bracket_view.dart';
import 'leaderboard_view.dart';
import '../../../../core/database/database_helper.dart';

class TournamentDashboardScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDashboardScreen({super.key, required this.tournament});

  @override
  State<TournamentDashboardScreen> createState() =>
      _TournamentDashboardScreenState();
}

class _TournamentDashboardScreenState extends State<TournamentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Tournament _tournament;
  late TournamentManager _manager;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _manager = TournamentManager(_tournament);
    
    // Determine tabs based on format
    int tabCount = 2; // Matches, Standings default
    if (_tournament.format != TournamentFormat.roundRobin) {
      tabCount = 3; // + Bracket
    }
    _tabController = TabController(length: tabCount, vsync: this);
  }

  Future<void> _updateScore(String matchId, int scoreA, int scoreB) async {
    setState(() {
      _tournament = _manager.updateMatch(matchId, scoreA, scoreB);
      _manager = TournamentManager(_tournament);
    });
    
    await DatabaseHelper.instance.updateTournament(_tournament);
  }

  Future<void> _updateSchedule(String matchId, DateTime scheduledTime) async {
    setState(() {
      _tournament = _manager.updateMatchSchedule(matchId, scheduledTime);
      _manager = TournamentManager(_tournament);
    });
    
    await DatabaseHelper.instance.updateTournament(_tournament);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_tournament.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate to Home (which is root, but since we pushedAndRemoveUntil, we might need to push Home or pop until root if possible)
              // Since pushAndRemoveUntil cleared stack, we should just push Home or PushReplacement Home.
              // Ideally, we restart app or go to initial route.
              // Let's assume HomeScreen is the main entry.
              Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
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
            const Tab(text: 'Matches'),
            if (_tournament.format != TournamentFormat.roundRobin)
              const Tab(text: 'Bracket'),
            const Tab(text: 'Standings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchList(),
          if (_tournament.format != TournamentFormat.roundRobin)
             BracketView(tournament: _tournament),
          LeaderboardView(tournament: _tournament),
        ],
      ),
    );
  }

  Widget _buildMatchList() {
    // Group by round
    // But for list view, maybe just flat list or grouped.
    // Let's filter by round.
    
    // Convert matches to map group by Round
    Map<int, List<TournamentMatch>> byRound = {};
    for (var m in _tournament.matches) {
       byRound.putIfAbsent(m.round, () => []).add(m);
    }
    
    List<int> rounds = byRound.keys.toList()..sort();

    return ListView.builder(
      itemCount: rounds.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        int r = rounds[index];
        List<TournamentMatch> matches = byRound[r]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Round $r',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...matches.map((m) {
              String subtitle = m.status == MatchStatus.completed
                  ? 'Score: ${m.scoreA} - ${m.scoreB}'
                  : 'Upcoming';
              
              if (m.scheduledTime != null) {
                subtitle += "\n${DateFormat('MMM d, h:mm a').format(m.scheduledTime!)}";
              }

              return Card(
                child: ListTile(
                  title: Text(
                    '${m.participantA?.name ?? "TBD"} vs ${m.participantB?.name ?? "TBD"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitle),
                  isThreeLine: m.scheduledTime != null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (m.status != MatchStatus.completed)
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.blue),
                          onPressed: () => _showScheduleDialog(m),
                        ),
                       if (m.status != MatchStatus.completed)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showScoreDialog(m),
                        )
                      else
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showScoreDialog(TournamentMatch match) {
    if (match.participantAId == null || match.participantBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for participants to be determined')),
      );
      return;
    }

    final scoreAController = TextEditingController();
    final scoreBController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreAController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${match.participantA?.name} Score'),
            ),
            TextField(
              controller: scoreBController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${match.participantB?.name} Score'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sA = int.tryParse(scoreAController.text) ?? 0;
              final sB = int.tryParse(scoreBController.text) ?? 0;
              
              _updateScore(match.id, sA, sB);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleDialog(TournamentMatch match) async {
    final now = DateTime.now();
    final initialDate = match.scheduledTime ?? now;
    final initialTime = TimeOfDay.fromDateTime(initialDate);

    // Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      // Pick Time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _updateSchedule(match.id, finalDateTime);
      }
    }
  }
}
