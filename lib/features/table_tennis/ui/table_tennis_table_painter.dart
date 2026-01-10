import 'package:flutter/material.dart';
import '../models/table_tennis_match_state.dart';

class TableTennisTablePainter extends CustomPainter {
  final TTPlayer server;
  final TTSide serveSide;

  TableTennisTablePainter({
    required this.server,
    required this.serveSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Table Colors
    const tableColor = Color(0xFF1565C0); // ITTF Blue
    const lineColor = Colors.white;
    
    final paint = Paint()
      ..color = tableColor
      ..style = PaintingStyle.fill;
    
    // Draw Table Surface
    final tableRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(tableRect, paint);
    
    // Draw Lines
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    // Outer Border
    canvas.drawRect(tableRect, linePaint);
    
    // Center Line (Vertical)
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), linePaint);
    
    // Net (Center Horizontal)
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    
    double netY = h / 2;
    canvas.drawLine(Offset(-10, netY), Offset(w + 10, netY), netPaint); 
    
    // Grid Lines
    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.0;
      
    for (double i = 0; i < w; i += 10) {
      canvas.drawLine(Offset(i, netY - 3), Offset(i + 5, netY + 3), gridPaint);
    }
    
    // Serve Highlight
    double topY = 0;
    double midY = h / 2;
    double botY = h;
    
    double leftX = 0;
    double midX = w / 2;
    double rightX = w;
    
    late Rect highlightRect;
    
    if (server == TTPlayer.playerA) {
      if (serveSide == TTSide.left) { // Viewer Left
         highlightRect = Rect.fromLTRB(leftX, topY, midX, midY); 
      } else { // Viewer Right
         highlightRect = Rect.fromLTRB(midX, topY, rightX, midY);
      }
    } else {
      if (serveSide == TTSide.left) { // Viewer Left
         highlightRect = Rect.fromLTRB(leftX, midY, midX, botY);
      } else { // Viewer Right
         highlightRect = Rect.fromLTRB(midX, midY, rightX, botY);
      }
    }
    
    // Glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawRect(highlightRect, glowPaint);
    
    // Outline
    final borderPaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
     
    canvas.drawRect(highlightRect.deflate(2), borderPaint);
  }

  @override
  bool shouldRepaint(covariant TableTennisTablePainter oldDelegate) {
    return oldDelegate.server != server || oldDelegate.serveSide != serveSide;
  }
}
