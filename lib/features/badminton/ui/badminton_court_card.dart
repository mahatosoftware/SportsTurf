import 'package:flutter/material.dart';
import '../models/badminton_match_state.dart';
import 'badminton_court_painter.dart';

class BadmintonCourtCard extends StatelessWidget {
  final BadmintonMatchState matchState;
  final VoidCallback onScoreA;
  final VoidCallback onScoreB;
  final VoidCallback onUndo;

  const BadmintonCourtCard({
    super.key,
    required this.matchState,
    required this.onScoreA,
    required this.onScoreB,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.65, 
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          int? activeBox = _calculateActiveServiceBox(matchState);
          Offset? indicatorPos;

           if (activeBox != null) {
            double cyTop = h * 0.25;
            double cyBot = h * 0.75;
            double cxLeft = w * 0.25;
            double cxRight = w * 0.75;

            switch (activeBox) {
              case 0: indicatorPos = Offset(cxLeft, cyTop); break;
              case 1: indicatorPos = Offset(cxRight, cyTop); break;
              case 2: indicatorPos = Offset(cxLeft, cyBot); break;
              case 3: indicatorPos = Offset(cxRight, cyBot); break;
            }
          }

          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32), 
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Court Visuals
                CustomPaint(
                  painter: BadmintonCourtPainter(
                    activeServiceBoxIndex: activeBox,
                    isDoubles: matchState.matchType == BadmintonMatchType.doubles
                  ),
                ),

                // 2. Click Zones
                Column(
                  children: [
                    // Top Half (Player A)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: matchState.isMatchComplete ? null : onScoreA,
                          splashColor: Colors.white12,
                          child: _buildPlayerSection(
                            BadmintonPlayer.playerA,
                            matchState.scoreA,
                            matchState.gamesWonA,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: matchState.isMatchComplete ? null : onScoreB,
                          splashColor: Colors.white12,
                          child: _buildPlayerSection(
                            BadmintonPlayer.playerB,
                            matchState.scoreB,
                            matchState.gamesWonB,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. Indicator
                if (indicatorPos != null)
                   Positioned(
                     left: indicatorPos.dx - 16,
                     top: indicatorPos.dy - 16,
                     child: const Icon(Icons.sports_tennis, 
                        color: Colors.white, size: 32, shadows: [Shadow(blurRadius: 10, color: Colors.yellowAccent)]),
                   ),
                   
                // 4. Undo Button
                Positioned(
                  top: 16, 
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white),
                    onPressed: onUndo,
                  ),
                ),
                
                 // Match Complete Overlay
                if (matchState.isMatchComplete)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            "${matchState.matchWinner == BadmintonPlayer.playerA ? _getPlayerLabel(BadmintonPlayer.playerA) : _getPlayerLabel(BadmintonPlayer.playerB)}\nWINS!",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildPlayerSection(BadmintonPlayer player, int score, int setsWon) {
    // Generate previous set scores string
    // Filter history for this player? No, show score like "21-15, 18-21"
    // Wait, usually we show history for the played sets.
    // Let's just create a string of previous sets results for THIS player.
    // e.g. for Player A: "21, 15"
    
    List<String> historyStrings = [];
    for (var setScore in matchState.setHistory) {
      if (player == BadmintonPlayer.playerA) {
        historyStrings.add("${setScore['A']}");
      } else {
        historyStrings.add("${setScore['B']}");
      }
    }
    String historyText = historyStrings.join(" - ");

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Name
          Text(
            _getPlayerLabel(player),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
             textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Current Score
          Text(
            "$score",
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 5, color: Colors.black26)]),
          ),
          
          // Sets & History
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text("SETS: $setsWon", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 if (historyText.isNotEmpty) ...[
                   const SizedBox(width: 8),
                   Container(width: 1, height: 16, color: Colors.white54),
                   const SizedBox(width: 8),
                   Text(historyText, style: const TextStyle(color: Colors.white70)),
                 ]
               ],
             ),
          ),
        ],
      ),
    );
  }

  int? _calculateActiveServiceBox(BadmintonMatchState state) {
    if (state.isMatchComplete) return null;
    
    int score = state.server == BadmintonPlayer.playerA ? state.scoreA : state.scoreB;
    bool isEven = (score % 2 == 0);
    
    if (state.server == BadmintonPlayer.playerA) {
       return isEven ? 0 : 1; 
    } else {
       return isEven ? 3 : 2;
    }
  }

  String _getPlayerLabel(BadmintonPlayer p) {
    if (p == BadmintonPlayer.playerA) {
      if (matchState.matchType == BadmintonMatchType.doubles) {
        return "${matchState.playerA1Name} / ${matchState.playerA2Name}".toUpperCase();
      }
      return matchState.playerA1Name.toUpperCase();
    } else {
      if (matchState.matchType == BadmintonMatchType.doubles) {
        return "${matchState.playerB1Name} / ${matchState.playerB2Name}".toUpperCase();
      }
      return matchState.playerB1Name.toUpperCase();
    }
  }
}
