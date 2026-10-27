import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 捕球時の短い中央表示と、受け手の足元の波紋。
class PassRunCatchFeedback extends StatelessWidget {
  const PassRunCatchFeedback({
    super.key,
    required this.progress,
    required this.receiver,
    required this.reducedMotion,
  });

  final double progress;
  final Offset receiver;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final bounce = reducedMotion ? 0.0 : math.sin(p * math.pi);
    return Opacity(
      opacity: reducedMotion ? 1 : 1 - p,
      child: Stack(children: [
        if (!reducedMotion)
          Positioned.fill(
              child: CustomPaint(painter: _CatchRipple(p, receiver))),
        Center(
          child: Transform.translate(
            offset: Offset(0, -12 * bounce),
            child: Transform.scale(
              scale: 1 + bounce * .12,
              child: const Text('NICE PASS',
                  key: Key('pass-catch-feedback'),
                  style: TextStyle(
                      color: Color(0xff124374),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.white, blurRadius: 5)])),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CatchRipple extends CustomPainter {
  _CatchRipple(this.progress, this.receiver);
  final double progress;
  final Offset receiver;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffe7faff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress) + 1;
    canvas.drawOval(
        Rect.fromCenter(
            center: receiver + const Offset(0, 35),
            width: 65 + 80 * progress,
            height: 18 + 25 * progress),
        paint);
    for (var i = 0; i < 6; i++) {
      final direction =
          Offset(math.cos(i * math.pi / 3), math.sin(i * math.pi / 3));
      final from = receiver + direction * (35 + 30 * progress);
      canvas.drawLine(from, from + direction * 8 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CatchRipple oldDelegate) =>
      progress != oldDelegate.progress || receiver != oldDelegate.receiver;
}
