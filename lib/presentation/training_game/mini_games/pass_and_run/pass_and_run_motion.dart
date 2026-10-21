import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PassRunFacing { front, back }

enum PassRunRunner { player, companion }

/// 1プレイ中は固定する走行プロファイル。未配備の管理設定には依存しません。
/// 次のプレイは別seed、復路は別乱数列。表示の脚位相と衝突時計は分離します。
class PassRunMotion {
  PassRunMotion({required int seed, this.roundSeconds = 15})
      : _outgoing = _PassRunTrajectory(seed, roundSeconds),
        _incoming = _PassRunTrajectory(seed ^ 0x54a1, roundSeconds);
  static const speedScale = 1.15;
  static const forwardRate = .18 * speedScale;
  static const facingSettleSeconds = .08;
  static const turnDuration = Duration(milliseconds: 1000);
  final double roundSeconds;
  final _PassRunTrajectory _outgoing, _incoming;
  _PassRunTrajectory _trajectory(bool outbound) =>
      outbound ? _outgoing : _incoming;
  double yAt(double seconds, PassRunRunner runner, {bool outbound = true}) =>
      _trajectory(outbound)
          .y(seconds, runner == PassRunRunner.companion, outbound);
  double worldVelocityYAt(double seconds, PassRunRunner runner,
          {bool outbound = true}) =>
      _trajectory(outbound)
          .speed(seconds, runner == PassRunRunner.companion, outbound);
  double distanceAt(double seconds, PassRunRunner runner,
          {bool outbound = true}) =>
      _trajectory(outbound)
          .distance(seconds, runner == PassRunRunner.companion, outbound);
  static ({PassRunFacing from, PassRunFacing to, double progress}) facingAt(
      double seconds, PassRunRunner runner,
      {bool outbound = true}) {
    final facing = outbound ? PassRunFacing.back : PassRunFacing.front;
    return (from: facing, to: facing, progress: 1);
  }

  /// 交換中央で前後順が逆でも本人と仲間・名前が重ならない回避経路。
  /// 小さい画面ではキャラ寸法に比例して回避幅も縮めます。
  Offset turnOffset(double progress, PassRunRunner runner,
      {required Size field, required double actorSize}) {
    final mate = runner == PassRunRunner.companion;
    final p = Curves.easeInOut.transform(progress.clamp(0, 1).toDouble());
    final start = Offset(field.width * (mate ? .75 : .25),
        field.height * yAt(roundSeconds, runner));
    final end = Offset(field.width * (mate ? .25 : .75),
        field.height * yAt(0, runner, outbound: false));
    final minGap = field.height *
        math.min(
            yAt(roundSeconds, PassRunRunner.player) -
                yAt(roundSeconds, PassRunRunner.companion),
            yAt(0, PassRunRunner.player, outbound: false) -
                yAt(0, PassRunRunner.companion, outbound: false));
    final scale = actorSize / 84;
    final bend = math.max(24 * scale, (150 * scale - minGap) / 2);
    // A narrow lane needs vertical clearance before the bodies cross horizontally.
    final lead = (actorSize / (field.width * .5) - .45).clamp(0.0, .3);
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

class _PassRunTrajectory {
  static const speedFactor = PassRunMotion.speedScale;
  _PassRunTrajectory(int seed, double roundSeconds) {
    final r = math.Random(seed);
    var time = 0.0;
    for (var i = 0;; i++) {
      final center = .5 + (r.nextDouble() - .5) * .025;
      final gap = .04 + r.nextDouble() * .03;
      points.add((
        time: time,
        player: center + (i.isEven ? -gap : gap),
        mate: center + (i.isEven ? gap : -gap),
        playerWarp: (r.nextDouble() - .5) * .44,
        mateWarp: (r.nextDouble() - .5) * .44
      ));
      if (time > (roundSeconds + 2) * speedFactor) break;
      time += 2.6 + r.nextDouble() * 1.2;
    }
    for (final mate in [false, true]) {
      final xs = <double>[], ys = <double>[];
      for (var i = 0; i < points.length; i++) {
        final a = points[i];
        final value = mate ? a.mate : a.player;
        xs.add(a.time);
        ys.add(value);
        if (i + 1 < points.length) {
          final b = points[i + 1];
          final warp = mate ? a.mateWarp : a.playerWarp;
          final fraction = .5 + warp * .4;
          // Pass-through waypoint: nonzero tangent, independent timing per runner.
          xs.add(a.time + (b.time - a.time) * fraction);
          ys.add(value +
              ((mate ? b.mate : b.player) - value) * (fraction + warp * .08));
        }
      }
      final slopes = List<double>.filled(xs.length, 0);
      for (var i = 1; i < xs.length - 1; i++) {
        final h0 = xs[i] - xs[i - 1], h1 = xs[i + 1] - xs[i];
        final d0 = (ys[i] - ys[i - 1]) / h0, d1 = (ys[i + 1] - ys[i]) / h1;
        if (d0 * d1 > 0) {
          final w0 = 2 * h1 + h0, w1 = h1 + 2 * h0;
          slopes[i] = (w0 + w1) / (w0 / d0 + w1 / d1);
        }
      }
      _tracks.add((x: xs, y: ys, m: slopes));
    }
  }
  final points = <({
    double time,
    double player,
    double mate,
    double playerWarp,
    double mateWarp
  })>[];
  final _tracks = <({List<double> x, List<double> y, List<double> m})>[];
  double y(double seconds, bool mate, bool up) {
    final t = seconds * speedFactor;
    final a = _tracks[mate ? 1 : 0];
    var i = 0;
    while (i + 1 < a.x.length - 1 && t > a.x[i + 1]) {
      i++;
    }
    final h = a.x[i + 1] - a.x[i];
    final p = ((t - a.x[i]) / h).clamp(0.0, 1.0);
    final p2 = p * p, p3 = p2 * p;
    final v = (2 * p3 - 3 * p2 + 1) * a.y[i] +
        (p3 - 2 * p2 + p) * h * a.m[i] +
        (-2 * p3 + 3 * p2) * a.y[i + 1] +
        (p3 - p2) * h * a.m[i + 1];
    return up ? v : 1 - v;
  }

  double speed(double t, bool mate, bool up) =>
      (y(t + .0001, mate, up) - y(t, mate, up)) / .0001 +
      (up ? -.18 : .18) * speedFactor;
  double distance(double t, bool mate, bool up) =>
      .18 * speedFactor * t + (up ? -1 : 1) * (y(t, mate, up) - y(0, mate, up));
}
