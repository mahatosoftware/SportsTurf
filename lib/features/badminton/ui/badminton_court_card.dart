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
      aspectRatio: 0.65, // Standard Mobile Portrait
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          int? activeBox = _calculateActiveServiceBox(matchState);
          Offset? indicatorPos;

           if (activeBox != null) {
            // Calculate center of the highlighted box to place the shuttlecock
            // We need to map the internal coordinates from Painter to here or just approximate
            // Painter logic:
            // TL(0): Left-Top
            // TR(1): Right-Top
            // BL(2): Left-Bottom
            // BR(3): Right-Bottom
            
            // NOTE: The painter logic has margins inside, but here we just need relative positions (0.25, 0.75 etc)
            // Top Y Center: Approximately 25% down (centered in top half service zone)
            // Bottom Y Center: Approximately 75% down
            
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
              color: const Color(0xFF2E7D32), // Court Green
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
                            activeBox == 0 || activeBox == 1 // Is Serving
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
                            activeBox == 2 || activeBox == 3 // Is Serving
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
                     child: const Icon(Icons.sports_tennis, // Placeholder for Shuttlecock
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

  Widget _buildPlayerSection(BadmintonPlayer player, int score, int games, bool isServing) {
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
          
          // Score
          Text(
            "$score",
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 5, color: Colors.black26)]),
          ),
          
          // Games
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
             decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
             child: Text("GAMES: $games", style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  int? _calculateActiveServiceBox(BadmintonMatchState state) {
    if (state.isMatchComplete) return null;
    
    // BWF Rules:
    // Even Score -> Right Court
    // Odd Score -> Left Court
    // Player A (Top) Facing Down: 
    //   Right Court is Viewer's LEFT (since they face down). WAIT.
    //   Let's check "Right Service Court". 
    //   Standard diagram: 
    //   Top Player (A): Right Service Court is Top-Left (from viewer). Left Service Court is Top-Right.
    //   Bottom Player (B): Right Service Court is Bottom-Right. Left Service Court is Bottom-Left.
    
    // Server A:
    //   Even: Top-Left (Index 0)
    //   Odd: Top-Right (Index 1)
    
    // Server B:
    //   Even: Bottom-Right (Index 3)
    //   Odd: Bottom-Left (Index 2)
    
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
