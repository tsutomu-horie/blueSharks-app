import 'recording_training_game_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/environment_badge.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_controls.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

class _DisplayController extends TrainingGameController {
  @override
  // 表示テストでは起動時通信・周期タイマーを開始しません。
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  testWidgets('状態・段階ラベルは全環境で非表示、DEBUGと数値・操作UIを維持', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = _DisplayController()
      ..stageIndex.value = 2
      ..isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (_, child) => EnvironmentBadge(child: child!),
        home: const TrainingGameScreen(
            evolutionSoundFactory: silentTrainingGameSound),
      ),
    ));
    await tester.pump();
    const debugUiVisible = AppEnvironment.showsTrainingDebugUi;
    final expected = debugUiVisible ? findsOneWidget : findsNothing;
    expect(find.byType(Banner), expected);
    expect(find.byTooltip('デバッグコマンド'), expected);
    expect(find.text('ノーマル鮫太朗（分岐前）'), findsNothing);
    expect(find.text(controller.currentStage.name), findsNothing);
    expect(find.byType(TrainingHomeMeter), findsNWidgets(4));
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
    // 状態ラベル用の予約高を取り除き、立ち絵の下端位置を保ちます。
    expect(
      tester.getSize(find.byType(TrainingHomeRoamingCharacter)).height,
      184,
    );

    for (final stage in [0, 1, 2, 3, 4]) {
      controller.stageIndex.value = stage;
      controller.clearPosition.value = stage == 4 ? 'プロップ' : null;
      await tester.pump();
      expect(find.text(controller.currentStage.name), findsNothing);
      expect(find.text('チュートリアル①（卵）'), findsNothing);
      expect(find.text('チュートリアル②（幼少）'), findsNothing);
      expect(find.text('ノーマル鮫太朗（分岐前）'), findsNothing);
      expect(find.text('プロップ'), findsNothing);
    }

    if (debugUiVisible) {
      await tester.tap(find.byTooltip('デバッグコマンド'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('現在：'), findsOneWidget);
      expect(find.text('＋6時間'), findsOneWidget);
      // メニューを開くだけでゲーム操作を送信しません。
    }
    await tester.pumpWidget(const SizedBox());
  });
}
