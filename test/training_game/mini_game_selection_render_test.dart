import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_sheet.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';

import 'training_home_controls_test.dart' show HomeControlsFixture;

void main() {
  setUpAll(() async {
    for (final (family, files) in [
      (
        'LINESeedJP',
        [
          'assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf',
          'assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf',
        ]
      ),
      ('Inter', ['assets/fonts/Inter-Regular.ttf']),
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
    (size: const Size(375, 812), scale: 1.0),
    (size: const Size(320, 568), scale: 1.5),
    (size: const Size(568, 320), scale: 2.0),
  ]) {
    testWidgets('実HOMEから実フォントで選択画面を描画 ${sample.size} ×${sample.scale}',
        (tester) async {
      tester.view.physicalSize = sample.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      Get.put<TrainingGameController>(HomeControlsFixture()
        ..stageIndex.value = 2
        ..isServerStateReady.value = true
        ..meters['食事'] = 55
        ..meters['仕事'] = 20
        ..meters['清潔'] = 97
        ..meters['体調'] = 20);
      final capture = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(sample.scale)),
              child: child!,
            ),
            home: const TrainingGameScreen(),
          ),
        ),
      ));
      await tester.pump();
      await tester.ensureVisible(find.text('練習 / MG'));
      await tester.pump();
      await tester.tap(find.text('練習 / MG'));
      await tester.pump();
      final context = tester.element(find.byType(MiniGameSelectionSheet));
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      expect(find.text('仲間に向けてフリック\n　パスをつないで走ろう'), findsOneWidget);
      const output = String.fromEnvironment('MINI_GAME_SELECTION_CAPTURE_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary = capture.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
                  '$output/selection-${sample.size.width.toInt()}-x${sample.scale}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final close = find.byKey(const ValueKey('mini-game-selection-close'));
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(MiniGameSelectionSheet), findsNothing);
      expect(find.byType(TrainingGameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
