import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_return_sprint.dart';

void main() {
  test('境界直前の返球でも通常加速度へ早く切り替えない', () {
    for (final up in [true, false]) {
      final y = up ? .105 : .895;
      final v = up ? -.18 : .18;
      final sprint = PassRunReturnSprint(
          start: 0,
          position: y,
          velocity: v,
          minimum: .1,
          maximum: .9,
          attackUp: up,
          normalPosition: (_) => .5,
          normalVelocity: (_) => 0,
          end: 3,
          normalSpeed: .207);
      sprint.release(0);
      for (var i = 0; i <= 3000; i++) {
        expect(sprint.positionAt(i * .001), inInclusiveRange(.1, .9));
      }
    }
  });
  test('受球加速と投球後制動は位置・速度が連続し、画面内で通常速度へ戻る', () {
    for (var seed = 0; seed < 32; seed++) {
      final m = PassRunMotion(seed: seed)
        ..updateFieldGeometry(const Size(390, 700));
      for (final up in [true, false]) {
        double base(double t) =>
            m.yAt(t, PassRunRunner.companion, outbound: up);
        double velocity(double t) =>
            m.worldVelocityYAt(t, PassRunRunner.companion, outbound: up) +
            (up ? 1 : -1) * m.runningForwardRate;
        final sprint = PassRunReturnSprint(
            start: 2,
            position: base(2),
            velocity: velocity(2),
            minimum: m.geometry.minimum,
            maximum: m.geometry.maximum,
            attackUp: up,
            normalPosition: base,
            normalVelocity: velocity,
            end: 20,
            normalSpeed: .18 * 1.15);
        expect(sprint.positionAt(2), closeTo(base(2), 1e-10));
        expect(sprint.velocityAt(2), closeTo(velocity(2), 1e-10));
        final beforeA = sprint.accelerationAt(2.237);
        final beforeY = sprint.positionAt(2.237),
            beforeV = sprint.velocityAt(2.237);
        sprint.release(2.237);
        expect(sprint.positionAt(2.237), closeTo(beforeY, 1e-10));
        expect(sprint.velocityAt(2.237), closeTo(beforeV, 1e-10));
        expect(sprint.accelerationAt(2.237), closeTo(beforeA, 1e-8));
        for (var i = 0; i < 18000; i++) {
          final t = 2 + i * .001;
          expect(
              sprint.positionAt(t),
              inInclusiveRange(
                  m.geometry.minimum - 1e-7, m.geometry.maximum + 1e-7),
              reason: 'seed=$seed up=$up t=$t');
          if (t > 2.6) {
            expect(sprint.velocityAt(t).abs(),
                lessThanOrEqualTo(.18 * 1.15 + .001));
          }
        }
        // Sampling a future position must never change the current/paused state.
        final frozen = sprint.positionAt(3);
        sprint.positionAt(18);
        expect(sprint.positionAt(3), frozen);
      }
    }
  });

  test('加速後の実位置から折り返しても名前と体が重ならず場内につながる', () {
    for (var seed = 0; seed < 8; seed++) {
      final motion = PassRunMotion(seed: seed);
      for (final size in [
        const Size(208, 262),
        const Size(390, 700),
        const Size(812, 200)
      ]) {
        motion.updateFieldGeometry(size);
        final g = motion.geometry;
        for (final y in [g.minimum, (g.minimum + g.maximum) / 2, g.maximum]) {
          for (var tick = 0; tick <= 100; tick++) {
            final progress = tick / 100;
            Offset at(PassRunRunner who) => motion.turnOffset(progress, who,
                field: size, actorSize: g.actorSize, mateStartY: y);
            final player = Rect.fromCenter(
                center: at(PassRunRunner.player),
                width: g.actorSize,
                height: g.actorSize);
            final mate = Rect.fromCenter(
                center: at(PassRunRunner.companion),
                width: g.actorSize,
                height: g.actorSize);
            final label = Rect.fromLTWH(
                player.left,
                player.top - 16 * g.labelScale - 2,
                g.actorSize,
                16 * g.labelScale);
            expect(player.overlaps(mate), isFalse);
            expect(label.overlaps(mate), isFalse);
            for (final rect in [player, mate]) {
              expect(rect.top, greaterThanOrEqualTo(-1e-8));
              expect(rect.bottom, lessThanOrEqualTo(size.height + 1e-8));
            }
            if (tick == 0) {
              expect(at(PassRunRunner.companion).dy,
                  closeTo(y * size.height, 1e-8));
            }
          }
        }
      }
    }
  });

  test('実寸定速返球の待ちを通常軌道と同条件で比較する', () {
    final before = <double>[], after = <double>[];
    var maxFramePixels = 0.0, maxAcceleration = 0.0, maxJerk = 0.0;
    for (var seed = 0; seed < 32; seed++) {
      final m = PassRunMotion(seed: seed)
        ..updateFieldGeometry(const Size(390, 700));
      for (final up in [true, false]) {
        for (final caught in [0.0, 3.0, 7.0, 11.0]) {
          double base(double t) =>
              m.yAt(t, PassRunRunner.companion, outbound: up);
          double velocity(double t) =>
              m.worldVelocityYAt(t, PassRunRunner.companion, outbound: up) +
              (up ? 1 : -1) * m.runningForwardRate;
          final span = m.geometry.movementRadius * 2;
          double fraction(double t) => (base(t) - m.geometry.minimum) / span;
          final sprint = PassRunReturnSprint(
              start: caught,
              position: fraction(caught),
              velocity: velocity(caught) / span,
              minimum: 0,
              maximum: 1,
              attackUp: up,
              normalPosition: fraction,
              normalVelocity: (t) => velocity(t) / span,
              end: caught + 9,
              normalSpeed: .18 * 1.15 / span);
          var releaseWait = 0.0;
          double waitFor(double Function(double) mate) {
            const speed = 390 * .5 / .44;
            for (var tick = 12; tick <= 1000; tick++) {
              final wait = tick * .008, t = caught + wait;
              var low = 0.0, high = 4.0;
              for (var i = 0; i < 32; i++) {
                final flight = (low + high) / 2;
                final dy =
                    (m.yAt(t + flight, PassRunRunner.player, outbound: up) -
                            mate(t)) *
                        700;
                if (math.sqrt(195 * 195 + dy * dy) > speed * flight) {
                  low = flight;
                } else {
                  high = flight;
                }
              }
              final dy =
                  m.yAt(t + high, PassRunRunner.player, outbound: up) - mate(t);
              if (up ? dy >= 0 : dy <= 0) {
                releaseWait = wait;
                return wait + high;
              }
            }
            return 12;
          }

          before.add(waitFor(base));
          final assistedWait =
              waitFor((t) => m.geometry.minimum + span * sprint.positionAt(t));
          after.add(assistedWait);
          sprint.release(caught + releaseWait);
          var lastA = sprint.accelerationAt(caught);
          for (var i = 1; i <= (releaseWait + 1) * 250; i++) {
            final t = caught + i * .004;
            final accel = sprint.accelerationAt(t);
            maxAcceleration = math.max(maxAcceleration, accel.abs());
            maxJerk = math.max(maxJerk, (accel - lastA).abs() / .004);
            maxFramePixels = math.max(
                maxFramePixels,
                (sprint.positionAt(t + .016667) - sprint.positionAt(t)).abs() *
                    span *
                    700);
            lastA = accel;
          }
        }
      }
    }
    before.sort();
    after.sort();
    final b95 = before[(before.length * .95).floor()],
        a95 = after[(after.length * .95).floor()];
    // A burst must improve tempo without changing the direction predicate.
    expect(a95, lessThan(b95));
    expect(after.last, lessThan(1.8));
    expect(maxFramePixels, lessThan(12));
    expect(maxAcceleration, lessThanOrEqualTo(3.51));
    expect(maxJerk, lessThanOrEqualTo(24.1));
    // ignore: avoid_print
    print(
        'natural movement max 60Hz displacement=${maxFramePixels.toStringAsFixed(2)}px at700px field; acceleration=${maxAcceleration.toStringAsFixed(2)} range/s2; jerk=${maxJerk.toStringAsFixed(2)} range/s3');
    // ignore: avoid_print
    print(
        'return sprint same seeds0..31 both directions catch[0,3,7,11] n=${before.length} catch-to-player p95 ${b95.toStringAsFixed(3)} -> ${a95.toStringAsFixed(3)}s max ${before.last.toStringAsFixed(3)} -> ${after.last.toStringAsFixed(3)}s');
  });
}
