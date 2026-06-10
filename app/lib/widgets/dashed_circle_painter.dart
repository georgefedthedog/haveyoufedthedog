import 'package:flutter/material.dart';

/// Dashed circular outline, optionally filled solid. Used for ghosted
/// "drop here" / "add new" affordances (the remove-member bin, the
/// add-chore chip).
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final bool filled;

  const DashedCirclePainter({required this.color, this.filled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;

    if (filled) {
      canvas.drawCircle(center, radius, Paint()..color = color);
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashCount = 18;
    const sweepPerDash = (2 * 3.141592653589793) / dashCount;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweepPerDash, sweepPerDash * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) =>
      old.color != color || old.filled != filled;
}
