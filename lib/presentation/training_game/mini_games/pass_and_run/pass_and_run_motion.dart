import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 走行する攻撃方向の外見です。投球判定には使いません。
enum PassRunFacing { front, back }

enum PassRunRunner { player, companion }

/// 承認された走行B。共通の前進は床のスクロールで表し、
/// 相対速度差で前後が入れ替わります。球の座標・速度には加算しません。
abstract final class PassRunMotion {
  static const forwardRate = .18;
  static const relativeAmplitude = .065;
  static const period = 3.8;
  static const facingSettleSeconds = .08;
  static const turnDuration = Duration(milliseconds: 1000);

  static double yAt(double seconds, PassRunRunner runner,
          {bool outbound = true}) =>
      .5 +
      (outbound ? -1 : 1) *
          (runner == PassRunRunner.player ? 1 : -1) *
          relativeAmplitude *
          math.cos(seconds * math.pi * 2 / period);

  static double velocityYAt(double seconds, PassRunRunner runner,
          {bool outbound = true}) =>
      (outbound ? -1 : 1) *
      (runner == PassRunRunner.player ? 1 : -1) *
      -relativeAmplitude *
      math.pi *
      2 /
      period *
      math.sin(seconds * math.pi * 2 / period);

  static double worldVelocityYAt(double seconds, PassRunRunner runner,
          {bool outbound = true}) =>
      velocityYAt(seconds, runner, outbound: outbound) +
      (outbound ? -1 : 1) * forwardRate;

  static ({PassRunFacing from, PassRunFacing to, double progress}) facingAt(
      double seconds, PassRunRunner runner,
      {bool outbound = true}) {
    final facing = outbound ? PassRunFacing.back : PassRunFacing.front;
    return (from: facing, to: facing, progress: 1);
  }

  /// 交換中央で前後順が逆でも本人と仲間・名前が重ならない回避経路。
  /// 小さい画面ではキャラ寸法に比例して回避幅も縮めます。
  static Offset turnOffset(double progress, PassRunRunner runner,
      {required Size field, required double actorSize}) {
    final mate = runner == PassRunRunner.companion;
    final p = Curves.easeInOut.transform(progress.clamp(0, 1).toDouble());
    final start = Offset(
        field.width * (mate ? .75 : .25), field.height * yAt(15, runner));
    final end = Offset(field.width * (mate ? .25 : .75),
        field.height * yAt(0, runner, outbound: false));
    final minGap = field.height *
        math.min(
            yAt(15, PassRunRunner.player) - yAt(15, PassRunRunner.companion),
            yAt(0, PassRunRunner.player, outbound: false) -
                yAt(0, PassRunRunner.companion, outbound: false));
    final scale = actorSize / 84;
    final bend = minGap >= 0
        ? 24 * scale
        : math.max(24 * scale, (130 * scale - minGap) / 2);
    // A narrow lane needs vertical clearance before the bodies cross horizontally.
    final lead = (actorSize / (field.width * .5) - .45).clamp(0.0, .2);
    final horizontal = lead == 0
        ? p
        : Curves.easeInOut
            .transform(((progress - lead) / (1 - 2 * lead)).clamp(0.0, 1.0));
    final middle = Offset.lerp(start, end, p)!;
    return Offset(start.dx + (end.dx - start.dx) * horizontal, middle.dy) +
        Offset(0, (mate ? -1 : 1) * bend * math.sin(math.pi * p));
  }

  static PassRunFacing facingForVelocity(double velocityY,
      {required PassRunFacing previous}) {
    if (!velocityY.isFinite || velocityY.abs() <= 1e-9) return previous;
    return velocityY > 0 ? PassRunFacing.front : PassRunFacing.back;
  }
}
