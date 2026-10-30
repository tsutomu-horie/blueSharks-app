import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'training_home_controls_test.dart'
    show HomeControlsFixture, homeControlsHost;
import 'package:koto_blue_sharks/presentation/training_game/training_screen_transitions.dart';

void main() {
  for (final complete in [false, true]) {
    testWidgets('実HOMEからお世話${complete ? '完了' : '中止'}後、退場してから1回だけ反映',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      final controller = _CareFixture()
        ..stageIndex.value = 2
        ..isServerStateReady.value = true;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(homeControlsHost());
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final frame in [
          ...SametarohAssets.careFramesFor(TrainingActionType.meal),
          SametarohAssets.completionFrameFor(TrainingActionType.meal),
        ]) {
          await precacheImage(AssetImage(frame.asset), context);
        }
        await precacheImage(
            AssetImage(
                TrainingCareScene.forAction(TrainingActionType.meal)!.asset),
            context);
      });
      await tester.tap(find.byKey(const ValueKey('training-home-care-meal')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (complete) {
        // 1タップで1秒進むため、5秒の行動は5回のタップで完了させます。
        for (var tap = 0; tap < 5; tap++) {
          await tester.tapAt(const Offset(2, 200));
          await tester.pump();
          if (tap < 4) {
            expect(find.text('タップして戻る'), findsNothing);
          }
        }
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('タップして戻る'), findsOneWidget);
        await tester.tap(find.text('タップして戻る'));
        await tester.pump();
      } else {
        await tester.tap(find.byTooltip('お世話を中止'));
      }
      await tester.pump();
      expect(controller.performed, 0);
      await tester.pump(const Duration(milliseconds: 110));
      expect(controller.performed, 0);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(controller.performed, complete ? 1 : 0);
      expect(find.text('お世話 ｜ ごはん'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('お世話の戻り終わりまで結果反映を待つ', (tester) async {
    var finished = false;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        final route = TrainingCareRoute<bool>(
                            builder: (context) => Scaffold(
                                body: TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('done'))));
                        final result = await Navigator.of(context).push(route);
                        await route.completed;
                        finished = result == true;
                      },
                      child: const Text('open')),
                ))));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    final opacity = tester.widget<Opacity>(find
        .ancestor(of: find.text('done'), matching: find.byType(Opacity))
        .first);
    expect(opacity.opacity, greaterThan(0));
    expect(opacity.opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('done'));
    await tester.pump();
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 110));
    expect(finished, isFalse);
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(find.text('done'), findsNothing);
  });

  Widget ending(String step,
          {bool reduceMotion = false, VoidCallback? onPressed}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Scaffold(
                body: TrainingEndingEntrance(
                    key: ValueKey(step),
                    builder: (context, animation) => Column(children: [
                          TrainingEndingItem(
                              animation: animation,
                              start: 0,
                              child: const Text('character')),
                          TrainingEndingItem(
                              animation: animation,
                              start: .7,
                              child: TextButton(
                                  onPressed: onPressed, child: Text(step))),
                        ])),
              )));

  testWidgets('見えないボタンは押せず、次の完了画面も演出を再生する', (tester) async {
    var taps = 0;
    await tester.pumpWidget(ending('first', onPressed: () => taps++));
    await tester.tap(find.text('first'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('first'));
    expect(taps, 1);
    await tester.pumpWidget(ending('second', onPressed: () => taps++));
    await tester.tap(find.text('second'), warnIfMissed: false);
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('second'));
    expect(taps, 2);
  });

  testWidgets('動きを減らす設定では待機せず全要素を表示する', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        ending('next', reduceMotion: true, onPressed: () => taps++));
    await tester.tap(find.text('next'));
    expect(taps, 1);
    expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .every((w) => w.opacity == 1),
        isTrue);
  });
}

class _CareFixture extends HomeControlsFixture {
  int performed = 0;

  @override
  void perform(TrainingActionType type, {MiniGameResult? miniGameResult}) {
    performed++;
  }
}
