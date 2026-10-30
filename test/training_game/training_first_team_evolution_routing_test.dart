import 'recording_training_game_sound.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

import 'prepare_grounded_frames.dart';

class _EvolutionFixtureController extends TrainingGameController {
  _EvolutionFixtureController({
    this.fixtureBranch = 'A フォワード型',
    this.fixturePosition = 'ウイング',
  });

  final String fixtureBranch;
  final String fixturePosition;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  String get position => fixturePosition;

  @override
  String? get branch => fixtureBranch;
}

Widget _host() => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(
          home: TrainingGameScreen(
              evolutionSoundFactory: silentTrainingGameSound)),
    );

Future<void> _preload(
    WidgetTester tester, Iterable<SametarohFrame> frames) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final frame in frames) {
      await precacheImage(AssetImage(frame.asset, bundle: rootBundle), context);
    }
  });
  await tester.pump();
}

double _opacity(WidgetTester tester, SametarohFrame frame) {
  final image = find.descendant(
    of: find.byType(TrainingEvolutionReveal),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == frame.asset,
    ),
  );
  if (image.evaluate().isEmpty) return 0;
  final opacity = find.ancestor(of: image, matching: find.byType(Opacity));
  return opacity.evaluate().isEmpty
      ? 1
      : tester.widget<Opacity>(opacity.first).opacity;
}

Finder _homeFrameImage(String asset) => find.byWidgetPredicate(
      (widget) =>
          widget is TrainingHomeCharacterFrameImage &&
          widget.frame.asset == asset,
    );

Finder _sametarohFrameImage(String asset) => find.byWidgetPredicate(
      (widget) => widget is SametarohFrameImage && widget.frame.asset == asset,
    );

void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String _screenGeometryRow(String sample, Rect rect, double? scale) => [
      sample,
      scale?.toStringAsFixed(5) ?? '',
      rect.left.toStringAsFixed(3),
      rect.top.toStringAsFixed(3),
      rect.width.toStringAsFixed(3),
      rect.height.toStringAsFixed(3),
      rect.bottom.toStringAsFixed(3),
    ].join(',');

