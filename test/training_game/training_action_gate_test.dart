import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_action_gate.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';

void main() {
  test('デバッグ解除なしではサーバー制限を尊重し、解除時は実行できる', () {
    final now = DateTime.utc(2026, 9, 4, 12);
    final gate = TrainingActionGate(now: () => now);

    gate.replaceServerCooldowns({
      TrainingActionType.meal: now.add(const Duration(seconds: 30)),
    });

    expect(
      gate.canPerform(
        TrainingActionType.meal,
        clientCooldownEnabled: false,
      ),
      isFalse,
    );
    expect(
      gate.canPerform(
        TrainingActionType.meal,
        clientCooldownEnabled: false,
        bypassServerCooldown: true,
      ),
      isTrue,
    );
    expect(
      gate.remaining(
        TrainingActionType.meal,
        clientCooldownEnabled: false,
      ),
      const Duration(seconds: 30),
    );
    expect(
      gate.remaining(
        TrainingActionType.meal,
        clientCooldownEnabled: false,
        bypassServerCooldown: true,
      ),
      Duration.zero,
    );
  });

  test('送信中の同一アクションを二重に受け付けない', () {
    final gate = TrainingActionGate(now: () => DateTime.utc(2026, 9, 4));

    expect(gate.markPending(TrainingActionType.clean), isTrue);
    expect(
      gate.canPerform(
        TrainingActionType.clean,
        clientCooldownEnabled: false,
      ),
      isFalse,
    );

    gate.clearPending(TrainingActionType.clean);
    expect(
      gate.canPerform(
        TrainingActionType.clean,
        clientCooldownEnabled: false,
      ),
      isTrue,
    );
  });
}
