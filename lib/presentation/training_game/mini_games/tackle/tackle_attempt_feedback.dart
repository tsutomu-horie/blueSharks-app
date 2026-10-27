import 'dart:math';
import 'package:flutter/material.dart';

/// 判定の意味を変えず、接触した位置とランクに応じて短い手応えを表示します。
class TackleAttemptFeedback extends StatefulWidget {
  const TackleAttemptFeedback(
      {super.key,
      required this.rank,
      required this.succeeded,
      required this.contactPoint,
      required this.impactDelay});
  final String rank;
  final bool succeeded;
  final Offset contactPoint;
  final Duration impactDelay;

  @override
  State<TackleAttemptFeedback> createState() => _TackleAttemptFeedbackState();
}

class _TackleAttemptFeedbackState extends State<TackleAttemptFeedback>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      _animation.forward();
    } else {
      _animation.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 短い判定演出を、アプリへ戻った後に遅れて再生しません。
    if (state != AppLifecycleState.resumed) _animation.value = 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = widget.rank == 'PERFECT'
        ? 3
        : widget.rank == 'GREAT'
            ? 2
            : widget.rank == 'GOOD'
                ? 1
                : 0;
    final color = !widget.succeeded
        ? const Color(0xffa74842)
        : strength == 3
            ? const Color(0xffb27b0b)
            : strength == 2
                ? const Color(0xff087ba4)
                : const Color(0xff002b6d);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
        child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final elapsed = _animation.value * 1.1 -
                  widget.impactDelay.inMicroseconds / 1000000;
              final p = (elapsed / .65).clamp(0.0, 1.0);
              final opacity = reduced
                  ? (_animation.value < .8 ? 1.0 : 0.0)
                  : elapsed < 0
                      ? 0.0
                      : 1 - ((p - .6) / .4).clamp(0.0, 1.0);
              final duration = [.26, .33, .42, .48][strength];
              return Semantics(
                  key: ValueKey(widget.succeeded
                      ? 'tackle-feedback-success'
                      : 'tackle-feedback-miss'),
                  label: '判定 ${widget.rank}',
                  excludeSemantics: true,
                  hidden: opacity == 0,
                  child: Stack(fit: StackFit.expand, children: [
                    if (!reduced &&
                        widget.succeeded &&
                        elapsed >= 0 &&
                        elapsed < duration)
                      CustomPaint(
                          painter: TackleImpactPainter(widget.contactPoint,
                              elapsed / duration, strength)),
                    Center(
                        child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                                scale: reduced
                                    ? 1
                                    : 1 +
                                        (widget.succeeded
                                                ? [.02, .04, .08, .12][strength]
                                                : 0) *
                                            (1 -
                                                Curves.easeOutCubic.transform(
                                                    (p / .35).clamp(0.0, 1.0))),
                                child: Text(widget.rank,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: widget.succeeded
                                            ? [24.0, 26.0, 29.0, 32.0][strength]
                                            : 26,
                                        fontWeight: FontWeight.w900,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.white,
                                              blurRadius: 8),
                                          Shadow(
                                              color: Colors.white,
                                              blurRadius: 3)
                                        ]))))),
                  ]));
            }));
  }
}

class TackleImpactPainter extends CustomPainter {
  TackleImpactPainter(this.point, this.progress, this.strength);
  final Offset point;
  final double progress;
  final int strength;
  @override
  void paint(Canvas c, Size s) {
    final p = Curves.easeOutCubic.transform(progress);
    final color =
        strength == 3 ? const Color(0xffffd56b) : const Color(0xff5fcbea);
    final radius = [30.0, 42.0, 58.0, 70.0][strength];
    c.drawCircle(
        point,
        8 + radius * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strength == 0 ? 1.5 : 2.5
          ..color = color.withValues(
              alpha: (1 - progress) * (strength == 0 ? .65 : 1)));
    if (strength >= 2) {
      c.drawCircle(
          point,
          6 + radius * .58 * p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 1 - progress));
    }
    if (strength >= 1) {
      final r = 4 + radius * .6 * p;
      c.drawCircle(
          point,
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              Colors.white.withValues(
                  alpha: (1 - progress) * (strength == 3 ? .5 : .2)),
              Colors.white.withValues(alpha: 0)
            ]).createShader(Rect.fromCircle(center: point, radius: r)));
      final count = strength == 3
          ? 8
          : strength == 2
              ? 6
              : 4;
      for (var i = 0; i < count; i++) {
        final a = i * pi * 2 / count + .25;
        c.drawLine(
            point + Offset(cos(a), sin(a)) * (12 + radius * .4 * p),
            point + Offset(cos(a), sin(a)) * (16 + radius * .72 * p),
            Paint()
              ..strokeWidth = strength == 3 ? 2 : 1.2
              ..strokeCap = StrokeCap.round
              ..color = color.withValues(alpha: 1 - progress));
      }
    }
  }

  @override
  bool shouldRepaint(covariant TackleImpactPainter old) =>
      old.progress != progress ||
      old.strength != strength ||
      old.point != point;
}

/// コートのラインデータとは別に描く、上下の入力領域の境目。
class TackleInputDividerPainter extends CustomPainter {
  const TackleInputDividerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeWidth = 1.5;
    for (var x = 16.0; x < size.width - 16; x += 16) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset((x + 8).clamp(16, size.width - 16), size.height / 2), pen);
    }
  }

  @override
  bool shouldRepaint(covariant TackleInputDividerPainter old) => false;
}

class TackleInputGuide extends StatelessWidget {
  const TackleInputGuide(
      {super.key,
      required this.up,
      required this.tapped,
      required this.attempt});
  final bool up;
  final bool tapped;
  final int attempt;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        if (tapped && !MediaQuery.disableAnimationsOf(context))
          TweenAnimationBuilder<double>(
              key: ValueKey(attempt),
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 220),
              builder: (context, p, _) => ColoredBox(
                  color: const Color(0xff4ea4d0).withValues(alpha: .16 * p))),
        Align(
            alignment: up ? Alignment.topCenter : Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(18)),
                    child: SizedBox(
                        width: 44,
                        height: 32,
                        child: Icon(
                            up
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 28,
                            color: const Color(0xff002b6d)
                                .withValues(alpha: .7)))))),
      ]);
}
