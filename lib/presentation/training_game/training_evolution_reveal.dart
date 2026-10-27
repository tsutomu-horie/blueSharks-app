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

  static const visualDuration = Duration(milliseconds: 1700);
  static Duration pageDuration(bool firstTeam) =>
      Duration(milliseconds: firstTeam ? 2700 : 2400);

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
                      ? _animation.value * 1.7
                      : widget.animation!.value *
                          widget.sceneDuration!.inMilliseconds /
                          1000;
                  if (t >= 1.7) {
                    return Center(child: afterImage());
                  }
                  final light = _glow(t);
                  final switched = t >= 1.05;
                  final pulse = 1 +
                      math.sin(_phase(t, .4, .6) * math.pi * 4) *
                          .018 *
                          (1 - _phase(t, .9, .15));
                  // 進化後の通常表示の底辺に、進化前の素材もそろえます。
                  final bottom = (outerHeight - afterSize.height) / 2;
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
                                      child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                              Colors.white.withValues(
                                                  alpha: light * .95),
                                              BlendMode.srcATop),
                                          child: image)))));
                  return Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: Size(width, height),
                        painter: _EvolutionLight(t, widget.firstTeam, false)),
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
                        scale: 1 + .045 * (1 - _ease(t, 1.1, .6)),
                        scaleKey:
                            const ValueKey('training-evolution-after-scale')),
                    IgnorePointer(
                        child: CustomPaint(
                            size: Size(width, height),
                            painter:
                                _EvolutionLight(t, widget.firstTeam, true))),
                  ]);
                }));
      });
}

double _phase(double t, double start, double span) =>
    ((t - start) / span).clamp(0.0, 1.0);
double _ease(double t, double start, double span) =>
    Curves.easeOutCubic.transform(_phase(t, start, span));
double _glow(double t) => t < 1.05
    ? Curves.easeInOut.transform(_phase(t, .45, .6))
    : 1 - _ease(t, 1.05, .65);

class _EvolutionLight extends CustomPainter {
  _EvolutionLight(this.t, this.firstTeam, this.foreground);
  final double t;
  final bool firstTeam;
  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final light = _glow(t);
    final unit = math.min(size.width / 300, size.height / 390);
    if (light > 0) {
      final radius = (foreground ? 155 * light : 125 + light * 38) * unit;
      final colors = foreground
          ? [
              Colors.white.withValues(alpha: light * .88),
              Colors.white.withValues(alpha: light * .65),
              Colors.white.withValues(alpha: 0),
            ]
          : [
              const Color(0xffffe6a0).withValues(alpha: light * .68),
              const Color(0xffffe6a0).withValues(alpha: light * .22),
              const Color(0xffffe6a0).withValues(alpha: 0),
            ];
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
                    colors: colors,
                    stops: foreground ? const [0, .45, 1] : null)
                .createShader(Rect.fromCircle(center: center, radius: radius)));
    }
    if (!foreground && t >= .45 && t < 1.05) {
      final q = _phase(t, .45, .6);
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi / 5;
        final radius = (140 * (1 - q) + 32) * unit;
        canvas.drawCircle(
            center +
                Offset(
                    math.cos(angle) * radius, math.sin(angle) * radius * .85),
            (1.8 + 1.2 * q) * unit,
            Paint()
              ..color = const Color(0xffffd674)
                  .withValues(alpha: math.sin(q * math.pi) * .9));
      }
    }
    if (foreground && t >= 1.2 && t < 1.7) {
      final a = math.sin(_phase(t, 1.2, .5) * math.pi);
      canvas.drawCircle(
          center,
          (70 + 90 * _ease(t, 1.2, .5)) * unit,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (firstTeam ? 2 : 1.2) * unit
            ..color = const Color(0xffffcf65)
                .withValues(alpha: a * (firstTeam ? .8 : .38)));
      if (firstTeam) {
        for (final delta in const [
          Offset(-98, -95),
          Offset(105, -60),
          Offset(90, 90)
        ]) {
          final point = center + delta * unit;
          final length = 6 * a * unit;
          final pen = Paint()
            ..color = const Color(0xffe7b445).withValues(alpha: a)
            ..strokeWidth = 1.5 * unit;
          canvas.drawLine(
              point - Offset(length, 0), point + Offset(length, 0), pen);
          canvas.drawLine(
              point - Offset(0, length), point + Offset(0, length), pen);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionLight old) =>
      old.t != t || old.firstTeam != firstTeam || old.foreground != foreground;
}
