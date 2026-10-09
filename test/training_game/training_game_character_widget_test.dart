import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => DefaultAssetBundle(
        bundle: rootBundle,
        child: MaterialApp(home: child),
      ),
    );

String shownAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image).first).image as AssetImage)
        .assetName;

String shownCareAsset(WidgetTester tester) => (tester
        .widget<Image>(find
            .descendant(
              of: find.byType(TrainingGameCareActionScreen),
              matching: find.byType(Image),
            )
            .first)
        .image as AssetImage)
    .assetName;

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

// UIの表示fixture。実API・保存・clockは起動しません。
class _DisplayFixtureController extends TrainingGameController {
  _DisplayFixtureController({this.fixturePosition = '判定前', this.fixtureBranch});
  final String fixturePosition;
  final String? fixtureBranch;
  final callbackTrace = <String>[];
  // 表示fixtureは基底onInitの実API・周期clock起動を意図的に省きます。
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  void onClose() {}
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
    return true;
  }

  @override
  void finishWorkPreparation() => callbackTrace.add('finishWorkPreparation');
  @override
  void perform(TrainingActionType type, {MiniGameResult? miniGameResult}) =>
      callbackTrace.add('perform:${type.name}');
  @override
  Future<void> refreshUnlockedPositions() async {
    callbackTrace.add('refreshUnlockedPositions');
  }

  // Ahemテストfontによる既存headerの幅を表示素材の検証へ混ぜません。
  @override
  String get clockLabel => '00:00';
}

void main() {
  testWidgets('同bodyの親再buildではmeal開始図へ戻らず、disposeでtimer停止', (tester) async {
    configurePhone(tester);
    final frames =
        SametarohAssets.careFramesFor(TrainingActionType.meal, bodyKey: 'pr');
    Widget meal() => host(SametarohAnimatedImage(
          frames: frames,
          initialFrame: SametarohAssets.initialFrameFor(TrainingActionType.meal,
              bodyKey: 'pr'),
          width: 250,
          height: 260,
        ));
    await tester.pumpWidget(meal());
    await preload(tester, [
      ...frames,
      SametarohAssets.initialFrameFor(TrainingActionType.meal, bodyKey: 'pr')!,
    ]);
    expect(shownAsset(tester), endsWith('/pr/meal_start.png'));
    await tester.pump(const Duration(milliseconds: 650));
    expect(shownAsset(tester), endsWith('/pr/meal_1.png'));
    await tester.pumpWidget(meal());
    expect(shownAsset(tester), endsWith('/pr/meal_1.png'));
    await tester.pump(const Duration(milliseconds: 650));
    expect(shownAsset(tester), endsWith('/pr/meal_2.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('care完了は500ms終了図を表示してtrueで戻り、中止はfalse', (tester) async {
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
    await tester.tap(find.text('完了する'));
    await tester.pump();
    expect(shownAsset(tester), endsWith('/sh/clean_done.png'));
    await tester.pump(const Duration(milliseconds: 499));
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    result = null;
    await tester.tap(find.text('open care'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('お世話を中止'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
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
    await tester.pumpWidget(host(const TrainingGameScreen()));
    expect(find.text('🥚'), findsOneWidget);
    controller.stageIndex.value = 1;
    await tester.pump();
    await preload(tester, [SametarohAssets.newbornFrame]);
    expect(shownAsset(tester), SametarohAssets.newbornFrame.asset);
    controller.evolutionStage.value = 1;
    await tester.pump();
    expect(shownAsset(tester), SametarohAssets.newbornFrame.asset);
    expect(find.text('次へ'), findsOneWidget);
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
      await tester.pumpWidget(host(const TrainingGameScreen()));
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
      await tester.pumpWidget(host(const TrainingGameScreen()));
      final idle = SametarohAssets.idleFramesForBodyKey(entry.value);
      final move = SametarohAssets.journeyFramesForBodyKey(entry.value);
      await preload(tester, [...idle, ...move]);
      expect(shownAsset(tester), idle.first.asset);
      final animation = tester
          .widget<SametarohAnimatedImage>(find.byType(SametarohAnimatedImage));
      expect(
          animation.fit, entry.value == null ? BoxFit.cover : BoxFit.contain);
      controller.evolutionStage.value = 3;
      await tester.pump();
      expect(shownAsset(tester), idle.first.asset);
      controller.evolutionStage.value = null;
      controller.ended.value = true;
      controller.clearPosition.value = 'プロップ';
      controller.endingStep.value = 2;
      await tester.pump();
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
      await tester.pumpWidget(host(const TrainingGameScreen()));
      await preload(tester, [
        ...SametarohAssets.idleFramesForBodyKey(entry.value),
        for (final action in actions)
          ...SametarohAssets.careFramesFor(action, bodyKey: entry.value),
        for (final action in actions)
          SametarohAssets.completionFrameFor(action, bodyKey: entry.value),
        SametarohAssets.initialFrameFor(TrainingActionType.meal,
            bodyKey: entry.value)!,
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
        final initial = SametarohAssets.initialFrameFor(action,
                bodyKey: entry.value) ??
            SametarohAssets.careFramesFor(action, bodyKey: entry.value).first;
        expect(shownCareAsset(tester), initial.asset);
        expect(controller.callbackTrace,
            action == TrainingActionType.work ? ['prepareWork'] : isEmpty);
        await tester.tap(find.byTooltip('お世話を中止'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
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
      await tester.tap(find.text('完了する'));
      await tester.pump();
      expect(shownCareAsset(tester), endsWith('/${entry.value}/work_done.png'));
      await tester.pump(const Duration(milliseconds: 499));
      expect(controller.callbackTrace, ['prepareWork']);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
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
      await tester.pumpWidget(host(const TrainingGameScreen()));
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
    await tester.pumpWidget(host(const TrainingGameScreen()));
    await preload(tester, [prop]);
    expect(propImage(), findsOneWidget);
    controller.ended.value = false;
    controller.clearPosition.value = null;
    await tester.pump();
    await preload(tester, SametarohAssets.normalFrames);
    await tester.tap(find.text('📙'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsOneWidget);
    expect(propImage(), findsOneWidget);
    expect(controller.callbackTrace, ['refreshUnlockedPositions']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('終了図鑑表示中の解放履歴更新で画像とlocked表示が追従する', (tester) async {
    configurePhone(tester);
    addTearDown(Get.reset);
    Get.testMode = true;
    final controller = _DisplayFixtureController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 4;
    controller.ended.value = true;
    controller.endingStep.value = 3;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(host(const TrainingGameScreen()));
    await preload(tester, [SametarohAssets.positionFrameFor('プロップ')!]);
    final propImage = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'assets/images/training_game/main/jersey/prop_plain.png');
    expect(propImage, findsNothing);
    expect(find.text('👤'), findsNWidgets(10));
    controller.unlockedPositions.assignAll(['prop']);
    await tester.pump();
    expect(propImage, findsOneWidget);
    expect(find.text('👤'), findsNWidgets(9));
    controller.unlockedPositions.clear();
    await tester.pump();
    expect(propImage, findsNothing);
    expect(find.text('👤'), findsNWidgets(10));
    expect(tester.takeException(), isNull);
  });
}
