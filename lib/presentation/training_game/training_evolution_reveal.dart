import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

import 'sametaroh_asset.dart';

/// 承認済みの予兆・局所発光・お披露目を既存素材で描画します。
class TrainingEvolutionReveal extends StatefulWidget {
  const TrainingEvolutionReveal({
    required this.beforeFrame,
    required this.afterFrame,
    this.beforeScale = .86,
    this.beforeSize,
    this.afterSize,
    this.afterVisual,
    this.firstTeam = false,
    this.soundFactory,
    this.animation,
    this.sceneDuration,
    super.key,
  })  : assert(afterVisual == null || afterSize != null),
        assert(animation == null || sceneDuration != null);

  static const visualDuration = Duration(milliseconds: 7000);
  static Duration pageDuration(bool firstTeam) =>
      Duration(milliseconds: firstTeam ? 8100 : 7800);

  final SametarohFrame beforeFrame;
  final SametarohFrame afterFrame;
  final double beforeScale;
  final Size? beforeSize;
  final Size? afterSize;
  final Widget? afterVisual;
  final bool firstTeam;

  /// 画面ごとの所有権を持つ効果音。単体の描画検証では省略できます。
  final TrainingGameSoundService Function()? soundFactory;
  final Animation<double>? animation;
  final Duration? sceneDuration;

  TrainingEvolutionReveal drivenBy(
          Animation<double> clock, Duration duration) =>
      TrainingEvolutionReveal(
          key: key,
          beforeFrame: beforeFrame,
          afterFrame: afterFrame,
          beforeScale: beforeScale,
          beforeSize: beforeSize,
          afterSize: afterSize,
          afterVisual: afterVisual,
          firstTeam: firstTeam,
          animation: clock,
          sceneDuration: duration);

  @override
  State<TrainingEvolutionReveal> createState() =>
      _TrainingEvolutionRevealState();
}

class _TrainingEvolutionRevealState extends State<TrainingEvolutionReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: TrainingEvolutionReveal.visualDuration);
  bool _started = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animation != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _animation.value = 1;
    } else {
      _start();
    }
  }

  void _start() {
    if (_started || !_active) return;
    _started = true;
    _animation.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.animation != null) return;
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      if (!_started) {
        _start();
      } else if (!_animation.isCompleted) {
        _animation.forward();
      }
    } else {
      _animation.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 300.0);
        final height = math.min(constraints.maxHeight, 390.0);
        final fallback = Size(width * .82, height * .9);
        final beforeSize = widget.beforeSize ?? fallback;
        final afterSize = widget.afterSize ??
            (widget.afterVisual == null
                ? fallback
                : widget.firstTeam
                    ? const Size(250, 250)
                    : const Size(128, 184));
        final outerWidth =
            widget.afterVisual == null ? width : constraints.maxWidth;
        final outerHeight =
            widget.afterVisual == null ? height : constraints.maxHeight;
        Widget afterImage() =>
            widget.afterVisual ??
            SametarohFrameImage(
                frame: widget.afterFrame,
                width: afterSize.width,
                height: afterSize.height,
                alignment: Alignment.bottomCenter,
                semanticLabel: '鮫太郎（進化後）');
        return SizedBox(
            width: outerWidth,
            height: outerHeight,
            child: AnimatedBuilder(
                animation: widget.animation ?? _animation,
                builder: (context, _) {
                  final t = widget.animation == null
                      ? _animation.value * 7
                      : widget.animation!.value *
                          widget.sceneDuration!.inMilliseconds /
                          1000;
                  if (t >= 7) return Center(child: afterImage());
                  final switched = t >= 4;
                  const pulse = 1.0;
                  // 進化後の通常表示の底辺に、進化前の素材もそろえます。
                  final bottom = (outerHeight - afterSize.height) / 2;
                  final bodyBounds = Rect.fromLTRB(
                    (outerWidth -
                            math.max(beforeSize.width * widget.beforeScale,
                                afterSize.width)) /
                        2,
                    outerHeight -
                        bottom -
                        math.max(beforeSize.height * widget.beforeScale,
                            afterSize.height),
                    (outerWidth +
                            math.max(beforeSize.width * widget.beforeScale,
                                afterSize.width)) /
                        2,
                    outerHeight - bottom,
                  );
                  Widget frame(Widget image,
                          {required bool visible,
                          required double scale,
                          Key? scaleKey}) =>
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: bottom,
                          child: Center(
                              heightFactor: 1,
                              child: Opacity(
                                  opacity: visible ? 1 : 0,
                                  child: Transform.scale(
                                      key: scaleKey,
                                      scale: scale,
                                      alignment: Alignment.bottomCenter,
                                      child: ShaderMask(
                                          blendMode: BlendMode.srcATop,
                                          shaderCallback: (bounds) =>
                                              LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withValues(
                                                      alpha:
                                                          _bodyLight(t, .65)),
                                                  Colors.white.withValues(
                                                      alpha: _bodyLight(t, 0)),
                                                ],
                                              ).createShader(bounds),
                                          child: image)))));
                  return ClipRect(
                      child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: Size(outerWidth, outerHeight),
                        painter: _EvolutionLight(
                            t, widget.firstTeam, false, bodyBounds)),
                    frame(
                        SametarohFrameImage(
                            frame: widget.beforeFrame,
                            width: beforeSize.width,
                            height: beforeSize.height,
                            alignment: Alignment.bottomCenter,
                            semanticLabel: '鮫太郎（進化前）'),
                        visible: !switched,
                        scale: widget.beforeScale * pulse),
                    frame(afterImage(),
                        visible: switched,
                        scale: 1,
                        scaleKey:
                            const ValueKey('training-evolution-after-scale')),
                    IgnorePointer(
                        child: CustomPaint(
                            size: Size(outerWidth, outerHeight),
                            painter: _EvolutionLight(
                                t, widget.firstTeam, true, bodyBounds))),
                  ]));
                }));
      });
}

