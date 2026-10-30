import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

String _shownAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image).first).image as AssetImage)
        .assetName;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('承認幼体12枚は原PNGのままbundleへ入り512角・透明余白を保つ', () async {
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .where((p) => p.startsWith('assets/images/training_game/child_care/'))
        .toSet();
    expect(SametarohAssets.childCareFrames, hasLength(12));
    expect(assets,
        SametarohAssets.childCareFrames.values.map((f) => f.asset).toSet());
    for (final frame in SametarohAssets.childCareFrames.values) {
      expect(frame.sourceSize, const Size(512, 512));
      expect(frame.canvasSize, const Size(512, 512));
      final data = await rootBundle.load(frame.asset);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      expect(bytes, File(frame.asset).readAsBytesSync());
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      expect(Size(image.width.toDouble(), image.height.toDouble()),
          const Size(512, 512));
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      expect(rgba[3], 0);
      expect(rgba[(512 * 512 - 1) * 4 + 3], 0);
      image.dispose();
      codec.dispose();
    }
  });

  test('幼体は4動作だけ・開始画像なし・全コマの共通登録位置を保持する', () {
    expect(SametarohAssets.supportedBodyKeys, isNot(contains('child')));
    for (final action in SametarohAssets.childCareActions) {
      final frames = SametarohAssets.careFramesFor(action,
          bodyKey: SametarohAssets.childBodyKey);
      expect(
          identical(
              frames,
              SametarohAssets.careFramesFor(action,
                  bodyKey: SametarohAssets.childBodyKey)),
          isTrue);
      expect(frames.map((f) => f.asset), [
        'assets/images/training_game/child_care/${action.name}_1.png',
        'assets/images/training_game/child_care/${action.name}_2.png',
      ]);
      expect(
          SametarohAssets.initialFrameFor(action,
              bodyKey: SametarohAssets.childBodyKey),
          isNull);
      expect(
          SametarohAssets.completionFrameFor(action,
                  bodyKey: SametarohAssets.childBodyKey)
              .asset,
          'assets/images/training_game/child_care/${action.name}_done.png');
      final scene = TrainingCareScene.forAction(action, isChild: true)!;
      expect(scene.characterRect.width, closeTo(66.15, 1e-9));
      expect(scene.characterRect.height, closeTo(66.15, 1e-9));
      expect(
          scene.characterRect,
          TrainingCareScene.forAction(action, isChild: true, completed: true)!
              .characterRect);
    }
    for (final action in [
      TrainingActionType.work,
      TrainingActionType.tackle,
      TrainingActionType.passAndRun
    ]) {
      expect(
          () => SametarohAssets.careFramesFor(action,
              bodyKey: SametarohAssets.childBodyKey),
          throwsArgumentError);
      expect(
          () => SametarohAssets.completionFrameFor(action,
              bodyKey: SametarohAssets.childBodyKey),
          throwsArgumentError);
      expect(TrainingCareScene.forAction(action, isChild: true), isNull);
    }
  });

  for (final action in [
    TrainingActionType.clean,
    TrainingActionType.squat,
    TrainingActionType.rest
  ]) {
    testWidgets('幼体${action.name}は承認2コマを反復し、タップで完了図から戻る', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
            home: Builder(
          builder: (context) => Scaffold(
              body: ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (_) => TrainingGameCareActionScreen(
                    actionType: action, bodyKey: SametarohAssets.childBodyKey),
              ));
            },
            child: const Text('open child'),
          )),
        )),
      ));
      final context = tester.element(find.byType(MaterialApp));
      final frames = SametarohAssets.careFramesFor(action,
          bodyKey: SametarohAssets.childBodyKey);
      final done = SametarohAssets.completionFrameFor(action,
          bodyKey: SametarohAssets.childBodyKey);
      await tester.runAsync(() async {
        for (final frame in [...frames, done]) {
          await precacheImage(AssetImage(frame.asset), context);
        }
        await precacheImage(
            AssetImage(TrainingCareScene.forAction(action,
                    isChild: true, completed: true)!
                .asset),
            context);
      });
      await tester.tap(find.text('open child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_shownAsset(tester), frames[0].asset);
      final before = tester
          .widget<TrainingCareSceneView>(find.byType(TrainingCareSceneView))
          .scene;
      await tester.pump(const Duration(milliseconds: 650));
      expect(_shownAsset(tester), frames[1].asset);
      await tester.tapAt(const Offset(2, 200));
      await tester.pump();
      expect(_shownAsset(tester), frames[1].asset);
      expect(find.text('タップで短縮できます。'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(_shownAsset(tester), done.asset);
      final after = tester
          .widget<TrainingCareSceneView>(find.byType(TrainingCareSceneView))
          .scene;
      expect(before.characterRect, after.characterRect);
      if (action == TrainingActionType.rest) {
        expect(before.asset, endsWith('rest_room_night.png'));
        expect(after.asset, endsWith('rest_room_day.png'));
      }
      await tester.pump(const Duration(milliseconds: 499));
      expect(result, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('タップして戻る'), findsOneWidget);
      expect(result, isNull);
      await tester.tap(find.text('タップして戻る'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }
}
