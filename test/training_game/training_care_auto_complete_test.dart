import 'prepare_grounded_frames.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

const _actions = [
  TrainingActionType.meal,
  TrainingActionType.clean,
  TrainingActionType.squat,
  TrainingActionType.work,
  TrainingActionType.rest,
];

Future<void> _openCare(
  WidgetTester tester, {
  TrainingActionType action = TrainingActionType.meal,
  String? body,
  required ValueChanged<bool?> onResult,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              onResult(await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (_) => TrainingGameCareActionScreen(
                  actionType: action,
                  bodyKey: body,
                ),
              )));
            },
            child: const Text('open care'),
          ),
        ),
      ),
    ),
  ));
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final frame in [
      ...SametarohAssets.careFramesFor(action, bodyKey: body),
      SametarohAssets.completionFrameFor(action, bodyKey: body),
    ]) {
      await precacheImage(AssetImage(frame.asset), context);
    }
    for (final completed in [false, true]) {
      final scene = TrainingCareScene.forAction(
        action,
        completed: completed,
        isChild: body == SametarohAssets.childBodyKey,
      );
      if (scene != null) {
        await precacheImage(AssetImage(scene.asset), context);
      }
    }
  });
  await tester.tap(find.text('open care'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(prepareGroundedFrames);
  for (final body in <String?>[null, SametarohAssets.childBodyKey]) {
    for (final action in _actions) {
      if (body == SametarohAssets.childBodyKey &&
          action == TrainingActionType.work) {
        continue;
      }
      testWidgets('$body/${action.name}は操作なしで5秒後に完了し1回だけ戻る', (tester) async {
        final results = <bool?>[];
        await _openCare(tester,
            action: action, body: body, onResult: results.add);
        expect(find.text('完了する'), findsNothing);
        expect(find.text('スキップ'), findsNothing);
        // 同じ画面の再buildで自動完了までの時間が延長されない。
        await tester.pump(const Duration(seconds: 2));
        tester
            .element(find.byType(TrainingGameCareActionScreen))
            .markNeedsBuild();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2699));
        expect(find.byType(SametarohAnimatedImage), findsOneWidget);
        expect(results, isEmpty);
        await tester.pump(const Duration(milliseconds: 1));
        // 補正画像準備の実asyncを排出し、500msのfake clockは進めない。
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        final done = tester
            .widget<SametarohFrameImage>(find.byType(SametarohFrameImage));
        expect(done.frame.asset,
            SametarohAssets.completionFrameFor(action, bodyKey: body).asset);
        await tester.pump(const Duration(milliseconds: 499));
        expect(results, isEmpty);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();
        expect(results, [true]);
        await tester.pump(const Duration(seconds: 6));
        expect(results, [true]);
        expect(find.text('open care'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final targetName in ['案内文', '余白', 'キャラクター', '画面下部']) {
    testWidgets('$targetName連打で待ち時間をスキップして1回だけ完了', (tester) async {
      final results = <bool?>[];
      await _openCare(tester, onResult: results.add);
      if (targetName != 'キャラクター') {
        await tester.pump(const Duration(milliseconds: 4699));
      }
      final target = switch (targetName) {
        '余白' => const Offset(2, 200),
        'キャラクター' => tester.getCenter(find.byType(SametarohAnimatedImage)),
        '画面下部' => const Offset(187.5, 780),
        _ => tester.getCenter(find.text('5秒で自動完了します。画面タップでスキップ')),
      };
      await tester.tapAt(target);
      await tester.tapAt(target);
      await tester.pump();
      expect(find.byType(SametarohAnimatedImage), findsNothing);
      expect(find.text('完了しました'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(
          tester
              .widget<IconButton>(find.ancestor(
                of: find.byTooltip('お世話を中止'),
                matching: find.byType(IconButton),
              ))
              .onPressed,
          isNull);
      // 5秒の境界を跨いでも再度完了処理を開始しない。
      await tester.pump(const Duration(milliseconds: 1));
      await tester.tapAt(target);
      await tester.pump(const Duration(milliseconds: 498));
      expect(results, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(results, [true]);
      await tester.pump(const Duration(seconds: 6));
      expect(results, [true]);
      expect(find.text('open care'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('中止後に5秒経過してもホームを閉じず効果を確定しない', (tester) async {
    final results = <bool?>[];
    await _openCare(tester, onResult: results.add);
    await tester.tap(find.byTooltip('お世話を中止'));
    await tester.pumpAndSettle();
    expect(results, [false]);
    await tester.pump(const Duration(seconds: 6));
    expect(results, [false]);
    expect(find.text('open care'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final skip in [false, true]) {
    testWidgets('画面破棄で${skip ? '完了演出' : '自動完了'}timerを停止', (tester) async {
      final results = <bool?>[];
      await _openCare(tester, onResult: results.add);
      if (skip) {
        await tester.tap(find.text('5秒で自動完了します。画面タップでスキップ'));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
      expect(results.where((result) => result == true), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
