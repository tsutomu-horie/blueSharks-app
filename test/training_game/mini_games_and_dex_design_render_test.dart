import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_frame.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_ocean_decoration.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_dex_dialog.dart';

import 'prepare_grounded_frames.dart';
import 'recording_training_game_sound.dart';

class _DexDesignFixture extends TrainingGameController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  Future<void> refreshUnlockedPositions() async {}
  @override
  bool isPositionUnlocked(String position) =>
      const {'プロップ', 'ウイング'}.contains(position);
}

Future<void> _capture(
    WidgetTester tester, GlobalKey capture, String name) async {
  expect(tester.takeException(), isNull);
  const output = String.fromEnvironment('GAMES_DEX_CAPTURE_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final image = await (capture.currentContext!.findRenderObject()
            as RenderRepaintBoundary)
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _precacheVisible(WidgetTester tester, BuildContext context) async {
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await prepareGroundedFrames();
    for (final (family, files) in [
      (
        'LINESeedJP',
        [
          'assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf',
          'assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf',
        ]
      ),
      ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  for (final game in ['tackle', 'pass']) {
    for (final phase in ['ready', 'playing', 'paused', 'result']) {
      testWidgets('実フォントでミニゲームを描画 $game/$phase', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var now = DateTime.utc(2026, 11, 2, 3);
        ServerTimeClock.instance.synchronize(now);
        Future<void> advance(Duration elapsed) async {
          now = now.add(elapsed);
          ServerTimeClock.instance.synchronize(now);
          await tester.pump(elapsed);
        }

        final sound = silentTrainingGameSound();
        addTearDown(sound.dispose);
        final screen = game == 'tackle'
            ? TackleGameScreen(
                random: Random(5),
                settings: const TackleSettings(
                    setCount: 1, snapshotToken: 'design-render-fixture'),
                soundService: sound,
                feedbackSoundFactory: silentTrainingGameSound,
              )
            : PassAndRunGameScreen(
                now: () => now, soundService: sound, motionSeed: 7);
        final capture = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Builder(
                builder: (context) => Scaffold(
                        body: TextButton(
                      onPressed: () => Navigator.of(context)
                          .push<MiniGameResult>(
                              MaterialPageRoute<MiniGameResult>(
                                  builder: (_) => screen)),
                      child: const Text('プレイ画面を開く'),
                    ))),
          ),
        ));
        await tester.tap(find.text('プレイ画面を開く'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final context = tester.element(find.byType(MaterialApp));
        if (game == 'pass') {
          await tester.runAsync(() async {
            for (final asset in PassAndRunCharacterVisual.assets) {
              await precacheImage(AssetImage(asset), context);
            }
          });
        }
        await _precacheVisible(tester, context);
        expect(find.text('スタート').hitTestable(), findsOneWidget);
        expect(
            tester
                .widget<ElevatedButton>(find
                    .ancestor(
                        of: find.text('スタート'),
                        matching: find.byType(ElevatedButton))
                    .first)
                .onPressed,
            isNotNull);
        // 読み込み後の無効→有効の色遷移も完了させます。
        await tester.pump(const Duration(milliseconds: 250));
        if (phase != 'ready') {
          await tester.tap(find.text('スタート'));
          await tester.pump();
          if (phase == 'result' && game == 'tackle') {
            await advance(const Duration(milliseconds: 1400));
            await tester.tap(find.byKey(const Key('tackle-tap-up')));
            await tester.pump();
            await advance(const Duration(milliseconds: 650));
            await tester.tap(find.text('SET 1 / 1'));
            await tester.pump();
            await advance(const Duration(milliseconds: 1100));
          } else if (phase == 'result') {
            await advance(const Duration(milliseconds: 15100));
            await advance(const Duration(milliseconds: 1000));
            await advance(const Duration(milliseconds: 15100));
            await tester.pump(const Duration(milliseconds: 1100));
          } else {
            await advance(Duration(
                milliseconds:
                    game == 'tackle' && phase == 'playing' ? 1400 : 600));
            if (phase == 'paused') {
              await tester.tap(find.byTooltip('一時停止'));
              await tester.pump();
              expect(find.text('一時停止中'), findsOneWidget);
            }
          }
        }
        await _precacheVisible(tester, context);
        if (phase == 'result') {
          expect(find.text('メインへ戻る').hitTestable(), findsOneWidget);
        }
        if (phase != 'playing') {
          final expected = switch (phase) {
            'ready' => TrainingWindowPattern.start,
            'paused' => TrainingWindowPattern.pause,
            _ => TrainingWindowPattern.result
          };
          expect(
              tester
                  .widgetList<MiniGameSelectionFrame>(
                      find.byType(MiniGameSelectionFrame))
                  .where((frame) => frame.pattern == expected),
              hasLength(1));
        }
        await _capture(tester, capture, '$game-$phase');
        if (phase == 'result') {
          await tester.tap(find.text('メインへ戻る'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(find.text('プレイ画面を開く').hitTestable(), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final history in [false, true]) {
    testWidgets('実HOMEからずかんを描画 history=$history', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      ServerTimeClock.instance.synchronize(DateTime.utc(2026, 11, 2, 3));
      final controller = _DexDesignFixture()
        ..isServerStateReady.value = true
        ..stageIndex.value = history ? 4 : 2
        ..ended.value = history
        ..endingStep.value = history ? 3 : 0
        ..clearPosition.value = history ? 'ウイング' : null
        ..unlockedPositions.addAll(['プロップ', 'ウイング']);
      Get.put<TrainingGameController>(controller);
      final capture = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: TrainingGameScreen(
                    evolutionSoundFactory: silentTrainingGameSound))),
      ));
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        await precacheImage(
            const AssetImage(
                'assets/images/training_game/scenes/home_outdoor_day.png'),
            context);
      });
      await tester.pump();
      if (!history) {
        await tester.tap(find.byKey(const ValueKey('training-home-dex')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TrainingDexDialog), findsOneWidget);
      }
      await _precacheVisible(tester, context);
      await _capture(tester, capture, history ? 'dex-history' : 'dex-top');
      if (!history) {
        await tester.scrollUntilVisible(find.text('フルバック'), 250,
            scrollable: find.byType(Scrollable).last);
        await _capture(tester, capture, 'dex-bottom');
        await tester.tap(find.text('閉じる'));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
