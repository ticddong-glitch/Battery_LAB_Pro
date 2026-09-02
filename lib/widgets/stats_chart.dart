import 'package:flutter/material.dart';
import 'dart:math';

import '../sevices/statistics_service.dart';

enum StatisticsChartType { histogram, scatterPlot, boxPlot }

class StatisticsChart extends StatelessWidget {
  final StatisticsChartType type;
  final HistogramSummary? histogram;
  final List<Point<double>> scatter;
  final BoxPlotSummary? boxPlot;

  const StatisticsChart({
    super.key,
    required this.type,
    this.histogram,
    this.scatter = const [],
    this.boxPlot,
  });

  @override
  Widget build(BuildContext context) {
    final CustomPainter painter = switch (type) {
      StatisticsChartType.histogram => HistogramPainter(
          counts: histogram?.counts ?? const [],
          barColor: Colors.blue.shade700,
        ),
      StatisticsChartType.scatterPlot => ScatterPainter(
          points: scatter,
          dotColor: Colors.orange.shade700,
        ),
      StatisticsChartType.boxPlot => BoxPlotPainter(
          summary: boxPlot,
          color: Colors.teal.shade700,
        ),
    };

    return SizedBox(
      height: 280,
      child: CustomPaint(
        size: Size.infinite,
        painter: painter,
      ),
    );
  }
}

class HistogramPainter extends CustomPainter {
  final List<int> counts;
  final Color barColor;

  HistogramPainter({required this.counts, this.barColor = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = barColor;
    final maxCount = counts.isEmpty ? 1 : counts.reduce(max);
    final barWidth = size.width / (counts.isEmpty ? 1 : counts.length);
    for (var i = 0; i < counts.length; i++) {
      final h = maxCount == 0 ? 0.0 : (counts[i] / maxCount) * size.height;
      final rect = Rect.fromLTWH(i * barWidth, size.height - h, barWidth - 2, h);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HistogramPainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.barColor != barColor;
  }
}

class TrendPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  TrendPainter({required this.values, this.lineColor = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1 == 0 ? 1 : values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    // draw points
    final pointPaint = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1 == 0 ? 1 : values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

class ScatterPainter extends CustomPainter {
  final List<Point<double>> points;
  final Color dotColor;

  ScatterPainter({required this.points, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final minX = points.map((p) => p.x).reduce(min);
    final maxX = points.map((p) => p.x).reduce(max);
    final minY = points.map((p) => p.y).reduce(min);
    final maxY = points.map((p) => p.y).reduce(max);

    final dx = (maxX - minX) == 0 ? 1.0 : (maxX - minX);
    final dy = (maxY - minY) == 0 ? 1.0 : (maxY - minY);

    final axis = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axis);

    final dot = Paint()..color = dotColor;
    for (final p in points) {
      final x = ((p.x - minX) / dx) * size.width;
      final y = size.height - ((p.y - minY) / dy) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant ScatterPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.dotColor != dotColor;
  }
}

class BoxPlotPainter extends CustomPainter {
  final BoxPlotSummary? summary;
  final Color color;

  BoxPlotPainter({required this.summary, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = summary;
    if (s == null) {
      return;
    }
    final minV = s.min;
    final maxV = s.max;
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    double mapX(double v) => ((v - minV) / range) * size.width;

    final y = size.height / 2;
    final whisker = Paint()
      ..color = color
      ..strokeWidth = 2;
    final box = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final xMin = mapX(s.min);
    final xQ1 = mapX(s.q1);
    final xMed = mapX(s.median);
    final xQ3 = mapX(s.q3);
    final xMax = mapX(s.max);

    canvas.drawLine(Offset(xMin, y), Offset(xMax, y), whisker);
    canvas.drawRect(Rect.fromLTRB(xQ1, y - 40, xQ3, y + 40), box);
    canvas.drawRect(
      Rect.fromLTRB(xQ1, y - 40, xQ3, y + 40),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(Offset(xMed, y - 40), Offset(xMed, y + 40), whisker);
    canvas.drawLine(Offset(xMin, y - 20), Offset(xMin, y + 20), whisker);
    canvas.drawLine(Offset(xMax, y - 20), Offset(xMax, y + 20), whisker);
  }

  @override
  bool shouldRepaint(covariant BoxPlotPainter oldDelegate) {
    return oldDelegate.summary != summary || oldDelegate.color != color;
  }
}
