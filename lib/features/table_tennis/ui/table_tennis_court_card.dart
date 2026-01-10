import 'package:flutter/material.dart';
import '../models/table_tennis_match_state.dart';
import 'table_tennis_table_painter.dart';

class TableTennisCourtCard extends StatelessWidget {
  final TableTennisMatchState matchState;
  final VoidCallback onScoreA;
  final VoidCallback onScoreB;
  final VoidCallback onUndo;
  final VoidCallback onToggleSide;

  const TableTennisCourtCard({
    super.key,
    required this.matchState,
    required this.onScoreA,
    required this.onScoreB,
    required this.onUndo,
    required this.onToggleSide,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.65, 
      child: LayoutBuilder(
        builder: (context, constraints) {
           final w = constraints.maxWidth;
           final h = constraints.maxHeight;
           
           // Calculate Ball Position
           double cxLeft = w * 0.25;
           double cxRight = w * 0.75;
           double cyTop = h * 0.25;
           double cyBot = h * 0.75;
           
           Offset? ballPos;
           if (!matchState.isMatchComplete) {
              bool isLeft = matchState.serveSide == TTSide.left;
              if (matchState.server == TTPlayer.playerA) {
                 ballPos = Offset(isLeft ? cxLeft : cxRight, cyTop);
              } else {
                 ballPos = Offset(isLeft ? cxLeft : cxRight, cyBot);
              }
           }

          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[900], 
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Table Visuals
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: TableTennisTablePainter(
                      server: matchState.server,
                      serveSide: matchState.serveSide
                    ),
                  ),
                ),
                
                // 2. Score & Names Layer
                Column(
                  children: [
                    // TOP HALF (Player A)
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPlayerInfo(TTPlayer.playerA, matchState.scoreA, matchState.gamesWonA),
                          
                          // Tap to Score
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: matchState.isMatchComplete ? null : onScoreA,
                                overlayColor: WidgetStateProperty.all(Colors.white12),
                              ),
                            ),
                          ),
                          
                           if (matchState.server == TTPlayer.playerA)
                             Positioned(
                               right: 8, top: 8,
                               child: _buildSideToggle(),
                             ),
                        ],
                      ),
                    ),
                    
                    // BOTTOM HALF (Player B)
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPlayerInfo(TTPlayer.playerB, matchState.scoreB, matchState.gamesWonB),
                          
                          // Tap to Score
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: matchState.isMatchComplete ? null : onScoreB,
                                overlayColor: WidgetStateProperty.all(Colors.white12),
                              ),
                            ),
                          ),
                          
                          if (matchState.server == TTPlayer.playerB)
                             Positioned(
                               right: 8, bottom: 8,
                               child: _buildSideToggle(),
                             ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 3. Ball Indicator
                if (ballPos != null)
                  Positioned(
                    left: ballPos.dx - 12, 
                    top: ballPos.dy - 12,
                    child: const Icon(Icons.circle, color: Colors.orange, size: 24, shadows: [Shadow(color: Colors.white, blurRadius: 5)]),
                  ),
                  
                // 4. Undo Button
                 Positioned(
                    left: 16, 
                    top: h / 2 - 24, 
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                        onPressed: onUndo,
                      ),
                    ),
                  ),
                  
                  // Match Complete
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
                            "${_getPlayerLabel(matchState.matchWinner == TTPlayer.playerA ? TTPlayer.playerA : TTPlayer.playerB)}\nWINS!",
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
  
  Widget _buildSideToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
      child: IconButton(
        icon: const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
        tooltip: "Switch Serve Side",
        onPressed: onToggleSide,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildPlayerInfo(TTPlayer player, int score, int games) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getPlayerLabel(player), 
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text("$score", style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w900)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
          child: Text("Sets: $games", style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _getPlayerLabel(TTPlayer p) {
    if (matchState.matchType == TTMatchType.doubles) {
      if (p == TTPlayer.playerA) {
        return "${matchState.playerA1Name} / ${matchState.playerA2Name}".toUpperCase();
      } else {
        return "${matchState.playerB1Name} / ${matchState.playerB2Name}".toUpperCase();
      }
    } else {
      // Singles
      if (p == TTPlayer.playerA) return matchState.playerA1Name.toUpperCase();
      return matchState.playerB1Name.toUpperCase();
    }
  }
}
