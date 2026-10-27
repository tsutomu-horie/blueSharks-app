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

  /// フィールド幅の半分を飛ぶ基準時間。投球・返球とも同じ一定球速です。
  static const standardPassDuration = Duration(milliseconds: 440);

  /// フリックとして扱う最低移動距離です。
  static const minimumDistance = 40.0;

  /// 表示上のボール半径です。
  static const ballCollisionRadius = 15.0;

  /// 表示上の仲間キャラクターを覆う当たり判定の半径です。
  static const mateCollisionRadius = 24.0;

  /// 入力が成立するフリックかを返します。
  static bool isFlick(PassFlick flick) {
    return flick.deltaX.isFinite &&
        flick.deltaY.isFinite &&
        flick.distance >= minimumDistance;
  }

  /// 真横付近の前方へのブレだけを吸収する。合法な後方の狙いは変えない。
  /// 自動返球の合法判定には適用しない。
  static ({double deltaX, double deltaY}) userPassDirection(
    PassFlick flick, {
    required bool outbound,
  }) {
    final horizontal = flick.deltaX.abs();
    final snap = isFlick(flick) &&
        horizontal > 0 &&
        flick.deltaY.abs() <= horizontal * math.tan(5 * math.pi / 180) &&
        isForwardDirection(
          deltaX: flick.deltaX,
          deltaY: flick.deltaY,
          outbound: outbound,
        );
    return (deltaX: flick.deltaX, deltaY: snap ? 0 : flick.deltaY);
  }

  /// 狙いから12度以内の合法な受け手だけを補助します。
  static ({double deltaX, double deltaY}) assistDirection({
    required double deltaX,
    required double deltaY,
    required double targetX,
    required double targetY,
    required bool outbound,
  }) {
    final original = (deltaX: deltaX, deltaY: deltaY);
    if (isForwardDirection(
            deltaX: deltaX, deltaY: deltaY, outbound: outbound) ||
        isForwardDirection(
            deltaX: targetX, deltaY: targetY, outbound: outbound)) {
      return original;
    }
    final length = math.sqrt(deltaX * deltaX + deltaY * deltaY);
    final targetLength = math.sqrt(targetX * targetX + targetY * targetY);
    if (length == 0 || targetLength == 0 || !targetLength.isFinite) {
      return original;
    }
    final cosine =
        (deltaX * targetX + deltaY * targetY) / (length * targetLength);
    if (cosine < math.cos(12 * math.pi / 180)) {
      return original;
    }
    return (
      deltaX: targetX / targetLength * length,
      deltaY: targetY / targetLength * length
    );
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

  /// 相対移動区間と線形に変わる合計半径の最初の交差位置（0〜1）。
  /// 球・受け手の両方を相対座標へ移し、二次式を解く。時間の細分化はしない。
  static double? sweptCollision({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double startRadius,
    required double endRadius,
  }) {
    final dx = endX - startX, dy = endY - startY;
    final dr = endRadius - startRadius;
    final c = startX * startX + startY * startY - startRadius * startRadius;
    if (c <= 0) return 0;
    final a = dx * dx + dy * dy - dr * dr;
    final b = 2 * (startX * dx + startY * dy - startRadius * dr);
    if (a.abs() < 1e-12) {
      if (b >= 0) return null;
      final root = -c / b;
      return root >= 0 && root <= 1 ? root : null;
    }
    final discriminant = b * b - 4 * a * c;
    if (discriminant < 0) return null;
    final root = math.sqrt(discriminant);
    final roots = [(-b - root) / (2 * a), (-b + root) / (2 * a)]..sort();
    for (final value in roots) {
      if (value >= 0 && value <= 1) return value;
    }
    return null;
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
