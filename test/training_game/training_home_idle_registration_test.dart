import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('未準備ホーム待機も第1コマの正規化座標を保持する', (tester) async {
    final frames = TrainingHomeCharacterFrameSet.forBodyKey('wtb');
    final first = frames.idleFrames.first;
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
            child: TrainingHomeCharacterFrameImage(
                frame: frames.idleFrames[1], width: 128, height: 184))));
    final fallback = find.descendant(
        of: find.byType(TrainingHomeIdleRegistration),
        matching: find.byType(Positioned));
    expect(fallback, findsOneWidget);
    final position = tester.widget<Positioned>(fallback);
    expect(position.left, first.imageOffset.dx);
    expect(position.top, first.imageOffset.dy);
    expect(position.width, first.sourceSize.width);
    expect(position.height, first.sourceSize.height);
    for (var i = 0; i < 20 && fallback.evaluate().isNotEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(fallback, findsNothing);
    expect(
        find.descendant(
            of: find.byType(TrainingHomeIdleRegistration),
            matching: find.byType(RawImage)),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ホーム非歩行WTBの接地輪郭は表示サイズ/DPRを変えてもXYとも0px変位', (tester) async {
    for (final body in ['wtb']) {
      final frames = TrainingHomeCharacterFrameSet.forBodyKey(body);
      await tester.runAsync(() async {
        for (final frame in frames.idleFrames) {
          await TrainingHomeIdleRegistration.prepare(frame);
        }
      });
      for (final size in [
        const Size(128, 184),
        const Size(118, 169),
        const Size(144, 207)
      ]) {
        for (final dpr in [1.0, 3.0]) {
          final key = GlobalKey();
          await tester.pumpWidget(Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                  child: RepaintBoundary(
                      key: key,
                      child: TrainingHomeCharacterAnimation(
                        frameSet: frames,
                        isWalking: false,
                        width: size.width,
                        height: size.height,
                        frameDuration: const Duration(milliseconds: 650),
                        semanticLabel: '鮫太朗',
                      )))));
          await tester.pump();
          final signatures = <List<int>>[];
          for (var i = 0; i < 2; i++) {
            if (i == 1) await tester.pump(const Duration(milliseconds: 650));
            final image = (await tester.runAsync(() => (key.currentContext!
                    .findRenderObject()! as RenderRepaintBoundary)
                .toImage(pixelRatio: dpr)))!;
            final bytes = (await tester.runAsync(() =>
                    image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
                .buffer
                .asUint8List();
            final rows =
                (32 * size.height / frames.canvasSize.height * dpr).floor();
            final footprint = <int>[];
            for (var y = image.height - rows; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                final p = (y * image.width + x) * 4;
                if (bytes[p] < 35 &&
                    bytes[p + 1] > 45 &&
                    bytes[p + 1] < 125 &&
                    bytes[p + 2] > 110 &&
                    bytes[p + 3] > 200) {
                  footprint.add(y * image.width + x);
                }
              }
            }
            expect(footprint, isNotEmpty);
            signatures.add(footprint);
            image.dispose();
          }
          // Full foot-pixel equality, not just bbox or a tolerance on centroids.
          expect(signatures[1], signatures[0], reason: '$body $size DPR$dpr');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });
  testWidgets('SHホームは共通尺度・平行移動だけで原RGBAを保持する', (tester) async {
    final frames = TrainingHomeCharacterFrameSet.forBodyKey('sh');
    expect(frames.idleFrames[0].sourceSize, const Size(194, 345));
    expect(frames.idleFrames[1].sourceSize, const Size(194, 345));
    expect(frames.idleFrames[1].imageOffset - frames.idleFrames[0].imageOffset,
        const Offset(7, 0));
    final anchors = <Offset>[];
    for (var n = 0; n < 2; n++) {
      final frame = frames.idleFrames[n];
      expect(TrainingHomeIdleRegistration.supports(frame), isFalse);
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
              child: RepaintBoundary(
                  key: key,
                  child: TrainingHomeCharacterFrameImage(
                      frame: frame,
                      width: frames.canvasSize.width,
                      height: frames.canvasSize.height)))));
      await tester.runAsync(
          () => precacheImage(AssetImage(frame.asset), key.currentContext!));
      await tester.pump();
      final image = (await tester.runAsync(() =>
          (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
              .toImage()))!;
      final rendered = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      final original = (await tester.runAsync(() async {
        final asset = await rootBundle.load(frame.asset);
        final codec =
            await ui.instantiateImageCodec(asset.buffer.asUint8List());
        final source = (await codec.getNextFrame()).image;
        final data =
            (await source.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        source.dispose();
        codec.dispose();
        return data;
      }))!;
      final expected = Uint8List(rendered.length);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final sx = x - frame.imageOffset.dx.toInt(),
              sy = y - frame.imageOffset.dy.toInt();
          if (sx < 0 || sx >= 194 || sy < 0 || sy >= 345) {
            continue;
          }
          final target = (y * image.width + x) * 4,
              source = (sy * 194 + sx) * 4;
          expected.setRange(target, target + 4, original, source);
        }
      }
      var alphaDifferences = 0, rgbaDifferences = 0;
      for (var i = 0; i < expected.length; i += 4) {
        if (expected[i + 3] != rendered[i + 3]) alphaDifferences++;
        if (List.generate(4, (c) => expected[i + c] != rendered[i + c])
            .any((v) => v)) {
          rgbaDifferences++;
        }
      }
      expect(alphaDifferences, 0, reason: 'SH frame$n original outline');
      expect(rgbaDifferences, 0,
          reason: 'SH frame$n original premultiplied RGBA');
      anchors.add(Offset((n == 0 ? 98.5 : 91.5) + frame.imageOffset.dx,
          335 + frame.imageOffset.dy));
      image.dispose();
    }
    expect(anchors[1], anchors[0]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
