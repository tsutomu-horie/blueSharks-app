import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/environment_badge.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_background.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_controls.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_hud_guide.dart';
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

Widget homeControlsHost({Key? captureKey, double textScale = 1}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: EnvironmentBadge(child: child!),
        ),
        home:
            RepaintBoundary(key: captureKey, child: const TrainingGameScreen()),
      ),
    );

void main() {
  testWidgets('第二段階の4メーターをタップすると対応するガイドを表示する', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = HomeControlsFixture()
      ..stageIndex.value = 1
      ..isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(homeControlsHost());
    await tester.pump();
    Future<void> pumpTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    const guideStates = <TrainingHudGuideItem, bool>{
      TrainingHudGuideItem.food: true,
      TrainingHudGuideItem.work: false,
      TrainingHudGuideItem.cleanliness: true,
      TrainingHudGuideItem.condition: true,
    };
    for (final entry in guideStates.entries) {
      final target =
          find.byKey(ValueKey('training-home-meter-${entry.key.name}'));
      expect(target, findsOneWidget);
      if (entry.key == TrainingHudGuideItem.food) {
        expect(
          tester.getSemantics(target),
          matchesSemantics(
            label: '食事 100',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
      }

      await tester.tap(target);
      await pumpTransition();
      expect(
        find.text(
            TrainingHudGuide.messageFor(entry.key, unlocked: entry.value)),
        findsOneWidget,
      );
      await tester.tap(find.text('閉じる'));
      await pumpTransition();
      expect(find.byKey(const ValueKey('training-hud-guide-dialog')),
          findsNothing);
    }

    for (final stage in [2, 3, 4]) {
      controller.stageIndex.value = stage;
      await tester.pump();
      for (final item in guideStates.keys) {
        await tester
            .tap(find.byKey(ValueKey('training-home-meter-${item.name}')));
        await pumpTransition();
        expect(find.text(TrainingHudGuide.messageFor(item, unlocked: true)),
            findsOneWidget);
        await tester.tap(find.text('閉じる'));
        await pumpTransition();
      }
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('練習/MGの短タップと長押しが既存解放条件のまま動く', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = HomeControlsFixture()
      ..stageIndex.value = 1
      ..isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(homeControlsHost());
    await tester.pump();

    final entry = find.text('練習 / MG');
    await tester.tap(entry);
    await tester.pump();
    expect(find.text('ミニゲームを選ぶ'), findsNothing);
    expect(
        find.byKey(const ValueKey('training-hud-guide-dialog')), findsNothing);

    final gesture = await tester.startGesture(tester.getCenter(entry));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 699));
    final ring = find.byKey(const ValueKey('training-hud-guide-progress'));
    expect(ring, findsOneWidget);
    expect(tester.widget<CircularProgressIndicator>(ring).value, lessThan(1));
    expect(find.text('長押し中'), findsNothing);
    expect(
        find.byKey(const ValueKey('training-hud-guide-dialog')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    const lockedMessage = 'もう少し育つと、ミニゲームで遊べるようになります。';
    expect(find.text(lockedMessage), findsOneWidget);
    expect(find.text('ミニゲームを選ぶ'), findsNothing);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('閉じる'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    controller.stageIndex.value = 2;
    await tester.pump();
    await tester.tap(find.text('練習 / MG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ミニゲームを選ぶ'), findsOneWidget);
    Navigator.of(tester.element(find.text('ミニゲームを選ぶ'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final unlockedGesture =
        await tester.startGesture(tester.getCenter(find.text('練習 / MG')));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.text(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.miniGame),
      ),
      findsOneWidget,
    );
    await unlockedGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ミニゲームを選ぶ'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('閉じる'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(375, 812),
    const Size(320, 568),
    const Size(834, 1194),
  ]) {
    testWidgets('実HOMEのずかんと練習/MGの下端が有効・無効時とも揃う $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      final controller = HomeControlsFixture()..isServerStateReady.value = true;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(homeControlsHost());
      await tester.pump();
      final dex = find.byKey(const ValueKey('training-home-dex'));
      final training = find.widgetWithText(TextButton, '練習 / MG');
      Rect? baseline;
      for (final stage in [1, 2]) {
        controller.stageIndex.value = stage;
        await tester.pump();
        final dexRect = tester.getRect(dex);
        final trainingRect = tester.getRect(training);
        final bodyRect = tester.getRect(find.byType(TrainingHomeBackground));
        expect(trainingRect.bottom, closeTo(dexRect.bottom, .001));
        expect(trainingRect.height, dexRect.height);
        expect(bodyRect.bottom - dexRect.bottom, closeTo(12.h, .001));
        expect(trainingRect.left, greaterThan(dexRect.right));
        expect(
          tester.widget<TextButton>(training).onPressed != null,
          stage >= 2,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('training-home-footer')))
              .height,
          92,
        );
        if (baseline != null) expect(trainingRect, baseline);
        baseline = trainingRect;
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });

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

  for (final size in [
    const Size(375, 812),
    const Size(320, 568),
    const Size(834, 1194),
  ]) {
    testWidgets('大きい文字でも育成ホームのフッターが画面内に収まる $size', (tester) async {
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
      await tester.pumpWidget(homeControlsHost(textScale: 1.5));
      await tester.pump();

      final footer = find.byKey(const ValueKey('training-home-footer'));
      expect(tester.getRect(footer).bottom, lessThanOrEqualTo(size.height));
      expect(find.text('掃除').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('30秒設定を100%として残り時間と設定変更を反映する', (tester) async {
    Future<void> show(int remaining, int configured) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TrainingHomeCareButton(
              type: TrainingActionType.meal,
              label: 'ごはん',
              remaining: Duration(seconds: remaining),
              cooldownDuration: Duration(seconds: configured),
              onPressed: null,
            ),
          ),
        ));
    double? progress() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value;
    await show(30, 60);
    expect(progress(), .5);
    await show(30, 30);
    expect(progress(), 1);
    await show(15, 30);
    expect(progress(), .5);
    await show(0, 30);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await show(30, 30);
    expect(progress(), 1);
  });

  testWidgets('読み上げの操作・待機状態と、設定された待機時間を保持', (tester) async {
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
                  cooldownDuration: const Duration(seconds: 120),
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

  testWidgets('筋トレ条件未達メッセージはタップで閉じ、連打とスワイプも保つ', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = HomeControlsFixture()
      ..stageIndex.value = 1
      ..isServerStateReady.value = true
      ..meters['食事'] = 49
      ..meters['清潔'] = 50
      ..meters['体調'] = 49;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(homeControlsHost());
    await tester.pump();

    const message = '食事・体調が50未満です。ごはん・休養で50以上に整えてから筋トレしましょう。';
    final squatButton = find.descendant(
      of: find.byKey(const ValueKey('training-home-care-squat')),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(squatButton).onPressed, isNotNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(squatButton);
      await tester.pump();
    }

    expect(find.text(message), findsOneWidget);
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 4),
    );

    // 同じ案内が続けて届いた場合は、最新の1件だけを表示します。
    final showRequirement = tester.widget<TextButton>(squatButton).onPressed!;
    showRequirement();
    await tester.pump();
    showRequirement();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(message), findsOneWidget);

    expect(controller.meters['食事'], 49);
    expect(controller.meters['清潔'], 50);
    expect(controller.meters['体調'], 49);
    expect(controller.trainingCount.value, 0);
    expect(controller.actionsToday.value, 0);

    await tester.pump(const Duration(milliseconds: 300));
    final messageFinder = find.text(message);
    final messageCenter = tester.getCenter(messageFinder);
    final messageRect = tester.getRect(messageFinder);
    final footerRect = tester.getRect(
      find.byKey(const ValueKey('training-home-footer')),
    );
    expect(
      messageRect.overlaps(footerRect),
      isTrue,
      reason: '筋トレ案内は下部のお世話メニューに重なっている: '
          'message=$messageRect footer=$footerRect',
    );

    // ダブルタップ中もメッセージを押下対象に保ち、下のメニューへ入力を通しません。
    await tester.tapAt(messageCenter);
    await tester.pump();
    await tester.tapAt(messageCenter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsNothing);
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(controller.trainingCount.value, 0);
    expect(controller.actionsToday.value, 0);

    // 続けて表示しても従来どおりスワイプで閉じられます。
    await tester.tap(squatButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsOneWidget);
    await tester.drag(find.text(message), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsNothing);

    // スワイプ後に再表示した案内もタップで閉じられます。
    await tester.tap(squatButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsOneWidget);
    await tester.tap(find.text(message));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsNothing);
    expect(controller.trainingCount.value, 0);
    expect(controller.actionsToday.value, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('筋トレ案内をタップで閉じるとフッターから専用画面へ進める', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = HomeControlsFixture()
      ..stageIndex.value = 1
      ..isServerStateReady.value = true
      ..meters['食事'] = 49
      ..meters['清潔'] = 50
      ..meters['体調'] = 49;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(homeControlsHost());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('training-home-care-squat')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    const message = '食事・体調が50未満です。ごはん・休養で50以上に整えてから筋トレしましょう。';
    expect(find.text(message), findsOneWidget);

    await tester.tap(find.text(message));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(message), findsNothing);

    final restButton = find.descendant(
      of: find.byKey(const ValueKey('training-home-care-rest')),
      matching: find.byType(TextButton),
    );
    await tester.tap(restButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
    expect(controller.trainingCount.value, 0);
    expect(controller.actionsToday.value, 0);

    await tester.tap(find.byTooltip('お世話を中止'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(find.text(message), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('超過バーはゆっくり加減速し途中更新でも連続する', (tester) async {
    Future<void> show(double value) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 150,
                height: 60,
                child: TrainingHomeMeter(name: '食事', value: value)))));
    double width() {
      final bars = tester
          .widgetList<FractionallySizedBox>(find.descendant(
              of: find.byType(TrainingHomeMeter),
              matching: find.byType(FractionallySizedBox)))
          .toList();
      return bars.length == 1 ? 0 : bars.last.widthFactor!;
    }

    await show(100);
    await show(150);
    expect(width(), 0);
    await tester.pump(const Duration(milliseconds: 200));
    final early = width();
    expect(early, greaterThan(0));
    expect(early, lessThan(.1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(width(), closeTo(.5, .03));
    await tester.pump(const Duration(milliseconds: 600));
    final late = width();
    expect(late, greaterThan(.9));
    expect(late, lessThan(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(width(), 1);

    await show(110);
    expect(width(), 1);
    await tester.pump(const Duration(milliseconds: 800));
    final before = width();
    expect(before, closeTo(.6, .03));
    await show(140);
    expect(width(), before);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(width(), closeTo(.8, .001));
    await show(90);
    expect(width(), closeTo(.8, .001));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(width(), 0);
    expect(tester.takeException(), isNull);
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
      await tester.pumpAndSettle();
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
