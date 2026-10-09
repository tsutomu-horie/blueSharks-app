import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('お世話5種に行動中フレームと完了フレームが割り当てられている', () {
    const careActions = [
      TrainingActionType.meal,
      TrainingActionType.clean,
      TrainingActionType.rest,
      TrainingActionType.squat,
      TrainingActionType.work,
    ];

    for (final action in careActions) {
      final frames = SametarohAssets.careFramesFor(action);
      final completion = SametarohAssets.completionFrameFor(action);
      expect(frames, isNotEmpty);
      expect(completion.asset, isNotEmpty);
      expect(frames.map((frame) => frame.canvasSize).toSet(), hasLength(1));
      expect(completion.canvasSize, frames.first.canvasSize);
    }

    final mealFrames = SametarohAssets.careFramesFor(TrainingActionType.meal);
    expect(
      mealFrames.map((frame) => frame.asset),
      [
        'assets/images/sametaroh/eating_sametaroh_1.png',
        'assets/images/sametaroh/eating_sametaroh_2.png',
      ],
    );
    expect(
      SametarohAssets.initialFrames[TrainingActionType.meal]?.asset,
      'assets/images/sametaroh/eating_sametaroh_start.png',
    );
  });

  test('通常画面と旅立ち画面に2フレームずつ割り当てられている', () {
    expect(SametarohAssets.normalFrames, hasLength(2));
    expect(SametarohAssets.journeyFrames, hasLength(2));
    expect(
      SametarohAssets.normalFrames.map((frame) => frame.canvasSize).toSet(),
      hasLength(1),
    );
    expect(
      SametarohAssets.journeyFrames.map((frame) => frame.canvasSize).toSet(),
      hasLength(1),
    );
  });

  test('本編72画像はpubspec由来のAssetBundleに収録され、原PNGとbyte一致する', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundledMainAssets = manifest
        .listAssets()
        .where((path) => path.startsWith('assets/images/training_game/main/'))
        .toSet();
    expect(
        bundledMainAssets,
        SametarohAssets.suppliedFrames.values
            .map((frame) => frame.asset)
            .toSet());
    for (final frame in SametarohAssets.suppliedFrames.values) {
      final data = await rootBundle.load(frame.asset);
      expect(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          File(frame.asset).readAsBytesSync(),
          reason: frame.asset);
    }
  });

  test('支給72画像が標準bundleから宣言実寸でdecodeでき、透明余白と白内部を保持する', () async {
    expect(SametarohAssets.suppliedFrames, hasLength(72));
    for (final entry in SametarohAssets.suppliedFrames.entries) {
      final frame = entry.value;
      final file = File(frame.asset);
      expect(file.existsSync(), isTrue, reason: entry.key);
      final bundledData = await rootBundle.load(frame.asset);
      final codec = await ui.instantiateImageCodec(bundledData.buffer
          .asUint8List(bundledData.offsetInBytes, bundledData.lengthInBytes));
      final info = await codec.getNextFrame();
      final image = info.image;
      expect(image.width, frame.sourceSize.width, reason: entry.key);
      expect(image.height, frame.sourceSize.height, reason: entry.key);
      expect(frame.sourceSize.width <= frame.canvasSize.width, isTrue);
      expect(frame.sourceSize.height <= frame.canvasSize.height, isTrue);
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      var opaqueWhite = 0;
      var partialAlpha = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final offset = (y * image.width + x) * 4;
          final alpha = data[offset + 3];
          if (x == 0 ||
              y == 0 ||
              x == image.width - 1 ||
              y == image.height - 1) {
            expect(alpha, 0, reason: '${entry.key} border ($x,$y)');
          }
          if (alpha == 255 &&
              data[offset] > 240 &&
              data[offset + 1] > 240 &&
              data[offset + 2] > 240) {
            opaqueWhite++;
          }
          if (alpha > 0 && alpha < 255) {
            partialAlpha++;
          }
        }
      }
      expect(opaqueWhite, greaterThan(0), reason: entry.key);
      expect(partialAlpha, greaterThan(0), reason: entry.key);
      image.dispose();
      codec.dispose();
    }
  });

  test('同じbodyは再buildで同一連番を保持し、未知bodyはnormalに戻る', () {
    for (final body in SametarohAssets.supportedBodyKeys) {
      expect(
          identical(SametarohAssets.idleFramesForBodyKey(body),
              SametarohAssets.idleFramesForBodyKey(body)),
          isTrue);
      for (final action in SametarohAssets.careFrames.keys) {
        final frames = SametarohAssets.careFramesFor(action, bodyKey: body);
        expect(
            identical(
                frames, SametarohAssets.careFramesFor(action, bodyKey: body)),
            isTrue);
        expect(frames, hasLength(2));
        expect(frames.map((f) => f.canvasSize).toSet(), hasLength(1));
        expect(
            SametarohAssets.completionFrameFor(action, bodyKey: body)
                .canvasSize,
            frames.first.canvasSize);
        expect(() => frames.add(frames.first), throwsUnsupportedError);
      }
    }
    expect(SametarohAssets.idleFramesForBodyKey('unknown'),
        same(SametarohAssets.normalFrames));
    expect(
        SametarohAssets.careFramesFor(TrainingActionType.work,
            bodyKey: 'unknown'),
        same(SametarohAssets.careFrames[TrainingActionType.work]));
  });

  test('SH/SOは原本1図を共用し、未知positionは既存表示へ戻る', () {
    expect(SametarohAssets.positionFrameFor('スクラムハーフ'),
        same(SametarohAssets.positionFrameFor('スタンドオフ')));
    expect(SametarohAssets.positionFrameFor('判定前'), isNull);
    expect(SametarohAssets.positionFrameFor('UNKNOWN'), isNull);
    expect(SametarohAssets.positionFrameFor('プロップ')?.asset,
        endsWith('/jersey/prop_plain.png'));
  });

  test('本人採用の3大別に対応し、未判定・未知値から体形を推測しない', () {
    expect(SametarohAssets.bodyKeyForBranch('A フォワード型'), 'pr');
    expect(SametarohAssets.bodyKeyForBranch('B 司令塔型'), 'sh');
    expect(SametarohAssets.bodyKeyForBranch('C バックス型'), 'wtb');
    expect(SametarohAssets.bodyKeyForBranch(null), isNull);
    expect(SametarohAssets.bodyKeyForBranch('UNKNOWN'), isNull);
  });
}
