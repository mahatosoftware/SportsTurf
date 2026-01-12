import 'package:flutter/material.dart';

class VolleyballCourtPainter extends CustomPainter {
  final bool isTeamAServing;
  final bool isTeamBServing;

  VolleyballCourtPainter({
    required this.isTeamAServing,
    required this.isTeamBServing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Court Colors
    final courtColor = const Color(0xFFE0C39C); // Wood color
    final outOfBoundsColor = const Color(0xFF4A9E88); // Green sport floor
    final lineColor = Colors.white;
    final highlightColor = Colors.yellow.withValues(alpha: 0.3);

    // Draw background (Out of bounds)
    final bgPaint = Paint()..color = outOfBoundsColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Court Dimensions (Standard 18m x 9m ratio is 2:1)
    // We want the court to fit within the canvas with some padding
    final padding = 20.0;
    final courtW = w - (padding * 2);
    final courtH = (courtW * 2); // 2:1 ratio (Height is length in portrait)
    
    // Center the court
    final left = padding;
    final top = (h - courtH) / 2;
    final right = left + courtW;
    final bottom = top + courtH;
    final courtRect = Rect.fromLTRB(left, top, right, bottom);

    // Draw Court Surface
    final courtPaint = Paint()..color = courtColor;
    canvas.drawRect(courtRect, courtPaint);

    // Highlight Service Zones
    // Service zone is technically infinite behind the end line, 
    // but visually we'll highlight the area immediately behind the baseline.
    if (isTeamAServing) {
      // Team A is Top
      final serviceZoneA = Rect.fromLTRB(left, top - 40, right, top);
      canvas.drawRect(serviceZoneA, Paint()..color = highlightColor);
      
      // Also highlight the court side slightly
      canvas.drawRect(Rect.fromLTRB(left, top, right, top + courtH / 2), Paint()..color = highlightColor);
    } 
    
    if (isTeamBServing) {
      // Team B is Bottom
      final serviceZoneB = Rect.fromLTRB(left, bottom, right, bottom + 40);
      canvas.drawRect(serviceZoneB, Paint()..color = highlightColor);

      // Also highlight the court side slightly
      canvas.drawRect(Rect.fromLTRB(left, top + courtH / 2, right, bottom), Paint()..color = highlightColor);
    }

    // Draw Lines
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Outer Boundary
    canvas.drawRect(courtRect, linePaint);

    // Center Line (Net)
    final centerY = top + (courtH / 2);
    canvas.drawLine(Offset(left, centerY), Offset(right, centerY), linePaint);

    // Attack Lines (3m line)
    // 3m is 1/3 of the 9m half-court.
    final halfCourtH = courtH / 2; // 9m equivalent
    final attackLineOffset = halfCourtH / 3; // 3m equivalent

    // Team A Attack Line
    final attackLineAY = centerY - attackLineOffset;
    canvas.drawLine(Offset(left, attackLineAY), Offset(right, attackLineAY), linePaint);

    // Team B Attack Line
    final attackLineBY = centerY + attackLineOffset;
    canvas.drawLine(Offset(left, attackLineBY), Offset(right, attackLineBY), linePaint);

    // Draw Net (Visual representation)
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 6.0;
    canvas.drawLine(Offset(left - 5, centerY), Offset(right + 5, centerY), netPaint);
  }

  @override
  bool shouldRepaint(covariant VolleyballCourtPainter oldDelegate) {
    return oldDelegate.isTeamAServing != isTeamAServing ||
        oldDelegate.isTeamBServing != isTeamBServing;
  }
}
