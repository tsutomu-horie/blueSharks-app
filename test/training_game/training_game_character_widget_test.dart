import 'recording_training_game_sound.dart';
import 'prepare_grounded_frames.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_dex_dialog.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_background.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_sync_indicator.dart';

Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => DefaultAssetBundle(
        bundle: rootBundle,
        child: MaterialApp(home: child),
      ),
    );

String shownAsset(WidgetTester tester) {
  final home = find.byType(TrainingHomeCharacterFrameImage);
  if (home.evaluate().isNotEmpty) {
    return tester
        .widget<TrainingHomeCharacterFrameImage>(home.first)
        .frame
        .asset;
  }
  return (tester.widget<Image>(find.byType(Image).first).image as AssetImage)
      .assetName;
}

double _evolutionAssetOpacity(WidgetTester tester, SametarohFrame frame) {
  final image = find.descendant(
    of: find.byType(TrainingEvolutionReveal),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == frame.asset,
    ),
  );
  // WTB等の登録済みidleはImage.assetではなく専用描画Widgetを使う。
  final renderedFrame = image.evaluate().isNotEmpty
      ? image
      : find.descendant(
          of: find.byType(TrainingEvolutionReveal),
          matching: find.byWidgetPredicate((widget) =>
              widget is TrainingHomeCharacterFrameImage &&
              widget.frame.asset == frame.asset),
        );
  if (renderedFrame.evaluate().isEmpty) return 0;
  final opacity =
      find.ancestor(of: renderedFrame, matching: find.byType(Opacity));
  return opacity.evaluate().isEmpty
      ? 1
      : tester.widget<Opacity>(opacity.first).opacity;
}

Future<String> shownCareAsset(WidgetTester tester) async {
  // Engine image preparation completes on the real async queue, independently
  // of the fake clock used to assert the five-second action timer.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  return tester
      .widget<SametarohFrameImage>(find
          .descendant(
              of: find.byType(TrainingGameCareActionScreen),
              matching: find.byType(SametarohFrameImage))
          .last)
      .frame
      .asset;
}

void configurePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> preload(
    WidgetTester tester, Iterable<SametarohFrame> frames) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final frame in frames) {
      await precacheImage(AssetImage(frame.asset, bundle: rootBundle), context);
    }
  });
  await tester.pump();
}

Future<void> preloadTrainingHomeBackground(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final asset in [
      'assets/images/training_game/scenes/home_outdoor_day.png',
      'assets/images/training_game/scenes/home_outdoor_night.png',
    ]) {
      await precacheImage(AssetImage(asset, bundle: rootBundle), context);
    }
  });
  await tester.pump();
}

// 呼吸・歩行は常時動くので、画面全体の静止を待たず遷移だけを進めます。
Future<void> pumpRouteTransition(WidgetTester tester) async {
  final theme = Theme.of(tester.element(find.byType(Navigator).first));
  final transitions = theme.pageTransitionsTheme.builders[theme.platform];
  final forward =
      transitions?.transitionDuration ?? const Duration(milliseconds: 300);
  final reverse = transitions?.reverseTransitionDuration ?? forward;
  await tester.pump();
  await tester.pump(forward > reverse ? forward : reverse);
  await tester.pump();
}

// UIの表示fixture。実API・保存・clockは起動しません。
class _DisplayFixtureController extends TrainingGameController {
  _DisplayFixtureController({this.fixturePosition = '判定前', this.fixtureBranch});
  final String fixturePosition;
  final String? fixtureBranch;
  final callbackTrace = <String>[];
  Completer<bool>? workPreparationGate;
  Completer<void>? dexRefreshGate;
  Object? dexRefreshFailure;
  // 表示fixtureは基底onInitの実API・周期clock起動を意図的に省きます。
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  String get position => fixturePosition;
  @override
  String? get branch => stageIndex.value < 3 ? null : fixtureBranch;
  // 表示配線のテストでは既存gateを通過するfixtureを用い、実APIは呼びません。
  @override
  bool canPerform(TrainingActionType type) => true;
  @override
  bool get canWorkToday => true;
  @override
  Future<bool> prepareWork() async {
    callbackTrace.add('prepareWork');
    final gate = workPreparationGate;
    if (gate != null) return gate.future;
    return true;
  }

