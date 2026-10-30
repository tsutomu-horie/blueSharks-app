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
    this.progressDiameter = 88,
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
  OverlayEntry? _progressOverlay;

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
    _removeProgressOverlay();
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress(LongPressDownDetails details) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final radius = widget.progressDiameter / 2;
    final origin = renderObject.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final view = View.of(context);
    final safeInsets =
        EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio);
    final globalX = (origin.dx + details.localPosition.dx)
        .clamp(
            safeInsets.left + radius + 8,
            math.max(safeInsets.left + radius + 8,
                media.size.width - safeInsets.right - radius - 8))
        .toDouble();
    final globalY = (origin.dy + details.localPosition.dy)
        .clamp(
            safeInsets.top + radius + 8,
            math.max(safeInsets.top + radius + 8,
                media.size.height - safeInsets.bottom - radius - 8))
        .toDouble();
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final center = overlayBox.globalToLocal(Offset(globalX, globalY));
    _removeProgressOverlay();
    _progressCenter = center;
    _progressOverlay = OverlayEntry(
        builder: (_) => Positioned(
              left: center.dx - radius,
              top: center.dy - radius,
              width: widget.progressDiameter,
              height: widget.progressDiameter,
              child: IgnorePointer(
                  child: AnimatedBuilder(
                animation: _progressController,
                builder: (_, __) => DecoratedBox(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x55000000), blurRadius: 4)
                      ]),
                  child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                          key: const ValueKey('training-hud-guide-progress'),
                          value: _progressController.value,
                          strokeWidth: 7,
                          color: const Color(0xff005a9c),
                          backgroundColor: const Color(0xffcbd5e1))),
                ),
              )),
            ));
    overlay.insert(_progressOverlay!);
    _progressController.forward(from: 0);
  }

  void _removeProgressOverlay() {
    final entry = _progressOverlay;
    _progressOverlay = null;
    entry?.remove();
    entry?.dispose();
  }

  void _clearProgress() {
    if (_progressCenter == null) return;
    _progressController.stop();
    _progressController.value = 0;
    _removeProgressOverlay();
    _progressCenter = null;
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
          child: widget.child,
        ),
      ),
    );
  }
}
