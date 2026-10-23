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
