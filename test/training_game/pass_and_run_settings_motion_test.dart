import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('既定速度は明示1.15と位置・速度・距離が完全に一致する', () {
    for (final seed in [0, 54, 999]) {
      final defaults = PassRunMotion(seed: seed);
      final explicit = PassRunMotion(seed: seed, speedScale: 1.15);
      for (final outbound in [true, false]) {
        for (final runner in PassRunRunner.values) {
          for (var ms = 0; ms <= 17000; ms += 20) {
            final t = ms / 1000;
            expect(defaults.yAt(t, runner, outbound: outbound),
                explicit.yAt(t, runner, outbound: outbound));
            expect(defaults.worldVelocityYAt(t, runner, outbound: outbound),
                explicit.worldVelocityYAt(t, runner, outbound: outbound));
            expect(defaults.distanceAt(t, runner, outbound: outbound),
                explicit.distanceAt(t, runner, outbound: outbound));
          }
        }
      }
    }
  });

  test('別速度は同seed軌道の時間だけを伸縮し、長いラウンドも生成する', () {
    final base = PassRunMotion(seed: 54, roundSeconds: 30);
    for (final scale in [.85, 1.25]) {
      final motion =
          PassRunMotion(seed: 54, roundSeconds: 30, speedScale: scale);
      expect(motion.roundSeconds, 30);
      expect(motion.runningForwardRate, .18 * scale);
      for (final outbound in [true, false]) {
        for (final runner in PassRunRunner.values) {
          // 末尾の補間接線に依存しない共通区間を比較する。
          for (var ms = 0; ms <= 25000; ms += 100) {
            final t = ms / 1000;
            final baseTime = t * scale / PassRunMotion.speedScale;
            expect(motion.yAt(t, runner, outbound: outbound),
                closeTo(base.yAt(baseTime, runner, outbound: outbound), 1e-12));
            expect(
                motion.distanceAt(t, runner, outbound: outbound),
                closeTo(base.distanceAt(baseTime, runner, outbound: outbound),
                    1e-12));
            expect(motion.yAt(30, runner, outbound: outbound),
                inInclusiveRange(.41, .59));
          }
        }
      }
    }
  });

  test('速度・時間の範囲端点64seedは連続し、入替経路も画面内に収まる', () {
    for (final scale in [.85, 1.25]) {
      for (final roundSeconds in [10.0, 30.0]) {
        for (var seed = 0; seed < 64; seed++) {
          final motion = PassRunMotion(
              seed: seed, roundSeconds: roundSeconds, speedScale: scale);
          final profile = 'seed=$seed scale=$scale round=$roundSeconds';
          for (final outbound in [true, false]) {
            for (final runner in PassRunRunner.values) {
              double? previousY;
              double? previousVelocity;
              // 受球先の予測に使う終了後2秒も含め、20msごとに掃引する。
              for (var ms = 0; ms <= (roundSeconds + 2) * 1000; ms += 20) {
                final t = ms / 1000;
                final y = motion.yAt(t, runner, outbound: outbound);
                final velocity =
                    motion.worldVelocityYAt(t, runner, outbound: outbound);
                final context =
                    '$profile outbound=$outbound runner=$runner t=$t';
                if (!y.isFinite || y < .40 || y > .60) {
                  fail('位置が有限なfield範囲外: $context y=$y');
                }
                if (!velocity.isFinite) {
                  fail('速度が非有限: $context velocity=$velocity');
                }
                // 20ms間でfield高1%超の移動や急な速度変化がないこと。
                if (previousY != null && (y - previousY).abs() > .01) {
                  fail('位置が不連続: $context previous=$previousY y=$y');
                }
                if (previousVelocity != null &&
                    (velocity - previousVelocity).abs() > .03) {
                  fail(
                      '速度が不連続: $context previous=$previousVelocity velocity=$velocity');
                }
                previousY = y;
                previousVelocity = velocity;
              }
            }
          }
          for (final field in [const Size(320, 400), const Size(375, 500)]) {
            for (final runner in PassRunRunner.values) {
              for (var step = 0; step <= 20; step++) {
                final progress = step / 20;
                final position = motion.turnOffset(progress, runner,
                    field: field, actorSize: 63);
                const halfActor = 63 / 2;
                if (!position.dx.isFinite ||
                    !position.dy.isFinite ||
                    position.dx < halfActor ||
                    position.dx > field.width - halfActor ||
                    position.dy < halfActor ||
                    position.dy > field.height - halfActor) {
                  fail(
                      '入替中のキャラがfield外: $profile field=$field runner=$runner progress=$progress position=$position');
                }
              }
            }
          }
        }
      }
    }
  });
}
