import 'dart:math' as math;

/// パス＆ランのフリック入力値です。
class PassFlick {
  /// フリック入力値を作成します。
  const PassFlick({
    required this.deltaX,
    required this.deltaY,
    required this.velocityX,
    required this.velocityY,
  });

  final double deltaX;
  final double deltaY;
  final double velocityX;
  final double velocityY;

  /// 指の移動距離です。
  double get distance => math.sqrt(deltaX * deltaX + deltaY * deltaY);

  /// 指を離した時点の速度です。
  double get speed => math.sqrt(velocityX * velocityX + velocityY * velocityY);

  /// 画面上のフリック軌跡から、入力方向をラジアンで返します。
  double get angle => math.atan2(deltaY, deltaX);
}

/// パス＆ランの確定値と方向判定を集約します。
abstract final class PassAndRunRules {
  /// 片道の制限時間です。
  static const roundDuration = Duration(seconds: 15);

  /// 方向ミス後にパスできない時間です。
  static const missPenalty = Duration(seconds: 2);

  /// フリックとして扱う最低移動距離です。
  static const minimumDistance = 24.0;

  /// フリックとして扱う最低速度です。
  static const minimumVelocity = 400.0;

  /// 仲間方向から許容する角度差です。
  static const toleranceDegrees = 10.0;

  /// 入力が成立するフリックかを返します。
  static bool isFlick(PassFlick flick) {
    return flick.distance >= minimumDistance && flick.speed >= minimumVelocity;
  }

  /// フリック方向が仲間の方向から±10度以内かを返します。
  static bool isAccurate({
    required PassFlick flick,
    required double targetDeltaX,
    required double targetDeltaY,
  }) {
    if (!isFlick(flick)) return false;
    final targetAngle = math.atan2(targetDeltaY, targetDeltaX);
    var difference = (flick.angle - targetAngle).abs();
    if (difference > math.pi) difference = math.pi * 2 - difference;
    return difference <= toleranceDegrees * math.pi / 180;
  }
}
