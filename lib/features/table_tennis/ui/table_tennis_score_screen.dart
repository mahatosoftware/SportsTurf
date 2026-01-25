import 'package:flutter/material.dart';
import '../models/table_tennis_match_state.dart';
import '../logic/table_tennis_state_machine.dart';
import 'table_tennis_court_card.dart';
import 'dart:convert';
import '../../../core/database/database_helper.dart';
import '../../../core/models/match_result.dart';

class TableTennisScoreScreen extends StatefulWidget {
  final TTMatchType matchType;
  final String playerA1;
  final String playerA2;
  final String playerB1;
  final String playerB2;
  final int setsToWin;

  const TableTennisScoreScreen({
    super.key,
    this.matchType = TTMatchType.singles,
    this.playerA1 = "Player A",
    this.playerA2 = "",
    this.playerB1 = "Player B",
    this.playerB2 = "",
    required this.setsToWin,
  });

  @override
  State<TableTennisScoreScreen> createState() => _TableTennisScoreScreenState();
}

class _TableTennisScoreScreenState extends State<TableTennisScoreScreen> {
  late TableTennisStateMachine _machine;

  @override
  void initState() {
    super.initState();
    _machine = TableTennisStateMachine(
      matchType: widget.matchType,
      playerA1Name: widget.playerA1,
      playerA2Name: widget.playerA2,
      playerB1Name: widget.playerB1,
      playerB2Name: widget.playerB2,
      gamesToWin: widget.setsToWin,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showServeSelectionDialog();
    });
  }

  void _update() => setState(() {});

  Future<void> _saveMatch() async {
    final state = _machine.state;
    if (!state.isMatchComplete) return;

    final String teamA = state.matchType == TTMatchType.doubles
        ? "${state.playerA1Name} & ${state.playerA2Name}"
        : state.playerA1Name;
    
    final String teamB = state.matchType == TTMatchType.doubles
        ? "${state.playerB1Name} & ${state.playerB2Name}"
        : state.playerB1Name;

    final result = MatchResult(
      sport: 'Table Tennis',
      date: DateTime.now(),
      teamA: teamA,
      teamB: teamB,
      scoreA: state.gamesWonA,
      scoreB: state.gamesWonB,
      winner: state.matchWinner == TTPlayer.playerA ? teamA : teamB,
      details: jsonEncode({
        'gamesWonA': state.gamesWonA,
        'gamesWonB': state.gamesWonB,
        'gamesToWin': state.gamesToWin,
        'setHistory': state.setHistory,
      }),
    );

    await DatabaseHelper.instance.insertMatch(result);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Match Result Saved!")),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }


  Future<void> _showServeSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Who serves first?"),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               ElevatedButton(
                onPressed: () { _machine.reset(startingServer: TTPlayer.playerA); _update(); Navigator.pop(context); },
                child: Text(_getLabel(TTPlayer.playerA)),
              ),
              const SizedBox(width: 8),
               ElevatedButton(
                onPressed: () { _machine.reset(startingServer: TTPlayer.playerB); _update(); Navigator.pop(context); },
                child: Text(_getLabel(TTPlayer.playerB)),
              ),
            ],
          ),
        ),
      )
    );
  }
  
  String _getLabel(TTPlayer p) {
    if (widget.matchType == TTMatchType.doubles) {
      if (p == TTPlayer.playerA) return "${widget.playerA1} / ${widget.playerA2}";
      return "${widget.playerB1} / ${widget.playerB2}";
    }
    if (p == TTPlayer.playerA) return widget.playerA1;
    return widget.playerB1;
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Match?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(onPressed: () { Navigator.pop(context); _showServeSelectionDialog(); }, child: const Text("RESET", style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Table Tennis"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _showResetDialog)
        ],
      ),
      body: SafeArea(
        child: Center(
          child: TableTennisCourtCard(
            matchState: _machine.state,
            onScoreA: () { _machine.scorePoint(TTPlayer.playerA); _update(); },
            onScoreB: () { _machine.scorePoint(TTPlayer.playerB); _update(); },
            onUndo: () { _machine.undo(); _update(); },
            onToggleSide: () { _machine.toggleServeSide(); _update(); },
            onSave: _saveMatch,
          ),
        ),
      ),
    );
  }
}
