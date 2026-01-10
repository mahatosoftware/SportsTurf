import 'package:flutter/material.dart';
import '../logic/badminton_state_machine.dart';
import '../models/badminton_match_state.dart';
import 'badminton_court_card.dart';

class BadmintonScoreScreen extends StatefulWidget {
  final BadmintonMatchType matchType;
  final String playerA1;
  final String playerA2;
  final String playerB1;
  final String playerB2;

  const BadmintonScoreScreen({
    super.key,
    this.matchType = BadmintonMatchType.singles,
    this.playerA1 = "Player A",
    this.playerA2 = "",
    this.playerB1 = "Player B",
    this.playerB2 = "",
  });

  @override
  State<BadmintonScoreScreen> createState() => _BadmintonScoreScreenState();
}

class _BadmintonScoreScreenState extends State<BadmintonScoreScreen> {
  late BadmintonStateMachine _machine;

  @override
  void initState() {
    super.initState();
    _machine = BadmintonStateMachine(
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
  
  Future<void> _showServeSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Who serves first?"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _machine.reset(startingServer: BadmintonPlayer.playerA);
                _update();
                Navigator.pop(context);
              },
              child: Text(widget.playerA1), // Show Name
            ),
            ElevatedButton(
              onPressed: () {
                _machine.reset(startingServer: BadmintonPlayer.playerB);
                _update();
                Navigator.pop(context);
              },
              child: Text(widget.playerB1), // Show Name
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
              Navigator.pop(context);
              _showServeSelectionDialog(); // Prompt again
            },
            child: const Text("RESET", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background for contrast
      appBar: AppBar(
        title: const Text("BADMINTON SCORE"),
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: BadmintonCourtCard(
                matchState: _machine.state,
                onScoreA: () {
                   _machine.scorePoint(BadmintonPlayer.playerA);
                   _update();
                },
                onScoreB: () {
                   _machine.scorePoint(BadmintonPlayer.playerB);
                   _update();
                },
                onUndo: () {
                   _machine.undo();
                   _update();
                },
              ),
            ),
          ),
          
          // Legend
          const Padding(
             padding: EdgeInsets.only(bottom: 24),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.sports_tennis, color: Colors.white, size: 16), // Shuttle
                 SizedBox(width: 8),
                 Text("Shuttle indicates Server", style: TextStyle(color: Colors.white54))
               ],
             ),
          )
        ],
      ),
    );
  }
}
