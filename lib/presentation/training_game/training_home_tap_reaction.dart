import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 素材と足元を保ったまま、承認済みの3種類のタップ反応を描画します。
class TrainingHomeTapReaction extends StatelessWidget {
  const TrainingHomeTapReaction(
      {super.key,
      required this.progress,
      required this.variant,
      required this.reducedMotion,
      required this.child});
  final double progress;
  final int variant;
  final bool reducedMotion;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    var sx = 1.0, sy = 1.0, dy = 0.0, angle = 0.0;
    if (!reducedMotion && progress < 1) {
      final t = progress.clamp(0.0, 1.0) * .75;
      if (t < .12) {
        final a = math.sin(t / .12 * math.pi / 2);
        sx = 1 + .06 * a;
        sy = 1 - .08 * a;
      } else {
        final u = (t - .12) / .63;
        final settle = math.exp(-u * 5) * math.sin(u * math.pi * 4);
        final press = math.exp(-u * 12) * (1 - u);
        sx = 1 + .06 * press - .035 * settle;
        sy = 1 - .08 * press + .045 * settle;
        dy = -math.sin(math.min(1.0, u / .65) * math.pi) *
            (variant == 2 ? 16 : 10);
        if (variant == 1) angle = math.sin(u * math.pi * 3) * .055 * (1 - u);
        if (variant == 2 && u > .6) dy -= 5 * math.sin((u - .6) / .4 * math.pi);
      }
    }
    return Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
                scaleX: sx,
                scaleY: sy,
                alignment: Alignment.bottomCenter,
                child: child)));
  }
}
