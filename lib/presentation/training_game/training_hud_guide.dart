import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum TrainingHudGuideItem {
  food('食事'),
  work('仕事'),
  cleanliness('清潔'),
  condition('体調'),
  miniGame('練習/MG');

  const TrainingHudGuideItem(this.title);

  final String title;
}

abstract final class TrainingHudGuide {
  static String messageFor(
    TrainingHudGuideItem item, {
    bool unlocked = true,
  }) {
    if (!unlocked) {
      return switch (item) {
        TrainingHudGuideItem.work => 'もう少し育つと、仕事ができるようになります。',
        TrainingHudGuideItem.miniGame => 'もう少し育つと、ミニゲームで遊べるようになります。',
        _ => _unlockedMessages[item]!,
      };
    }
    return _unlockedMessages[item]!;
  }

  static const _unlockedMessages = <TrainingHudGuideItem, String>{
    TrainingHudGuideItem.food: '食事の状態を表します。時間の経過や行動で減るため、ごはんで補いましょう。',
    TrainingHudGuideItem.work: '仕事への取り組みを表します。仕事は1日1回行えます。実行後は食事と体調にも気を配りましょう。',
    TrainingHudGuideItem.cleanliness: '清潔さを表します。時間の経過や行動で低下するため、定期的に掃除をしましょう。',
    TrainingHudGuideItem.condition: '体の調子を表します。疲れがたまったときは、休養をとって回復させましょう。',
    TrainingHudGuideItem.miniGame:
        'タップしてミニゲームを選びます。プレイすると仕事の値が上がりますが、食事・清潔・体調を消費するため、お世話も必要です。',
  };

  static Future<void> show(
    BuildContext context,
    TrainingHudGuideItem item, {
    bool unlocked = true,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('training-hud-guide-dialog'),
        title: Text(item.title),
        content: Text(messageFor(item, unlocked: unlocked)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// 子の短いタップ動作を維持し、長押しが完了するまで丸い進捗表示を出します。
class TrainingHudGuidePressTarget extends StatefulWidget {
  const TrainingHudGuidePressTarget({
    required this.child,
    required this.semanticsLabel,
    required this.onLongPressGuide,
    this.onTap,
    this.holdDuration = const Duration(milliseconds: 700),
    this.progressDiameter = 38,
    super.key,
  }) : assert(progressDiameter > 0);

  final Widget child;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final VoidCallback onLongPressGuide;
  final Duration holdDuration;
  final double progressDiameter;

  @override
  State<TrainingHudGuidePressTarget> createState() =>
      _TrainingHudGuidePressTargetState();
}

class _TrainingHudGuidePressTargetState
    extends State<TrainingHudGuidePressTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Offset? _progressCenter;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
  }

  @override
  void didUpdateWidget(covariant TrainingHudGuidePressTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _progressController.duration = widget.holdDuration;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress(LongPressDownDetails details) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final radius = widget.progressDiameter / 2;
    final size = renderObject.size;
    final maxX = math.max(radius, size.width - radius);
    final maxY = math.max(radius, size.height - radius);
    final center = Offset(
      details.localPosition.dx.clamp(math.min(radius, maxX), maxX).toDouble(),
      details.localPosition.dy.clamp(math.min(radius, maxY), maxY).toDouble(),
    );
    setState(() => _progressCenter = center);
    _progressController.forward(from: 0);
  }

  void _clearProgress() {
    if (_progressCenter == null) return;
    _progressController.stop();
    _progressController.value = 0;
    setState(() => _progressCenter = null);
  }

  void _completeLongPress(LongPressStartDetails details) {
    _clearProgress();
    widget.onLongPressGuide();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPressGuide,
      child: ExcludeSemantics(
        child: RawGestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.translucent,
          gestures: {
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: widget.holdDuration),
              (recognizer) => recognizer
                ..onLongPressDown = _startProgress
                ..onLongPressStart = _completeLongPress
                ..onLongPressCancel = _clearProgress
                ..onLongPressEnd = (_) => _clearProgress(),
            ),
          },
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final center = _progressCenter;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (child != null) child,
                  if (center != null)
                    Positioned(
                      left: center.dx - widget.progressDiameter / 2,
                      top: center.dy - widget.progressDiameter / 2,
                      width: widget.progressDiameter,
                      height: widget.progressDiameter,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: CircularProgressIndicator(
                              value: _progressController.value,
                              strokeWidth: 3,
                              color: const Color(0xffe4872b),
                              backgroundColor: const Color(0xffdce5ee),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