void main() {
  setUpAll(prepareGroundedFrames);
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('通常の一軍遷移は確定済みユニフォームへ進化演出する', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 4;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('ウイング')!;

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(tester, [before, after]);

    expect(find.text('進化'), findsOneWidget);
    expect(find.text('ついに、一軍の舞台へ！'), findsOneWidget);
    expect(find.text('段階「一軍」へ進みました。'), findsNothing);
    expect(find.textContaining('進化演出'), findsNothing);
    expect(
      find.byKey(const ValueKey('training-evolution-4')),
      findsOneWidget,
    );
    expect(_opacity(tester, before), 1);
    expect(_opacity(tester, after), 0);

    await tester.pump(const Duration(milliseconds: 650));
    expect(_opacity(tester, before), 1);
    expect(_opacity(tester, after), 0);
    await tester.pump(const Duration(milliseconds: 450));
    expect(_opacity(tester, before), 0);
    expect(_opacity(tester, after), 1);
    await tester.pump(const Duration(seconds: 2));
    expect(_opacity(tester, before), 0);
    expect(_opacity(tester, after), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('通常ルートの2→3は集光後に進化後画像が現れる', (tester) async {
    // stageIndex=3 / evolutionStage=3 is the controller state after the
    // normal server transition from stage 2; do not pre-cache the next-body
    // image so this exercises the ordinary first-entry route.
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 3
      ..evolutionStage.value = 3;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.normalFrames.first;
    final after = SametarohAssets.idleFramesForBodyKey('pr').first;

    await tester.pumpWidget(_host());
    await tester.pump();
    expect(
      find.byKey(const ValueKey('training-evolution-3')),
      findsOneWidget,
    );
    final reveal = tester.widget<TrainingEvolutionReveal>(
      find.byKey(const ValueKey('training-evolution-3')),
    );
    expect(reveal.beforeFrame.asset, before.asset);
    expect(reveal.afterFrame.asset, after.asset);

    await tester.pump(const Duration(milliseconds: 1100));
    final scale = tester
        .widget<Transform>(
          find.byKey(const ValueKey('training-evolution-after-scale')),
        )
        .transform
        .entry(0, 0);
    expect(scale, greaterThan(0.85));
    expect(_opacity(tester, after), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  for (final stage in [2, 3]) {
    for (final bodyKey in SametarohAssets.supportedBodyKeys) {
      final branch = switch (bodyKey) {
        'pr' => 'A フォワード型',
        'sh' => 'B 司令塔型',
        'wtb' => 'C バックス型',
        _ => throw StateError('Unsupported fixture body: $bodyKey'),
      };

      testWidgets('実画面stage$stage/$bodyKey: 1.20→1.25秒と完了tickで外形が跳ねず通常idleへ続く',
          (tester) async {
        _useDesignViewport(tester);
        final controller = _EvolutionFixtureController(fixtureBranch: branch)
          ..isServerStateReady.value = true
          ..stageIndex.value = stage
          ..evolutionStage.value = stage;
        Get.put<TrainingGameController>(controller);
        final homeFrame =
            TrainingHomeCharacterFrameSet.forBodyKey(bodyKey).idleFrames.first;
        final before = stage == 2
            ? SametarohAssets.newbornFrame
            : SametarohAssets.normalFrames.first;

        await tester.pumpWidget(_host());
        await tester.pump();
        await _preload(tester, [
          before,
          SametarohAssets.idleFramesForBodyKey(bodyKey).first,
        ]);

        expect(find.text('進化'), findsOneWidget);
        expect(find.text('次へ'), findsOneWidget);
        final revealKey = ValueKey('training-evolution-$stage');
        expect(find.byKey(revealKey), findsOneWidget);
        final target = _homeFrameImage(homeFrame.asset);
        expect(target, findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1200));
        final at1200 = tester.getRect(target);
        final scaleAt1200 = tester
            .widget<Transform>(
              find.byKey(const ValueKey('training-evolution-after-scale')),
            )
            .transform
            .entry(0, 0);
        final measurements = <String>[
          'sample,scale,left,top,width,height,bottom',
          _screenGeometryRow('1200ms', at1200, scaleAt1200),
        ];

        await tester.pump(const Duration(milliseconds: 50));
        final at1250 = tester.getRect(target);
        final scaleAt1250 = tester
            .widget<Transform>(
              find.byKey(const ValueKey('training-evolution-after-scale')),
            )
            .transform
            .entry(0, 0);
        measurements.add(_screenGeometryRow('1250ms', at1250, scaleAt1250));
        expect(scaleAt1250, lessThanOrEqualTo(scaleAt1200));
        expect(scaleAt1250, greaterThanOrEqualTo(1));
        expect(scaleAt1250, lessThanOrEqualTo(1.045));
        expect(at1250.width / at1200.width, lessThanOrEqualTo(1.02));
        expect(at1250.height / at1200.height, lessThanOrEqualTo(1.02));

        await tester.pump(const Duration(milliseconds: 449));
        expect(
          find.byKey(const ValueKey('training-evolution-after-scale')),
          findsOneWidget,
        );
        final lastRevealRect = tester.getRect(target);
        final lastScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('training-evolution-after-scale')),
            )
            .transform
            .entry(0, 0);
        measurements.add(
          _screenGeometryRow('1699ms', lastRevealRect, lastScale),
        );
        await tester.pump(const Duration(milliseconds: 20));
        expect(
          find.byKey(const ValueKey('training-evolution-after-scale')),
          findsNothing,
        );
        final completedRect = tester.getRect(target);
        measurements.add(_screenGeometryRow('completed', completedRect, 1));
        expect(completedRect.width, closeTo(lastRevealRect.width, 0.01));
        expect(completedRect.height, closeTo(lastRevealRect.height, 0.01));
        expect(completedRect.left, closeTo(lastRevealRect.left, 0.01));
        expect(completedRect.top, closeTo(lastRevealRect.top, 0.01));

        await tester.pump(const Duration(milliseconds: 1000));

        await tester.tap(find.text('次へ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump();
        expect(find.byType(TrainingEvolutionReveal), findsNothing);
        expect(find.byType(TrainingHomeCharacterAnimation), findsOneWidget);
        final regularTarget = _homeFrameImage(homeFrame.asset);
        expect(regularTarget, findsOneWidget);
        final regularFrame =
            tester.widget<TrainingHomeCharacterFrameImage>(regularTarget);
        expect(regularFrame.frame.canvasSize, homeFrame.canvasSize);
        expect(regularFrame.frame.visibleBounds.bottom,
            closeTo(regularFrame.frame.canvasSize.height, 0.001));
        final regularRect = tester.getRect(regularTarget);
        measurements.add(_screenGeometryRow('regular_idle', regularRect, 1));
        expect(regularRect.width, closeTo(completedRect.width, 0.01));
        expect(regularRect.height, closeTo(completedRect.height, 0.01));
        expect(tester.takeException(), isNull);

        final file = File(
          'artifacts/evolution-review-screen/stage${stage}_$bodyKey.csv',
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('${measurements.join('\n')}\n');
      });
    }
  }

  testWidgets('実画面一軍: 1.20→1.25秒、完了tick、ポジション確認でサイズ連続', (tester) async {
    _useDesignViewport(tester);
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 4;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('ウイング')!;

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(tester, [before, after]);

    expect(find.text('進化'), findsOneWidget);
    expect(find.text('ついに、一軍の舞台へ！'), findsOneWidget);
    final target = _sametarohFrameImage(after.asset);
    expect(target, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    final at1200 = tester.getRect(target);
    final scaleAt1200 = tester
        .widget<Transform>(
          find.byKey(const ValueKey('training-evolution-after-scale')),
        )
        .transform
        .entry(0, 0);
    await tester.pump(const Duration(milliseconds: 50));
    final at1250 = tester.getRect(target);
    final scaleAt1250 = tester
        .widget<Transform>(
          find.byKey(const ValueKey('training-evolution-after-scale')),
        )
        .transform
        .entry(0, 0);
    expect(scaleAt1250, lessThanOrEqualTo(scaleAt1200));
    expect(scaleAt1250, greaterThanOrEqualTo(1));
    expect(scaleAt1250, lessThanOrEqualTo(1.045));
    expect(at1250.width / at1200.width, lessThanOrEqualTo(1.02));
    expect(at1250.height / at1200.height, lessThanOrEqualTo(1.02));

    await tester.pump(const Duration(milliseconds: 449));
    // 録画1.220→1.236667秒の約11%ジャンプに対応する完了tick前後。
    // fixtureのcontroller開始を基準に1699→1719msで分岐を跨ぐ。
    final lastRevealRect = tester.getRect(target);
    final rows = <String>[
      'sample,scale,left,top,width,height,bottom',
      _screenGeometryRow('1200ms', at1200, scaleAt1200),
      _screenGeometryRow('1250ms', at1250, scaleAt1250),
      _screenGeometryRow('completion_before_1699ms', lastRevealRect, 1)
    ];
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.byKey(const ValueKey('training-evolution-after-scale')),
      findsNothing,
    );
    final completedRect = tester.getRect(target);
    rows.add(_screenGeometryRow('completion_after_1719ms', completedRect, 1));
    expect(completedRect.width, closeTo(lastRevealRect.width, 0.01));
    expect(completedRect.height, closeTo(lastRevealRect.height, 0.01));
    expect(completedRect.left, closeTo(lastRevealRect.left, 0.01));
    expect(completedRect.top, closeTo(lastRevealRect.top, 0.01));

    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text('次へ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('ポジション確定'), findsOneWidget);
    final regularTarget = _sametarohFrameImage(after.asset);
    expect(regularTarget, findsOneWidget);
    final regularRect = tester.getRect(regularTarget);
    expect(regularRect.width, closeTo(completedRect.width, 0.01));
    expect(regularRect.height, closeTo(completedRect.height, 0.01));
    rows.add(_screenGeometryRow('position_confirm', regularRect, 1));
    final file = File('artifacts/evolution-review-screen/stage4_wing.csv');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${rows.join('\n')}\n');
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(600, 1000)
  ]) {
    for (final position in [
      'プロップ',
      'フッカー',
      'ロック',
      'フランカー',
      'ナンバーエイト',
      'スクラムハーフ',
      'スタンドオフ',
      'センター',
      'ウイング',
      'フルバック'
    ]) {
      testWidgets('viewport $viewport / $position: 完了tickと次へで1px以内',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller =
            _EvolutionFixtureController(fixturePosition: position)
              ..isServerStateReady.value = true
              ..stageIndex.value = 4
              ..evolutionStage.value = 4;
        Get.put<TrainingGameController>(controller);
        final after = SametarohAssets.positionFrameFor(position)!;
        await tester.pumpWidget(_host());
        await tester.pump();
        await _preload(tester, [after]);
        await tester.pump(const Duration(milliseconds: 1699));
        final target = _sametarohFrameImage(after.asset);
        final before = tester.getRect(target);
        await tester.pump(const Duration(milliseconds: 20));
        final completed = tester.getRect(target);
        for (final delta in [
          completed.left - before.left,
          completed.top - before.top,
          completed.width - before.width,
          completed.height - before.height
        ]) {
          expect(delta.abs(), lessThanOrEqualTo(1));
        }
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.tap(find.text('次へ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        expect(find.text('ポジション確定'), findsOneWidget);
        final regular = tester.getRect(_sametarohFrameImage(after.asset));
        expect((regular.width - completed.width).abs(), lessThanOrEqualTo(1));
        expect((regular.height - completed.height).abs(), lessThanOrEqualTo(1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('一軍演出の完了後に同じ演出を再生せずポジション確認へ進む', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 4
      ..ended.value = true
      ..endingStep.value = 0
      ..clearPosition.value = 'ウイング';
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('ウイング')!;

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(tester, [before, after]);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(TrainingEvolutionReveal), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.text('次へ'));
    // 同一frame内の連打で次の終了画面まで飛ばさない。
    await tester.tap(find.text('次へ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(controller.evolutionStage.value, isNull);
    expect(controller.endingStep.value, 1);
    expect(find.text('ポジション確定'), findsOneWidget);
    expect(find.byType(TrainingEvolutionReveal), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('現在段階が一軍なら未対応進化コードでも仮表示へ戻らない', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 0;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('ウイング')!;

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(tester, [before, after]);

    expect(find.text('ついに、一軍の舞台へ！'), findsOneWidget);
    expect(find.text('段階「一軍」へ進みました。'), findsNothing);
    expect(find.textContaining('進化演出'), findsNothing);
    expect(find.byType(TrainingEvolutionReveal), findsOneWidget);
    expect(
      tester
          .widget<TrainingEvolutionReveal>(
            find.byType(TrainingEvolutionReveal),
          )
          .afterFrame
          .asset,
      after.asset,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('幼少段階に不整合なコードが来ても一軍演出へ進まない', (tester) async {
    for (final evolutionCode in [0, 4, 99]) {
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
      final controller = _EvolutionFixtureController()
        ..isServerStateReady.value = true
        ..stageIndex.value = 1
        ..evolutionStage.value = evolutionCode;
      Get.put<TrainingGameController>(controller);

      await tester.pumpWidget(_host());
      await tester.pump();
      await _preload(
        tester,
        [SametarohAssets.idleFramesForBodyKey('pr').first],
      );

      expect(find.byType(TrainingEvolutionReveal), findsNothing);
      expect(find.text('ついに、一軍の舞台へ！'), findsNothing);
      expect(find.textContaining('一軍'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('失敗終了に進化段階が残っても失敗画面を優先する', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 0
      ..ended.value = true
      ..endingStep.value = 2;
    Get.put<TrainingGameController>(controller);

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(
      tester,
      [SametarohAssets.idleFramesForBodyKey('pr').first],
    );

    expect(find.text('旅立ち'), findsOneWidget);
    expect(find.byType(TrainingEvolutionReveal), findsNothing);
    expect(find.text('ついに、一軍の舞台へ！'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('positive-end（デバッグ完了を含む）も演出後に既存の次画面へ進む', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..ended.value = true
      ..endingStep.value = 0
      ..clearPosition.value = 'ウイング';
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('ウイング')!;

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(tester, [before, after]);

    expect(find.text('進化'), findsOneWidget);
    expect(find.text('ついに、一軍の舞台へ！'), findsOneWidget);
    expect(find.textContaining('進化演出'), findsNothing);
    expect(
      find.byKey(const ValueKey('training-evolution-4')),
      findsOneWidget,
    );
    expect(_opacity(tester, before), 1);
    expect(_opacity(tester, after), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(_opacity(tester, before), 0);
    expect(_opacity(tester, after), 1);

    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text('次へ'));
    await tester.pump();
    expect(controller.endingStep.value, 1);
    expect(find.text('ポジション確定'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    await tester.tap(find.text('次へ'), warnIfMissed: false);
    await tester.pump();
    expect(controller.endingStep.value, 1);
    expect(find.text('ポジション確定'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.text('次へ'));
    await tester.pump();
    expect(controller.endingStep.value, 2);
    expect(find.text('旅立ち'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('演出中に画面を離れても破棄後に例外が起きない', (tester) async {
    final controller = _EvolutionFixtureController()
      ..isServerStateReady.value = true
      ..stageIndex.value = 4
      ..evolutionStage.value = 4;
    Get.put<TrainingGameController>(controller);

    await tester.pumpWidget(_host());
    await tester.pump();
    await _preload(
      tester,
      [
        SametarohAssets.idleFramesForBodyKey('pr').first,
        SametarohAssets.positionFrameFor('ウイング')!,
      ],
    );
    await tester.pump(const Duration(milliseconds: 650));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(TrainingEvolutionReveal), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
