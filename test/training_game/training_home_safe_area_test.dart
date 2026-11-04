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
    for (final (family, files) in [
      (
        'LINESeedJP',
        [
          'assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf',
          'assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf'
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
  for (final bottom in [0.0, 34.0]) {
    testWidgets('下端の背景は安全領域まで続き操作はその上に収まる bottom=$bottom', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: 44, bottom: bottom);
      tester.view.viewPadding = FakeViewPadding(top: 44, bottom: bottom);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      Get.testMode = true;
      addTearDown(Get.reset);
      Get.put<TrainingGameController>(HomeControlsFixture()
        ..stageIndex.value = 2
        ..isServerStateReady.value = true);
      final capture = GlobalKey();
      await tester.pumpWidget(homeControlsHost(captureKey: capture));
      await tester.runAsync(() async {
        final context = capture.currentContext!;
        for (final period in ['day', 'night']) {
          await precacheImage(
              AssetImage(
                  'assets/images/training_game/scenes/home_outdoor_$period.png'),
              context);
        }
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      final footer =
          tester.getRect(find.byKey(const ValueKey('training-home-footer')));
      expect(footer.bottom, 812);
      expect(footer.height, 136 + bottom);
      for (final name in ['meal', 'clean', 'squat', 'work', 'rest']) {
        final button = find.byKey(ValueKey('training-home-care-$name'));
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(812 - bottom));
        expect(tester.getRect(button).top, closeTo(695 - bottom, .001));
      }
      final panel = tester
          .getRect(find.byKey(const ValueKey('training-home-parameter-panel')));
      expect(panel.top, 56);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (capture.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final pixels =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final offset = ((image.height - 2) * image.width + 8) * 4;
        expect([
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2)
        ], isNot([255, 255, 255]));
        const output = String.fromEnvironment('SAFE_AREA_CAPTURE_DIR');
        if (output.isNotEmpty) {
          await Directory(output).create(recursive: true);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/home-safe-${bottom.toInt()}.png')
              .writeAsBytes(png!.buffer.asUint8List());
        }
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
