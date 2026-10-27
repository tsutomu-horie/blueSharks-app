import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sametaroh_asset.dart';

/// 既存の鮫太郎素材を使い、進化前から進化後へ一度だけ切り替えます。
class TrainingEvolutionReveal extends StatefulWidget {
  const TrainingEvolutionReveal({
    required this.beforeFrame,
    required this.afterFrame,
    this.beforeScale = 0.86,
    this.afterVisual,
    super.key,
  });

  final SametarohFrame beforeFrame;
  final SametarohFrame afterFrame;
  final double beforeScale;

  /// 完了後に使う通常表示と同じレイアウトの最初のフレーム。
  /// 進化演出の終端と次画面で同じWidgetを使い、寸法と足元を揃えます。
  final Widget? afterVisual;

  @override
  State<TrainingEvolutionReveal> createState() =>
      _TrainingEvolutionRevealState();
}

class _TrainingEvolutionRevealState extends State<TrainingEvolutionReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _duration = Duration(milliseconds: 1700);

  late final AnimationController _animation;
  bool _resumeAfterLifecyclePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(vsync: this, duration: _duration)
      ..forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_resumeAfterLifecyclePause && !_animation.isCompleted) {
        _resumeAfterLifecyclePause = false;
        unawaited(_animation.forward(from: _animation.value));
      }
      return;
    }

    if (_animation.isAnimating) {
      _resumeAfterLifecyclePause = true;
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 300.0).toDouble();
        final height = math.min(constraints.maxHeight, 390.0).toDouble();
        final imageWidth = width * 0.82;
        final imageHeight = height * 0.9;
        Widget afterFrameImage() =>
            widget.afterVisual ??
            SametarohFrameImage(
              frame: widget.afterFrame,
              width: imageWidth,
              height: imageHeight,
              alignment: Alignment.bottomCenter,
              semanticLabel: '鮫太郎（進化後）',
            );

        return SizedBox(
          // 通常表示と同じ親制約を維持する。演出装飾の300×390上限で
          // afterVisualの250.w等を縮めると「次へ」で再拡大してしまう。
          width: widget.afterVisual == null ? width : constraints.maxWidth,
          height: widget.afterVisual == null ? height : constraints.maxHeight,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final progress = _animation.value;
              if (_animation.isCompleted) {
                // SizedBoxは子へtight制約を渡すため、Stackを外して画像を
                // 直返しすると演出枠いっぱいへ拡大される。演出中と同じ
                // 中央配置で、最後のtickにscale/translationを変えない。
                return Center(child: afterFrameImage());
              }
              final fade = Curves.easeInOut.transform(
                const Interval(0.32, 0.58).transform(progress),
              );
              final reveal = Curves.easeOutCubic.transform(
                const Interval(0.18, 0.82).transform(progress),
              );
              final sparkle = math
                  .sin(
                    math.pi * const Interval(0.25, 0.8).transform(progress),
                  )
                  .clamp(0.0, 1.0)
                  .toDouble();

              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1 - fade,
                    child: Transform.scale(
                      alignment: Alignment.bottomCenter,
                      scale: widget.beforeScale * (1 - 0.08 * fade),
                      child: SametarohFrameImage(
                        frame: widget.beforeFrame,
                        width: imageWidth,
                        height: imageHeight,
                        alignment: Alignment.bottomCenter,
                        semanticLabel: '鮫太郎（進化前）',
                      ),
                    ),
                  ),
                  if (sparkle > 0)
                    Transform.scale(
                      scale: 0.6 + 0.55 * sparkle,
                      child: Opacity(
                        opacity: sparkle * 0.85,
                        child: Container(
                          width: width * 0.58,
                          height: width * 0.58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffffd66b),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffffd66b)
                                    .withValues(alpha: 0.35 * sparkle),
                                blurRadius: 22,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      key: const ValueKey('training-evolution-after-scale'),
                      alignment: Alignment.bottomCenter,
                      scale: 0.62 + 0.38 * reveal,
                      child: afterFrameImage(),
                    ),
                  ),
                  Positioned(
                    top: height * 0.12,
                    right: width * 0.18,
                    child: Opacity(
                      opacity: sparkle,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: const Color(0xffffc847),
                        size: width * 0.11,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
