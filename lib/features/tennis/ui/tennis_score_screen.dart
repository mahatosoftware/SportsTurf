import 'package:flutter/material.dart';
import '../logic/tennis_state_machine.dart';
import '../models/tennis_match_state.dart';
import 'tennis_court_card.dart';

class TennisScoreScreen extends StatefulWidget {
  final MatchType matchType;
  final String playerA1;
  final String playerA2;
  final String playerB1;
  final String playerB2;

  const TennisScoreScreen({
    super.key,
    this.matchType = MatchType.singles,
    this.playerA1 = "Player A",
    this.playerA2 = "",
    this.playerB1 = "Player B",
    this.playerB2 = "",
  });

  @override
  State<TennisScoreScreen> createState() => _TennisScoreScreenState();
}

class _TennisScoreScreenState extends State<TennisScoreScreen> {
  late TennisStateMachine _machine;
  
  @override
  void initState() {
    super.initState();
    _machine = TennisStateMachine(
      matchType: widget.matchType,
      playerA1Name: widget.playerA1,
      playerA2Name: widget.playerA2,
      playerB1Name: widget.playerB1,
      playerB2Name: widget.playerB2,
    );
    
    // Choose initial server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showServeSelectionDialog();
    });
  }

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("TENNIS SCORE"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showResetDialog,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: TennisCourtCard(
                  matchState: _machine.state,
                  onScoreA: () {
                    _machine.scorePoint(Player.playerA);
                    _update();
                  },
                  onScoreB: () {
                    _machine.scorePoint(Player.playerB);
                    _update();
                  },
                  onUndo: () {
                    _machine.undo();
                    _update();
                  },
                ),
              ),
            ),
            
            // Simple Legend
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   // _LegendItem(color: Colors.yellowAccent, label: "Server"), // Icon is now on court
                   _LegendItem(color: Colors.white, label: "Point"),
                   _LegendItem(color: Colors.orangeAccent, label: "Game/Set"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showServeSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Force selection
      builder: (context) => AlertDialog(
        title: const Text("Who serves first?"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _machine.reset(startingServer: Player.playerA);
                _update();
                Navigator.pop(context);
              },
              child: Text(_getPlayerALabel()),
            ),
            ElevatedButton(
              onPressed: () {
                _machine.reset(startingServer: Player.playerB);
                _update();
                Navigator.pop(context);
              },
              child: Text(_getPlayerBLabel()),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Match?"),
        content: const Text("This will clear all scores."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Confirmation
              _showServeSelectionDialog(); // Show Selection
            },
            child: const Text("RESET", style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  String _getPlayerALabel() {
    if (widget.matchType == MatchType.doubles) {
       return "${widget.playerA1} / ${widget.playerA2}";
    }
    return widget.playerA1;
  }

  String _getPlayerBLabel() {
    if (widget.matchType == MatchType.doubles) {
       return "${widget.playerB1} / ${widget.playerB2}";
    }
    return widget.playerB1;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))
      ],
    );
  }
}
