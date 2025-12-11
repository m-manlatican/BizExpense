import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> points;

  LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minVal = points.reduce((a, b) => a < b ? a : b);

    final dx = size.width / (points.length - 1);
    final chartHeight = size.height * 0.7;

    final bgPaint = Paint()
      ..color = const Color(0xFFEFF3FA)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, bgPaint);

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
      final normalized =
          maxVal == minVal ? 0.5 : (points[i] - minVal) / (maxVal - minVal);
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

    final dotPaint = Paint()
      ..color = const Color(0xFF00C665)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = dx * i;
      final normalized =
          maxVal == minVal ? 0.5 : (points[i] - minVal) / (maxVal - minVal);
      final y = chartHeight - (normalized * chartHeight) + 12;
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    // Optimized: Repaint if the points data has changed
    return oldDelegate.points != points;
  }
}