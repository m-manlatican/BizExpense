import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final bool showGridLines;

  LineChartPainter(this.points, {this.showGridLines = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce((a, b) => a > b ? a : b);
    // Ensure minVal handles all-zero case nicely
    final minVal = points.reduce((a, b) => a < b ? a : b); 
    final safeMax = maxVal == minVal ? maxVal + 1 : maxVal;
    final safeMin = minVal;

    final dx = size.width / (points.length - 1);
    final chartHeight = size.height * 0.75; // Use 75% height for chart, space for visual breathing

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFFEFF3FA)
      ..style = PaintingStyle.fill;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 🔥 GRID LINES (New)
    // We infer label positions based on point count (every 4th for Day, etc.)
    // But simplistically, if we want grid lines for every labeled point:
    // This logic mimics the label logic in DashboardPage:
    // Day: 24 points (mod 4)
    // Week: 7 points (all)
    // Month: 30 points (mod 5)
    
    if (showGridLines) {
      final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      int interval = 1;
      if (points.length == 24) interval = 4; // Day view
      else if (points.length == 30) interval = 5; // Month view

      for (int i = 0; i < points.length; i++) {
        if (i % interval == 0) {
          final x = dx * i;
          canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), gridPaint);
        }
      }
    }

    // Line & Fill Setup
    final linePaint = Paint()
      ..color = const Color(0xFF00C665)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF00C665).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = dx * i;
      final normalized = (points[i] - safeMin) / (safeMax - safeMin);
      
      // Invert Y (0 is top, height is bottom). +12 padding top.
      final y = chartHeight - (normalized * chartHeight) + 12;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(dx * (points.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00C665)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = dx * i;
      final normalized = (points[i] - safeMin) / (safeMax - safeMin);
      final y = chartHeight - (normalized * chartHeight) + 12;
      
      // Draw dot if value > 0 or it's a key interval point
      if (points[i] > 0 || (points.length == 7) || (i % 4 == 0 && points.length == 24)) {
         canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}