double _phase(double t, double start, double span) =>
    ((t - start) / span).clamp(0.0, 1.0);
double _smooth(double t, double start, double end) {
  final q = _phase(t, start, end - start);
  return q * q * (3 - 2 * q);
}

double _bodyLight(double t, double delay) =>
    _smooth(t, 1.65 + delay, 3.3 + delay * .38) * (1 - _smooth(t, 4.45, 5.65));

/// 足元の予兆、上昇光、身体を完全に隠す光、余韻を同じ時計で描く。
class _EvolutionLight extends CustomPainter {
  _EvolutionLight(this.t, this.firstTeam, this.foreground, this.bodyBounds);
  final double t;
  final bool firstTeam;
  final bool foreground;
  final Rect bodyBounds;
  static const palette = [
    Color(0xff30a9e5),
    Color(0xff59d4ed),
    Color(0xff9a90de),
    Color(0xfff6d993)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = bodyBounds.center;
    final foot = Offset(center.dx, bodyBounds.bottom);
    final unit = math.min(size.width / 335, size.height / 390);
    final strength = _smooth(t, .05, 1.2) * (1 - _smooth(t, 4.6, 6.4));
    final rise = _smooth(t, .1, 1.8);
    final peak = math.exp(-math.pow((t - 3.9) / .6, 2));
    if (!foreground) {
      canvas.drawOval(
          Rect.fromCenter(center: foot, width: 150 * unit, height: 36 * unit),
          Paint()
            ..color = palette[1].withValues(alpha: .4 * strength)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * unit));
      for (var j = 0; j < 11; j++) {
        final side = (j - 5) / 5;
        final path = Path();
        for (var n = 0; n <= 30; n++) {
          final q = n / 30 * rise;
          final x = foot.dx +
              (side * (35 + 62 * q) + math.sin(q * 4 + t * 1.4 + j) * 5 * q) *
                  unit;
          final y = foot.dy - q * (bodyBounds.height + 20 + 27 * math.cos(j));
          if (n == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..color = palette[j % 3]
                  .withValues(alpha: (.18 + .25 * peak) * strength)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * unit);
      }
      for (var j = 0; j < 3; j++) {
        final q = (t * .36 + j / 3) % 1;
        final rx = (38 + q * 83) * unit;
        canvas.drawOval(
            Rect.fromCenter(center: foot, width: rx * 2, height: rx * .46),
            Paint()
              ..color = palette[j].withValues(alpha: .59 * (1 - q) * strength)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * unit);
      }
      return;
    }
    final cover = _smooth(t, 2.85, 3.6) * (1 - _smooth(t, 4.4, 5.45));
    // 固定した光の形で両画像の矩形全域を覆い、4秒の画像交換を隠す。
    // 楕円の内側に矩形四隅も入るようsqrt(2)より広い1.6倍で確保する。
    final shell = Rect.fromCenter(
      center: center,
      width: bodyBounds.width * 1.6,
      height: bodyBounds.height * 1.6,
    );
    canvas.drawOval(
        shell,
        Paint()
          ..color = palette[1].withValues(alpha: cover * .7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * unit));
    canvas.drawOval(shell,
        Paint()..color = const Color(0xfff0fdff).withValues(alpha: cover));
    for (var j = 0; j < 52; j++) {
      final a = ((j * .61803) % 1);
      final b = ((j * .41421) % 1);
      final q = (a + t * (.16 + .08 * b)) % 1;
      final point = Offset(
          foot.dx +
              ((b - .5) * (180 - 35 * q) + math.sin(t * 1.1 + j + q * 3) * 6) *
                  unit,
          foot.dy + 12 * unit - q * (bodyBounds.height + 70 * unit) * rise);
      final opacity = .7 * strength * math.sin(math.pi * q);
      final length = (1.2 + 1.9 * b) * unit;
      final pen = Paint()
        ..color = palette[j % 4].withValues(alpha: opacity)
        ..strokeWidth = 1.5 * unit
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          point - Offset(length, 0), point + Offset(length, 0), pen);
      canvas.drawLine(
          point - Offset(0, length), point + Offset(0, length), pen);
    }
    final celebration = _smooth(t, 4.95, 5.4) * (1 - _smooth(t, 5.7, 6.65));
    for (var j = 0; j < (firstTeam ? 16 : 12); j++) {
      final angle = j * math.pi * 2 / (firstTeam ? 16 : 12);
      final radius = (65 + math.max(0, t - 4.95) * 35) * unit;
      final point = center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius * 1.15);
      final pen = Paint()
        ..color =
            palette[j % 3 == 0 ? 3 : 1].withValues(alpha: .65 * celebration)
        ..strokeWidth = 1.6 * unit;
      final length = 2.6 * unit;
      canvas.drawLine(
          point - Offset(length, 0), point + Offset(length, 0), pen);
      canvas.drawLine(
          point - Offset(0, length), point + Offset(0, length), pen);
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionLight old) =>
      old.t != t ||
      old.firstTeam != firstTeam ||
      old.foreground != foreground ||
      old.bodyBounds != bodyBounds;
}
