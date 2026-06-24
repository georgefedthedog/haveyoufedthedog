import 'package:flutter/material.dart';

/// Dashed rounded-rectangle outline - the rounded-square sibling of
/// [DashedCirclePainter], for square "drop here" affordances. Walks the
/// rounded-rect path and lays evenly-spaced dashes along it.
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedRRectPainter({
    required this.color,
    this.radius = 20,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dashLength;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0.0, metric.length)),
          paint,
        );
        dist = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
