import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_sheet.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';

class _SelectionFixture extends TrainingGameController {
  int completions = 0;
  bool coolingDown = false;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  bool canPerform(TrainingActionType type) => !coolingDown;

  @override
  Duration cooldownRemaining(TrainingActionType type) =>
      coolingDown ? const Duration(seconds: 60) : Duration.zero;

  @override
  void completeMiniGame(TrainingActionType type, MiniGameResult result) {
    completions++;
  }
}

void main() {
  Future<_SelectionFixture> home(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = _SelectionFixture()
      ..stageIndex.value = 2
      ..isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(home: TrainingGameScreen()),
    ));
    await tester.pump();
    return controller;
  }

  for (final type in [
    TrainingActionType.tackle,
    TrainingActionType.passAndRun
  ]) {
    testWidgets('実HOMEからゲームを選択し、未プレイで戻っても結果を送らず再選択できる ${type.name}',
        (tester) async {
      final controller = await home(tester);
      await tester.tap(find.text('練習 / MG'));
      await tester.pumpAndSettle();
      final onTap = tester
          .widget<InkWell>(
              find.byKey(ValueKey('mini-game-selection-${type.name}')))
          .onTap!;
      onTap();
      onTap();
      await tester.pumpAndSettle();
      expect(
          type == TrainingActionType.tackle
              ? find.byType(TackleGameScreen)
              : find.byType(PassAndRunGameScreen),
          findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TrainingGameScreen), findsOneWidget);
      expect(controller.completions, 0);
      await tester.tap(find.text('練習 / MG'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniGameSelectionSheet), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(controller.completions, 0);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('既存の育成段階・終了状態による入口の有効条件を保持', (tester) async {
    final controller = await home(tester);
    TextButton entry() =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, '練習 / MG'));
    expect(entry().onPressed, isNotNull);
    controller.stageIndex.value = 1;
    await tester.pump();
    expect(entry().onPressed, isNull);
    controller.stageIndex.value = 2;
    await tester.pump();
    expect(entry().onPressed, isNotNull);
    controller.ended.value = true;
    await tester.pump();
    expect(find.text('練習 / MG'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
