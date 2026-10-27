import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';

void main() {
  group('PassAndRunRules', () {
    test('真横は往路・復路とも許可し、左右を区別しない', () {
      for (final outbound in [true, false]) {
        for (final dx in [-100.0, 100.0]) {
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: 0,
              outbound: outbound,
            ),
            isFalse,
          );
        }
      }
    });
    test('攻撃方向の成分が少しでもある投球を禁止する', () {
      for (final dx in [-100.0, 0.0, 100.0]) {
        for (final dy in [0.000001, 1.0, 100.0]) {
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: -dy,
              outbound: true,
            ),
            isTrue,
          );
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: dy,
              outbound: false,
            ),
            isTrue,
          );
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: dy,
              outbound: true,
            ),
            isFalse,
          );
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: -dy,
              outbound: false,
            ),
            isFalse,
          );
        }
      }
    });
    test('不正な数値を合法方向として扱わない', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          PassAndRunRules.isForwardDirection(
            deltaX: value,
            deltaY: 0,
            outbound: true,
          ),
          isTrue,
        );
        expect(
          PassAndRunRules.isForwardDirection(
            deltaX: 100,
            deltaY: value,
            outbound: false,
          ),
          isTrue,
        );
      }
    });
    test('描画縮小後の球と仲間の半径で当たり判定を縮める', () {
      expect(
        PassAndRunRules.hasCollided(ballDeltaX: 35, ballDeltaY: 0),
        isTrue,
      );
      expect(
        PassAndRunRules.hasCollided(
          ballDeltaX: 35,
          ballDeltaY: 0,
          ballRadius: 11.25,
          mateRadius: 18,
        ),
        isFalse,
      );
      expect(
        PassAndRunRules.hasCollided(
          ballDeltaX: 29.25,
          ballDeltaY: 0,
          ballRadius: 11.25,
          mateRadius: 18,
        ),
        isTrue,
      );
    });
    test('ボールと仲間の当たり判定が重なれば成功にする', () {
      expect(
        PassAndRunRules.hasCollided(ballDeltaX: 30, ballDeltaY: 20),
        isTrue,
      );
    });

    test('当たり判定が重ならないボールは成功にしない', () {
      expect(
        PassAndRunRules.hasCollided(ballDeltaX: 40, ballDeltaY: 40),
        isFalse,
      );
    });

    test('40px必須で速度は問わず、速い短距離入力も受け付けない', () {
      for (final speed in [0.0, 100.0, 1000.0]) {
        for (final distance in [0.0, 10.0, 24.0, 39.9, 40.0, 50.0]) {
          expect(
              PassAndRunRules.isFlick(PassFlick(
                  deltaX: distance, deltaY: 0, velocityX: speed, velocityY: 0)),
              distance >= 40);
        }
      }
    });
    test('方向補助は近い合法方向のみ、前方と逆向きは補正しない', () {
      final assisted = PassAndRunRules.assistDirection(
          deltaX: 100, deltaY: 10, targetX: 100, targetY: 20, outbound: true);
      expect(assisted.deltaY / assisted.deltaX, closeTo(.2, .00001));
      for (final target in [(100.0, -1.0), (-100.0, 10.0), (100.0, 100.0)]) {
        expect(
            PassAndRunRules.assistDirection(
                deltaX: 100,
                deltaY: 10,
                targetX: target.$1,
                targetY: target.$2,
                outbound: true),
            (deltaX: 100.0, deltaY: 10.0));
      }
    });
    test('短い入力はフリックとして扱わない', () {
      const shortInput = PassFlick(
        deltaX: 10,
        deltaY: 0,
        velocityX: 700,
        velocityY: 0,
      );

      expect(PassAndRunRules.isFlick(shortInput), isFalse);
    });
  });
}
