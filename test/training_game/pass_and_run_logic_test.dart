import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';

void main() {
  group('PassAndRunRules', () {
    test('仲間方向から10度以内のフリックを成功にする', () {
      const flick = PassFlick(
        deltaX: 100,
        deltaY: 0,
        velocityX: 700,
        velocityY: 0,
      );

      expect(
        PassAndRunRules.isAccurate(
          flick: flick,
          targetDeltaX: 100,
          targetDeltaY: 10,
        ),
        isTrue,
      );
    });

    test('10度を超える方向ミスと短い入力を失敗にする', () {
      const wrongDirection = PassFlick(
        deltaX: 100,
        deltaY: 0,
        velocityX: 700,
        velocityY: 0,
      );
      const shortInput = PassFlick(
        deltaX: 10,
        deltaY: 0,
        velocityX: 700,
        velocityY: 0,
      );

      expect(
        PassAndRunRules.isAccurate(
          flick: wrongDirection,
          targetDeltaX: 100,
          targetDeltaY: 50,
        ),
        isFalse,
      );
      expect(PassAndRunRules.isFlick(shortInput), isFalse);
    });
  });
}
