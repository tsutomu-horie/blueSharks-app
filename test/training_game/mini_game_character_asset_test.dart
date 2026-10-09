import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_character_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('4姿勢の全12倍率画像がbundleに存在し、透過余白を保持する', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final pose in MiniGameCharacterPose.values) {
      expect(manifest.listAssets(), contains(pose.assetPath));
      final variants = manifest.getAssetVariants(pose.assetPath)!;
      expect(
          variants.map((variant) => variant.key),
          containsAll([
            pose.assetPath,
            pose.assetPath.replaceFirst('minigames/', 'minigames/2.0x/'),
            pose.assetPath.replaceFirst('minigames/', 'minigames/3.0x/'),
          ]));
      for (var scale = 1; scale <= 3; scale++) {
        final path = scale == 1
            ? pose.assetPath
            : pose.assetPath.replaceFirst('minigames/', 'minigames/$scale.0x/');
        final bytes = await rootBundle.load(path);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 38 * scale);
        expect(image.height, 72 * scale);
        final rgba =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final data = rgba.buffer.asUint8List();
        var opaquePixels = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final alpha = data[(y * image.width + x) * 4 + 3];
            if (x == 0 ||
                y == 0 ||
                x == image.width - 1 ||
                y == image.height - 1) {
              expect(alpha, 0, reason: '$path の縁に背景/切欠けがある');
            }
            if (alpha == 255) opaquePixels++;
          }
        }
        expect(opaquePixels, greaterThan(image.width * image.height ~/ 5));
        image.dispose();
        codec.dispose();
      }
    }
  });

  test('パスの往復と送受球だけで提供済み4姿勢を選ぶ', () {
    expect(MiniGameCharacterPose.forPass(outbound: true, passing: false),
        MiniGameCharacterPose.rightRest);
    expect(MiniGameCharacterPose.forPass(outbound: true, passing: true),
        MiniGameCharacterPose.rightReach);
    expect(MiniGameCharacterPose.forPass(outbound: false, passing: true),
        MiniGameCharacterPose.leftReach);
    expect(MiniGameCharacterPose.forPass(outbound: false, passing: false),
        MiniGameCharacterPose.leftRest);
  });

  for (final fontSize in [44.0, 52.0, 72.0]) {
    testWidgets('画像が元emojiの領域と入力透過を保持する: $fontSize', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            Text('🦈',
                key: const Key('legacy'), style: TextStyle(fontSize: fontSize)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: MiniGameCharacterAsset(
                key: const Key('image-player'),
                pose: MiniGameCharacterPose.rightRest,
                fontSize: fontSize,
              ),
            ),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('image-player'))),
          tester.getSize(find.byKey(const Key('legacy'))));
      await tester
          .tapAt(tester.getCenter(find.byKey(const Key('image-player'))));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
