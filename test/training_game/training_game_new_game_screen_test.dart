import 'recording_training_game_sound.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game_new_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_flow.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_hatching_scene.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Provider extends TrainingGameProvider {
  int starts = 0;
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async {
    starts++;
    await gate?.future;
    if (fail) throw StateError('offline');
    return {
      'id': 1,
      'cycle_no': 1,
      'stage_code': stageCode,
      'status': 'playing'
    };
  }
}

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  tearDown(() {
    if (Get.isRegistered<TrainingGameNewGameController>()) {
      Get.find<TrainingGameNewGameController>().onDelete();
    }
    Get.reset();
  });

  Future<void> host(WidgetTester tester, _Provider provider,
      {Size size = const Size(375, 812),
      bool reducedMotion = false,
      TrainingGameSoundService Function() soundFactory =
          silentTrainingGameSound}) async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // 実デコードをFakeAsyncの演出時計から切り離し、再実行時も開始前に完了させます。
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final preloadContext = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      for (final path in [
        TrainingHatchingScene.eggAsset,
        TrainingHatchingScene.silhouetteAsset,
        SametarohAssets.newbornFrame.asset,
      ]) {
        await precacheImage(AssetImage(path), preloadContext);
      }
    });
    Get.put(TrainingGameNewGameController(provider: provider));
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: TrainingGameNewGameScreen(soundFactory: soundFactory),
        getPages: [
          GetPage(
              name: Routes.TRAINING_GAME,
              page: () => Scaffold(
                    body: Text('育成:${(Get.arguments as Map)['stage_code']}'),
                  )),
        ],
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('孵化完了まではAPIを呼ばず、保存成功後にchildで育成へ進む', (tester) async {
    final gate = Completer<void>();
    final provider = _Provider()..gate = gate;
    await host(tester, provider);
    expect(provider.starts, 0);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(provider.starts, 0);
    // 演出中の連打は無視します。
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 2300));
    expect(provider.starts, 1);
    expect(find.text('育成:child'), findsNothing);
    expect(find.text('はじめまして、鮫太朗！'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('育成:child'), findsOneWidget);
    expect((Get.arguments as Map)['_new_cycle'], isTrue);
    expect(provider.starts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('背景移行中は孵化を止め、復帰後に残りを再生する', (tester) async {
    final provider = _Provider();
    await host(tester, provider);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(provider.starts, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pumpAndSettle();
    expect(provider.starts, 1);
    expect(find.text('育成:child'), findsOneWidget);
  });

  testWidgets('演出中に画面が破棄されても遅延callbackでAPIを送らない', (tester) async {
    final provider = _Provider();
    await host(tester, provider);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(provider.starts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('失敗後は幼体を表示したまま接続を再試行できる', (tester) async {
    final provider = _Provider()..fail = true;
    final sound = RecordingTrainingGameSound();
    await host(tester, provider, soundFactory: () => sound.service);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(TrainingHatchingScene.duration);
    await tester.pumpAndSettle();
    expect(provider.starts, 1);
    expect(find.text('もう一度接続する'), findsOneWidget);
    expect(find.text('育成:child'), findsNothing);
    provider.fail = false;
    await tester.tap(find.text('もう一度接続する'));
    await tester.pumpAndSettle();
    expect(provider.starts, 2);
    expect(find.text('育成:child'), findsOneWidget);
    expect(
        sound.playedAssetPaths, [TrainingGameSoundEffect.hatching.assetPath]);
  });

  testWidgets('小さい端末でもスクロールで開始でき、レイアウト例外がない', (tester) async {
    final provider = _Provider();
    await host(tester, provider, size: const Size(320, 568));
    await tester.ensureVisible(find.text('はじめる'));
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(TrainingHatchingScene.duration);
    await tester.pumpAndSettle();
    expect(provider.starts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('動きを減らす設定でも短い演出の完了後に一度だけ開始する', (tester) async {
    final provider = _Provider();
    await host(tester, provider, reducedMotion: true);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(provider.starts, 1);
    expect(find.text('育成:child'), findsOneWidget);
  });

  testWidgets('保存応答が背景で届いた場合、復帰するまで画面遷移を保留する', (tester) async {
    final gate = Completer<void>();
    final provider = _Provider()..gate = gate;
    await host(tester, provider);
    await tester.tap(find.text('はじめる'));
    await tester.pump();
    await tester.pump(TrainingHatchingScene.duration);
    // duration境界を越える次フレームでAnimationStatus.completedを通知します。
    await tester.pump(const Duration(milliseconds: 16));
    expect(provider.starts, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    gate.complete();
    await tester.pump();
    expect(find.text('育成:child'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('育成:child'), findsOneWidget);
    expect(provider.starts, 1);
  });

  test('孵化原画2枚と幼体が標準AssetBundleに含まれている', () async {
    final assets =
        (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
    for (final path in [
      TrainingHatchingScene.eggAsset,
      TrainingHatchingScene.silhouetteAsset,
      SametarohAssets.newbornFrame.asset
    ]) {
      expect(assets, contains(path));
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
  });
}
