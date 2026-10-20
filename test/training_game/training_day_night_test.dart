import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_background.dart';

String background(WidgetTester tester) =>
    ((tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
                as BoxDecoration)
            .image!
            .image as AssetImage)
        .assetName;

void main() {
  test('日本時間6時と18時で切り替え、入力のtimezone表現に依存しない', () {
    for (final pair in <String, bool>{
      '2026-10-18T20:59:59.999Z': false,
      '2026-10-18T21:00:00Z': true,
      '2026-10-19T08:59:59.999Z': true,
      '2026-10-19T09:00:00Z': false,
      '2026-10-19T05:59:59+09:00': false,
      '2026-10-19T06:00:00+09:00': true,
      '2026-10-19T18:00:00+09:00': false,
      '2026-12-31T21:00:00Z': true,
    }.entries) {
      expect(TrainingHomeDaylight.isDay(DateTime.parse(pair.key)), pair.value,
          reason: pair.key);
    }
    expect(
        TrainingHomeDaylight.refreshAfter(
            DateTime.parse('2026-10-19T08:59:59.500Z')),
        const Duration(milliseconds: 500));
    expect(
        TrainingHomeDaylight.refreshAfter(
            DateTime.parse('2026-10-19T09:00:00Z')),
        const Duration(minutes: 1));
  });

  testWidgets('表示中の境界・休止復帰・時計再同期へ追従してdisposeで停止', (tester) async {
    var instant = DateTime.parse('2026-10-19T08:59:59.500Z');
    await tester.pumpWidget(MaterialApp(
      home: TrainingHomeBackground(now: () => instant),
    ));
    expect(background(tester), endsWith('home_outdoor_day.png'));
    var decoration = tester
        .widget<DecoratedBox>(find.byType(DecoratedBox).first)
        .decoration as BoxDecoration;
    expect(decoration.image!.fit, BoxFit.fitWidth);
    expect(decoration.image!.alignment, Alignment.bottomCenter);
    expect(decoration.color, const Color(0xff2ca8d3));
    instant = instant.add(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(background(tester), endsWith('home_outdoor_night.png'));
    decoration = tester
        .widget<DecoratedBox>(find.byType(DecoratedBox).first)
        .decoration as BoxDecoration;
    expect(decoration.color, const Color(0xff4c789f));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    instant = DateTime.parse('2026-10-19T21:00:00Z');
    await tester.pump(const Duration(hours: 12));
    expect(background(tester), endsWith('home_outdoor_night.png'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(background(tester), endsWith('home_outdoor_day.png'));
    instant = DateTime.parse('2026-10-20T09:00:00Z');
    await tester.pump(const Duration(minutes: 1));
    expect(background(tester), endsWith('home_outdoor_night.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('休養は睡眠中が夜、完了フレームと同時に昼へ切り替わる', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(
        home: TrainingGameCareActionScreen(actionType: TrainingActionType.rest),
      ),
    ));
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(
            'assets/images/training_game/scenes/rest_room_day.png'),
        context,
      );
    });
    expect(
        tester
            .widget<TrainingCareSceneView>(find.byType(TrainingCareSceneView))
            .scene
            .asset,
        endsWith('rest_room_night.png'));
    await tester.tap(find.text('5秒で自動完了します。画面タップでスキップ'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(
        tester
            .widget<TrainingCareSceneView>(find.byType(TrainingCareSceneView))
            .scene
            .asset,
        endsWith('rest_room_day.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
