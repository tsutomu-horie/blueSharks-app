import 'package:flutter/material.dart';

/// Outcome-independent presentation path; milliseconds are relative to input.
class TackleRunningTrajectory {
  const TackleRunningTrajectory({
    required this.start,
    required this.downward,
    this.hasFeint = true,
  });
  final Alignment start;
  final bool downward;
  final bool hasFeint;

  /// GOから750msで承認済み経路のモデル500msへ進む表示時計です。
  static const presentationRate = 13 / 25;
  static const preludeRate = 2 / 3;
  static const feintDuration = Duration(milliseconds: 165);
  static double preludeVisualMilliseconds(double realMilliseconds) =>
      (realMilliseconds * preludeRate).clamp(0, 110);
  static double visualMilliseconds(double realMilliseconds) =>
      110 + realMilliseconds * presentationRate;
  static const laneSpeedPerMillisecond = .63 / 650;
  static double contactTime(double tapMilliseconds) =>
      (tapMilliseconds + 160).clamp(240, double.infinity);

  Alignment sample(double milliseconds) {
    final sign = downward ? 1.0 : -1.0;
    final feint = hasFeint ? Alignment(-.18, -sign * .48) : start;
    final lane = Alignment(-.36, sign * .58);
    if (milliseconds <= 110) {
      return Alignment.lerp(
        start,
        feint,
        Curves.easeInOut.transform((milliseconds / 110).clamp(0, 1)),
      )!;
    }
    if (milliseconds < 220) {
      final t = (milliseconds - 110) / 110;
      final h00 = 2 * t * t * t - 3 * t * t + 1;
      final h10 = t * t * t - 2 * t * t + t;
      final h01 = -2 * t * t * t + 3 * t * t;
      final h11 = t * t * t - t * t;
      return Alignment(
        h00 * feint.x +
            h10 * 0 +
            h01 * lane.x +
            h11 * (-laneSpeedPerMillisecond * 110),
        h00 * feint.y + h01 * lane.y,
      );
    }
    return Alignment(
      lane.x - laneSpeedPerMillisecond * (milliseconds - 220),
      lane.y,
    );
  }
}
