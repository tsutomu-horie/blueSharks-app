import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_presentation_layout.dart';

import 'prepare_grounded_frames.dart';
import 'recording_training_game_sound.dart';

class _PresentationFixture extends TrainingGameController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  String get position => 'ウイング';
  @override
  String? get branch => stageIndex.value < 3 ? null : 'A フォワード型';
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

  for (final sample in [
    (
      name: 'evolution-child',
      stage: 1,
      evolution: 1,
      ending: 0,
      ended: false,
      positive: false
    ),
    (
      name: 'evolution-training',
      stage: 2,
      evolution: 2,
      ending: 0,
      ended: false,
      positive: false
    ),
    (
      name: 'evolution-growth',
      stage: 3,
      evolution: 3,
      ending: 0,
      ended: false,
      positive: false
    ),
    (
      name: 'evolution-first-team',
      stage: 4,
      evolution: 0,
      ending: 0,
      ended: true,
      positive: true
    ),
    (
      name: 'position',
      stage: 4,
      evolution: 0,
      ending: 1,
      ended: true,
      positive: true
    ),
    (
      name: 'journey',
      stage: 4,
      evolution: 0,
      ending: 2,
      ended: true,
      positive: true
    ),
    (
      name: 'retirement',
      stage: 3,
      evolution: 0,
      ending: 2,
      ended: true,
      positive: false
    ),
    (
      name: 'retirement-egg',
      stage: 0,
      evolution: 0,
      ending: 2,
      ended: true,
      positive: false
    ),
  ]) {
    testWidgets('共通レイアウトの実フォント描画 ${sample.name}', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      final controller = _PresentationFixture()
        ..isServerStateReady.value = true
        ..stageIndex.value = sample.stage
        ..evolutionStage.value = sample.evolution == 0 ? null : sample.evolution
        ..ended.value = sample.ended
        ..endingStep.value = sample.ending
        ..clearPosition.value = sample.positive ? 'ウイング' : null;
      Get.put<TrainingGameController>(controller);
      final capture = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: TrainingGameScreen(
                evolutionSoundFactory: silentTrainingGameSound),
          ),
        ),
      ));
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final frame in [
          SametarohAssets.newbornFrame,
          ...SametarohAssets.normalFrames,
          ...SametarohAssets.idleFramesForBodyKey('pr'),
          ...SametarohAssets.journeyFramesForBodyKey('pr'),
          SametarohAssets.positionFrameFor('ウイング')!,
        ]) {
          await precacheImage(AssetImage(frame.asset), context);
        }
        await TrainingHomeCharacterFrameSet.forBodyKey(null).precache(context);
        await TrainingHomeCharacterFrameSet.forBodyKey('pr').precache(context);
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TrainingPresentationBody), findsOneWidget);
      if (sample.stage == 0) {
        final visual = tester.widget<Text>(find.text('🥚\n引退'));
        expect(visual.style?.color, const Color(0xff002b6d));
      }
      if (sample.evolution != 0 || (sample.positive && sample.ending < 2)) {
        expect(find.text('次へ').hitTestable(), findsOneWidget);
      }
      if (sample.stage != 0) {
        final homeFrame = find.byType(TrainingHomeCharacterFrameImage);
        final animated = find.byType(SametarohAnimatedImage);
        final target = homeFrame.evaluate().isNotEmpty
            ? homeFrame
            : animated.evaluate().isNotEmpty
                ? animated
                : find.byType(SametarohFrameImage).last;
        expect(tester.getSize(target).height, closeTo(217, .01));
      }
      expect(find.byIcon(Icons.close), findsNothing);
      expect(tester.takeException(), isNull);
      const output = String.fromEnvironment('PRESENTATION_CAPTURE_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final image = await (capture.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/${sample.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
