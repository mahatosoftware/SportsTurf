import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/volleyball_state_machine.dart';
import '../models/volleyball_match_state.dart';
import 'volleyball_court_painter.dart';
import 'dart:convert';
import '../../../core/providers/match_providers.dart';
import '../../../core/models/match_result.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../tournament/models/match.dart';

class VolleyballScoreScreen extends ConsumerStatefulWidget {
  final String teamAName;
  final String teamBName;
  final int setsToWin;
  final int pointsPerSet;
  final String? tournamentId;
  final String? matchId;

  const VolleyballScoreScreen({
    super.key,
    this.teamAName = "Team A",
    this.teamBName = "Team B",
    this.setsToWin = 3,
    this.pointsPerSet = 25,
    this.tournamentId,
    this.matchId,
  });

  @override
  ConsumerState<VolleyballScoreScreen> createState() => _VolleyballScoreScreenState();
}

class _VolleyballScoreScreenState extends ConsumerState<VolleyballScoreScreen> {
  late VolleyballStateMachine _stateMachine;

  @override
  void initState() {
    super.initState();
    _stateMachine = VolleyballStateMachine(
      teamAName: widget.teamAName,
      teamBName: widget.teamBName,
      setsToWin: widget.setsToWin,
      pointsPerSet: widget.pointsPerSet,
    );
  }

  void _scorePoint(VolleyballTeam team) {
    setState(() {
      _stateMachine.scorePoint(team);
    });
  }

  void _undo() {
    setState(() {
      _stateMachine.undo();
    });
  }

  void _reset() {
    setState(() {
      _stateMachine.reset();
    });
  }

  Future<void> _saveMatch() async {
    final state = _stateMachine.state;
    if (!state.isMatchComplete) return;

    final result = MatchResult(
      sport: 'Volleyball',
      date: DateTime.now(),
      teamA: widget.teamAName,
      teamB: widget.teamBName,
      scoreA: state.setsWonA, // For Volleyball, match score is Sets won? Or total points? Standard is Sets.
      scoreB: state.setsWonB,
      winner: state.matchWinner == VolleyballTeam.teamA ? widget.teamAName : widget.teamBName,
      details: jsonEncode({
        'setsWonA': state.setsWonA,
        'setsWonB': state.setsWonB,
        'setHistory': state.setHistory,
      }),
    );

    await ref.read(matchControllerProvider.notifier).saveMatch(result);

    if (widget.tournamentId != null && widget.matchId != null) {
      try {
        final currentUser = ref.read(currentUserProvider);
        final tourney = await ref.read(tournamentRepositoryProvider).getTournamentById(widget.tournamentId!);
        final match = tourney?.matches.where((m) => m.id == widget.matchId).firstOrNull;
        final isOrganizer = currentUser != null && tourney != null && (currentUser.isSuperAdmin || tourney.creatorId == currentUser.id || tourney.isManager(currentUser.id));
        final canScore = isOrganizer || (currentUser != null && ((match != null && match.assignedScorerId == currentUser.id) || (tourney != null && tourney.isScorer(currentUser.id))));

        if (!canScore) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission Denied: Spectators cannot submit tournament match scores.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final winnerId = state.matchWinner == VolleyballTeam.teamA ? widget.teamAName : widget.teamBName;
        await ref.read(tournamentRepositoryProvider).updateMatchScore(
          widget.tournamentId!,
          widget.matchId!,
          state.setsWonA,
          state.setsWonB,
          winnerId,
        );
        await ref.read(tournamentRepositoryProvider).updateMatchStatus(
          widget.tournamentId!,
          widget.matchId!,
          MatchStatus.completed,
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Match Result Saved!")),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _stateMachine.state;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Volleyball Scorer'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _stateMachine.canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Confirm reset
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Reset Match?'),
                  content: const Text('This will clear all scores.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _reset();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Court Background
              Center(
                child: CustomPaint(
                  size: Size(w, h),
                  painter: VolleyballCourtPainter(
                    isTeamAServing: state.servingTeam == VolleyballTeam.teamA,
                    isTeamBServing: state.servingTeam == VolleyballTeam.teamB,
                  ),
                ),
              ),

              // 2. Team A Zone (Top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h / 2,
                child: _buildTeamZone(
                  teamName: widget.teamAName,
                  score: state.scoreA,
                  sets: state.setsWonA,
                  isServing: state.servingTeam == VolleyballTeam.teamA,
                  onTap: () => _scorePoint(VolleyballTeam.teamA),
                  isRotated: true,
                  color: Colors.redAccent,
                ),
              ),

              // 3. Team B Zone (Bottom)
              Positioned(
                top: h / 2,
                left: 0,
                right: 0,
                height: h / 2,
                child: _buildTeamZone(
                  teamName: widget.teamBName,
                  score: state.scoreB,
                  sets: state.setsWonB,
                  isServing: state.servingTeam == VolleyballTeam.teamB,
                  onTap: () => _scorePoint(VolleyballTeam.teamB),
                  isRotated: false,
                  color: Colors.blueAccent,
                ),
              ),

              // 4. Set Info (Centered)
              Positioned(
                top: h / 2 - 20,
                left: 20,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Set ${state.currentSet}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              
              // 5. Match Winner Overlay
              if (state.isMatchComplete)
                Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${state.matchWinner == VolleyballTeam.teamA ? widget.teamAName : widget.teamBName} Wins!",
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reset,
                          child: const Text("New Match"),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _saveMatch,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Result"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildTeamZone({
    required String teamName,
    required int score,
    required int sets,
    required bool isServing,
    required VoidCallback onTap,
    required bool isRotated,
    required Color color,
  }) {
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent, // Ensures hit testing catches touches ANYWHERE inside the entire court half
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreRow(teamName, score, sets, isServing, color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String name, int score, int sets, bool isServing, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Serve Indicator
        if (isServing) 
           const Padding(
             padding: EdgeInsets.only(right: 12),
             child: Icon(Icons.sports_volleyball, color: Colors.yellow, size: 32),
           )
        else
           const SizedBox(width: 44), // Placeholder

        Column(
          children: [
            Text(
              name,
              style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              "$score",
              style: TextStyle(color: color, fontSize: 80, fontWeight: FontWeight.bold),
            ),
            Text(
              "Sets: $sets",
              style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        
         const SizedBox(width: 44), // Symmetry
      ],
    );
  }
}
