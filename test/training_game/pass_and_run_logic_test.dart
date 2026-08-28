import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';

void main() {
  group('PassAndRunRules', () {
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
