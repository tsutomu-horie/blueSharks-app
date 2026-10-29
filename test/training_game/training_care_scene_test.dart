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

const _careActions = [
  TrainingActionType.meal,
  TrainingActionType.clean,
  TrainingActionType.squat,
  TrainingActionType.work,
  TrainingActionType.rest,
];

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('8背景は標準bundleに原PNGを収録し、全5動作の配置が収まる', () async {
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .where((p) => p.startsWith('assets/images/training_game/scenes/'))
        .toSet();
    expect(assets, hasLength(8));
    expect(
        assets,
        containsAll({
          for (final action in _careActions)
            TrainingCareScene.forAction(action)!.asset,
          TrainingCareScene.forAction(TrainingActionType.rest, completed: true)!
              .asset,
          'assets/images/training_game/scenes/home_outdoor_day.png',
          'assets/images/training_game/scenes/home_outdoor_night.png',
        }));
    for (final action in _careActions) {
      final scene = TrainingCareScene.forAction(action);
      if (scene == null) continue;
      final data = await rootBundle.load(scene.asset);
      expect(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          File(scene.asset).readAsBytesSync());
      expect(Offset.zero & TrainingCareScene.sourceSize,
          containsRect(scene.characterRect));
    }
  });

  test('新規書出し64コマは寸法が一致し、外周透過と白い目・歯を保つ', () async {
    var count = 0;
    for (final body in <String?>[null, ...SametarohAssets.supportedBodyKeys]) {
      for (final action in _careActions) {
        final frames = [
          if (SametarohAssets.initialFrameFor(action, bodyKey: body)
              case final initial?)
            initial,
          ...SametarohAssets.careFramesFor(action, bodyKey: body),
          SametarohAssets.completionFrameFor(action, bodyKey: body),
        ];
        for (final frame in frames) {
          count++;
          final bytes = await rootBundle.load(frame.asset);
          final codec = await ui.instantiateImageCodec(bytes.buffer
              .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
          final image = (await codec.getNextFrame()).image;
          expect(Size(image.width.toDouble(), image.height.toDouble()),
              frame.sourceSize,
              reason: frame.asset);
          final rgba =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                  .buffer
                  .asUint8List();
          var white = 0;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final n = (y * image.width + x) * 4;
              if (x == 0 ||
                  y == 0 ||
                  x == image.width - 1 ||
                  y == image.height - 1) {
                expect(rgba[n + 3], 0, reason: '${frame.asset}: ($x, $y)');
              }
              if (rgba[n + 3] == 255 &&
                  rgba[n] >= 240 &&
                  rgba[n + 1] >= 240 &&
                  rgba[n + 2] >= 240) {
                white++;
              }
            }
          }
          expect(white, greaterThan(0), reason: frame.asset);
          image.dispose();
          codec.dispose();
        }
      }
    }
    expect(count, 64);
  });

  for (final size in [const Size(375, 812), const Size(320, 568)]) {
    testWidgets('5動作と幼体の背景・キャラは${size.width}x${size.height}で収まる',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final body in <String?>[
        null,
        ...SametarohAssets.supportedBodyKeys,
        SametarohAssets.childBodyKey,
      ]) {
        for (final action in _careActions) {
          if (body == SametarohAssets.childBodyKey &&
              !SametarohAssets.childCareActions.contains(action)) {
            continue;
          }
          await tester.pumpWidget(_host(TrainingGameCareActionScreen(
            actionType: action,
            bodyKey: body,
          )));
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(() async {
            for (final frame in [
              ...SametarohAssets.careFramesFor(action, bodyKey: body),
              SametarohAssets.completionFrameFor(action, bodyKey: body),
            ]) {
              await precacheImage(AssetImage(frame.asset), context);
            }
          });
          await tester.pump(const Duration(milliseconds: 650));
          expect(tester.takeException(), isNull, reason: '$body/$action');
          expect(find.byType(SametarohAnimatedImage), findsOneWidget);
          final expectedScene = TrainingCareScene.forAction(
            action,
            isChild: body == SametarohAssets.childBodyKey,
          );
          expect(find.byType(TrainingCareSceneView),
              expectedScene == null ? findsNothing : findsOneWidget);
          if (expectedScene != null) {
            final sceneBounds =
                tester.getRect(find.byType(TrainingCareSceneView));
            final panel = tester.getRect(find.descendant(
              of: find.byType(TrainingCareSceneView),
              matching: find.byType(DecoratedBox),
            ));
            final character =
                tester.getRect(find.byType(SametarohAnimatedImage));
            expect(panel.contains(character.topLeft), isTrue);
            expect(panel.contains(character.bottomRight), isTrue);
            // 写真枠や下部キャプションで縮めず、利用可能な領域へ最大contain。
            final expectedSize = applyBoxFit(
              BoxFit.contain,
              TrainingCareScene.sourceSize,
              sceneBounds.size,
            ).destination;
            expect(panel.width, closeTo(expectedSize.width, 0.01));
            expect(panel.height, closeTo(expectedSize.height, 0.01));
            expect(panel.center.dx, closeTo(sceneBounds.center.dx, 0.01));
            expect(panel.center.dy, closeTo(sceneBounds.center.dy, 0.01));
            final illustration = tester.widget<SametarohAnimatedImage>(
                find.byType(SametarohAnimatedImage));
            expect(find.text(illustration.semanticLabel!), findsNothing);
            final progressLabel = switch (action) {
              TrainingActionType.meal => '食事中…',
              TrainingActionType.clean => '掃除中…',
              TrainingActionType.squat => 'トレーニング中…',
              TrainingActionType.work => '仕事中…',
              TrainingActionType.rest => 'ケア中…',
              _ => throw StateError('お世話対象外'),
            };
            final progressChip = tester.getRect(find
                .ancestor(
                  of: find.text(progressLabel),
                  matching: find.byType(Container),
                )
                .first);
            expect(progressChip.top - sceneBounds.bottom,
                closeTo(20 * size.height / 812, 0.01));
            // 画面下部の自動完了案内と専用ボタンは表示しない。
            expect(find.text('スキップ'), findsNothing);
            expect(find.text('5秒で自動完了します。画面タップでスキップ'), findsNothing);
            if (action == TrainingActionType.meal) {
              expect(find.text('食事中…'), findsOneWidget);
              expect(find.text('食事内容を選ぶ'), findsNothing);
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

Matcher containsRect(Rect inner) => predicate<Rect>(
      (outer) =>
          outer.contains(inner.topLeft) && outer.contains(inner.bottomRight),
      'contains the complete character canvas',
    );
