import 'package:koto_blue_sharks/presentation/training_game/sametaroh_grounded_profiles.dart';
import 'package:flutter/services.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_registration_layers.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_clean_warp.dart';
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
        if (sequence.key != 'clean' && sequence.key != 'squat') {
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

  testWidgets('休養完了に睡眠輪郭を残さず右支柱との継ぎ目を不透明に保つ', (tester) async {
    const formerSleeperEdges = <String, List<Offset>>{
      'pr': [Offset(27, 206), Offset(381, 216)],
      'sh': [Offset(428, 208), Offset(409, 217)],
      'wtb': [Offset(336, 235), Offset(328, 245)],
    };
    const mattressPostSeams = <String, List<Offset>>{
      'pr': [Offset(385, 187), Offset(389, 197)],
      'sh': [Offset(432, 150), Offset(439, 166), Offset(444, 179)],
      'wtb': [Offset(339, 192), Offset(343, 202)],
    };
    for (final body in ['pr', 'sh', 'wtb']) {
      final frames = [
        ...SametarohAssets.careFramesFor(TrainingActionType.rest,
            bodyKey: body),
        SametarohAssets.completionFrameFor(TrainingActionType.rest,
            bodyKey: body),
      ];
      for (var n = 0; n < frames.length; n++) {
        final image = await _render(tester, frames[n]);
        final bytes = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        for (final point in mattressPostSeams[body]!) {
          final i = (point.dy.toInt() * image.width + point.dx.toInt()) * 4;
          expect(bytes[i + 3], 255,
              reason: '$body pose$n original mattress/post seam $point');
        }
        if (n == frames.length - 1) {
          for (final point in formerSleeperEdges[body]!) {
            final i = (point.dy.toInt() * image.width + point.dx.toInt()) * 4;
            expect(bytes.sublist(i, i + 4), [199, 231, 241, 255],
                reason: '$body no sleeping outline at $point');
          }
        }
        image.dispose();
      }
    }
  });

  test('ノーマルもホーム待機と全補正アクションの対象になる', () {
    final home = TrainingHomeCharacterFrameSet.forBodyKey(null);
    expect(home.bodyKey, 'normal');
    expect(home.idleFrames.map((frame) => frame.asset),
        SametarohAssets.normalFrames.map((frame) => frame.asset));
    for (final action in [
      TrainingActionType.clean,
      TrainingActionType.squat,
      TrainingActionType.work,
      TrainingActionType.rest
    ]) {
      for (final frame in [
        ...SametarohAssets.careFramesFor(action),
        SametarohAssets.completionFrameFor(action),
      ]) {
        expect(frame.asset, startsWith('assets/images/sametaroh/'));
        if (frame ==
            SametarohAssets.completionFrameFor(TrainingActionType.work)) {
          // Work completion preserves the original whole pose by translation.
          expect(frame.registrationX, 11);
        } else {
          expect(
              action == TrainingActionType.rest
                  ? registeredFrameLayers.containsKey(frame.asset)
                  : SametarohCleanWarp.supports(frame),
              isTrue,
              reason: frame.asset);
        }
      }
    }
  });

  testWidgets('ノーマル休養の頭下の原画濃青輪郭を全コマで直線クリップしない', (tester) async {
    for (final frame in [
      ...SametarohAssets.careFramesFor(TrainingActionType.rest),
      SametarohAssets.completionFrameFor(TrainingActionType.rest),
    ]) {
      final original = (await tester.runAsync(() async {
        final data = await rootBundle.load(frame.asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        image.dispose();
        codec.dispose();
        return bytes;
      }))!;
      final image = await _render(tester, frame);
      final actual = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      final dx = ((frame.canvasSize.width - frame.sourceSize.width) / 2 +
              frame.registrationX)
          .round();
      final dy = (frame.canvasSize.height - frame.sourceSize.height).round();
      var checked = 0;
      for (var y = 0; y < frame.sourceSize.height; y++) {
        for (var x = 0; x < frame.sourceSize.width; x++) {
          final i = (y * frame.sourceSize.width.toInt() + x) * 4;
          final navy = (original[i] == 41 &&
                  original[i + 1] == 79 &&
                  original[i + 2] == 135) ||
              (original[i] == 24 &&
                  original[i + 1] == 83 &&
                  original[i + 2] == 149);
          if (!navy || original[i + 3] != 255) continue;
          final target = ((y + dy) * image.width + x + dx) * 4;
          expect(actual.sublist(target, target + 4), original.sublist(i, i + 4),
              reason: '${frame.asset} original navy ($x,$y)');
          checked++;
        }
      }
      expect(checked, greaterThan(100), reason: frame.asset);
      image.dispose();
    }
  });

  testWidgets('ノーマル休養は右下接合部を連続させ補完範囲外の原画RGBAを保持する', (tester) async {
    final first = SametarohAssets.careFramesFor(TrainingActionType.rest).first;
    final original = (await tester.runAsync(() async {
      final asset = await rootBundle.load(first.asset);
      final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      image.dispose();
      codec.dispose();
      return data;
    }))!;
    for (final frame in [
      ...SametarohAssets.careFramesFor(TrainingActionType.rest),
      SametarohAssets.completionFrameFor(TrainingActionType.rest),
    ]) {
      final rendered = await _render(tester, frame);
      final bytes = (await tester.runAsync(
              () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      var differences = 0;
      for (var y = 213; y < 266; y++) {
        for (var x = 384; x < 426; x++) {
          // Only the explicit furniture joint may change from the supplied PNG.
          if (x >= 397 && x <= 413 && y >= 239 && y <= 255) continue;
          final source = (y * 426 + x) * 4;
          final target = ((y + 34) * rendered.width + x) * 4;
          for (var c = 0; c < 4; c++) {
            if (bytes[target + c] != original[source + c]) differences++;
          }
        }
      }
      expect(differences, 0,
          reason: '${frame.asset}: original furniture outside the small joint');
      for (var y = 274; y <= 289; y++) {
        for (var x = 405; x <= 413; x++) {
          final pixel = (y * rendered.width + x) * 4;
          expect(bytes[pixel + 3], 255,
              reason:
                  '${frame.asset}: no background visible through joint ($x,$y)');
        }
      }
      rendered.dispose();
    }
  });

  testWidgets('ホームの透明余白正規化後も全体形の待機足中心を固定する', (tester) async {
    for (final body in <String?>[null, ...SametarohAssets.supportedBodyKeys]) {
      final frames = TrainingHomeCharacterFrameSet.forBodyKey(body);
      final centers = <double>[];
      for (var i = 0; i < frames.idleFrames.length; i++) {
        final frame = frames.idleFrames[i];
        if (TrainingHomeIdleRegistration.supports(frame)) {
          await tester
              .runAsync(() => TrainingHomeIdleRegistration.prepare(frame));
        }
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

  testWidgets('baseを含む掃除と筋トレの1→2→完了で両足接地を維持する', (tester) async {
    bool foot(List<int> p) =>
        p[0] < 35 && p[1] > 45 && p[1] < 125 && p[2] > 110 && p[3] > 180;
    bool broom(List<int> p) {
      if (p[3] < 180) return false;
      for (final c in [
        [127, 172, 166],
        [223, 224, 153],
        [175, 170, 144]
      ]) {
        final rgb = [for (var j = 0; j < 3; j++) p[j] * 255 / p[3]];
        final t = (rgb[0] - 24) / (c[0] - 24);
        if (t > 0 &&
            t <= 1.02 &&
            (rgb[1] - (83 + (c[1] - 83) * t)).abs() < 3 &&
            (rgb[2] - (149 + (c[2] - 149) * t)).abs() < 3) {
          return true;
        }
      }
      return false;
    }

    bool weight(List<int> p) {
      if (p[3] < 180) return false;
      final rgb = [for (var j = 0; j < 3; j++) p[j] * 255 / p[3]];
      for (final c in [
        [223, 84, 48],
        [231, 228, 183]
      ]) {
        final t = (rgb[0] - 24) / (c[0] - 24);
        if (t > 0 &&
            t <= 1.02 &&
            (rgb[1] - (83 + (c[1] - 83) * t)).abs() < 3 &&
            (rgb[2] - (149 + (c[2] - 149) * t)).abs() < 3) {
          return true;
        }
      }
      return false;
    }

    for (final body in <String?>[null, 'pr', 'sh', 'wtb']) {
      for (final action in [
        TrainingActionType.clean,
        TrainingActionType.squat
      ]) {
        final frames = [
          ...SametarohAssets.careFramesFor(action, bodyKey: body),
          SametarohAssets.completionFrameFor(action, bodyKey: body)
        ];
        final signatures = <List<List<int>>>[];
        for (final frame in frames) {
          final image = await _render(tester, frame);
          final bytes = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          final p = groundedProfiles[frame.asset]!;
          final floor =
              (p.targetFloor + frame.canvasSize.height - p.targetHeight)
                  .round();
          final pixels = <List<int>>[];
          for (var y = floor - 5; y <= floor; y++) {
            for (var x = 0; x < image.width; x++) {
              final i = (y * image.width + x) * 4;
              pixels.add(bytes.sublist(i, i + 4));
            }
          }
          signatures.add(pixels);
          image.dispose();
        }
        for (var f = 1; f < signatures.length; f++) {
          for (var i = 0; i < signatures[0].length; i++) {
            final a = signatures[0][i], b = signatures[f][i];
            if (foot(a) != foot(b)) {
              expect(
                  (action == TrainingActionType.clean &&
                          broom(foot(a) ? b : a)) ||
                      (action == TrainingActionType.squat &&
                          weight(foot(a) ? b : a)),
                  isTrue,
                  reason: '$body $action frame$f contact$i $a / $b');
            }
          }
        }
      }
    }
  });

  testWidgets('道具を除いた人物の左右接地輪郭は全動作と完了で同一', (tester) async {
    for (final body in <String?>[null, 'pr', 'sh', 'wtb']) {
      for (final action in [
        TrainingActionType.clean,
        TrainingActionType.squat
      ]) {
        final signatures = <List<bool>>[];
        for (final frame in [
          ...SametarohAssets.careFramesFor(action, bodyKey: body),
          SametarohAssets.completionFrameFor(action, bodyKey: body)
        ]) {
          final image =
              (await tester.runAsync(() => SametarohCleanWarp.prepare(frame)))!;
          final bytes = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          final p = groundedProfiles[frame.asset]!;
          final floor =
              (p.targetFloor + frame.canvasSize.height - p.targetHeight)
                  .round();
          final signature = <bool>[];
          // 掃除は足裏だけでなく甲・足首まで比較し、旧14px境界の欠けを検出する。
          final contactHeight = action == TrainingActionType.clean ? 20 : 5;
          for (var y = floor - contactHeight; y <= floor; y++) {
            for (var x = 0; x < image.width; x++) {
              final i = (y * image.width + x) * 4;
              signature.add(bytes[i] < 35 &&
                  bytes[i + 1] > 45 &&
                  bytes[i + 1] < 125 &&
                  bytes[i + 2] > 110 &&
                  bytes[i + 3] > 180);
            }
          }
          signatures.add(signature);
        }
        expect(signatures[1], signatures[0],
            reason: '$body $action loop actor');
        expect(signatures[2], signatures[0],
            reason: '$body $action completion actor');
      }
    }
  });

  testWidgets('BASE・SH掃除の甲に透明な水平亀裂や孤立した尾片を作らない', (tester) async {
    for (final body in <String?>[null, 'sh']) {
      for (final frame in [
        ...SametarohAssets.careFramesFor(TrainingActionType.clean,
            bodyKey: body),
        SametarohAssets.completionFrameFor(TrainingActionType.clean,
            bodyKey: body),
      ]) {
        final image =
            (await tester.runAsync(() => SametarohCleanWarp.prepare(frame)))!;
        final data = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final profile = groundedProfiles[frame.asset]!;
        final floor = (profile.targetFloor +
                frame.canvasSize.height -
                profile.targetHeight)
            .round();
        int alpha(int x, int y) => data[(y * image.width + x) * 4 + 3];
        for (var y = floor - 25; y < floor - 1; y++) {
          for (var x = 1; x < image.width - 1; x++) {
            expect(
                alpha(x, y) < 10 &&
                    alpha(x, y - 1) > 200 &&
                    alpha(x, y + 1) > 200,
                isFalse,
                reason: '${frame.asset} transparent crack ($x,$y)');
          }
        }
        final seen = <int>{};
        final components = <List<int>>[];
        for (var i = 0; i < image.width * image.height; i++) {
          if (data[i * 4 + 3] <= 128 || seen.contains(i)) continue;
          final queue = [i], points = <int>[];
          seen.add(i);
          while (queue.isNotEmpty) {
            final current = queue.removeLast();
            points.add(current);
            final x = current % image.width, y = current ~/ image.width;
            for (final next in [
              if (x > 0) current - 1,
              if (x + 1 < image.width) current + 1,
              if (y > 0) current - image.width,
              if (y + 1 < image.height) current + image.width
            ]) {
              if (data[next * 4 + 3] > 128 && seen.add(next)) queue.add(next);
            }
          }
          components.add(points);
        }
        components.sort((a, b) => b.length.compareTo(a.length));
        for (final component in components.skip(1)) {
          final navy = component.where((i) =>
              i ~/ image.width > floor - 50 &&
              data[i * 4] == 6 &&
              data[i * 4 + 1] == 41 &&
              data[i * 4 + 2] == 83);
          expect(navy, isEmpty, reason: '${frame.asset} detached tail pixels');
        }
      }
    }
  });

  testWidgets('筋トレの人物メッシュはダンベル画素を含まない', (tester) async {
    for (final body in <String?>[null, 'pr', 'sh', 'wtb']) {
      for (final frame in [
        ...SametarohAssets.careFramesFor(TrainingActionType.squat,
            bodyKey: body),
        SametarohAssets.completionFrameFor(TrainingActionType.squat,
            bodyKey: body)
      ]) {
        final image = (await tester
            .runAsync(() => SametarohCleanWarp.prepareActor(frame)))!;
        final bytes = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        var red = 0;
        for (var i = 0; i < bytes.length; i += 4) {
          if (bytes[i + 3] > 180 && bytes[i] > 150 && bytes[i + 1] < 140) red++;
        }
        expect(red, 0, reason: frame.asset);
      }
    }
  });

  testWidgets('筋トレのダンベル不透明領域を動作中と完了で原画どおり保持する', (tester) async {
    for (final body in <String?>[null, 'pr', 'sh', 'wtb']) {
      for (final frame in [
        ...SametarohAssets.careFramesFor(TrainingActionType.squat,
            bodyKey: body),
        SametarohAssets.completionFrameFor(TrainingActionType.squat,
            bodyKey: body),
      ]) {
        final profile = groundedProfiles[frame.asset]!;
        final done =
            frame.asset.contains('_done') || frame.asset.contains('complete');
        final offset = done
            ? groundedProfiles[profile.first]!.axis -
                profile.axis +
                (frame.sourceSize.width - profile.targetWidth) / 2
            : profile.upperX;
        final actual = await _render(tester, frame);
        final original = await _capture(
            tester,
            SizedBox.fromSize(
              size: frame.canvasSize,
              child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox.fromSize(
                        size: frame.sourceSize,
                        child: Image.asset(frame.asset, fit: BoxFit.fill)),
                  )),
            ));
        Future<List<int>> redPixels(ui.Image image) async {
          final data = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          return [
            for (var i = 0; i < data.length; i += 4)
              if (data[i + 3] == 255 &&
                  data[i] == 223 &&
                  data[i + 1] == 84 &&
                  data[i + 2] == 48)
                i ~/ 4
          ];
        }

        final expected = await redPixels(original);
        expect(expected.length, greaterThan(100), reason: frame.asset);
        final found = await redPixels(actual);
        if (found.toString() != expected.toString()) {
          final missing = expected.toSet().difference(found.toSet());
          final extra = found.toSet().difference(expected.toSet());
          fail('${frame.asset}: missing $missing extra $extra');
        }
        actual.dispose();
        original.dispose();
      }
    }
  });

  testWidgets('PRの机上の黒い物体は動作中と完了で同じ画素を保持する', (tester) async {
    final signatures = <List<int>>[];
    for (final frame in [
      ...SametarohAssets.careFramesFor(TrainingActionType.work, bodyKey: 'pr'),
      SametarohAssets.completionFrameFor(TrainingActionType.work,
          bodyKey: 'pr'),
    ]) {
      final image = await _render(tester, frame);
      final data = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      final source =
          SametarohAssets.careFramesFor(TrainingActionType.work, bodyKey: 'pr')
              .first;
      final left =
          ((frame.canvasSize.width - source.sourceSize.width) / 2).round() + 34;
      final top =
          (frame.canvasSize.height - source.sourceSize.height).round() + 228;
      final signature = <int>[];
      for (var y = top; y < top + 38; y++) {
        for (var x = left; x < left + 27; x++) {
          final i = (y * image.width + x) * 4;
          signature.addAll(data.sublist(i, i + 4));
        }
      }
      expect(signature.where((c) => c == 52).length, greaterThan(500));
      signatures.add(signature);
      image.dispose();
    }
    expect(signatures[1], signatures[0]);
    expect(signatures[2], signatures[0]);
  });

  testWidgets('仕事は人物の頭中心と机前縁を独立して固定する', (tester) async {
    for (final body in <String?>[null, 'pr', 'sh', 'wtb']) {
      final heads = <double>[], desks = <List<int>>[];
      for (final frame in SametarohAssets.careFramesFor(TrainingActionType.work,
          bodyKey: body)) {
        final image = await _render(tester, frame);
        final data = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        final blueRows = <int, List<int>>{}, deskX = <int>[], deskY = <int>[];
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final i = (y * image.width + x) * 4;
            if (data[i + 3] != 255) continue;
            if (data[i] == 82 && data[i + 1] == 156 && data[i + 2] == 193) {
              (blueRows[y] ??= []).add(x);
            }
            if (data[i] == 127 && data[i + 1] == 172 && data[i + 2] == 166) {
              deskX.add(x);
              deskY.add(y);
            }
          }
        }
        final top = blueRows.keys.reduce((a, b) => a < b ? a : b);
        final centers = <double>[];
        for (var y = top + 20; y < top + 65; y++) {
          final xs = blueRows[y];
          if (xs != null && xs.length > 10) {
            centers.add((xs.first + xs.last) / 2);
          }
        }
        centers.sort();
        heads.add(centers[centers.length ~/ 2]);
        deskX.sort();
        deskY.sort();
        desks.add([deskX.first, deskX.last, deskY.first, deskY.last]);
        image.dispose();
      }
      expect((heads[1] - heads[0]).abs(), 0,
          reason: '$body head center $heads');
      for (var i = 0; i < 4; i++) {
        expect((desks[1][i] - desks[0][i]).abs(), 0,
            reason: '$body desk bounds $desks');
      }
    }
  });

  testWidgets('SH・WTBの頭とヒレを原画alphaから切り落とさない', (tester) async {
    for (final body in ['sh', 'wtb']) {
      final frame = SametarohAssets.careFramesFor(TrainingActionType.rest,
          bodyKey: body)[1];
      final path =
          registrationPath(registeredFrameLayers[frame.asset]!.dynamicClip);
      final result = await tester.runAsync(() async {
        final asset = await rootBundle.load(frame.asset);
        final codec =
            await ui.instantiateImageCodec(asset.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        final box = body == 'sh'
            ? const Rect.fromLTRB(400, 145, 434, 203)
            : const Rect.fromLTRB(315, 139, 340, 189);
        var checked = 0, missing = 0;
        for (var y = box.top.toInt(); y < box.bottom; y++) {
          for (var x = box.left.toInt(); x < box.right; x++) {
            final i = (y * image.width + x) * 4;
            if (bytes[i + 3] > 0 &&
                bytes[i] < 35 &&
                bytes[i + 1] > 45 &&
                bytes[i + 1] < 125 &&
                bytes[i + 2] > 110) {
              checked++;
              if (!path.contains(Offset(x + .5, y + .5))) missing++;
            }
          }
        }
        image.dispose();
        codec.dispose();
        return [checked, missing];
      });
      expect(result![0], greaterThan(body == 'sh' ? 300 : 200));
      expect(result[1], 0, reason: '$body original head/fin alpha');
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

  testWidgets('PR仕事の本体と机上物はcenter指定でも共通座標を保持する', (tester) async {
    for (final frame in [
      ...SametarohAssets.careFramesFor(TrainingActionType.work, bodyKey: 'pr'),
      SametarohAssets.completionFrameFor(TrainingActionType.work,
          bodyKey: 'pr'),
    ]) {
      final signatures = <List<int>>[];
      for (final alignment in [Alignment.center, Alignment.bottomCenter]) {
        final image = await _capture(
            tester,
            SametarohFrameImage(
                frame: frame,
                width: frame.canvasSize.width,
                height: frame.canvasSize.height,
                alignment: alignment));
        final data = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        signatures.add(data.toList());
        image.dispose();
      }
      expect(signatures[1], signatures[0], reason: frame.asset);
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

Future<ui.Image> _render(WidgetTester tester, SametarohFrame frame) async {
  if (SametarohCleanWarp.supports(frame)) {
    await tester.runAsync(() => SametarohCleanWarp.prepare(frame));
  }
  return _capture(
      tester,
      SametarohFrameImage(
          frame: frame,
          width: frame.canvasSize.width,
          height: frame.canvasSize.height,
          alignment: Alignment.bottomCenter));
}

Future<ui.Image> _capture(WidgetTester tester, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: RepaintBoundary(key: key, child: child)),
  ));
  await tester.runAsync(() async {
    final warps = tester
        .widgetList<SametarohCleanWarp>(find.byType(SametarohCleanWarp))
        .toList();
    await Future.wait(warps.map((w) => SametarohCleanWarp.prepare(w.frame)));
    final home = tester.widgetList<TrainingHomeIdleRegistration>(
        find.byType(TrainingHomeIdleRegistration));
    await Future.wait(home
        .map((widget) => TrainingHomeIdleRegistration.prepare(widget.frame)));
    final decorations =
        tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    for (final box in decorations) {
      final d = box.decoration;
      if (d is BoxDecoration && d.image != null) {
        await precacheImage(d.image!.image, tester.element(find.byKey(key)));
      }
    }
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    await Future.wait(images.map((image) =>
        precacheImage(image.image, tester.element(find.byKey(key)))));
  });
  await tester.pump();
  return (await tester.runAsync(() =>
      (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
          .toImage(pixelRatio: 1)))!;
}
