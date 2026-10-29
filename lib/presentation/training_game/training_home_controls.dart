import 'package:flutter/material.dart';

import 'models/training_game_models.dart';

/// 既存HOMEの文字・白地・細い枠に合わせる育成専用の表示定数です。
abstract final class TrainingHomeStyle {
  static const navy = Color(0xff002b6d);
  static const border = Color(0xffcccccc);
  static const footerHeight = 92.0;
  static const buttonHeight = 67.0;
}

/// 通常100・超過50の既存ゲージを、数値と同じ枠に表示します。
class TrainingHomeMeter extends StatefulWidget {
  const TrainingHomeMeter(
      {super.key,
      required this.name,
      required this.value,
      this.feedbackVersion = 0,
      this.feedbackStartValue,
      this.delta = 0});
  final String name;
  final double value;
  final int feedbackVersion;
  final double delta;
  final double? feedbackStartValue;

  @override
  State<TrainingHomeMeter> createState() => _TrainingHomeMeterState();
}

class _TrainingHomeMeterState extends State<TrainingHomeMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _feedback = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  double _from = 0;
  double _target = 0;
  double _delta = 0;

  double get _progress =>
      Curves.easeOutCubic.transform((_feedback.value / .55).clamp(0.0, 1.0));
  double get _displayValue => _from + (_target - _from) * _progress;

  @override
  void initState() {
    super.initState();
    _from = _target = widget.value;
  }

  @override
  void didUpdateWidget(TrainingHomeMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedbackVersion != oldWidget.feedbackVersion &&
        widget.delta != 0) {
      _from = widget.feedbackStartValue ?? oldWidget.value;
      _target = widget.value;
      // The meter itself is displayed as a rounded integer, so the animated
      // change label must describe the same visible difference.
      _delta = (_target.round() - _from.round()).toDouble();
      _feedback.forward(from: 0);
    } else if (widget.value != oldWidget.value) {
      // 演出の開始値を保持し、同期補正・自然減衰後も表示値の差と一致させます。
      if (_feedback.isAnimating) {
        _target = widget.value;
        _delta = (_target.round() - _from.round()).toDouble();
      } else {
        _from = _target = widget.value;
        _delta = 0;
      }
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${widget.name} ${widget.value.round()}',
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _feedback,
          builder: (context, _) {
            final value = _displayValue;
            final normal = value.clamp(0, 100) / 100;
            final overage = (widget.value - 100).clamp(0, 50) / 50;
            final color = value <= 19
                ? const Color(0xffd03b3b)
                : value < 50
                    ? const Color(0xffeda100)
                    : value < 80
                        ? const Color(0xff7ec8f0)
                        : const Color(0xff5ee05e);
            final visible = _delta != 0 && _feedback.value < 1;
            final opacity = (1 - ((_feedback.value - .7) / .3).clamp(0.0, 1.0));
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (visible)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            '${_delta > 0 ? '+' : ''}${_delta.toStringAsFixed(_delta == _delta.roundToDouble() ? 0 : 1)}',
                            key: ValueKey('meter-delta-${widget.name}'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _delta > 0
                                  ? const Color(0xff16805d)
                                  : const Color(0xffb44235),
                            ),
                          ),
                        ),
                      ),
                    Text(
                      '${value.round()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0xffe8edf2)),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: normal,
                          child: ColoredBox(color: color),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: overage, end: overage),
                          duration: const Duration(milliseconds: 1600),
                          curve: Curves.easeInOutCubic,
                          builder: (context, width, _) => width > 0
                              ? FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: width,
                                  child: const ColoredBox(
                                      color: Color(0xffd03b3b)),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

/// 待機中も外寸を変えず、ラベルだけを残り時間へ置き換えます。
class TrainingHomeCareButton extends StatelessWidget {
  const TrainingHomeCareButton({
    super.key,
    required this.type,
    required this.label,
    required this.remaining,
    this.cooldownDuration = const Duration(seconds: 60),
    required this.onPressed,
    this.trainingCount,
  });
  final TrainingActionType type;
  final String label;
  final Duration remaining;
  final Duration cooldownDuration;
  final VoidCallback? onPressed;
  final int? trainingCount;

  @override
  Widget build(BuildContext context) {
    final waiting = remaining > Duration.zero;
    final enabled = onPressed != null;
    final seconds =
        (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final icon = switch (type) {
      TrainingActionType.meal => Icons.restaurant_outlined,
      TrainingActionType.clean => Icons.cleaning_services_outlined,
      TrainingActionType.squat => Icons.fitness_center_outlined,
      TrainingActionType.work => Icons.work_outline,
      TrainingActionType.rest => Icons.bed_outlined,
      _ => Icons.sports_rugby_outlined,
    };
    return Semantics(
      label: waiting ? '$label、待機中、あと $time' : label,
      value: trainingCount == null ? null : '$trainingCount/15',
      button: true,
      enabled: enabled,
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox(
        height: TrainingHomeStyle.buttonHeight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, TrainingHomeStyle.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            foregroundColor: TrainingHomeStyle.navy,
          ),
          child: Stack(
            children: [
              Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  icon,
                  size: 24,
                  color: enabled
                      ? TrainingHomeStyle.navy
                      : const Color(0xff888888),
                ),
                const SizedBox(height: 6),
                SizedBox(
                    height: 16,
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(waiting ? 'あと $time' : label,
                            style: TextStyle(
                                fontFamily: 'LINESeedJP',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: waiting || enabled
                                    ? TrainingHomeStyle.navy
                                    : const Color(0xff616161))))),
              ])),
              if (waiting)
                Positioned(
                  left: 7,
                  right: 7,
                  bottom: 4,
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      value: (remaining.inMicroseconds /
                              (cooldownDuration.inMicroseconds > 0
                                  ? cooldownDuration.inMicroseconds
                                  : 1))
                          .clamp(0, 1),
                      color: const Color(0xff48a6d5),
                      backgroundColor: const Color(0xffe5ebf0),
                      minHeight: 2,
                    ),
                  ),
                ),
              if (trainingCount != null)
                Positioned(
                    top: 0,
                    right: 2,
                    child: Text('$trainingCount/15',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TrainingHomeStyle.navy))),
            ],
          ),
        ),
      ),
    );
  }
}
