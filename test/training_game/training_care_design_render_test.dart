import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

import 'package:koto_blue_sharks/presentation/training_game/sametaroh_clean_warp.dart';

import 'prepare_grounded_frames.dart';

void main() {
  setUpAll(() async {
    await prepareGroundedFrames();
    for (final (family, files) in [
      (
        'LINESeedJP',
        [
          'assets/fonts/line_seed_jp/LINESeedJP-Regular.ttf',
          'assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf',
        ]
      ),
      ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  for (final sample in [
    (size: const Size(375, 812), scale: 1.0),
    (size: const Size(320, 568), scale: 1.5),
  ]) {
    for (final action in [
      TrainingActionType.meal,
      TrainingActionType.clean,
      TrainingActionType.squat,
      TrainingActionType.work,
      TrainingActionType.rest,
    ]) {
      testWidgets(
          '実フォントでお世話画面を描画 ${action.name} ${sample.size} ×${sample.scale}',
          (tester) async {
        tester.view.physicalSize = sample.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        // 画像と補正済みフレームの準備後に撮影対象をマウントします。
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final context = tester.element(find.byType(MaterialApp));
        await tester.runAsync(() async {
          final frames = [
            ...SametarohAssets.careFramesFor(action),
            SametarohAssets.completionFrameFor(action),
          ];
          for (final asset in [
            ...frames.map((frame) => frame.asset),
            TrainingCareScene.forAction(action)!.asset,
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
          for (final frame in frames) {
            if (SametarohCleanWarp.supports(frame)) {
              await SametarohCleanWarp.prepare(frame);
            }
          }
        });
        await tester.pumpWidget(RepaintBoundary(
          key: capture,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(sample.scale)),
                child: child!,
              ),
              home: TrainingGameCareActionScreen(actionType: action),
            ),
          ),
        ));
        // マウント時の非同期precacheが完了してから進行中の状態を撮ります。
        for (var i = 0;
            i < 20 &&
                find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
            i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
        expect(find.byType(SametarohAnimatedImage), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        final photoClip = find
            .ancestor(
              of: find.byType(TrainingCareSceneView),
              matching: find.byType(ClipPath),
            )
            .first;
        final clipSize = tester.getSize(photoClip);
        final clip =
            tester.widget<ClipPath>(photoClip).clipper!.getClip(clipSize);
        for (final corner in [
          const Offset(1, 1),
          Offset(clipSize.width - 1, 1),
          Offset(1, clipSize.height - 1),
          Offset(clipSize.width - 1, clipSize.height - 1),
        ]) {
          expect(clip.contains(corner), isFalse);
        }
        const output = String.fromEnvironment('CARE_DESIGN_CAPTURE_DIR');
        if (output.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary = capture.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(output).create(recursive: true);
            await File(
                    '$output/care-${action.name}-${sample.size.width.toInt()}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        final hint = find.text('タップで短縮できます。');
        await tester.ensureVisible(hint);
        await tester.pump();
        expect(hint.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
