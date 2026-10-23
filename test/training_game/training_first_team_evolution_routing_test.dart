import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';

import 'prepare_grounded_frames.dart';

class _EvolutionFixtureController extends TrainingGameController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  String get position => 'ウイング';

  @override
  String? get branch => 'A フォワード型';
}

Widget _host() => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(home: TrainingGameScreen()),
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
    expect(_opacity(tester, before), lessThan(1));
    expect(_opacity(tester, after), greaterThan(0));
    await tester.pump(const Duration(seconds: 2));
    expect(_opacity(tester, before), 0);
    expect(_opacity(tester, after), 1);
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

    await tester.tap(find.text('次へ'));
    await tester.pump();
    expect(controller.endingStep.value, 1);
    expect(find.text('ポジション確定'), findsOneWidget);

    await tester.tap(find.text('次へ'));
    await tester.pump();
    expect(controller.endingStep.value, 1);
    expect(find.text('ポジション確定'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
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
