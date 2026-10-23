import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_pace_assist.dart';

void main() {
  test('最大設定の加速/解除でも6秒先の予測が既存profile内に収まる', () {
    for (final scale in PassRunMotion.supportedMotionScales) {
      for (final round in [15.0, 30.0]) {
        final horizon = round + PassRunMotion.maxForecastSeconds;
        final room = math.max(0.0,
            PassRunMotion.trajectoryProfileHorizonSeconds / scale - horizon);
        final target = math.min(1.12, 1 + room / (horizon * 1.25));
        for (final release in [null, .07, .21, .35, .49, .63]) {
          final movement = PassRunPaceAssist(
              start: 0,
              normalPosition: (t) => t,
              normalVelocity: (_) => 1,
              targetRate: target,
              attackUp: true);
          if (release != null) movement.release(release);
          expect(movement.phaseAt(horizon) * scale,
              lessThanOrEqualTo(PassRunMotion.trajectoryProfileHorizonSeconds));
          for (var i = 0; i <= 1000; i++) {
            expect(movement.rateAt(i * .001), inInclusiveRange(.85, 1.15));
          }
        }
      }
    }
  });

  test('減速から解除途中の再加速も位置速度加速度と先読み余白を維持', () {
    double position(double t) => .5 + .4 * math.sin(t * .7);
    double velocity(double t) => .28 * math.cos(t * .7);
    final horizon = 30 + PassRunMotion.maxForecastSeconds;
    final room = PassRunMotion.trajectoryProfileHorizonSeconds / 1.25 - horizon;
    final target = 1 + room / (horizon * 1.25);
    var movement = PassRunPaceAssist(
        start: 0,
        normalPosition: position,
        normalVelocity: velocity,
        targetRate: .88,
        attackUp: true);
    for (var i = 1; i <= 20; i++) {
      final t = i * .4;
      movement.release(t - .15);
      final p = movement.positionAt(t),
          v = movement.velocityAt(t),
          a = movement.accelerationAt(t);
      movement = PassRunPaceAssist(
          start: t,
          normalPosition: position,
          normalVelocity: velocity,
          targetRate: target,
          attackUp: true,
          previous: movement);
      expect(movement.positionAt(t), closeTo(p, 1e-10));
      expect(movement.velocityAt(t), closeTo(v, 1e-10));
      expect(movement.accelerationAt(t), closeTo(a, 1e-7));
    }
    expect(movement.phaseAt(horizon) * 1.25,
        lessThanOrEqualTo(PassRunMotion.trajectoryProfileHorizonSeconds));
  });

  for (final rate in [.88, 1.12]) {
    test('速度補助$rateでも元軌道の順序・位置を保持し解除でC2接続', () {
      double position(double t) => .5 + .4 * math.sin(t * .7);
      double velocity(double t) => .28 * math.cos(t * .7);
      final a = PassRunPaceAssist(
          start: 2,
          normalPosition: position,
          normalVelocity: velocity,
          targetRate: rate,
          attackUp: true);
      expect(a.positionAt(2), position(2));
      expect(a.velocityAt(2), velocity(2));
      var phase = 2.0;
      for (var i = 0; i <= 3000; i++) {
        final t = 2 + i * .001;
        expect(a.phaseAt(t), greaterThanOrEqualTo(phase));
        expect(a.positionAt(t), closeTo(position(a.phaseAt(t)), 1e-12));
        expect(a.rateAt(t), inInclusiveRange(.88, 1.12));
        phase = a.phaseAt(t);
      }
      final p = a.positionAt(2.31),
          v = a.velocityAt(2.31),
          acc = a.accelerationAt(2.31);
      a.release(2.31);
      expect(a.positionAt(2.31), closeTo(p, 1e-12));
      expect(a.velocityAt(2.31), closeTo(v, 1e-12));
      expect(a.accelerationAt(2.31), closeTo(acc, 1e-8));
      expect(a.rateAt(4), closeTo(1, 1e-12));
      final frozen = a.positionAt(3);
      a.positionAt(12);
      expect(a.positionAt(3), frozen);
    });
  }
}
