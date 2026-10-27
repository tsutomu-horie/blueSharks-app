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
  const TrainingEndingEntrance({super.key, required this.builder});

  final Widget Function(BuildContext context, Animation<double> animation)
      builder;

  @override
  State<TrainingEndingEntrance> createState() => _TrainingEndingEntranceState();
}

class _TrainingEndingEntranceState extends State<TrainingEndingEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _animation.forward();
    }
  }

  @override
  void dispose() {
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
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final progress = Curves.easeOutCubic
              .transform(((animation.value - start) / .3).clamp(0.0, 1.0));
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
