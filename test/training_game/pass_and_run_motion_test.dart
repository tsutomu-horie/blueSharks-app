import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('80ms向き補間は反転点の両側で連続し、終了後に新方向へ固定', () {
    for (final runner in PassRunRunner.values) {
      final period = runner == PassRunRunner.player ? 2.6 : 2.05;
      final phase = runner == PassRunRunner.player ? 0 : math.pi * .65;
      final turn = (math.pi * 2.5 - phase) * period / (math.pi * 2);
      expect(
          PassRunMotion.facingAt(turn - .001, runner).to, PassRunFacing.front);
      final middle = PassRunMotion.facingAt(turn + .04, runner);
      expect(middle.from, PassRunFacing.front);
      expect(middle.to, PassRunFacing.back);
      expect(middle.progress, closeTo(.5, 1e-10));
      final end = PassRunMotion.facingAt(turn + .080001, runner);
      expect(end.to, PassRunFacing.back);
      expect(end.progress, 1);
    }
  });
  test('下は正面・上は背面、静止頂点と不正値は前の向きを保持', () {
    for (final previous in PassRunFacing.values) {
      expect(
        PassRunMotion.facingForVelocity(1, previous: previous),
        PassRunFacing.front,
      );
      expect(
        PassRunMotion.facingForVelocity(-1, previous: previous),
        PassRunFacing.back,
      );
      for (final stopped in [0.0, 1e-12, -1e-12, double.nan, double.infinity]) {
        expect(
          PassRunMotion.facingForVelocity(stopped, previous: previous),
          previous,
        );
      }
    }
  });

  test('両者の既存軌道・周期を維持し、速度が実移動方向と一致する', () {
    for (final runner in PassRunRunner.values) {
      final period = runner == PassRunRunner.player ? 2.6 : 2.05;
      final phase = runner == PassRunRunner.player ? 0 : math.pi * .65;
      for (var ms = 0; ms <= 15000; ms += 13) {
        final t = ms / 1000;
        final y = PassRunMotion.yAt(t, runner);
        expect(
          y,
          closeTo(.5 + .28 * math.sin(t * math.pi * 2 / period + phase), 1e-12),
        );
        final derivative = (PassRunMotion.yAt(t + .00001, runner) -
                PassRunMotion.yAt(t - .00001, runner)) /
            .00002;
        expect(PassRunMotion.velocityYAt(t, runner), closeTo(derivative, 1e-8));
      }
    }
  });

  test('各走者の反転直前・頂点・直後で向きを連続して選択する', () {
    for (final runner in PassRunRunner.values) {
      final period = runner == PassRunRunner.player ? 2.6 : 2.05;
      final phase = runner == PassRunRunner.player ? 0 : math.pi * .65;
      final top = (math.pi * 2.5 - phase) * period / (math.pi * 2);
      final before = PassRunMotion.facingForVelocity(
        PassRunMotion.velocityYAt(top - .001, runner),
        previous: PassRunFacing.back,
      );
      expect(before, PassRunFacing.front);
      expect(
        PassRunMotion.facingForVelocity(
          PassRunMotion.velocityYAt(top, runner),
          previous: before,
        ),
        before,
      );
      expect(
        PassRunMotion.facingForVelocity(
          PassRunMotion.velocityYAt(top + .001, runner),
          previous: before,
        ),
        PassRunFacing.back,
      );
    }
  });

  test('顔・移動方向が変わってもNo54は往路上/復路下を禁止し横・後方を許可', () {
    for (final runner in PassRunRunner.values) {
      for (var ms = 0; ms <= 15000; ms += 240) {
        // 外見方向は別に選択でき、ルールへの引数になりません。
        PassRunMotion.facingForVelocity(
          PassRunMotion.velocityYAt(ms / 1000, runner),
          previous: PassRunFacing.front,
        );
        for (final outbound in [true, false]) {
          for (final dx in [-100.0, 0.0, 100.0]) {
            for (final dy in [-100.0, -.000001, 0.0, .000001, 100.0]) {
              expect(
                PassAndRunRules.isForwardDirection(
                  deltaX: dx,
                  deltaY: dy,
                  outbound: outbound,
                ),
                outbound ? dy < 0 : dy > 0,
              );
            }
          }
        }
      }
    }
  });
}
