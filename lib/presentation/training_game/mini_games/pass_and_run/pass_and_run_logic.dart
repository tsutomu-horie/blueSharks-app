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
  static const missPenalty = Duration(seconds: 1);

  /// フリックとして扱う最低移動距離です。
  static const minimumDistance = 24.0;

  /// フリックとして扱う最低速度です。
  static const minimumVelocity = 400.0;

  /// 表示上のボール半径です。
  static const ballCollisionRadius = 15.0;

  /// 表示上の仲間キャラクターを覆う当たり判定の半径です。
  static const mateCollisionRadius = 24.0;

  /// 入力が成立するフリックかを返します。
  static bool isFlick(PassFlick flick) {
    return flick.distance >= minimumDistance && flick.speed >= minimumVelocity;
  }

  /// 前方は相手側デッドボールライン方向です（往路は上、復路は下）。
  /// World Rugby Definitions / Law 11 を慣性のない2D投球へ簡略化し、
  /// 攻撃方向との内積が正なら禁止、厳密に真横なら許可します。
  /// 顔の向き・上下の歩行速度・独自の許容角度は判定に使いません。
  static bool isForwardDirection({
    required double deltaX,
    required double deltaY,
    required bool outbound,
  }) {
    if (!deltaX.isFinite || !deltaY.isFinite) return true;
    return outbound ? deltaY < 0 : deltaY > 0;
  }

  /// ボール中心と仲間の中心が、画面上の当たり判定で重なっているかを返します。
  static bool hasCollided({
    required double ballDeltaX,
    required double ballDeltaY,
    double ballRadius = ballCollisionRadius,
    double mateRadius = mateCollisionRadius,
  }) {
    // 中心間距離の二乗で比較し、毎フレームの平方根計算を避けます。
    final collisionDistance = ballRadius + mateRadius;
    final distanceSquared = ballDeltaX * ballDeltaX + ballDeltaY * ballDeltaY;
    return distanceSquared <= collisionDistance * collisionDistance;
  }
}
