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
  VoidCallback? onCompletionSound,
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
                  onCompletionSound: onCompletionSound,
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
      testWidgets('$body/${action.name}は5秒後に完了画面を表示し、タップで1回戻る', (tester) async {
        final results = <bool?>[];
        final semantics = tester.ensureSemantics();
        await _openCare(tester,
            action: action, body: body, onResult: results.add);
        expect(find.text('完了する'), findsNothing);
        expect(find.text('スキップ'), findsNothing);
        // 同じ画面の再buildで自動完了までの時間が延長されない。
        await tester.pump(const Duration(milliseconds: 2200));
        final seekBar = find.bySemanticsLabel('お世話の進行状況');
        expect(tester.getSemantics(seekBar).getSemanticsData().value, '50%');
        tester
            .element(find.byType(TrainingGameCareActionScreen))
            .markNeedsBuild();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2499));
        expect(find.byType(SametarohAnimatedImage), findsOneWidget);
        expect(results, isEmpty);
        await tester.pump(const Duration(milliseconds: 1));
        expect(tester.getSemantics(seekBar).getSemanticsData().value, '100%');
        semantics.dispose();
        await tester.pump(const Duration(milliseconds: 10));
        // 補正画像準備の実asyncを排出し、完了画面が表示されるまで待ちます。
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        final done = tester
            .widget<SametarohFrameImage>(find.byType(SametarohFrameImage));
        expect(done.frame.asset,
            SametarohAssets.completionFrameFor(action, bodyKey: body).asset);
        expect(find.text('タップして戻る'), findsOneWidget);
        expect(results, isEmpty);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
        await tester.tap(find.text('タップして戻る'));
        await tester.pumpAndSettle();
        expect(results, [true]);
        await tester.pump(const Duration(seconds: 6));
        expect(results, [true]);
        expect(find.text('open care'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final targetName in [
    '案内文のあった位置',
    '余白',
    'キャラクター',
    '画面下部',
  ]) {
    testWidgets('$targetNameのタップで進捗が1秒分進む', (tester) async {
      final results = <bool?>[];
      final semantics = tester.ensureSemantics();
            await _openCare(tester, onResult: results.add);
      final seekBar = find.bySemanticsLabel('お世話の進行状況');
      final before = int.parse(tester
          .getSemantics(seekBar)
          .getSemanticsData()
          .value
          .replaceFirst('%', ''));
      final target = switch (targetName) {
        '余白' => const Offset(2, 200),
        'キャラクター' => tester.getCenter(find.byType(SametarohAnimatedImage)),
        '画面下部' => const Offset(187.5, 780),
        _ => const Offset(187.5, 760),
      };
      await tester.tapAt(target);
      await tester.pump();
      final after = int.parse(tester
          .getSemantics(seekBar)
          .getSemanticsData()
          .value
          .replaceFirst('%', ''));
      expect(after - before, inInclusiveRange(19, 21));
      expect(find.text('1タップで時間・バーが1秒進みます。'), findsOneWidget);
      expect(find.byType(SametarohAnimatedImage), findsOneWidget);
      expect(results, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('タップして戻る'), findsNothing);
      expect(results, isEmpty);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('タップは鮫太郎のコマを飛ばさず自然経過で切り替える', (tester) async {
    final results = <bool?>[];
    final semantics = tester.ensureSemantics();
        await _openCare(tester, onResult: results.add);
    final character = find.byType(SametarohFrameImage);
    final seekBar = find.bySemanticsLabel('お世話の進行状況');
    final frameBefore =
        tester.widget<SametarohFrameImage>(character).frame.asset;
    final progressBefore = int.parse(tester
        .getSemantics(seekBar)
        .getSemanticsData()
        .value
        .replaceFirst('%', ''));

    await tester.tapAt(const Offset(2, 200));
    await tester.pump();
    final frameAfterTap =
        tester.widget<SametarohFrameImage>(character).frame.asset;
    final progressAfterTap = int.parse(tester
        .getSemantics(seekBar)
        .getSemanticsData()
        .value
        .replaceFirst('%', ''));
    expect(frameAfterTap, frameBefore);
    expect(progressAfterTap - progressBefore, inInclusiveRange(19, 21));

    await tester.pump(const Duration(milliseconds: 700));
    final frameAfterNaturalInterval =
        tester.widget<SametarohFrameImage>(character).frame.asset;
    final progressAfterNaturalInterval = int.parse(tester
        .getSemantics(seekBar)
        .getSemanticsData()
        .value
        .replaceFirst('%', ''));
    expect(frameAfterNaturalInterval, isNot(frameBefore));
    expect(progressAfterNaturalInterval, greaterThan(progressAfterTap));
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('連打しても進捗は100%で止まり完了音を一度だけ鳴らす', (tester) async {
    final results = <bool?>[];
    final semantics = tester.ensureSemantics();
        var soundRequests = 0;
    await _openCare(
      tester,
      onResult: results.add,
      onCompletionSound: () => soundRequests++,
    );
    final seekBar = find.bySemanticsLabel('お世話の進行状況');

    for (var tap = 0; tap < 5; tap++) {
      await tester.tapAt(const Offset(2, 200));
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(tester.getSemantics(seekBar).getSemanticsData().value, '100%');
    expect(find.text('タップして戻る'), findsOneWidget);
    expect(soundRequests, 1);
    expect(results, isEmpty);
    await tester.pump(const Duration(seconds: 6));
    expect(soundRequests, 1);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('自然完了直前のタップでも完了は一度だけ', (tester) async {
    final results = <bool?>[];
    var soundRequests = 0;
    await _openCare(
      tester,
      onResult: results.add,
      onCompletionSound: () => soundRequests++,
    );
    await tester.pump(const Duration(milliseconds: 4400));
    await tester.tapAt(const Offset(2, 200));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('タップして戻る'), findsOneWidget);
    expect(soundRequests, 1);

    // 元の自然完了予定時刻を越えても、キャンセル済みタイマーで再完了しない。
    await tester.pump(const Duration(milliseconds: 500));
    expect(soundRequests, 1);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('バックグラウンドから復帰しても完了処理は一度だけ', (tester) async {
    final results = <bool?>[];
    var soundRequests = 0;
    await _openCare(
      tester,
      onResult: results.add,
      onCompletionSound: () => soundRequests++,
    );
    await tester.tapAt(const Offset(2, 200));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
    expect(results, isEmpty);

    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('タップして戻る'), findsOneWidget);
    expect(soundRequests, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(soundRequests, 1);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1タップ後は約4秒で完了し、完了SEを一度だけ要求する', (tester) async {
    final results = <bool?>[];
    var soundRequests = 0;
    await _openCare(
      tester,
      onResult: results.add,
      onCompletionSound: () => soundRequests++,
    );
    await tester.tapAt(const Offset(2, 200));
    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.byType(SametarohAnimatedImage), findsOneWidget);
    expect(find.text('タップして戻る'), findsNothing);
    expect(results, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('タップして戻る'), findsOneWidget);
    expect(soundRequests, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(soundRequests, 1);
    await tester.tap(find.text('タップして戻る'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('進捗タップ後に中止しても効果を確定しない', (tester) async {
    final results = <bool?>[];
    await _openCare(tester, onResult: results.add);
    await tester.tapAt(const Offset(2, 200));
    await tester.pump();
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
        await tester.tapAt(const Offset(2, 200));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
      expect(results.where((result) => result == true), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
