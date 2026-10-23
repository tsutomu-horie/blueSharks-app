import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('v7の1000seedは全区間と未来受球点で同方向・速度連続・位置範囲内', () {
    expect(PassRunMotion.forwardRate, closeTo(.207, 1e-12));
    expect(PassRunMotion.turnDuration, const Duration(milliseconds: 1000));
    expect(PassAndRunRules.roundDuration, const Duration(seconds: 15));
    expect(PassAndRunRules.standardPassDuration,
        const Duration(milliseconds: 440));
    expect(PassAndRunRules.missPenalty, const Duration(seconds: 1));
    for (var seed = 0; seed < 1000; seed++) {
      final motion = PassRunMotion(seed: seed);
      for (final up in [true, false]) {
        for (final runner in PassRunRunner.values) {
          var last = motion.worldVelocityYAt(0, runner, outbound: up);
          for (var ms = 0; ms <= 17000; ms += 20) {
            final t = ms / 1000;
            final y = motion.yAt(t, runner, outbound: up);
            expect(y, inInclusiveRange(.41, .59));
            final v = motion.worldVelocityYAt(t, runner, outbound: up);
            expect(up ? v < 0 : v > 0, isTrue);
            expect(v.abs(), inInclusiveRange(.025, .34));
            expect((v - last).abs(), lessThan(.01));
            last = v;
          }
        }
      }
    }
  });
  test('同seedは再現し別seed・往復は異なる軌道、脚距離は常に増える', () {
    final a = PassRunMotion(seed: 54),
        b = PassRunMotion(seed: 54),
        c = PassRunMotion(seed: 95);
    for (final runner in PassRunRunner.values) {
      expect(a.yAt(2, runner), b.yAt(2, runner));
      expect(a.yAt(2, runner), isNot(c.yAt(2, runner)));
      expect(a.yAt(2, runner), isNot(1 - a.yAt(2, runner, outbound: false)));
      for (final up in [true, false]) {
        for (var ms = 1; ms <= 15000; ms += 20) {
          final t = ms / 1000;
          expect(a.distanceAt(t, runner, outbound: up),
              greaterThan(a.distanceAt(t - .001, runner, outbound: up)));
        }
      }
    }
  });
  test('1000seedの左右交換は狭幅・横画面でも体と名前が重ならず端点へ連続', () {
    for (var seed = 0; seed < 1000; seed++) {
      final m = PassRunMotion(seed: seed);
      for (final field in [
        const Size(208, 262),
        const Size(288, 262),
        const Size(370, 568),
        const Size(812, 200)
      ]) {
        final size = .75 *
            (112.0.clamp(0, field.height * .4).clamp(0, field.width * .5));
        for (var i = 0; i <= 100; i++) {
          final p = i / 100;
          Rect body(PassRunRunner runner) => Rect.fromCenter(
              center: m.turnOffset(p, runner, field: field, actorSize: size),
              width: size,
              height: size);
          final a = body(PassRunRunner.player),
              b = body(PassRunRunner.companion);
          expect(a.overlaps(b), isFalse, reason: '$seed $field $p');
          final label = Rect.fromLTWH(a.left, a.top - 18, size, 16);
          expect(label.overlaps(b), isFalse, reason: 'label $seed $field $p');
          for (final r in [a, b]) {
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(field.width));
            expect(r.bottom, lessThanOrEqualTo(field.height));
          }
        }
        for (final runner in PassRunRunner.values) {
          final mate = runner == PassRunRunner.companion;
          expect(
              m.turnOffset(0, runner, field: field, actorSize: size),
              Offset(field.width * (mate ? .75 : .25),
                  field.height * m.yAt(15, runner)));
          expect(
              (m.turnOffset(1, runner, field: field, actorSize: size) -
                      Offset(field.width * (mate ? .25 : .75),
                          field.height * m.yAt(0, runner, outbound: false)))
                  .distance,
              lessThan(1e-6));
        }
      }
    }
  });
  test('No54は顔とカメラに依存せず上/下攻撃に対する前方だけ禁止', () {
    for (final up in [true, false]) {
      for (final dx in [-100.0, 0.0, 100.0]) {
        for (final dy in [-100.0, -.000001, 0.0, .000001, 100.0]) {
          expect(
              PassAndRunRules.isForwardDirection(
                  deltaX: dx, deltaY: dy, outbound: up),
              up ? dy < 0 : dy > 0);
        }
      }
    }
  });
}
