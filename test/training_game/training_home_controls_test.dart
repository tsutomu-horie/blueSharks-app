import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/environment_badge.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_background.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_controls.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

/// 表示だけのfixture。実API、時計、永続化を起動しません。
class HomeControlsFixture extends TrainingGameController {
  Duration remaining = Duration.zero;
  bool pending = false;
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  Duration cooldownRemaining(TrainingActionType type) {
    cooldownTick.value;
    return type == TrainingActionType.clean ? remaining : Duration.zero;
  }

  @override
  bool canPerform(TrainingActionType type) =>
      type != TrainingActionType.clean ||
      (!pending && remaining == Duration.zero);
  void setRemaining(Duration value) {
    remaining = value;
    cooldownTick.value++;
  }
}

Widget homeControlsHost({Key? captureKey}) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (_, child) => EnvironmentBadge(child: child!),
        home:
            RepaintBoundary(key: captureKey, child: const TrainingGameScreen()),
      ),
    );

void main() {
  for (final size in [const Size(375, 812), const Size(320, 568)]) {
    testWidgets('実HOMEの待機前後でフッター・5ボタン・本文・キャラクター位置が固定 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      final controller = HomeControlsFixture()
        ..stageIndex.value = 2
        ..isServerStateReady.value = true;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(homeControlsHost());
      await tester.pump();
      Map<String, Rect> rects() => {
            'footer': tester
                .getRect(find.byKey(const ValueKey('training-home-footer'))),
            'body': tester.getRect(find.byType(TrainingHomeBackground)),
            'character':
                tester.getRect(find.byType(TrainingHomeRoamingCharacter)),
            for (final type in [
              TrainingActionType.meal,
              TrainingActionType.clean,
              TrainingActionType.squat,
              TrainingActionType.work,
              TrainingActionType.rest
            ])
              type.name: tester.getRect(
                  find.byKey(ValueKey('training-home-care-${type.name}'))),
          };
      final baseline = rects();
      expect(baseline['footer']!.height, 92);
      final clean = find.byKey(const ValueKey('training-home-care-clean'));
      final states = [
        const Duration(seconds: 12),
        const Duration(milliseconds: 800),
        const Duration(microseconds: 1),
        Duration.zero
      ];
      for (final value in states) {
        controller.setRemaining(value);
        await tester.pump();
        expect(rects(), baseline, reason: '$value');
        final button = tester.widget<TextButton>(
            find.descendant(of: clean, matching: find.byType(TextButton)));
        expect(button.onPressed == null, value > Duration.zero);
        if (value > Duration.zero) {
          expect(find.text(value.inSeconds >= 1 ? 'あと 00:12' : 'あと 00:01'),
              findsOneWidget);
        } else {
          expect(find.text('掃除'), findsOneWidget);
          expect(find.textContaining('あと '), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
      controller.pending = true;
      controller.cooldownTick.value++;
      await tester.pump();
      expect(rects(), baseline);
      expect(
          tester
              .widget<TextButton>(
                  find.descendant(of: clean, matching: find.byType(TextButton)))
              .onPressed,
          isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('読み上げの操作・待機状態と、長いサーバー期限を保持', (tester) async {
    final semantics = tester.ensureSemantics();

    var taps = 0;
    Duration remaining = Duration.zero;
    Future<void> show() => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 70,
                child: TrainingHomeCareButton(
                  type: TrainingActionType.clean,
                  label: '掃除',
                  remaining: remaining,
                  onPressed: remaining == Duration.zero ? () => taps++ : null,
                )))));
    await show();
    final button = find.byType(TrainingHomeCareButton);
    expect(
        tester.getSemantics(button),
        matchesSemantics(
            label: '掃除',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true));
    await tester.tap(find.byType(TextButton));
    expect(taps, 1);
    remaining = const Duration(seconds: 120);
    await show();
    expect(find.text('あと 02:00'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        1);
    remaining = const Duration(seconds: 60);
    await show();
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .5);
    remaining = const Duration(milliseconds: 800);
    await show();
    expect(
        tester.getSemantics(button),
        matchesSemantics(
            label: '掃除、待機中、あと 00:01',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false));
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
  testWidgets('ゲージの既存色境界と100超過50を維持', (tester) async {
    const red = Color(0xffd03b3b),
        orange = Color(0xffeda100),
        blue = Color(0xff7ec8f0),
        green = Color(0xff5ee05e);
    for (final sample in [
      (0.0, red, 0.0, 0.0),
      (19.0, red, .19, 0.0),
      (19.5, orange, .195, 0.0),
      (20.0, orange, .2, 0.0),
      (49.0, orange, .49, 0.0),
      (50.0, blue, .5, 0.0),
      (79.0, blue, .79, 0.0),
      (80.0, green, .8, 0.0),
      (100.0, green, 1.0, 0.0),
      (101.0, green, 1.0, .02),
      (125.0, green, 1.0, .5),
      (150.0, green, 1.0, 1.0),
    ]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 150,
                  height: 60,
                  child: TrainingHomeMeter(name: '食事', value: sample.$1)))));
      final root = find.byType(TrainingHomeMeter);
      final bars = tester
          .widgetList<FractionallySizedBox>(find.descendant(
              of: root, matching: find.byType(FractionallySizedBox)))
          .toList();
      expect(bars.first.widthFactor, sample.$3);
      expect((bars.first.child as ColoredBox).color, sample.$2);
      final fill = find.descendant(
          of: find.byType(FractionallySizedBox).first,
          matching: find.byType(ColoredBox));
      expect(tester.getSize(fill).height, 5);
      expect(tester.getSize(fill).width, closeTo(150 * sample.$3, .001));
      expect(bars.length, sample.$4 == 0 ? 1 : 2);
      if (sample.$4 > 0) {
        expect(bars.last.widthFactor, sample.$4);
        expect((bars.last.child as ColoredBox).color, red);
      }
      expect(find.text('${sample.$1.round()}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
