import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';
import '../core/models/match_result.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  String? _selectedSport; // null = All
  late Future<List<MatchResult>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    setState(() {
      _matchesFuture = DatabaseHelper.instance.getMatches(sport: _selectedSport);
    });
  }

  Future<void> _deleteMatch(int id, int index) async {
    // Optimistic UI update not strictly needed as we reload list from DB or snapshot, 
    // but Swipe Dismiss removes item from UI immediately so we must handle DB async
    await DatabaseHelper.instance.deleteMatch(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Match deleted")),
    );
    // Don't need _loadMatches() if we trust Swipe removal, 
    // but better to reload to stay in sync or removal logic from list.
    // If we use FutureBuilder, we need to refresh connection.
    _loadMatches();
  }

  Future<void> _confirmDeleteAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All History?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteAllMatches();
      _loadMatches();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All matches deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Scorecard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmDeleteAll,
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, "All"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Badminton", "Badminton"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Volleyball", "Volleyball"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Tennis", "Tennis"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Table Tennis", "Table Tennis"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Cricket", "Cricket"),
                ],
              ),
            ),
          ),
          
          // List Section
          Expanded(
            child: FutureBuilder<List<MatchResult>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "No matches found.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final matches = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Dismissible(
                      key: Key(match.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) {
                        _deleteMatch(match.id!, index);
                      },
                      child: _buildMatchCard(match),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? value, String label) {
    bool isSelected = _selectedSport == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedSport = value;
        });
        _loadMatches();
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.deepPurple,
    );
  }

  Widget _buildMatchCard(MatchResult match) {
    IconData sportIcon;
    Color sportColor;
    
    switch (match.sport.toLowerCase()) {
      case 'badminton':
        sportIcon = Icons.sports_tennis; // Shuttlecock proxy
        sportColor = Colors.green;
        break;
      case 'volleyball':
        sportIcon = Icons.sports_volleyball;
        sportColor = Colors.orange;
        break;
      case 'tennis':
        sportIcon = Icons.sports_tennis;
        sportColor = Colors.lightGreen;
        break;
      case 'table tennis':
        sportIcon = Icons.sports_baseball; // Placeholder
        sportColor = Colors.blue;
        break;
      case 'cricket':
        sportIcon = Icons.sports_cricket;
        sportColor = Colors.blueAccent;
        break;
      default:
        sportIcon = Icons.sports;
        sportColor = Colors.blue;
    }

    final dateFormat = DateFormat('MMM d, y • h:mm a');
    
    // Parse Details for Set History
    List<dynamic> setHistory = [];
    String finalScoreText = "Score: ${match.scoreA} - ${match.scoreB}";

    try {
      final details = jsonDecode(match.details);
      if (details is Map && details.containsKey('setHistory')) {
         setHistory = details['setHistory'] as List<dynamic>;
      }
      
      // Special case for Cricket
      if (match.sport.toLowerCase() == 'cricket' && details.containsKey('finalScore')) {
        finalScoreText = "Score: ${details['finalScore']}";
      }
    } catch (e) {
      // ignore
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sportColor.withOpacity(0.1),
          child: Icon(sportIcon, color: sportColor),
        ),
        title: Text(
          "${match.teamA} vs ${match.teamB}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(dateFormat.format(match.date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
             const SizedBox(height: 4),
             Text(
               finalScoreText,
               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
             ),
             if (setHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 4,
                    children: setHistory.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(s.toString(), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    )).toList(),
                  ),
                ),
             Text(
               "Winner: ${match.winner}",
               style: TextStyle(color: sportColor, fontWeight: FontWeight.w500, fontSize: 13),
             ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
