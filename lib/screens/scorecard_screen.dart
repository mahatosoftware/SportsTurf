import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../core/models/match_result.dart';
import '../core/widgets/bottom_navigation_padding.dart';
import '../core/providers/match_providers.dart';
import '../features/cricket/ui/cricket_stats_screen.dart';
import '../features/cricket/models/cricket_match_state.dart';

class ScorecardScreen extends ConsumerStatefulWidget {
  const ScorecardScreen({super.key});

  @override
  ConsumerState<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends ConsumerState<ScorecardScreen> {
  String? _selectedSport; // null = All

  Future<void> _deleteMatch(String id) async {
    await ref.read(matchControllerProvider.notifier).deleteMatch(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Match deleted")),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All History?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(matchControllerProvider.notifier).deleteAllMatches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All matches deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesStreamProvider(_selectedSport));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Scorecard"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete all history",
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
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
            child: matchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error: $error'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.refresh(matchesStreamProvider(_selectedSport)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (matches) {
                if (matches.isEmpty) {
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

                return ListView.builder(
                  padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Dismissible(
                      key: Key(match.id ?? index.toString()),
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
                        if (match.id != null) {
                          _deleteMatch(match.id!);
                        }
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
      ),
    );
  }

  Widget _buildFilterChip(String? value, String label) {
    bool isSelected = _selectedSport == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSport = value;
        });
      },
      selectedColor: const Color(0xFF1B5E20).withAlpha(40),
      checkmarkColor: const Color(0xFF1B5E20),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMatchCard(MatchResult match) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (match.sport == "Cricket") {
            try {
              final Map<String, dynamic> data = jsonDecode(match.details);
              if (data.containsKey('cricket_state')) {
                final state = CricketMatchState.fromMap(data['cricket_state']);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CricketStatsScreen(state: state)),
                );
              }
            } catch (_) {}
          }
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSportColor(match.sport).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      match.sport.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getSportColor(match.sport),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(match.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.teamA,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: match.winner == match.teamA ? Colors.green : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.teamB,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: match.winner == match.teamB ? Colors.green : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${match.scoreA}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: match.winner == match.teamA ? Colors.green : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${match.scoreB}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: match.winner == match.teamB ? Colors.green : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Winner: ${match.winner}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDetailsText(match),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsText(MatchResult match) {
    if (match.sport == "Badminton" || match.sport == "Table Tennis" || match.sport == "Tennis" || match.sport == "Volleyball") {
      try {
        final Map<String, dynamic> data = jsonDecode(match.details);
        if (data.containsKey('setScores')) {
          final List sets = data['setScores'];
          return Text(
            sets.join(" | "),
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          );
        }
      } catch (_) {}
    } else if (match.sport == "Cricket") {
      try {
        final Map<String, dynamic> data = jsonDecode(match.details);
        if (data.containsKey('finalScore')) {
          return Text(
            data['finalScore'],
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          );
        }
      } catch (_) {}
    }
    return const SizedBox.shrink();
  }

  Color _getSportColor(String sport) {
    switch (sport) {
      case 'Badminton':
        return Colors.blue;
      case 'Volleyball':
        return Colors.orange;
      case 'Tennis':
        return Colors.green;
      case 'Table Tennis':
        return Colors.purple;
      case 'Cricket':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
