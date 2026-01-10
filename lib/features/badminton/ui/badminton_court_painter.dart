import 'package:flutter/material.dart';

class BadmintonCourtPainter extends CustomPainter {
  final int? activeServiceBoxIndex; // 0=TL, 1=TR, 2=BL, 3=BR
  final bool isDoubles;

  BadmintonCourtPainter({this.activeServiceBoxIndex, required this.isDoubles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    
    // Margins - Standard Court Aspect Ratio is roughly 13.4m x 6.1m (~2.2:1)
    // We fit it into the provided size with some padding.
    // However, on mobile portrait, it's better to just use the container size with some internal padding.
    
    // Court Boundaries
    // Outer Box (Doubles Sidelines / Back Boundary)
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, paint);
    
    // Singles Sidelines (Inner Vertical Lines)
    // Roughly 46cm from side in a 6.1m court (~7.5%)
    double sideMargin = w * 0.08; 
    canvas.drawLine(Offset(sideMargin, 0), Offset(sideMargin, h), paint);
    canvas.drawLine(Offset(w - sideMargin, 0), Offset(w - sideMargin, h), paint);

    // Center Net Line
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
    
    // Short Service Lines
    // Roughly 1.98m from net in 6.7m half (~30% from net)
    double shortServiceOffset = h * 0.15; // 15% from center each way
    double topShortServiceY = (h / 2) - shortServiceOffset;
    double bottomShortServiceY = (h / 2) + shortServiceOffset;
    
    canvas.drawLine(Offset(0, topShortServiceY), Offset(w, topShortServiceY), paint);
    canvas.drawLine(Offset(0, bottomShortServiceY), Offset(w, bottomShortServiceY), paint);
    
    // Center Service Line (Vertical middle)
    // Extends from Short Service Line to Back Boundary
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, topShortServiceY), paint);
    canvas.drawLine(Offset(w / 2, bottomShortServiceY), Offset(w / 2, h), paint);
    
    // Doubles Long Service Line (Back)
    // Roughly 0.76m from back boundary (~5.6% of half length)
    // Only relevant for Doubles Service
    if (isDoubles) {
      double backServiceMargin = h * 0.05; 
      canvas.drawLine(Offset(0, backServiceMargin), Offset(w, backServiceMargin), paint); // Top court (Team A)
      canvas.drawLine(Offset(0, h - backServiceMargin), Offset(w, h - backServiceMargin), paint); // Bottom court (Team B)
    }

    // Highlighting Active Service Box
    if (activeServiceBoxIndex != null) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.5) // Dark Green
        ..style = PaintingStyle.fill;
      
      Rect? targetRect;
      
      // Regions:
      // 0: Top-Left (Team A Left - Odd)
      // 1: Top-Right (Team A Right - Even)
      // 2: Bottom-Left (Team B Left - Odd)
      // 3: Bottom-Right (Team B Right - Even)
      
      // Note: "Right" service court is relative to the player standing on that side.
      // Top Player (A): Facing down. Their Right is viewer's Left (TL). Their Left is viewer's Right (TR).
      // Bottom Player (B): Facing up. Their Right is viewer's Right (BR). Their Left is viewer's Left (BL).
      
      // Service box boundaries:
      // Top Half: Between Net (Short Service) and Back (Long Service/Back Boundary)
      // Bottom Half: Between Net (Short Service) and Back (Long Service/Back Boundary)
      // Sidelines: Center to Outer(Doubles)/Inner(Singles)? 
      // Rule: Service is always to the diagonally opposite court. But here we usually highlight WHERE THE SERVER IS.
      // User Request: "Highlight the exact service court from which the server must serve".
      
      // Let's define the boxes precisely.
      // Top Half Y Range: [0 (or BackServiceMargin) to TopShortServiceY]
      // Bottom Half Y Range: [BottomShortServiceY to h (or h-BackServiceMargin)]
      
      double topYStart = isDoubles ? h * 0.05 : 0;
      double topYEnd = topShortServiceY;
      
      double botYStart = bottomShortServiceY;
      double botYEnd = isDoubles ? h - (h*0.05) : h;
      
      double midX = w / 2;
      
      // In singles, side is Inner. In Doubles, side is Outer.
      // Wait, Service Court for Doubles is Short and Wide. Singles is Long and Narrow.
      // But usually user just wants the "Box". Let's stick to the main lines. 
      // Simplified: Highlight the specific quadrant defined by Short Service Line and Center Line.
      // We will fill the full width for simplicity unless we want to be pedantic about singles sidelines.
      // Let's adhere to rule:
      // Singles Serve: Base to Inner Side.
      // Doubles Serve: Long Service Line to Outer Side.
      
      double xMin = 0;
      double xMax = w;
      if (!isDoubles) {
         xMin = sideMargin;
         xMax = w - sideMargin;
      }
      
      // Correct Left/Right X coords
      // Left Box: xMin to midX
      // Right Box: midX to xMax
      
      switch (activeServiceBoxIndex) {
        case 0: // Top Left (Viewer Left)
          targetRect = Rect.fromLTRB(xMin, topYStart, midX, topYEnd);
          break;
        case 1: // Top Right (Viewer Right)
          targetRect = Rect.fromLTRB(midX, topYStart, xMax, topYEnd);
          break;
        case 2: // Bottom Left (Viewer Left)
          targetRect = Rect.fromLTRB(xMin, botYStart, midX, botYEnd);
          break;
        case 3: // Bottom Right (Viewer Right)
          targetRect = Rect.fromLTRB(midX, botYStart, xMax, botYEnd);
          break;
      }
      
      if (targetRect != null) {
        canvas.drawRect(targetRect, highlightPaint);
        
        // Glow effect
        final glowPaint = Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawRect(targetRect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BadmintonCourtPainter oldDelegate) {
    return oldDelegate.activeServiceBoxIndex != activeServiceBoxIndex ||
           oldDelegate.isDoubles != isDoubles;
  }
}
