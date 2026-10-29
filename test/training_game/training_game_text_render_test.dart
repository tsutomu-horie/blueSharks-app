import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';

import 'training_home_controls_test.dart'
    show HomeControlsFixture, homeControlsHost;

void main() {
  setUpAll(() async {
    final loader = FontLoader('LINESeedJP')
      ..addFont(
          rootBundle.load('assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf'))
      ..addFont(
          rootBundle.load('assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf'));
    await loader.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(834, 1194)
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('既存フォントで育成ホームを描画 $size ×$scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Get.testMode = true;
        addTearDown(Get.reset);
        Get.put<TrainingGameController>(HomeControlsFixture()
          ..stageIndex.value = 2
          ..isServerStateReady.value = true);
        final key = GlobalKey();
        await tester
            .pumpWidget(homeControlsHost(captureKey: key, textScale: scale));
        await tester.runAsync(() async {
          final context = key.currentContext!;
          for (final period in ['day', 'night']) {
            await precacheImage(
                AssetImage(
                    'assets/images/training_game/scenes/home_outdoor_$period.png'),
                context);
          }
          for (final widget in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(widget.image, context);
          }
        });
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        const output = String.fromEnvironment('GAME_TEXT_CAPTURE_DIR');
        if (output.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(output).create(recursive: true);
            await File('$output/home-${size.width.toInt()}-x$scale.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
