import 'dart:math' as math;

/// 画面内の上下移動から決まる外見です。攻撃方向・投球判定には使いません。
enum PassRunFacing { front, back }

enum PassRunRunner { player, companion }

/// 既存の走行軌道を変えず、位置とその微分から表示方向を求めます。
abstract final class PassRunMotion {
  static double _period(PassRunRunner runner) =>
      runner == PassRunRunner.player ? 2.6 : 2.05;

  static double _phase(PassRunRunner runner) =>
      runner == PassRunRunner.player ? 0 : math.pi * .65;

  /// フィールド高に対する相対位置。既存の .5 ± .28 を維持します。
  static double yAt(double seconds, PassRunRunner runner) =>
      .5 +
      .28 * math.sin(seconds * math.pi * 2 / _period(runner) + _phase(runner));

  /// 画面Y座標は下が正です。単位はフィールド高/秒です。
  static double velocityYAt(double seconds, PassRunRunner runner) =>
      .28 *
      math.pi *
      2 /
      _period(runner) *
      math.cos(seconds * math.pi * 2 / _period(runner) + _phase(runner));

  static const facingSettleSeconds = .08;

  /// 反転点の直後だけ保持球の投影位置を80msでつなぎます。
  static ({PassRunFacing from, PassRunFacing to, double progress}) facingAt(
    double seconds,
    PassRunRunner runner,
  ) {
    final omega = math.pi * 2 / _period(runner);
    final phase = _phase(runner);
    final k = ((omega * seconds + phase - math.pi / 2) / math.pi).floor();
    final changedAt = (math.pi / 2 + k * math.pi - phase) / omega;
    final current = facingForVelocity(velocityYAt(seconds, runner),
        previous: facingForVelocity(velocityYAt(seconds - .00001, runner),
            previous: PassRunFacing.front));
    if (changedAt < 0 || seconds - changedAt >= facingSettleSeconds) {
      return (from: current, to: current, progress: 1);
    }
    final to = k.isEven ? PassRunFacing.back : PassRunFacing.front;
    final from =
        to == PassRunFacing.front ? PassRunFacing.back : PassRunFacing.front;
    return (
      from: from,
      to: to,
      progress:
          ((seconds - changedAt) / facingSettleSeconds).clamp(0, 1).toDouble()
    );
  }

  /// 静止・上下反転の厳密な頂点では直前の向きを維持します。
  /// 停止中は停止時の速度または保持済み向きを使い、実時計で更新しません。
  static PassRunFacing facingForVelocity(
    double velocityY, {
    required PassRunFacing previous,
  }) {
    if (!velocityY.isFinite || velocityY.abs() <= 1e-9) return previous;
    return velocityY > 0 ? PassRunFacing.front : PassRunFacing.back;
  }
}
