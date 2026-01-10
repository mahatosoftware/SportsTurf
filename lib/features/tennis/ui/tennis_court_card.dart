import 'package:flutter/material.dart';
import '../models/tennis_match_state.dart';
import 'tennis_court_painter.dart';

class TennisCourtCard extends StatelessWidget {
  final TennisMatchState matchState;
  final VoidCallback onScoreA;
  final VoidCallback onScoreB;
  final VoidCallback onUndo;
  final VoidCallback? onSave;

  const TennisCourtCard({
    super.key,
    required this.matchState,
    required this.onScoreA,
    required this.onScoreB,
    required this.onUndo,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7, // Portrait Aspect Ratio
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final margin = 16.0;
          final alley = 30.0;
          final serviceOffset = (h - margin * 2) * 0.25;
          final serviceTop = margin + serviceOffset;
          final serviceBottom = h - margin - serviceOffset;
          final centerX = w / 2;
          final centerY = h / 2;

          int? activeBox = _calculateActiveServiceBox(matchState);
          Offset? ballPos;
          
          if (activeBox != null) {
            double bx = 0, by = 0;
            switch (activeBox) {
              case 0: // TL
                bx = (margin + alley + centerX) / 2;
                by = (serviceTop + centerY) / 2;
                break;
              case 1: // TR
                bx = (centerX + w - margin - alley) / 2;
                by = (serviceTop + centerY) / 2;
                break;
              case 2: // BL
                bx = (margin + alley + centerX) / 2;
                by = (centerY + serviceBottom) / 2;
                break;
              case 3: // BR
                bx = (centerX + w - margin - alley) / 2;
                by = (centerY + serviceBottom) / 2;
                break;
            }
            ballPos = Offset(bx, by);
          }

          return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32), // Standard Court Green
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Lines & Highlight
              CustomPaint(
                painter: TennisCourtPainter(
                  activeServiceBoxIndex: activeBox
                ),
              ),

              // 2. Interactive Zones
              Column(
                children: [
                  // Player A Zone (Top)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: matchState.isMatchComplete ? null : onScoreA,
                        splashColor: Colors.white24,
                        highlightColor: Colors.white12,
                        child: _buildPlayerSection(
                          Player.playerA, 
                          matchState.pointPlayerA, 
                          matchState.gamesPlayerA,
                          matchState.setsWonPlayerA
                        ),
                      ),
                    ),
                  ),
                  
                  // Net Divider (Visual only, line painted below)
                  Container(height: 2, color: Colors.transparent), 

                  // Player B Zone (Bottom)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: matchState.isMatchComplete ? null : onScoreB,
                        splashColor: Colors.white24,
                        highlightColor: Colors.white12,
                        child: _buildPlayerSection(
                          Player.playerB, 
                          matchState.pointPlayerB, 
                          matchState.gamesPlayerB,
                          matchState.setsWonPlayerB
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 3. Ball Icon (Server Indicator)
              if (ballPos != null)
                Positioned(
                  left: ballPos.dx - 12, // Center icon size 24
                  top: ballPos.dy - 12,
                  child: const Icon(Icons.sports_tennis, color: Colors.yellowAccent, size: 24),
                ),

              // 4. UI Overlays (Scores, Undo, etc)
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white),
                  onPressed: onUndo,
                  tooltip: 'Undo',
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
                          "${matchState.matchWinner == Player.playerA ? _getPlayerLabel(Player.playerA) : _getPlayerLabel(Player.playerB)}\nWINS!",
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (onSave != null)
                          ElevatedButton.icon(
                            onPressed: onSave,
                            icon: const Icon(Icons.save),
                            label: const Text("Save Match Result"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      })
    );
  }

  Widget _buildPlayerSection(Player player, TennisPoint point, int games, int setsWon) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player Label
          Text(
            _getPlayerLabel(player),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),

          // Score Display
          Text(
            matchState.isTimBreak 
                ? (player == Player.playerA ? matchState.tieBreakPointA.toString() : matchState.tieBreakPointB.toString())
                : _getPointString(point),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
            ),
          ),
          
          if (matchState.isTimBreak)
             const Text("TIE BREAK", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 10)),
          if (!matchState.isTimBreak && point == TennisPoint.ad)
             const Text("ADVANTAGE", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),
          
          // Set Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
              "SETS: $setsWon | GAMES: $games",
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getPointString(TennisPoint point) {
    switch (point) {
      case TennisPoint.love: return "0";
      case TennisPoint.fifteen: return "15";
      case TennisPoint.thirty: return "30";
      case TennisPoint.forty: return "40";
      case TennisPoint.ad: return "AD";
      case TennisPoint.game: return "GAME";
    }
  }

  int? _calculateActiveServiceBox(TennisMatchState state) {
    if (state.isMatchComplete) return null;

    // Total points to determine Deuce/Ad side
    int pointsA = state.isTimBreak ? state.tieBreakPointA : _pointToInt(state.pointPlayerA);
    int pointsB = state.isTimBreak ? state.tieBreakPointB : _pointToInt(state.pointPlayerB);
    int total = pointsA + pointsB;

    bool isDeuceSide = (total % 2 == 0); // Even = Deuce, Odd = Ad

    if (state.server == Player.playerA) {
      // Player A is Top.
      // Deuce (Left from Viewer) -> Highlight Top-Left (Index 0).
      // Ad (Right from Viewer) -> Highlight Top-Right (Index 1).
      return isDeuceSide ? 0 : 1;
    } else {
      // Player B is Bottom.
      // Deuce (Right from Viewer) -> Highlight Bottom-Right (Index 3).
      // Ad (Left from Viewer) -> Highlight Bottom-Left (Index 2).
      return isDeuceSide ? 3 : 2;
    }
  }

  int _pointToInt(TennisPoint p) {
    switch (p) {
      case TennisPoint.love: return 0;
      case TennisPoint.fifteen: return 1;
      case TennisPoint.thirty: return 2;
      case TennisPoint.forty: return 3;
      case TennisPoint.ad: return 4; 
      default: return 0;
    }
  }

  String _getPlayerLabel(Player p) {
    if (p == Player.playerA) {
      if (matchState.matchType == MatchType.doubles) {
        return "${matchState.playerA1Name} / ${matchState.playerA2Name}";
      }
      return matchState.playerA1Name;
    } else {
      if (matchState.matchType == MatchType.doubles) {
        return "${matchState.playerB1Name} / ${matchState.playerB2Name}";
      }
      return matchState.playerB1Name;
    }
  }
}
