import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';

class _ReturnFixture extends TrainingGameController {
  Completer<bool> pending = Completer<bool>();
  int syncCalls = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<bool> syncBeforeReturningHome() async {
    syncCalls++;
    isReturningHome.value = true;
    final result = await pending.future;
    if (!result) isReturningHome.value = false;
    return result;
  }
}

void main() {
  testWidgets('同期中は離脱せず、成功後はHOMEへ戻って再度開ける', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = _ReturnFixture()
      ..stageIndex.value = 2
      ..isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller, permanent: true);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        home: Scaffold(
            body: TextButton(
          onPressed: () => Get.toNamed<void>(Routes.TRAINING_GAME),
          child: const Text('育成を開く'),
        )),
        getPages: [
          GetPage(
              name: Routes.TRAINING_GAME,
              page: () => const TrainingGameScreen())
        ],
      ),
    ));
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 2; attempt++) {
      controller.pending = Completer<bool>();
      controller.isReturningHome.value = false;
      await tester.tap(find.text('育成を開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('training-home-exit')));
      await tester.pump();
      expect(controller.syncCalls, attempt + 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(TrainingGameScreen), findsOneWidget);
      controller.pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(TrainingGameScreen), findsNothing);
      expect(find.text('育成を開く'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
