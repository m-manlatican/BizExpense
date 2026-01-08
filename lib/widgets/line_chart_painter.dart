import 'package:flutter/material.dart';
import 'dart:math'; // Required for max/min

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final bool showGridLines;

  LineChartPainter(this.points, {this.showGridLines = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFFEFF3FA)
      ..style = PaintingStyle.fill;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, bgPaint);

    if (points.isEmpty) return;

    // Grid Lines
    final dx = size.width / (points.length - 1);
    final chartHeight = size.height * 0.75; 

    if (showGridLines) {
      final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      int interval = 1;
      if (points.length == 7) interval = 1; // Week view
      else if (points.length == 30) interval = 5; // Month view

      for (int i = 0; i < points.length; i++) {
        if (i % interval == 0) {
          final x = dx * i;
          canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), gridPaint);
        }
      }
    }

    // 🔥 FIX: robust Min/Max calculation
    double maxVal = points.reduce(max);
    double minVal = points.reduce(min);
    
    double safeMin = minVal;
    double safeMax = maxVal;

    // If flat line (min == max), adjust scale so it doesn't look like 0 (unless it is 0)
    if (maxVal == minVal) {
      if (maxVal == 0) {
        safeMax = 100; // Force range 0-100 so line is at bottom
      } else {
        safeMin = 0;   // Force 0 baseline so line is drawn relative to 0
        safeMax = maxVal * 1.2; // Add headroom
      }
    } else {
       // Optional: Force baseline to 0 for better "Sales" visualization
       // safeMin = 0; 
    }

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
      // Normalize value to 0.0 - 1.0 range
      final normalized = (points[i] - safeMin) / (safeMax - safeMin);
      
      // Invert Y because 0 is top
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
      if (points[i] > 0 || (points.length <= 7) || (i % 5 == 0)) {
         canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}