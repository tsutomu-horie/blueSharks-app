import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/environment_badge.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

class _DisplayController extends TrainingGameController {
  @override
  // 表示テストでは起動時通信・周期タイマーを開始しません。
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  testWidgets('検証版のDEBUG・デバコマ・段階とタイプは同時表示、通常版はすべて非表示', (tester) async {
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
        home: const TrainingGameScreen(),
      ),
    ));
    await tester.pump();
    const visible = AppEnvironment.showsTrainingDebugUi;
    final expected = visible ? findsOneWidget : findsNothing;
    expect(find.byType(Banner), expected);
    expect(find.byTooltip('デバッグコマンド'), expected);
    expect(find.text('ノーマル鮫太朗（分岐前）'), expected);
    expect(find.text(controller.currentStage.name), expected);
    // 通常版にも食事等の可視パラメーターを維持します。
    expect(find.textContaining('食事'), findsWidgets);
    if (visible) {
      await tester.tap(find.byTooltip('デバッグコマンド'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('現在：'), findsOneWidget);
      expect(find.text('＋6時間'), findsOneWidget);
      // メニューを開くだけでゲーム操作を送信しません。
    }
    await tester.pumpWidget(const SizedBox());
  });
}
