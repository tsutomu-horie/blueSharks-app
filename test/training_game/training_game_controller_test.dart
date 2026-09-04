import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';

void main() {
  test('進化演出中のOS割り込み後も、次へ進むと16倍速の時間が再開する', () {
    final controller = TrainingGameController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 1;
    controller.evolutionStage.value = 1;
    controller.timeSpeed.value = 16;

    controller.pauseLocalProgress();
    expect(controller.isTutorialTimeActive, isFalse);

    controller.advanceEvolution();
    expect(controller.isTutorialTimeActive, isTrue);

    controller.tickTutorialTimer();
    expect(controller.secondsInStage.value, 16);
  });

  test('進化演出がない状態では、次へ操作で停止状態を解除しない', () {
    final controller = TrainingGameController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 1;
    controller.pauseLocalProgress();

    controller.advanceEvolution();

    expect(controller.isTutorialTimeActive, isFalse);
  });
}
