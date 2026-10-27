import 'dart:async';
import 'dart:math' as math;

import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

import 'package:flutter/material.dart';

import 'sametaroh_asset.dart';

/// 支給原画の卵2コマと幼体を用いた、新規開始専用の孵化演出です。
class TrainingHatchingScene extends StatefulWidget {
  const TrainingHatchingScene({
    super.key,
    required this.isPlaying,
    required this.onCompleted,
    this.onLoadFailed,
    this.soundFactory,
  });

  static const eggAsset = 'assets/images/training_game/hatching/egg_1.png';
  static const silhouetteAsset =
      'assets/images/training_game/hatching/egg_2.png';
  static const duration = Duration(milliseconds: 4200);

  final bool isPlaying;
  final VoidCallback onCompleted;
  final VoidCallback? onLoadFailed;
  final TrainingGameSoundService Function()? soundFactory;

  @override
  State<TrainingHatchingScene> createState() => _TrainingHatchingSceneState();
}

class _TrainingHatchingSceneState extends State<TrainingHatchingScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  bool _completed = false;
  bool _foreground = true;
  bool _assetsReady = false;
  bool _preloading = false;
  bool _soundReady = false;
  bool _started = false;
  bool _soundPaused = false;
  TrainingGameSoundService? _sound;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _animation = AnimationController(
      vsync: this,
      duration: TrainingHatchingScene.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          widget.onCompleted();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloading) {
      _preloading = true;
      // デコードを待ってから進め、初回表示でも卵の揺れを見逃しません。
      var loadFailed = false;
      void onImageError(Object error, StackTrace? stackTrace) =>
          loadFailed = true;
      Future.wait([
        precacheImage(const AssetImage(TrainingHatchingScene.eggAsset), context,
            onError: onImageError),
        precacheImage(
            const AssetImage(TrainingHatchingScene.silhouetteAsset), context,
            onError: onImageError),
        precacheImage(AssetImage(SametarohAssets.newbornFrame.asset), context,
            onError: onImageError),
      ]).then((_) {
        if (!mounted) return;
        if (loadFailed) {
          widget.onLoadFailed?.call();
          return;
        }
        _assetsReady = true;
        unawaited(_prepareSound());
      });
    } else if (_assetsReady) {
      _play();
    }
  }

  Future<void> _prepareSound() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sound = reduceMotion ? null : widget.soundFactory?.call();
    _sound = sound;
    final loaded = sound == null ||
        await sound
            .prepare(TrainingGameSoundEffect.hatching)
            .timeout(const Duration(milliseconds: 600), onTimeout: () => false);
    if (!mounted) return;
    if (!loaded) {
      unawaited(sound.dispose());
      _sound = null;
    }
    _soundReady = true;
    _play();
  }

  @override
  void didUpdateWidget(covariant TrainingHatchingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) _play();
    if (!widget.isPlaying && oldWidget.isPlaying) _pause();
  }

  void _play() {
    if (!_assetsReady ||
        !_soundReady ||
        !widget.isPlaying ||
        !_foreground ||
        _completed) {
      return;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _animation.duration = reduceMotion
        ? const Duration(milliseconds: 450)
        : TrainingHatchingScene.duration;
    if (reduceMotion) {
      unawaited(_sound?.dispose());
      _sound = null;
    }
    if (!_started) {
      _started = true;
      _animation.forward();
      unawaited(_sound?.play(TrainingGameSoundEffect.hatching));
    } else if (!_animation.isAnimating) {
      _animation.forward();
      if (_soundPaused) {
        _soundPaused = false;
        unawaited(_sound?.resume());
      }
    }
  }

  void _pause() {
    _animation.stop(canceled: false);
    if (_started) {
      _soundPaused = true;
      unawaited(_sound?.pause());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _play();
    } else {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    unawaited(_sound?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        final reveal = ((t - .57) / .24).clamp(0.0, 1.0).toDouble();
        final emerge = Curves.easeOutBack.transform(reveal);
        final shellOpacity = 1.0 - ((t - .52) / .13).clamp(0.0, 1.0).toDouble();
        final pulse = math.sin(((t - .42) / .36).clamp(0.0, 1.0) * math.pi);
        final shaking = t > .08 && t < .57;
        final shake = shaking ? math.sin(t * math.pi * 34) * .075 : 0.0;
        final message = t < .18
            ? 'もうすぐ、会えるね。'
            : t < .57
                ? 'あれ？ 卵が動きはじめた！'
                : 'はじめまして、鮫太朗！';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: message,
              image: true,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.white.withValues(alpha: .95),
                            const Color(0xffbfeaff).withValues(alpha: .15),
                          ]),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        child: Container(
                          width: 100 + reveal * 10,
                          height: 13,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xff245e78).withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      if (shellOpacity > 0)
                        Opacity(
                          opacity: shellOpacity,
                          child: Transform.rotate(
                            angle: shake,
                            alignment: Alignment.bottomCenter,
                            child: Transform.scale(
                              scale: 1 + pulse * .08,
                              child: Image.asset(
                                t < .3
                                    ? TrainingHatchingScene.eggAsset
                                    : TrainingHatchingScene.silhouetteAsset,
                                width: 280,
                                height: 280,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      if (pulse > 0)
                        IgnorePointer(
                          child: Transform.scale(
                            scale: .5 + pulse * .9,
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  Colors.white.withValues(alpha: pulse),
                                  const Color(0xffffecc0)
                                      .withValues(alpha: pulse * .6),
                                  Colors.white.withValues(alpha: 0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      if (reveal > 0)
                        Positioned(
                          bottom: 35 + math.sin(reveal * math.pi) * 24,
                          child: Opacity(
                            opacity: reveal,
                            child: Transform.scale(
                              scale: .65 + emerge * .35,
                              alignment: Alignment.bottomCenter,
                              child: Image.asset(
                                SametarohAssets.newbornFrame.asset,
                                width: 120,
                                height: 190,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      if (t > .54)
                        Positioned.fill(
                          child: CustomPaint(painter: _HatchingSparkles(t: t)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff124b72),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reveal > .5 ? '小さな一歩から、一緒に育っていこう。' : '新しい出会いが、ここからはじまります。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff496d80), fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}

class _HatchingSparkles extends CustomPainter {
  const _HatchingSparkles({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = ((t - .54) / .46).clamp(0.0, 1.0).toDouble();
    final center = Offset(size.width / 2, size.height * .52);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final radius = 45 + Curves.easeOut.transform(progress) * 88;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final paint = Paint()
        ..color = (i.isEven ? const Color(0xffffc95f) : const Color(0xff50b7d6))
            .withValues(alpha: (1 - progress) * .9);
      final r = (i.isEven ? 6.0 : 4.0) * (1 - progress * .5);
      final path = Path()
        ..moveTo(point.dx, point.dy - r)
        ..lineTo(point.dx + r * .45, point.dy)
        ..lineTo(point.dx, point.dy + r)
        ..lineTo(point.dx - r * .45, point.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchingSparkles oldDelegate) =>
      oldDelegate.t != t;
}
