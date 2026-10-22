import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PassRunFacing { front, back }

enum PassRunRunner { player, companion }

/// 1プレイ中は固定する走行プロファイル。
/// 次のプレイは別seed、復路は別乱数列。表示の脚位相と衝突時計は分離します。
class PassRunMotion {
  PassRunMotion({
    required int seed,
    this.roundSeconds = 15,
    double speedScale = PassRunMotion.speedScale,
  })  : runningSpeedScale = speedScale,
        _outgoing = _PassRunTrajectory(seed, roundSeconds, speedScale),
        _incoming = _PassRunTrajectory(seed ^ 0x54a1, roundSeconds, speedScale);
  static const speedScale = 1.15;
  static const forwardRate = .18 * speedScale;
  static const facingSettleSeconds = .08;
  static const turnDuration = Duration(milliseconds: 1000);
  final double roundSeconds;
  final double runningSpeedScale;
  double get runningForwardRate => .18 * runningSpeedScale;
  final _PassRunTrajectory _outgoing, _incoming;
  _PassRunTrajectory _trajectory(bool outbound) =>
      outbound ? _outgoing : _incoming;
  double yAt(double seconds, PassRunRunner runner, {bool outbound = true}) =>
      _trajectory(outbound)
          .y(seconds, runner == PassRunRunner.companion, outbound);
  double worldVelocityYAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) =>
      _trajectory(outbound)
          .speed(seconds, runner == PassRunRunner.companion, outbound);
  double distanceAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) =>
      _trajectory(outbound)
          .distance(seconds, runner == PassRunRunner.companion, outbound);
  static ({PassRunFacing from, PassRunFacing to, double progress}) facingAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) {
    final facing = outbound ? PassRunFacing.back : PassRunFacing.front;
    return (from: facing, to: facing, progress: 1);
  }

  /// 交換中央で前後順が逆でも本人と仲間・名前が重ならない回避経路。
  /// 小さい画面ではキャラ寸法に比例して回避幅も縮めます。
  Offset turnOffset(
    double progress,
    PassRunRunner runner, {
    required Size field,
    required double actorSize,
  }) {
    final mate = runner == PassRunRunner.companion;
    final p = Curves.easeInOut.transform(progress.clamp(0, 1).toDouble());
    final start = Offset(
      field.width * (mate ? .75 : .25),
      field.height * yAt(roundSeconds, runner),
    );
    final end = Offset(
      field.width * (mate ? .25 : .75),
      field.height * yAt(0, runner, outbound: false),
    );
    final minGap = field.height *
        math.min(
          yAt(roundSeconds, PassRunRunner.player) -
              yAt(roundSeconds, PassRunRunner.companion),
          yAt(0, PassRunRunner.player, outbound: false) -
              yAt(0, PassRunRunner.companion, outbound: false),
        );
    final scale = actorSize / 84;
    final bend = math.max(24 * scale, (150 * scale - minGap) / 2);
    // A narrow lane needs vertical clearance before the bodies cross horizontally.
    final lead = (actorSize / (field.width * .5) - .45).clamp(0.0, .3);
    final horizontal = lead == 0
        ? p
        : Curves.easeInOut.transform(
            ((progress - lead) / (1 - 2 * lead)).clamp(0.0, 1.0),
          );
    final middle = Offset.lerp(start, end, p)!;
    return Offset(start.dx + (end.dx - start.dx) * horizontal, middle.dy) +
        Offset(0, (mate ? -1 : 1) * bend * math.sin(math.pi * p));
  }

  static PassRunFacing facingForVelocity(
    double velocityY, {
    required PassRunFacing previous,
  }) {
    if (!velocityY.isFinite || velocityY.abs() <= 1e-9) return previous;
    return velocityY > 0 ? PassRunFacing.front : PassRunFacing.back;
  }
}

/// 有界な複数の波を合成。フレーム乱数や交代点・停止点を設けず、
/// 位置・速度・加速度を連続にする。時間倍率だけ管理設定に追従する。
class _PassRunTrajectory {
  _PassRunTrajectory(int seed, double roundSeconds, this.speedFactor) {
    final random = math.Random(seed);
    _center = _Wave(.012, .35 + random.nextDouble() * .3,
        random.nextDouble() * math.pi * 2);
    _gap = [
      _Wave(.016 + random.nextDouble() * .002, 1.7 + random.nextDouble() * .6,
          random.nextDouble() * math.pi * 2),
      _Wave(.006, 2.7 + random.nextDouble() * .7,
          random.nextDouble() * math.pi * 2),
      _Wave(.003, .27 + random.nextDouble() * .2,
          random.nextDouble() * math.pi * 2),
    ];
  }
  final double speedFactor;
  late final _Wave _center;
  late final List<_Wave> _gap;
  double y(double seconds, bool mate, bool up) {
    final t = seconds * speedFactor;
    final gap = _gap.fold(0.0, (sum, wave) => sum + wave.value(t));
    final value = .5 + _center.value(t) + (mate ? gap : -gap);
    return up ? value : 1 - value;
  }

  double speed(double seconds, bool mate, bool up) {
    final t = seconds * speedFactor;
    final gap = _gap.fold(0.0, (sum, wave) => sum + wave.velocity(t));
    final relative = (_center.velocity(t) + (mate ? gap : -gap)) * speedFactor;
    return (up ? relative : -relative) + (up ? -.18 : .18) * speedFactor;
  }

  double distance(double t, bool mate, bool up) =>
      .18 * speedFactor * t + (up ? -1 : 1) * (y(t, mate, up) - y(0, mate, up));
}

class _Wave {
  const _Wave(this.amplitude, this.frequency, this.phase);
  final double amplitude, frequency, phase;
  double value(double t) => amplitude * math.sin(frequency * t + phase);
  double velocity(double t) =>
      amplitude * frequency * math.cos(frequency * t + phase);
}
