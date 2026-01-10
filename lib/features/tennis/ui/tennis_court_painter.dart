import 'package:flutter/material.dart';

class TennisCourtPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final int? activeServiceBoxIndex; // 0: TL, 1: TR, 2: BL, 3: BR

  TennisCourtPainter({
    this.lineColor = Colors.white70,
    this.lineWidth = 2.0,
    this.activeServiceBoxIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Margin
    const margin = 16.0;
    
    // Dimensions
    const alleyWidth = 30.0;
    final serviceLineOffset = (h - margin * 2) * 0.25; 
    final centerY = h / 2;
    final centerX = w / 2;
    
    // Define Service Boxes (Rects)
    // Top Left (Player B's Ad Court receiving, Player A's Ad Court serving target? No. 
    // Player B (Bottom) serves to Top Left (A's Deuce Box - Viewer Left).
    // Let's just define rects geometrically first.
    
    // Top Left Box
    final rectTL = Rect.fromLTRB(
      margin + alleyWidth, 
      margin + serviceLineOffset, 
      centerX, 
      centerY
    );
    
    // Top Right Box
    final rectTR = Rect.fromLTRB(
      centerX, 
      margin + serviceLineOffset, 
      w - margin - alleyWidth, 
      centerY
    );
    
    // Bottom Left Box
    final rectBL = Rect.fromLTRB(
      margin + alleyWidth, 
      centerY, 
      centerX, 
      h - margin - serviceLineOffset
    );
    
    // Bottom Right Box
    final rectBR = Rect.fromLTRB(
      centerX, 
      centerY, 
      w - margin - alleyWidth, 
      h - margin - serviceLineOffset
    );
    
    final boxes = [rectTL, rectTR, rectBL, rectBR];

    // Draw Highlight
    if (activeServiceBoxIndex != null && activeServiceBoxIndex! >= 0 && activeServiceBoxIndex! < 4) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF66BB6A).withValues(alpha: 0.5) // Brighter green, ~0.5 opacity
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Glow effect
        
      canvas.drawRect(boxes[activeServiceBoxIndex!], highlightPaint);
      
      // Draw standard fill (non-blurred) on top for sharpness? 
      // User asked for "glow or accent outline" + "Brighter green fill".
      // Let's do a crisp fill with a glow underneath? Or just the fill. 
      // The mask filter blurs the whole rect.
      // Let's draw a sharp brighter rect too.
      final fillPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(boxes[activeServiceBoxIndex!], fillPaint);
    }
    
    // Draw Non-Highlighted Dimming? 
    // "Non-serving service boxes should appear dimmed or neutral"
    // The background is already deep green. Highlight is brighter. So non-highlighted are implicitly dimmer.

    // 1. Outer Boundary
    final rect = Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2);
    canvas.drawRect(rect, paint);
    
    // 2. Singles Side Lines
    canvas.drawLine(
      Offset(margin + alleyWidth, margin), 
      Offset(margin + alleyWidth, h - margin), 
      paint
    );
    canvas.drawLine(
      Offset(w - margin - alleyWidth, margin), 
      Offset(w - margin - alleyWidth, h - margin), 
      paint
    );

    // 3. Service Lines
    // Top
    canvas.drawLine(
      Offset(margin + alleyWidth, margin + serviceLineOffset),
      Offset(w - margin - alleyWidth, margin + serviceLineOffset),
      paint
    );
    // Bottom
    canvas.drawLine(
      Offset(margin + alleyWidth, h - margin - serviceLineOffset),
      Offset(w - margin - alleyWidth, h - margin - serviceLineOffset),
      paint
    );
    // Center
    canvas.drawLine(
      Offset(centerX, margin + serviceLineOffset),
      Offset(centerX, h - margin - serviceLineOffset),
      paint
    );

    
    // 4. Net (Dashed Line in center)
    final netPaint = Paint()
      ..color = const Color.fromARGB(128, 255, 255, 255) // ~0.5 opacity
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
      
    _drawDashedLine(canvas, Offset(0, centerY), Offset(w, centerY), netPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = 0.0;
    double totalDistance = (p2 - p1).distance;
    
    while (distance < totalDistance) {
      canvas.drawLine(
        Offset(p1.dx + distance, p1.dy),
        Offset(p1.dx + distance + dashWidth, p1.dy),
        paint
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
