import 'dart:async';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:flutter/material.dart';

/// お世話画面を短いフェードと小さな移動でホームにつなぎます。
class TrainingCareRoute<T> extends PageRouteBuilder<T> {
  TrainingCareRoute({required WidgetBuilder builder, bool reduceMotion = false})
      : super(
          opaque: false,
          transitionDuration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
          reverseTransitionDuration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final progress = Curves.easeOutCubic.transform(animation.value);
            final distance =
                animation.status == AnimationStatus.reverse ? 10.0 : 24.0;
            return Stack(fit: StackFit.expand, children: [
              ColoredBox(color: Colors.black.withValues(alpha: .2 * progress)),
              Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, distance * (1 - progress)),
                  child: child,
                ),
              ),
            ]);
          },
        );
}

/// 完了画面の各要素で共有する、一度だけ進む登場アニメーションです。
class TrainingEndingEntrance extends StatefulWidget {
  const TrainingEndingEntrance(
      {super.key,
      required this.builder,
      this.duration = const Duration(milliseconds: 900),
      this.soundFactory,
      this.soundEffect});

  final Duration duration;
  final TrainingGameSoundService Function()? soundFactory;
  final TrainingGameSoundEffect? soundEffect;

  final Widget Function(BuildContext context, Animation<double> animation)
      builder;

  @override
  State<TrainingEndingEntrance> createState() => _TrainingEndingEntranceState();
}

class _TrainingEndingEntranceState extends State<TrainingEndingEntrance>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;
  bool _active = true;
  bool _preparing = false;
  bool _ready = false;
  TrainingGameSoundService? _sound;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  Future<void> _start() async {
    if (_started || _preparing || !_active) return;
    if (!_ready) {
      _preparing = true;
      final sound = widget.soundFactory?.call();
      _sound = sound;
      var loaded = true;
      if (sound != null && widget.soundEffect != null) {
        loaded = await sound
            .prepare(widget.soundEffect!)
            .timeout(const Duration(milliseconds: 600), onTimeout: () => false);
      }
      if (!mounted) return;
      _preparing = false;
      _ready = true;
      if (!loaded) {
        unawaited(sound?.dispose());
        _sound = null;
      }
    }
    if (!_active || _started) return;
    _started = true;
    _animation.forward();
    if (widget.soundEffect != null) {
      unawaited(_sound?.play(widget.soundEffect!));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      if (!_started) {
        unawaited(_start());
      } else {
        if (!_animation.isCompleted) _animation.forward();
        unawaited(_sound?.resume());
      }
    } else {
      _animation.stop(canceled: false);
      if (_started) unawaited(_sound?.pause());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
      _started = true;
      unawaited(_sound?.dispose());
      _sound = null;
    } else {
      unawaited(_start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sound?.dispose());
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _animation);
}

/// 配置を変えず、キャラ・見出し・説明・ボタンを順に見せます。
class TrainingEndingItem extends StatelessWidget {
  const TrainingEndingItem({
    super.key,
    required this.animation,
    required this.start,
    this.span = .3,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final double span;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final progress = animation.isCompleted
              ? 1.0
              : Curves.easeOutCubic.transform(
                  ((animation.value - start) / span).clamp(0.0, 1.0));
          return IgnorePointer(
            ignoring: progress < 1,
            child: ExcludeSemantics(
              excluding: progress < 1,
              child: Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - progress)),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}
