import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('sweepは通過・接線・変化半径を検出し、離れた区間はMISS', () {
    double? hit(double y, double r0, double r1) =>
        PassAndRunRules.sweptCollision(
            startX: -50,
            startY: y,
            endX: 50,
            endY: y,
            startRadius: r0,
            endRadius: r1);
    expect(hit(0, 10, 10), closeTo(.4, 1e-12));
    expect(hit(10, 10, 10), closeTo(.5, 1e-12));
    expect(hit(10.01, 10, 10), isNull);
    expect(hit(12, 10, 15), isNotNull);
    expect(hit(12, 15, 10), isNotNull);
    expect(hit(16, 15, 10), isNull);
    // 終端で半径が拡大する場合、区間直前には非衝突でも終端点は衝突する。
    expect(
        PassAndRunRules.sweptCollision(
            startX: 100.02,
            startY: 0,
            endX: 100.02,
            endY: 0,
            startRadius: 100,
            endRadius: 100),
        isNull);
    expect(
        PassAndRunRules.hasCollided(
            ballDeltaX: 100.02,
            ballDeltaY: 0,
            ballRadius: 100.03,
            mateRadius: 0),
        isTrue);
    expect(
        PassAndRunRules.sweptCollision(
            startX: 20,
            startY: 0,
            endX: 20,
            endY: 0,
            startRadius: 10,
            endRadius: 30),
        closeTo(.5, 1e-12));
  });

  test('横補正は成立した入力の±5度内だけで前後方向を保つ', () {
    for (final dx in [-100.0, 100.0]) {
      for (final degrees in [-5.01, -5.0, -4.99, 0.0, 4.99, 5.0, 5.01]) {
        final dy = dx.abs() * math.tan(degrees * math.pi / 180);
        final direction = PassAndRunRules.userPassDirection(
            PassFlick(deltaX: dx, deltaY: dy, velocityX: 500, velocityY: 0));
        expect(direction.deltaX, dx);
        expect(direction.deltaY, degrees.abs() <= 5 ? 0 : dy);
        for (final outbound in [true, false]) {
          expect(
              PassAndRunRules.isForwardDirection(
                  deltaX: direction.deltaX,
                  deltaY: direction.deltaY,
                  outbound: outbound),
              degrees.abs() <= 5 ? false : (outbound ? dy < 0 : dy > 0));
        }
      }
    }
    for (final flick in [
      const PassFlick(deltaX: 23, deltaY: -.1, velocityX: 500, velocityY: 0),
      const PassFlick(deltaX: 100, deltaY: -.1, velocityX: 399, velocityY: 0),
      const PassFlick(deltaX: 0, deltaY: -100, velocityX: 0, velocityY: 500),
    ]) {
      expect(PassAndRunRules.userPassDirection(flick).deltaY, flick.deltaY);
    }
    // 自動返球が呼ぶ厳密判定には横補正を入れない。
    expect(
        PassAndRunRules.isForwardDirection(
            deltaX: 100, deltaY: -.01, outbound: true),
        isTrue);
  });

  test('設定端点と複数seedで加速度連続・画面内・未来合法返球機会', () {
    for (var seed = 0; seed < 128; seed++) {
      for (final scale in [.85, 1.15, 1.25]) {
        final motion =
            PassRunMotion(seed: seed, roundSeconds: 30, speedScale: scale);
        for (final outbound in [true, false]) {
          var legal = 0;
          var longestWait = 0;
          var wait = 0;
          for (var step = 0; step <= 300; step++) {
            final t = step / 10;
            // 375x500の中心点を用いた440ms先の合法方向機会。
            final origin =
                motion.yAt(t, PassRunRunner.companion, outbound: outbound);
            final future =
                motion.yAt(t + .44, PassRunRunner.player, outbound: outbound);
            final forward = PassAndRunRules.isForwardDirection(
                deltaX: 187.5,
                deltaY: (future - origin) * 500,
                outbound: outbound);
            if (!forward) {
              legal++;
              wait = 0;
            } else {
              wait++;
            }
            longestWait = math.max(longestWait, wait);
            for (final runner in PassRunRunner.values) {
              double velocity(double at) =>
                  motion.worldVelocityYAt(at, runner, outbound: outbound);
              final leftAcceleration =
                  (velocity(t) - velocity(t - .001)) / .001;
              final rightAcceleration =
                  (velocity(t + .001) - velocity(t)) / .001;
              expect(
                  (leftAcceleration - rightAcceleration).abs(), lessThan(.001));
              expect(motion.yAt(t, runner, outbound: outbound),
                  inInclusiveRange(.442, .558));
              expect(velocity(t).abs(), inInclusiveRange(.08, .34));
            }
          }
          expect(legal, greaterThan(70), reason: '$seed $scale $outbound');
          expect(longestWait, lessThan(70), reason: '$seed $scale $outbound');
        }
      }
    }
  });
}
