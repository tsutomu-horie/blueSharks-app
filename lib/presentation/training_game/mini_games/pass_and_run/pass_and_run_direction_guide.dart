import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A direction cue, not a catch area. The field clips it without moving its anchor.
class PassRunDirectionGuidePainter extends CustomPainter {
  const PassRunDirectionGuidePainter({
    required this.center,
    required this.attackUp,
    required this.seconds,
  });

  final Offset center;
  final bool attackUp;
  final double seconds;

  double get opacity => (1 - math.cos(2 * math.pi * seconds / 3.2)) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromCircle(center: center, radius: 100);
    final area = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(circle, attackUp ? 0 : math.pi, math.pi, false)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = Colors.white.withValues(alpha: .10 * opacity),
    );
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: .58 * opacity)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final unit in [
      const Offset(-1, 0),
      Offset(0, attackUp ? 1 : -1),
      const Offset(1, 0),
    ]) {
      final end = center + unit * 96;
      canvas.drawLine(center + unit * 77, end, stroke);
      final angle = math.atan2(unit.dy, unit.dx);
      for (final turn in [-.55, .55]) {
        canvas.drawLine(
          end,
          end - Offset(math.cos(angle + turn), math.sin(angle + turn)) * 7,
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PassRunDirectionGuidePainter oldDelegate) =>
      center != oldDelegate.center ||
      attackUp != oldDelegate.attackUp ||
      seconds != oldDelegate.seconds;
}
