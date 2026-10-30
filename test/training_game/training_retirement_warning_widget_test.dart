import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_home_controls_test.dart'
    show homeControlsHost, HomeControlsFixture;
import 'package:koto_blue_sharks/presentation/training_game/models/training_retirement_warning.dart';

/// Display-only fixture; controller persistence/API boundaries are tested in the
/// separate fake-provider suite. No HTTP, Firebase, timers, or storage writes.
class _WarningHomeFixture extends HomeControlsFixture {
  final _collapsed = false.obs;
  @override
  List<TrainingRetirementWarning> get retirementWarnings =>
      TrainingRetirementWarning.evaluate(
        scope: 'widget-fixture',
        stageIndex: stageIndex.value,
        ended: ended.value,
        meters: meters,
        overStartedAt: {'食事': DateTime.utc(2026, 10, 28)},
        zeroHours: {},
        elapsedHours: 0,
        serverNow: DateTime.utc(2026, 10, 30),
      );
  @override
  bool isRetirementWarningCollapsed(TrainingRetirementWarning warning) =>
      _collapsed.value;
  @override
  void collapseRetirementWarning(TrainingRetirementWarning warning) =>
      _collapsed.value = true;
  @override
  void expandRetirementWarning(TrainingRetirementWarning warning) =>
      _collapsed.value = false;
}

void main() {
  for (final variant in [
    (size: const Size(375, 812), scale: 1.0),
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(375, 667), scale: 1.6),
  ]) {
    testWidgets(
        'card/chip preserve character and menus: ${variant.size} text ${variant.scale}',
        (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (Platform.environment['NO119_CAPTURE_DIR'] != null) {
        await tester.runAsync(() async {
          final font = FontLoader('LINESeedJP')
            ..addFont(rootBundle
                .load('assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf'));
          await font.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
      }
      SharedPreferences.setMockInitialValues({});
      await MySharedPref.init();
      Get.testMode = true;
      addTearDown(Get.reset);
      final c = _WarningHomeFixture()
        ..stageIndex.value = 2
        ..isServerStateReady.value = true;
      c.meters['食事'] = 145;
      Get.put<TrainingGameController>(c);
      const capture = ValueKey('retirement-warning-capture');
      await tester.pumpWidget(
          homeControlsHost(captureKey: capture, textScale: variant.scale));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (Platform.environment['NO119_CAPTURE_DIR'] != null) {
        await tester.runAsync(() async {
          // Give bundled character/background decodes a real async turn.
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();
      }
      final card = find.byKey(const ValueKey('retirement-warning-card'));
      final chip = find.byKey(const ValueKey('retirement-warning-chip'));
      final close = find.byKey(const ValueKey('retirement-warning-close'));
      expect(card, findsOneWidget);
      expect(find.text('食事のバランスに注意'), findsOneWidget);
      expect(find.text('回復すると、この警告は消えます。'), findsNothing);
      expect(find.text('閉じる'), findsNothing);
      expect(find.textContaining('あと24時間'), findsNothing);
      void checkBounds(Finder warning) {
        final rect = tester.getRect(warning);
        final character =
            tester.getRect(find.byType(TrainingHomeRoamingCharacter));
        expect(rect.bottom, lessThanOrEqualTo(character.top));
        for (final finder in [
          find.byKey(const ValueKey('training-home-dex')),
          find.text('練習 / MG'),
          find.widgetWithText(TextButton, 'ごはん'),
          find.widgetWithText(TextButton, '掃除'),
          find.widgetWithText(TextButton, '筋トレ'),
          find.widgetWithText(TextButton, '仕事'),
          find.widgetWithText(TextButton, '休養'),
        ]) {
          expect(finder, findsOneWidget);
          expect(rect.overlaps(tester.getRect(finder)), isFalse);
        }
        expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(44));
      }

      checkBounds(card);
      final directory = Platform.environment['NO119_CAPTURE_DIR'];
      if (directory != null) {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File(
                  '$directory/no119-card-${variant.size.width.toInt()}x${variant.size.height.toInt()}-${variant.scale}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(close);
      await tester.pump();
      expect(card, findsNothing);
      expect(chip, findsOneWidget);
      final chipRect = tester.getRect(chip);
      expect(
          chipRect.bottom,
          lessThan(
              tester.getRect(find.byType(TrainingHomeRoamingCharacter)).top));
      c.cooldownTick.value++;
      await tester.pump();
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();
      expect(card, findsOneWidget);
      c.meters['食事'] = 100;
      await tester.pump();
      expect(card, findsNothing);
      expect(chip, findsNothing);
      expect(c.canPerform(TrainingActionType.clean), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
