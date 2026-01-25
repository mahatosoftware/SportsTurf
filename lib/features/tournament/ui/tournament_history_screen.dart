import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../models/tournament.dart';
import 'tournament_dashboard_screen.dart';

class TournamentHistoryScreen extends StatefulWidget {
  const TournamentHistoryScreen({super.key});

  @override
  State<TournamentHistoryScreen> createState() => _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends State<TournamentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _sports = ['Tennis', 'Badminton', 'Table Tennis', 'Cricket', 'Volleyball', 'Football', 'Basketball', 'Other'];
  
  // Cache tournaments
  Map<String, List<Tournament>> _tournamentsBySport = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sports.length, vsync: this);
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoading = true);
    final allTournaments = await DatabaseHelper.instance.getTournaments();
    
    _tournamentsBySport = {};
    for (var sport in _sports) {
      _tournamentsBySport[sport] = allTournaments.where((t) => t.sportType == sport).toList();
    }
    
    // Also handle unexpected sports
    final otherSports = allTournaments.where((t) => !_sports.contains(t.sportType)).toList();
    if (otherSports.isNotEmpty) {
      _tournamentsBySport['Other'] = [...(_tournamentsBySport['Other'] ?? []), ...otherSports];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Update Tournaments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _sports.map((s) => Tab(text: s)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _sports.map((sport) => _buildTournamentList(sport)).toList(),
            ),
    );
  }

  Widget _buildTournamentList(String sport) {
    final tournaments = _tournamentsBySport[sport] ?? [];
    
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $sport tournaments yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDashboardScreen(tournament: tournament),
                ),
              );
              _loadTournaments(); // Refresh on return in case of updates
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(tournament.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                     children: [
                       const Icon(Icons.people, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text('${tournament.participants.length} Teams'),
                       const SizedBox(width: 16),
                       const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(_formatDate(tournament.createdAt)),
                     ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Format: ${tournament.format.name.toUpperCase()}',
                     style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(TournamentStatus status) {
    Color color;
    switch (status) {
      case TournamentStatus.setup:
        color = Colors.orange;
        break;
      case TournamentStatus.ongoing:
        color = Colors.blue;
        break;
      case TournamentStatus.completed:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
