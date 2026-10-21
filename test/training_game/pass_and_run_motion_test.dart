import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('承認Bの並走は全15秒で同じ攻撃方向、相対位置は画面内で前後交替', () {
    expect(PassRunMotion.forwardRate, .18);
    expect(PassRunMotion.period, 3.8);
    expect(PassRunMotion.turnDuration, const Duration(milliseconds: 1000));
    expect(PassAndRunRules.missPenalty, const Duration(seconds: 1));
    expect(PassAndRunRules.standardPassDuration,
        const Duration(milliseconds: 440));
    expect(PassAndRunRules.roundDuration, const Duration(seconds: 15));
    for (final up in [true, false])
      for (final runner in PassRunRunner.values)
        for (var ms = 0; ms <= 15000; ms += 10) {
          final t = ms / 1000;
          final y = PassRunMotion.yAt(t, runner, outbound: up);
          expect(y, inInclusiveRange(.435, .565));
          final v = PassRunMotion.worldVelocityYAt(t, runner, outbound: up);
          expect(up ? v < 0 : v > 0, isTrue);
          expect(PassRunMotion.facingAt(t, runner, outbound: up).to,
              up ? PassRunFacing.back : PassRunFacing.front);
          final numerical =
              (PassRunMotion.yAt(t + .00001, runner, outbound: up) -
                      PassRunMotion.yAt(t - .00001, runner, outbound: up)) /
                  .00002;
          expect(PassRunMotion.velocityYAt(t, runner, outbound: up),
              closeTo(numerical, 1e-8));
        }
    expect(PassRunMotion.yAt(0, PassRunRunner.player),
        lessThan(PassRunMotion.yAt(0, PassRunRunner.companion)));
    expect(PassRunMotion.yAt(1.9, PassRunRunner.player),
        greaterThan(PassRunMotion.yAt(1.9, PassRunRunner.companion)));
  });
  test('交換は開始/終了がレーン軌道に連続する', () {
    const field = Size(370, 568);
    for (final runner in PassRunRunner.values) {
      final mate = runner == PassRunRunner.companion;
      expect(
          PassRunMotion.turnOffset(0, runner, field: field, actorSize: 84),
          Offset(field.width * (mate ? 0.75 : .25),
              field.height * PassRunMotion.yAt(15, runner)));
      expect(
          (PassRunMotion.turnOffset(1, runner, field: field, actorSize: 84) -
                  Offset(
                      field.width * (mate ? 0.25 : .75),
                      field.height *
                          PassRunMotion.yAt(0, runner, outbound: false)))
              .distance,
          lessThan(1e-6));
    }
  });
  test('No54は顔とカメラに依存せず上/下攻撃に対する前方だけ禁止', () {
    for (final up in [true, false])
      for (final dx in [-100.0, 0.0, 100.0])
        for (final dy in [-100.0, -.000001, 0.0, .000001, 100.0]) {
          expect(
              PassAndRunRules.isForwardDirection(
                  deltaX: dx, deltaY: dy, outbound: up),
              up ? dy < 0 : dy > 0);
        }
  });
}
