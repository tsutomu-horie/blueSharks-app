import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/services/server_time_clock.dart';

/// 育成ホームの表示だけに使う、日本時間の昼夜ルールです。
class TrainingHomeDaylight {
  static DateTime japanTime(DateTime instant) =>
      instant.toUtc().add(const Duration(hours: 9));

  static bool isDay(DateTime instant) {
    final hour = japanTime(instant).hour;
    return hour >= 6 && hour < 18;
  }

  static String asset(DateTime instant) =>
      'assets/images/training_game/scenes/home_outdoor_${isDay(instant) ? 'day' : 'night'}.png';

  /// 境界には正確に追従し、サーバー時計の再同期も最大1分で反映します。
  static Duration refreshAfter(DateTime instant) {
    final japan = japanTime(instant);
    final boundary = japan.hour < 6
        ? DateTime.utc(japan.year, japan.month, japan.day, 6)
        : japan.hour < 18
            ? DateTime.utc(japan.year, japan.month, japan.day, 18)
            : DateTime.utc(japan.year, japan.month, japan.day + 1, 6);
    final remaining = boundary.difference(japan);
    return remaining < const Duration(minutes: 1)
        ? remaining
        : const Duration(minutes: 1);
  }
}

/// ゲームと同じサーバー時計を参照し、休止中はタイマーを停止します。
class TrainingHomeBackground extends StatefulWidget {
  const TrainingHomeBackground({this.now, super.key});

  final DateTime Function()? now;

  @override
  State<TrainingHomeBackground> createState() => _TrainingHomeBackgroundState();
}

class _TrainingHomeBackgroundState extends State<TrainingHomeBackground>
    with WidgetsBindingObserver {
  Timer? _timer;
  late String _asset;
  late Color _skyColor;
  bool _active = true;

  DateTime get _now => widget.now?.call() ?? ServerTimeClock.instance.now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _refresh();
  }

  @override
  void didUpdateWidget(covariant TrainingHomeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  void _refresh() {
    _timer?.cancel();
    final instant = _now;
    _asset = TrainingHomeDaylight.asset(instant);
    // 支給画像の空と同色で上へ延長し、建物と地面は画面幅に合わせます。
    _skyColor = TrainingHomeDaylight.isDay(instant)
        ? const Color(0xff2ca8d3)
        : const Color(0xff4c789f);
    if (!_active) return;
    _timer = Timer(TrainingHomeDaylight.refreshAfter(instant), () {
      if (mounted) setState(_refresh);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      setState(_refresh);
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _skyColor,
          image: DecorationImage(
            image: AssetImage(_asset),
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
          ),
        ),
      );
}
