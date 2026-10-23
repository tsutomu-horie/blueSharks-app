import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_care_scene.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('成体全体形の実描画で足元と家具のX座標を固定する', (tester) async {
    final output = Platform.environment['NO67_RENDER_OUTPUT'];
    for (final body in <String?>[null, ...SametarohAssets.supportedBodyKeys]) {
      final sequences = <String, List<SametarohFrame>>{
        'idle': SametarohAssets.idleFramesForBodyKey(body),
        for (final action in SametarohAssets.careFrames.keys)
          action.name: [
            ...SametarohAssets.careFramesFor(action, bodyKey: body),
            SametarohAssets.completionFrameFor(action, bodyKey: body),
            if (SametarohAssets.initialFrameFor(action, bodyKey: body)
                case final initial?)
              initial,
          ],
      };
      for (final sequence in sequences.entries) {
        final anchors = <double>[];
        for (var i = 0; i < sequence.value.length; i++) {
          final frame = sequence.value[i];
          final rendered = await _render(tester, frame);
          final w = rendered.width;
          final h = rendered.height;
          final bytes = (await tester.runAsync(() =>
                  rendered.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          final action = sequence.key;
          if (['idle', 'clean', 'squat'].contains(action)) {
            // 足裏の青い輪郭。箒・ダンベル・尻尾の外形中心を基準にしない。
            final rows = <double>[];
            for (var y = h - 1; y >= h - 48; y--) {
              final xs = <int>[];
              for (var x = 0; x < w; x++) {
                final p = (y * w + x) * 4;
                if (bytes[p + 3] > 200 &&
                    bytes[p] < 35 &&
                    bytes[p + 1] > 45 &&
                    bytes[p + 1] < 125 &&
                    bytes[p + 2] > 110) {
                  xs.add(x);
                }
              }
              if (xs.length > 15) rows.add((xs.first + xs.last) / 2);
            }
            final feet = rows.skip(2).take(10).toList()..sort();
            expect(feet, isNotEmpty, reason: frame.asset);
            anchors.add(
                (feet[(feet.length - 1) ~/ 2] + feet[feet.length ~/ 2]) / 2);
          } else {
            final xs = <int>[];
            final color = action == 'rest' ? [199, 231, 241] : [127, 172, 166];
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                final p = (y * w + x) * 4;
                if (bytes[p] == color[0] &&
                    bytes[p + 1] == color[1] &&
                    bytes[p + 2] == color[2] &&
                    bytes[p + 3] == 255) {
                  xs.add(x);
                }
              }
            }
            expect(xs, isNotEmpty, reason: frame.asset);
            xs.sort();
            anchors.add(action == 'rest'
                ? xs.first.toDouble()
                : (xs.first + xs.last) / 2);
          }
          if (output != null) {
            final png = await tester.runAsync(
                () => rendered.toByteData(format: ui.ImageByteFormat.png));
            File('$output/${body ?? 'base'}_${sequence.key}_$i.png')
              ..parent.createSync(recursive: true)
              ..writeAsBytesSync(png!.buffer.asUint8List());
            if (action != 'idle') {
              final type = TrainingActionType.values
                  .firstWhere((value) => value.name == action);
              final scene =
                  TrainingCareScene.forAction(type, completed: i == 2)!;
              final panel = await _capture(
                  tester,
                  SizedBox(
                      width: TrainingCareScene.sourceSize.width * 2,
                      height: TrainingCareScene.sourceSize.height * 2,
                      child: TrainingCareSceneView(
                          scene: scene,
                          character: SametarohFrameImage(
                              frame: frame,
                              width: scene.characterRect.width,
                              height: scene.characterRect.height,
                              alignment: Alignment.bottomCenter))));
              final panelPng = await tester.runAsync(
                  () => panel.toByteData(format: ui.ImageByteFormat.png));
              File('$output/scene_${body ?? 'base'}_${sequence.key}_$i.png')
                  .writeAsBytesSync(panelPng!.buffer.asUint8List());
              panel.dispose();
            }
          }
          rendered.dispose();
        }
        if (sequence.key != 'clean') {
          expect(
              anchors.reduce((a, b) => a > b ? a : b) -
                  anchors.reduce((a, b) => a < b ? a : b),
              lessThanOrEqualTo(1.5),
              reason: '$body.${sequence.key}: $anchors');
        }
      }
    }
  });

  testWidgets('掃除は両足の接地形状を固定し、休養は家具画素を固定する', (tester) async {
    for (final body in ['pr', 'sh', 'wtb']) {
      final clean = SametarohAssets.careFramesFor(TrainingActionType.clean,
          bodyKey: body);
      final feet = <List<List<int>>>[];
      final floor = {'pr': 261, 'sh': 296, 'wtb': 322}[body]!;
      for (final frame in clean) {
        final image = await _render(tester, frame);
        final data = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final signature = <List<int>>[];
        // Scan the whole contact band, including both outer sole contours.
        // A bbox midpoint cannot detect the old mirrored contact shapes.
        for (final interval in [
          [0, image.width]
        ]) {
          for (var y = floor - 5; y < floor; y++) {
            for (var x = interval[0]; x < interval[1]; x++) {
              final pixel = (y * image.width + x) * 4;
              signature.add(data.sublist(pixel, pixel + 4));
            }
          }
        }
        feet.add(signature);
        image.dispose();
      }
      for (var i = 0; i < feet[0].length; i++) {
        final a = feet[0][i], b = feet[1][i];
        bool foot(List<int> p) =>
            p[0] < 35 && p[1] > 45 && p[1] < 125 && p[2] > 110 && p[3] > 180;
        bool broomOverFoot(List<int> p) {
          if (p[3] < 180) return false;
          // Only actual broom pigment, including its antialias blend with the sole.
          for (final color in [
            [127, 172, 166],
            [223, 224, 153],
            [175, 170, 144]
          ]) {
            final t = (p[0] - 24) / (color[0] - 24);
            if (t > 0 &&
                t <= 1.02 &&
                (p[1] - (83 + (color[1] - 83) * t)).abs() < 3 &&
                (p[2] - (149 + (color[2] - 149) * t)).abs() < 3) {
              return true;
            }
          }
          return false;
        }

        if (foot(a) != foot(b)) {
          expect(broomOverFoot(foot(a) ? b : a), isTrue,
              reason:
                  '$body contact $i must be occluded by broom, not displaced: $a / $b');
        }
      }
      final rest =
          SametarohAssets.careFramesFor(TrainingActionType.rest, bodyKey: body);
      final furniture = <List<int>>[];
      for (final frame in rest) {
        final image = await _render(tester, frame);
        final data = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final signature = <int>[];
        final post = {'pr': 414, 'sh': 466, 'wtb': 364}[body]!;
        for (final rect in [
          const Rect.fromLTWH(15, 250, 20, 60),
          Rect.fromLTWH(post.toDouble(), 220, 3, 90)
        ]) {
          for (var y = rect.top.toInt(); y < rect.bottom; y++) {
            for (var x = rect.left.toInt(); x < rect.right; x++) {
              final pixel = (y * image.width + x) * 4;
              signature.addAll(data.sublist(pixel, pixel + 4));
            }
          }
        }
        furniture.add(signature);
        image.dispose();
      }
      expect(furniture[1], furniture[0],
          reason: '$body mattress/base/right post stay still');
    }
  });

  testWidgets('SH・WTB休養第2コマのベッド側面を補完しPRも保持する', (tester) async {
    for (final body in SametarohAssets.supportedBodyKeys) {
      final frames =
          SametarohAssets.careFramesFor(TrainingActionType.rest, bodyKey: body);
      for (final frame in [
        ...frames,
        SametarohAssets.completionFrameFor(TrainingActionType.rest,
            bodyKey: body)
      ]) {
        final rendered = await _render(tester, frame);
        final bytes = (await tester.runAsync(
                () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final x = {'pr': 415, 'sh': 467, 'wtb': 365}[body]!;
        final y = {'pr': 260, 'sh': 260, 'wtb': 280}[body]!;
        final p = (y * rendered.width + x) * 4;
        expect(bytes.sublist(p, p + 4), [82, 156, 193, 255],
            reason: frame.asset);
        rendered.dispose();
      }
    }
  });

  testWidgets('ホームの透明余白正規化後も全体形の待機足中心を固定する', (tester) async {
    for (final body in <String?>[null, ...SametarohAssets.supportedBodyKeys]) {
      final frames = TrainingHomeCharacterFrameSet.forBodyKey(body);
      final centers = <double>[];
      for (var i = 0; i < frames.idleFrames.length; i++) {
        final frame = frames.idleFrames[i];
        final rendered = await _capture(
            tester,
            TrainingHomeCharacterFrameImage(
                frame: frame,
                width: frames.canvasSize.width,
                height: frames.canvasSize.height));
        final bytes = (await tester.runAsync(
                () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final rows = <double>[];
        for (var y = rendered.height - 1; y >= rendered.height - 48; y--) {
          final xs = <int>[];
          for (var x = 0; x < rendered.width; x++) {
            final p = (y * rendered.width + x) * 4;
            if (bytes[p + 3] > 200 &&
                bytes[p] < 35 &&
                bytes[p + 1] > 45 &&
                bytes[p + 1] < 125 &&
                bytes[p + 2] > 110) {
              xs.add(x);
            }
          }
          if (xs.length > 15) rows.add((xs.first + xs.last) / 2);
        }
        final feet = rows.skip(2).take(10).toList()..sort();
        centers.add((feet[4] + feet[5]) / 2);
        final output = Platform.environment['NO67_RENDER_OUTPUT'];
        if (output != null) {
          final png = await tester.runAsync(
              () => rendered.toByteData(format: ui.ImageByteFormat.png));
          File('$output/home_${body ?? 'base'}_$i.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
        rendered.dispose();
      }
      expect((centers[0] - centers[1]).abs(), lessThanOrEqualTo(1.5),
          reason: '$body: $centers');
    }
  });

  testWidgets('人物と家具を共通座標へ登録してから外側alignmentを適用する', (tester) async {
    for (final body in ['pr', 'sh', 'wtb']) {
      for (final frame in [
        ...SametarohAssets.careFramesFor(TrainingActionType.rest,
            bodyKey: body),
        SametarohAssets.completionFrameFor(TrainingActionType.rest,
            bodyKey: body)
      ]) {
        final signatures = <List<int>>[];
        for (final align in [Alignment.center, Alignment.bottomCenter]) {
          final image = await _capture(
              tester,
              SametarohFrameImage(
                  frame: frame,
                  width: frame.canvasSize.width,
                  height: frame.canvasSize.height,
                  alignment: align));
          final bytes = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          signatures.add(bytes.toList());
          image.dispose();
        }
        expect(signatures[0], signatures[1], reason: frame.asset);
      }
    }
  });

  testWidgets('ベッド補完は既定center配置にも追従する', (tester) async {
    for (final body in ['sh', 'wtb']) {
      final frame = SametarohAssets.careFramesFor(TrainingActionType.rest,
          bodyKey: body)[1];
      final image = await _capture(
          tester,
          SametarohFrameImage(
              frame: frame,
              width: frame.canvasSize.width,
              height: frame.canvasSize.height));
      final bytes = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      final x = body == 'sh' ? 467 : 365;
      final y = body == 'sh' ? 250 : 250;
      final p = (y * image.width + x) * 4;
      expect(bytes[p + 3], 255);
      expect(bytes[p], closeTo(82, 1));
      expect(bytes[p + 1], closeTo(156, 1));
      image.dispose();
    }
  });

  test('幼体・歩行の登録座標と全原PNGを保持する', () {
    for (final body in <String?>[null, ...SametarohAssets.supportedBodyKeys]) {
      for (final frame in SametarohAssets.journeyFramesForBodyKey(body)) {
        expect(frame.registrationX, 0);
      }
    }
    for (final frame in SametarohAssets.childCareFrames.values) {
      expect(frame.registrationX, 0);
    }
  });
}

Future<ui.Image> _render(WidgetTester tester, SametarohFrame frame) => _capture(
    tester,
    SametarohFrameImage(
        frame: frame,
        width: frame.canvasSize.width,
        height: frame.canvasSize.height,
        alignment: Alignment.bottomCenter));

Future<ui.Image> _capture(WidgetTester tester, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: RepaintBoundary(key: key, child: child)),
  ));
  await tester.runAsync(() async {
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    await Future.wait(images.map((image) =>
        precacheImage(image.image, tester.element(find.byKey(key)))));
  });
  await tester.pump();
  return (await tester.runAsync(() =>
      (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
          .toImage(pixelRatio: 1)))!;
}