  @override
  void finishWorkPreparation() => callbackTrace.add('finishWorkPreparation');
  @override
  void perform(TrainingActionType type, {MiniGameResult? miniGameResult}) =>
      callbackTrace.add('perform:${type.name}');
  @override
  Future<void> refreshUnlockedPositions() {
    callbackTrace.add('refreshUnlockedPositions');
    final failure = dexRefreshFailure;
    if (failure != null) return Future<void>.error(failure);
    return dexRefreshGate?.future ?? Future<void>.value();
  }

  // Ahemテストfontによる既存headerの幅を表示素材の検証へ混ぜません。
  @override
  String get clockLabel => '00:00';
}

void main() {
  setUpAll(prepareGroundedFrames);
  setUpAll(() async {
    final lineSeed = FontLoader('LINESeedJP')
      ..addFont(
          rootBundle.load('assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf'))
      ..addFont(
          rootBundle.load('assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf'));
    await lineSeed.load();
  });

  for (final size in [const Size(375, 812), const Size(320, 568)]) {
    testWidgets('ホーム背景がHUDの背面まで続き、同期通知でも下部配置を保つ $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      addTearDown(Get.reset);
      final controller = _DisplayFixtureController();
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 1;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      await preload(tester, [SametarohAssets.newbornFrame]);

      final background = find.byType(TrainingHomeBackground);
      final backgroundRect = tester.getRect(background);
      final meal = find.widgetWithText(TextButton, 'ごはん');
      final mealRect = tester.getRect(meal);
      final characterRect = tester.getRect(find.byType(SametarohFrameImage));
      final exitRect =
          tester.getRect(find.byKey(const ValueKey('training-home-exit')));
      final debugRect = tester.getRect(find.byTooltip('デバッグコマンド'));
      expect(backgroundRect.top, 0);
      expect(backgroundRect.width, size.width);
      expect(
          backgroundRect.contains(tester.getCenter(find.text('食事'))), isTrue);
      expect(
          backgroundRect.contains(tester.getCenter(find.text('清潔'))), isTrue);
      expect(backgroundRect.bottom, lessThanOrEqualTo(mealRect.top));
      expect(debugRect.center.dx, closeTo(exitRect.center.dx, .01));
      expect(debugRect.top, greaterThan(exitRect.bottom));
      expect(find.text('鮫太朗育成'), findsNothing);
      expect(find.text(controller.clockLabel), findsNothing);
      expect(find.text('▮▮▮ ᯤ 🔋'), findsNothing);

      controller.syncStatus.value = TrainingSyncStatus.syncing;
      controller.syncStatusMessage.value = '育成状態を同期しています。';
      await tester.pump();
      expect(find.text('育成状態を同期しています。'), findsNothing);
      expect(find.byType(TrainingSyncIndicator), findsOneWidget);
      expect(tester.getRect(background), backgroundRect);
      expect(tester.getRect(meal), mealRect);
      expect(tester.getRect(find.byType(SametarohFrameImage)), characterRect);
      expect(tester.getRect(find.byKey(const ValueKey('training-home-exit'))),
          exitRect);
      final indicatorRect = tester.getRect(find.byType(TrainingSyncIndicator));
      expect(backgroundRect.contains(indicatorRect.topLeft), isTrue);
      expect(indicatorRect.overlaps(exitRect), isFalse);
      expect(indicatorRect.overlaps(debugRect), isFalse);
      expect(
          indicatorRect.overlaps(tester.getRect(find.byType(GridView).first)),
          isFalse);

      controller.syncStatus.value = TrainingSyncStatus.idle;
      controller.syncStatusMessage.value = '';
      await tester.pump();
      expect(find.byType(TrainingSyncIndicator), findsNothing);
      expect(tester.getRect(find.byType(SametarohFrameImage)), characterRect);

      controller.syncStatus.value = TrainingSyncStatus.stopped;
      controller.syncStatusMessage.value = 'サーバーへ同期中';
      await tester.pump();
      expect(find.text('サーバーへ同期中'), findsOneWidget);
      expect(find.byType(TrainingSyncIndicator), findsNothing);
      expect(tester.getRect(background), backgroundRect);
      expect(tester.getRect(meal), mealRect);
      final updatedCharacterRect =
          tester.getRect(find.byType(SametarohFrameImage));
      expect(updatedCharacterRect.left, closeTo(characterRect.left, .01));
      expect(updatedCharacterRect.top, closeTo(characterRect.top, .01));
      expect(updatedCharacterRect.right, closeTo(characterRect.right, .01));
      expect(updatedCharacterRect.bottom, closeTo(characterRect.bottom, .01));
      await tester.tap(find.byTooltip('デバッグコマンド'));
      await pumpRouteTransition(tester);
      expect(find.text('⏸ 停止'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('同期アイコンは白い背景で2秒に1周し、動きを減らす設定では停止する', (tester) async {
    configurePhone(tester);
    Widget indicator({bool disableAnimations = false}) => host(MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const Center(child: TrainingSyncIndicator()),
        ));
    await tester.pumpWidget(indicator());
    final rotation = find.descendant(
      of: find.byType(TrainingSyncIndicator),
      matching: find.byType(RotationTransition),
    );
    double turns() => tester.widget<RotationTransition>(rotation).turns.value;
    expect(turns(), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(turns(), closeTo(-0.25, .001));
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(TrainingSyncIndicator),
      matching: find.byType(Container),
    ));
    expect((container.decoration! as BoxDecoration).color, Colors.white);
    await tester.pumpWidget(indicator(disableAnimations: true));
    final stoppedTurns = turns();
    await tester.pump(const Duration(seconds: 1));
    expect(turns(), stoppedTurns);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('同bodyの親再buildでは食事2コマの連番を保持し、disposeでtimer停止', (tester) async {
    configurePhone(tester);
    final frames =
        SametarohAssets.careFramesFor(TrainingActionType.meal, bodyKey: 'pr');
    Widget meal() => host(SametarohAnimatedImage(
          frames: frames,
          width: 250,
          height: 260,
        ));
    await tester.pumpWidget(meal());
    await preload(tester, [
      ...frames,
    ]);
    expect(shownAsset(tester), endsWith('/pr/meal_1.png'));
    await tester.pump(const Duration(milliseconds: 650));
    expect(shownAsset(tester), endsWith('/pr/meal_2.png'));
    await tester.pumpWidget(meal());
    expect(shownAsset(tester), endsWith('/pr/meal_2.png'));
    await tester.pump(const Duration(milliseconds: 650));
    expect(shownAsset(tester), endsWith('/pr/meal_1.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('care完了図はタップまで保持しtrueで戻り、中止はfalse', (tester) async {
    configurePhone(tester);
    bool? result;
    await tester.pumpWidget(host(Builder(
        builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result =
                      await Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (_) => const TrainingGameCareActionScreen(
                      actionType: TrainingActionType.clean,
                      bodyKey: 'sh',
                    ),
                  ));
                },
                child: const Text('open care'),
              ),
            ))));
    await preload(tester, [
      ...SametarohAssets.careFramesFor(TrainingActionType.clean, bodyKey: 'sh'),
      SametarohAssets.completionFrameFor(TrainingActionType.clean,
          bodyKey: 'sh'),
    ]);
    await tester.tap(find.text('open care'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(2, 200));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(
        tester
            .widget<SametarohFrameImage>(find.byType(SametarohFrameImage).last)
            .frame
            .asset,
        endsWith('/sh/clean_done.png'));
    await tester.pump(const Duration(milliseconds: 499));
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('タップして戻る'), findsOneWidget);
    expect(result, isNull);
    await tester.tap(find.text('タップして戻る'));
    await pumpRouteTransition(tester);
    expect(result, isTrue);
    result = null;
    await tester.tap(find.text('open care'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('お世話を中止'));
    await pumpRouteTransition(tester);
    expect(result, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('進化段階ごとの本文を出し分け、他段階の本文と次へ操作を保つ', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController(fixtureBranch: 'A フォワード型');
    controller.isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    const growthMessage = '成長した鮫太郎と、いろんなことに挑戦してみましょう！！';
    const firstTeamMessage = 'ついに、一軍の舞台へ！';

    for (final stage in [1, 2, 3, 4]) {
      controller.stageIndex.value = stage;
      controller.evolutionStage.value = stage;
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      await tester.pump();
      // 光の中央で進化画面がマウントされてから、既存の演出を待つ。
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2700));

      expect(find.text('進化'), findsOneWidget);
      expect(find.text(growthMessage),
          stage == 2 || stage == 3 ? findsOneWidget : findsNothing);
      expect(find.text(firstTeamMessage),
          stage == 4 ? findsOneWidget : findsNothing);
      expect(find.text('段階「${controller.currentStage.name}」へ進みました。'),
          stage == 1 ? findsOneWidget : findsNothing);
      await tester.tap(find.text('次へ'));
      expect(controller.evolutionStage.value, isNull);
      expect(controller.stageIndex.value, stage);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('育成期の進化は幼体から通常形へ切り替わる', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 2;
    controller.evolutionStage.value = 2;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.newbornFrame;
    final after = SametarohAssets.normalFrames.first;

    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester, [before, after]);
    expect(_evolutionAssetOpacity(tester, before), 1);
    expect(_evolutionAssetOpacity(tester, after), 0);

    await tester.pump(const Duration(seconds: 2));
    expect(_evolutionAssetOpacity(tester, before), 0);
    expect(_evolutionAssetOpacity(tester, after), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('進化演出は既存の前後素材を一度だけ切り替え、背景復帰後も続けられる', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController(fixtureBranch: 'A フォワード型');
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 3;
    controller.evolutionStage.value = 3;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.normalFrames.first;
    final after = SametarohAssets.idleFramesForBodyKey('pr').first;
    const screen =
        TrainingGameScreen(evolutionSoundFactory: silentTrainingGameSound);

    await tester.pumpWidget(host(screen));
    await preload(tester, [before, after]);
    expect(find.byKey(const ValueKey('training-evolution-3')), findsOneWidget);
    expect(_evolutionAssetOpacity(tester, before), 1);
    expect(_evolutionAssetOpacity(tester, after), 0);

    await tester.pump(const Duration(milliseconds: 650));
    final beforePause = _evolutionAssetOpacity(tester, before);
    final afterPause = _evolutionAssetOpacity(tester, after);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(_evolutionAssetOpacity(tester, before), beforePause);
    expect(_evolutionAssetOpacity(tester, after), afterPause);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(host(screen));
    await tester.pump(const Duration(seconds: 2));
    expect(_evolutionAssetOpacity(tester, before), 0);
    expect(_evolutionAssetOpacity(tester, after), 1);
    await tester.pumpWidget(host(screen));
    expect(_evolutionAssetOpacity(tester, after), 1);
    await tester.pump(const Duration(seconds: 2));
    expect(_evolutionAssetOpacity(tester, after), 1);

    await tester.tap(find.text('次へ'));
    expect(controller.evolutionStage.value, isNull);
    expect(controller.stageIndex.value, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('一軍への進化は確定済みポジション姿を表示して切り替える', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController(
      fixturePosition: 'プロップ',
      fixtureBranch: 'A フォワード型',
    );
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 4;
    controller.evolutionStage.value = 4;
    Get.put<TrainingGameController>(controller);
    final before = SametarohAssets.idleFramesForBodyKey('pr').first;
    final after = SametarohAssets.positionFrameFor('プロップ')!;

    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester, [before, after]);
    expect(find.byKey(const ValueKey('training-evolution-4')), findsOneWidget);
    expect(_evolutionAssetOpacity(tester, before), 1);
    expect(_evolutionAssetOpacity(tester, after), 0);

    await tester.pump(const Duration(seconds: 2));
    expect(_evolutionAssetOpacity(tester, before), 0);
    expect(_evolutionAssetOpacity(tester, after), 1);
    expect(find.text('ついに、一軍の舞台へ！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('一軍ポジション未確定時は推測したユニフォームを表示しない', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController(
      fixturePosition: '判定前',
      fixtureBranch: 'A フォワード型',
    );
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 4;
    controller.evolutionStage.value = 4;
    Get.put<TrainingGameController>(controller);
    final existingBody = SametarohAssets.idleFramesForBodyKey('pr').first;
    final prop = SametarohAssets.positionFrameFor('プロップ')!;

    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester, [existingBody, prop]);
    expect(find.byKey(const ValueKey('training-evolution-4')), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == prop.asset),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == existingBody.asset),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('卵を保持し、幼少の部屋と進化には支給newbornを表示する', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() async {
      Get.reset();
    });
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    expect(find.text('🥚'), findsOneWidget);
    controller.stageIndex.value = 1;
    await tester.pump();
    await preload(tester, [SametarohAssets.newbornFrame]);
    expect(shownAsset(tester), SametarohAssets.newbornFrame.asset);
    controller.evolutionStage.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(shownAsset(tester), SametarohAssets.newbornFrame.asset);
    expect(find.text('次へ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('幼体は4動作だけを表示して幼体素材へ渡し、育成期は仕事を保つ', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 1;
    controller.meters.updateAll((key, value) => 100);
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester, [
      SametarohAssets.newbornFrame,
      ...SametarohAssets.childCareFrames.values,
      ...SametarohAssets.normalFrames,
      ...SametarohAssets.careFramesFor(TrainingActionType.meal),
    ]);
    expect(find.widgetWithText(TextButton, '仕事'), findsNothing);
    const labels = {
      TrainingActionType.meal: 'ごはん',
      TrainingActionType.clean: '掃除',
      TrainingActionType.squat: '筋トレ',
      TrainingActionType.rest: '休養'
    };
    for (final entry in labels.entries) {
      controller.callbackTrace.clear();
      await tester.tap(find.widgetWithText(TextButton, entry.value));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final care = tester.widget<TrainingGameCareActionScreen>(
          find.byType(TrainingGameCareActionScreen));
      expect(care.bodyKey, SametarohAssets.childBodyKey);
      expect(care.actionType, entry.key);
      expect(await shownCareAsset(tester),
          'assets/images/training_game/child_care/${entry.key.name}_1.png');
      await tester.tap(find.byTooltip('お世話を中止'));
      await pumpRouteTransition(tester);
      expect(controller.callbackTrace, isEmpty);
    }
    controller.stageIndex.value = 2;
    await tester.pump();
    expect(find.widgetWithText(TextButton, '仕事'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'ごはん'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester
            .widget<TrainingGameCareActionScreen>(
                find.byType(TrainingGameCareActionScreen))
            .bodyKey,
        isNull);
    expect(await shownCareAsset(tester),
        'assets/images/sametaroh/eating_sametaroh_1.png');
    await tester.tap(find.byTooltip('お世話を中止'));
    await pumpRouteTransition(tester);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('育成期の古い仕事callbackも幼体へ戻った後は仕事を開かない', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 2;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    final oldWork = tester
        .widget<TextButton>(find.widgetWithText(TextButton, '仕事'))
        .onPressed!;
    controller.stageIndex.value = 1;
    await tester.pump();
    expect(find.widgetWithText(TextButton, '仕事'), findsNothing);
    oldWork();
    await tester.pump();
    expect(controller.callbackTrace, isEmpty);
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('仕事の可否照会中に幼体へ変わっても仕事画面を開かない', (tester) async {
    configurePhone(tester);
    Get.testMode = true;
    addTearDown(() => Get.reset());
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 2;
    controller.workPreparationGate = Completer<bool>();
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester,
        [SametarohAssets.newbornFrame, ...SametarohAssets.normalFrames]);
    await tester.tap(find.widgetWithText(TextButton, '仕事'));
    await tester.pump();
    expect(controller.callbackTrace, ['prepareWork']);
    controller.stageIndex.value = 1;
    controller.workPreparationGate!.complete(true);
    await tester.pump();
    expect(controller.callbackTrace, ['prepareWork', 'finishWorkPreparation']);
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(find.widgetWithText(TextButton, '仕事'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('全10positionの確定画面に支給jerseyを表示する', (tester) async {
    configurePhone(tester);
    addTearDown(() async {
      Get.reset();
    });
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
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      Get.testMode = true;
      final controller = _DisplayFixtureController(fixturePosition: position);
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 4;
      controller.ended.value = true;
      controller.clearPosition.value = position;
      controller.endingStep.value = 1;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      final frame = SametarohAssets.positionFrameFor(position);
      expect(frame, isNotNull, reason: position);
      await preload(tester, [frame!]);
      expect(shownAsset(tester), frame.asset, reason: position);
      expect(find.text(position), findsOneWidget);
      expect(tester.takeException(), isNull, reason: position);
    }
  });

  testWidgets('3大別の部屋・進化・旅立ちを揃え、未確定/未知branchはnormalを保持する', (tester) async {
    configurePhone(tester);
    addTearDown(Get.reset);
    const cases = {
      'A フォワード型': 'pr',
      'B 司令塔型': 'sh',
      'C バックス型': 'wtb',
      null: null,
      'UNKNOWN': null,
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      Get.testMode = true;
      final controller = _DisplayFixtureController(fixtureBranch: entry.key);
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 3;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      final idle = SametarohAssets.idleFramesForBodyKey(entry.value);
      final move = SametarohAssets.journeyFramesForBodyKey(entry.value);
      await preload(tester, [...idle, ...move]);
      expect(shownAsset(tester), idle.first.asset);
      final animation = tester.widget<TrainingHomeCharacterAnimation>(
          find.byType(TrainingHomeCharacterAnimation));
      expect(animation.isWalking, isFalse);
      expect(animation.frameSet.idleFrames.first.asset, idle.first.asset);
      expect(animation.frameSet.walkFrames.first.asset, move.first.asset);
      controller.evolutionStage.value = 3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();
      if (entry.value == null) {
        expect(shownAsset(tester), idle.first.asset);
      } else {
        await tester.pump(const Duration(seconds: 2));
        expect(_evolutionAssetOpacity(tester, idle.first), 1);
      }
      controller.evolutionStage.value = null;
      controller.ended.value = true;
      controller.clearPosition.value = 'プロップ';
      controller.endingStep.value = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await preload(tester, move);
      expect(shownAsset(tester), move.first.asset);
      expect(tester.takeException(), isNull, reason: '${entry.key}');
    }
  });

  testWidgets('本編から3体形の全careへ渡し、中止/完了と仕事の呼出し順を保持する', (tester) async {
    configurePhone(tester);
    addTearDown(Get.reset);
    const branches = {
      'A フォワード型': 'pr',
      'B 司令塔型': 'sh',
      'C バックス型': 'wtb',
    };
    const actions = [
      TrainingActionType.meal,
      TrainingActionType.clean,
      TrainingActionType.rest,
      TrainingActionType.squat,
      TrainingActionType.work,
    ];
    const labels = {
      TrainingActionType.meal: 'ごはん',
      TrainingActionType.clean: '掃除',
      TrainingActionType.rest: '休養',
      TrainingActionType.squat: '筋トレ',
      TrainingActionType.work: '仕事',
    };
    for (final entry in branches.entries) {
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      Get.testMode = true;
      final controller = _DisplayFixtureController(fixtureBranch: entry.key);
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 3;
      controller.meters.updateAll((key, value) => 100);
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      await preload(tester, [
        ...SametarohAssets.idleFramesForBodyKey(entry.value),
        for (final action in actions)
          ...SametarohAssets.careFramesFor(action, bodyKey: entry.value),
        for (final action in actions)
          SametarohAssets.completionFrameFor(action, bodyKey: entry.value),
      ]);
      for (final action in actions) {
        controller.callbackTrace.clear();
        await tester.tap(find.text(labels[action]!).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final care = tester.widget<TrainingGameCareActionScreen>(
            find.byType(TrainingGameCareActionScreen));
        expect(care.bodyKey, entry.value);
        expect(care.actionType, action);
        final initial =
            SametarohAssets.careFramesFor(action, bodyKey: entry.value).first;
        expect(await shownCareAsset(tester), initial.asset);
        expect(controller.callbackTrace,
            action == TrainingActionType.work ? ['prepareWork'] : isEmpty);
        await tester.tap(find.byTooltip('お世話を中止'));
        // SDK既定の戻る遷移が終わり、次のcareボタンを操作できるまで待つ。
        await pumpRouteTransition(tester);
        expect(
            controller.callbackTrace,
            action == TrainingActionType.work
                ? ['prepareWork', 'finishWorkPreparation']
                : isEmpty);
      }
      controller.callbackTrace.clear();
      await tester.tap(find.text('仕事').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // 操作せず5秒に到達すると既存の完了・効果反映経路へ進む。
      await tester.pump(const Duration(milliseconds: 4700));
      await tester.pump();
      expect(await shownCareAsset(tester),
          endsWith('/${entry.value}/work_done.png'));
      await tester.pump(const Duration(milliseconds: 499));
      expect(controller.callbackTrace, ['prepareWork']);
      await tester.tap(find.text('タップして戻る'));
      await tester.pump(const Duration(milliseconds: 1));
      await pumpRouteTransition(tester);
      expect(controller.callbackTrace,
          ['prepareWork', 'finishWorkPreparation', 'perform:work']);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('未完了終了は卵/幼少/本編の最後の姿を保持し幽霊を使わない', (tester) async {
    configurePhone(tester);
    addTearDown(Get.reset);
    const cases = [
      (0, null, null),
      (1, null, null),
      (2, null, null),
      (3, 'A フォワード型', 'pr'),
      (3, 'B 司令塔型', 'sh'),
      (3, 'C バックス型', 'wtb'),
      (3, 'UNKNOWN', null),
    ];
    for (final (stage, branch, body) in cases) {
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      Get.testMode = true;
      final controller = _DisplayFixtureController(fixtureBranch: branch);
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = stage;
      controller.ended.value = true;
      controller.endingStep.value = 2;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      if (stage == 0) {
        expect(find.text('🥚\n引退'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      } else if (stage == 1) {
        await preload(tester, [SametarohAssets.newbornFrame]);
        expect(shownAsset(tester), SametarohAssets.newbornFrame.asset);
      } else {
        final frames = SametarohAssets.idleFramesForBodyKey(body);
        await preload(tester, frames);
        expect(shownAsset(tester), frames.first.asset);
      }
      expect(find.text('次の卵へ'), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName.endsWith('/ghost.png')),
          findsNothing);
      expect(tester.takeException(), isNull, reason: '$stage/$branch');
    }
  });

  testWidgets('終了図鑑と通常図鑑で登録済propは同じヘッドギア無しを使う', (tester) async {
    configurePhone(tester);
    addTearDown(Get.reset);
    final prop = SametarohAssets.positionFrameFor('プロップ')!;
    Finder propImage() => find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == prop.asset);
    Get.testMode = true;
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 3;
    controller.ended.value = true;
    controller.clearPosition.value = 'プロップ';
    controller.endingStep.value = 3;
    controller.unlockedPositions.assignAll(['prop']);
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen(
        evolutionSoundFactory: silentTrainingGameSound)));
    await preload(tester, [prop]);
    expect(propImage(), findsOneWidget);
    controller.ended.value = false;
    controller.clearPosition.value = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await preload(tester, SametarohAssets.normalFrames);
    await tester.tap(find.byKey(const ValueKey('training-home-dex')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsOneWidget);
    expect(propImage(), findsOneWidget);
    expect(find.byType(TrainingDexDialog), findsOneWidget);
    expect(find.textContaining('1/10 登録'), findsOneWidget);
    controller.unlockedPositions.assignAll(['prop', 'hooker']);
    await tester.pump();
    expect(find.textContaining('2/10 登録'), findsOneWidget);
    expect(find.text('✅ 登録済み'), findsNWidgets(2));
    await tester.tap(find.text('閉じる'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TrainingDexDialog), findsNothing);
    expect(controller.callbackTrace, ['refreshUnlockedPositions']);
    expect(tester.takeException(), isNull);
  });

  for (final failure in [false, true]) {
    testWidgets(
        failure ? '図鑑取得失敗時も直近の到達状態と未到達シルエットを維持する' : '図鑑読み込み中も未到達の進化先をシルエット表示する',
        (tester) async {
      configurePhone(tester);
      addTearDown(Get.reset);
      Get.testMode = true;
      const positions = [
        'プロップ',
        'フッカー',
        'ロック',
        'フランカー',
        'ナンバーエイト',
        'スクラムハーフ',
        'スタンドオフ',
        'ウイング',
        'センター',
        'フルバック',
      ];
      final controller = _DisplayFixtureController();
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 3;
      if (failure) {
        controller.unlockedPositions.assignAll(['prop']);
        controller.dexRefreshFailure = StateError('fixture failure');
      } else {
        controller.dexRefreshGate = Completer<void>();
      }
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      await preload(tester, SametarohAssets.normalFrames);
      await preload(
          tester,
          positions.map(
            (position) => SametarohAssets.positionFrameFor(position)!,
          ));
      await tester.tap(find.byKey(const ValueKey('training-home-dex')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dialog = find.byType(TrainingDexDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.byType(SametarohFrameImage)),
        findsNWidgets(10),
      );
      expect(
        find.descendant(of: dialog, matching: find.byType(ColorFiltered)),
        findsNWidgets(failure ? 9 : 10),
      );
      expect(
        find.text('✅ 登録済み'),
        failure ? findsOneWidget : findsNothing,
      );
      expect(find.text('🔒 未解放'), findsNWidgets(failure ? 9 : 10));
      expect(controller.callbackTrace, ['refreshUnlockedPositions']);
      if (!failure) {
        expect(controller.dexRefreshGate!.isCompleted, isFalse);
        controller.dexRefreshGate!.complete();
        await tester.pump();
      } else {
        expect(find.textContaining('1/10 登録'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final size in [const Size(375, 812), const Size(320, 568)]) {
    testWidgets('完了後図鑑は屋外背景の2列5行で到達状態を反映する $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(Get.reset);
      Get.testMode = true;
      const positions = [
        'プロップ',
        'フッカー',
        'ロック',
        'フランカー',
        'ナンバーエイト',
        'スクラムハーフ',
        'スタンドオフ',
        'ウイング',
        'センター',
        'フルバック',
      ];
      final controller = _DisplayFixtureController();
      controller.isServerStateReady.value = true;
      controller.stageIndex.value = 4;
      controller.ended.value = true;
      controller.clearPosition.value = 'ウイング';
      controller.endingStep.value = 3;
      Get.put<TrainingGameController>(controller);
      await tester.pumpWidget(host(const TrainingGameScreen(
          evolutionSoundFactory: silentTrainingGameSound)));
      await preloadTrainingHomeBackground(tester);
      await preload(
        tester,
        positions.map(
          (position) => SametarohAssets.positionFrameFor(position)!,
        ),
      );

      Finder imageFor(SametarohFrame frame) => find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == frame.asset,
          );
      final prop = SametarohAssets.positionFrameFor('プロップ')!;
      final wing = SametarohAssets.positionFrameFor('ウイング')!;
      expect(find.byType(TrainingHomeBackground), findsOneWidget);
      expect(
        tester
            .widget<TrainingHomeBackground>(
              find.byType(TrainingHomeBackground),
            )
            .imageFit,
        BoxFit.cover,
      );
      final backgroundDecoration = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(TrainingHomeBackground),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;
      expect(backgroundDecoration.image?.fit, BoxFit.cover);
      expect(backgroundDecoration.image?.alignment, Alignment.bottomCenter);
      expect(find.byType(TrainingDexDialog), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.byKey(const ValueKey('training-completion-title-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('training-completion-count-pill')),
        findsOneWidget,
      );
      expect(find.text('図鑑・クリア履歴'), findsOneWidget);
      expect(find.text('到達 1/10'), findsOneWidget);
      expect(find.text('次の卵へ'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('training-completion-next-egg')),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      expect(imageFor(prop), findsOneWidget);
      expect(imageFor(wing), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNWidgets(9));
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('training-completion-history-grid')),
      );
      expect(find.byType(SametarohFrameImage), findsNWidgets(10));
      expect(grid.childrenDelegate.estimatedChildCount, 10);
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2,
      );
      final wingCard = find.byKey(
        const ValueKey('training-completion-position-7'),
      );
      final wingImage = find.descendant(
        of: wingCard,
        matching: find.byType(SametarohFrameImage),
      );
      final wingLabel = find.descendant(
        of: wingCard,
        matching: find.text('ウイング'),
      );
      expect(
        tester.getRect(wingImage).center.dx,
        closeTo(tester.getRect(wingCard).center.dx, 2),
      );
      expect(
        tester.getRect(wingImage).bottom,
        lessThan(tester.getRect(wingLabel).top),
      );
      expect(tester.takeException(), isNull);

      controller.unlockedPositions.assignAll(['prop']);
      await tester.pump();
      expect(find.text('到達 2/10'), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNWidgets(8));

      controller.unlockedPositions.clear();
      await tester.pump();
      expect(find.text('到達 1/10'), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNWidgets(9));
      expect(tester.takeException(), isNull);
    });
  }
}
