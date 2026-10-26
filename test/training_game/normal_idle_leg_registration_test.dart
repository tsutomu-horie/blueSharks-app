import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

class _LegMaskMetrics {
  const _LegMaskMetrics({
    required this.pixels,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.centroidX,
    required this.centroidY,
  });

  final Set<int> pixels;
  final int left;
  final int top;
  final int right;
  final int bottom;
  final double centroidX;
  final double centroidY;

  int get width => right - left;
  int get height => bottom - top;
}

_LegMaskMetrics _measureBlueMask(
  List<int> rgba, {
  required int imageWidth,
  required int imageHeight,
  required int xStart,
  required int xEnd,
  required int bandHeight,
}) {
  final yStart = imageHeight - bandHeight;
  final pixels = <int>{};
  var left = imageWidth;
  var top = imageHeight;
  var right = 0;
  var bottom = 0;
  var sumX = 0.0;
  var sumY = 0.0;
  for (var y = yStart; y < imageHeight; y++) {
    for (var x = xStart; x < xEnd; x++) {
      final i = (y * imageWidth + x) * 4;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final a = rgba[i + 3];
      if (a <= 80 || r >= 45 || g <= 45 || g >= 145 || b <= 115) continue;
      pixels.add(y * imageWidth + x);
      if (x < left) left = x;
      if (y < top) top = y;
      if (x + 1 > right) right = x + 1;
      if (y + 1 > bottom) bottom = y + 1;
      sumX += x;
      sumY += y;
    }
  }
  if (pixels.isEmpty) throw StateError('No leg pixels in rendered mask');
  return _LegMaskMetrics(
    pixels: pixels,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    centroidX: sumX / pixels.length,
    centroidY: sumY / pixels.length,
  );
}

double _maskIoU(_LegMaskMetrics a, _LegMaskMetrics b) {
  final smaller = a.pixels.length < b.pixels.length ? a.pixels : b.pixels;
  final larger = identical(smaller, a.pixels) ? b.pixels : a.pixels;
  var intersection = 0;
  for (final pixel in smaller) {
    if (larger.contains(pixel)) intersection++;
  }
  return intersection / (a.pixels.length + b.pixels.length - intersection);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ノーマル待機の脚輪郭は実表示サイズと各DPRで水平登録を保つ', (tester) async {
    final frames = TrainingHomeCharacterFrameSet.forBodyKey(null);
    const sizes = [
      Size(128, 184),
      Size(118, 169),
      Size(144, 207),
    ];
    for (final size in sizes) {
      final fitScale = math.min(
        size.width / frames.canvasSize.width,
        size.height / frames.canvasSize.height,
      );
      for (final dpr in [1.0, 2.0, 3.0]) {
        final masks = <List<bool>>[];
        final lowerLegs = <List<_LegMaskMetrics>>[];
        final soles = <List<_LegMaskMetrics>>[];
        var maskWidth = 0;
        var maskHeight = 0;
        for (var i = 0; i < frames.idleFrames.length; i++) {
          final frame = frames.idleFrames[i];
          final sourceFrame = SametarohAssets.normalFrames[i];
          final sourceScale =
              frame.sourceSize.width / sourceFrame.sourceSize.width;
          expect(sourceScale, 1.0,
              reason: '$size DPR$dpr frame${i + 1}: preserve source scale');

          final key = GlobalKey();
          await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: TrainingHomeCharacterFrameImage(
                  frame: frame,
                  width: size.width,
                  height: size.height,
                ),
              ),
            ),
          ));
          await tester.runAsync(() =>
              precacheImage(AssetImage(frame.asset), key.currentContext!));
          await tester.pump();
          final image = (await tester.runAsync(() =>
              (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                  .toImage(pixelRatio: dpr)))!;
          final bytes = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
              .buffer
              .asUint8List();
          expect(frame.sourceSize.height / sourceFrame.sourceSize.height, 1.0,
              reason: '$size DPR$dpr frame${i + 1}: preserve source height');
          if (size == sizes.first && dpr == 3.0) {
            final output = io.Platform.environment['NORMAL_IDLE_RENDER_OUTPUT'];
            if (output != null) {
              final png = (await tester.runAsync(
                      () => image.toByteData(format: ui.ImageByteFormat.png)))!
                  .buffer
                  .asUint8List();
              io.Directory(output).createSync(recursive: true);
              io.File('$output/frame_$i.png').writeAsBytesSync(png);
            }
          }
          maskWidth = (72 * size.height / 184 * dpr).round();
          maskHeight = (20 * size.height / 184 * dpr).round();
          final left = (image.width - maskWidth) ~/ 2;
          final top = image.height - maskHeight;
          masks.add([
            for (var y = top; y < image.height; y++)
              for (var x = left; x < left + maskWidth; x++)
                bytes[(y * image.width + x) * 4 + 3] > 128,
          ]);
          final halfWidth = image.width ~/ 2;
          final bandHeight = (52 * fitScale * dpr).round();
          final soleBandHeight = (22 * fitScale * dpr).round();
          lowerLegs.add([
            _measureBlueMask(
              bytes,
              imageWidth: image.width,
              imageHeight: image.height,
              xStart: 0,
              xEnd: halfWidth,
              bandHeight: bandHeight,
            ),
            _measureBlueMask(
              bytes,
              imageWidth: image.width,
              imageHeight: image.height,
              xStart: halfWidth,
              xEnd: image.width,
              bandHeight: bandHeight,
            ),
          ]);
          soles.add([
            _measureBlueMask(
              bytes,
              imageWidth: image.width,
              imageHeight: image.height,
              xStart: 0,
              xEnd: halfWidth,
              bandHeight: soleBandHeight,
            ),
            _measureBlueMask(
              bytes,
              imageWidth: image.width,
              imageHeight: image.height,
              xStart: halfWidth,
              xEnd: image.width,
              bandHeight: soleBandHeight,
            ),
          ]);
          image.dispose();
        }

        final scores = <int, double>{};
        for (var dx = -2; dx <= 2; dx++) {
          var intersection = 0;
          var union = 0;
          for (var y = 0; y < maskHeight; y++) {
            for (var x = 0; x < maskWidth; x++) {
              final first = masks[0][y * maskWidth + x];
              final secondX = x + dx;
              final second = secondX >= 0 && secondX < maskWidth
                  ? masks[1][y * maskWidth + secondX]
                  : false;
              if (first && second) intersection++;
              if (first || second) union++;
            }
          }
          scores[dx] = intersection / union;
        }
        final bestShift =
            scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        expect(bestShift, 0,
            reason: '$size DPR$dpr: best leg-mask shift; IoU=$scores');
        for (var side = 0; side < 2; side++) {
          final first = lowerLegs[0][side];
          final second = lowerLegs[1][side];
          expect(_maskIoU(first, second), greaterThanOrEqualTo(0.98),
              reason: '$size DPR$dpr leg${side + 1}: outline IoU');
          expect((second.centroidX - first.centroidX).abs(), lessThan(0.5),
              reason: '$size DPR$dpr leg${side + 1}: rendered X centroid');
          expect((second.centroidY - first.centroidY).abs(), lessThan(0.5),
              reason: '$size DPR$dpr leg${side + 1}: rendered Y centroid');
          expect((second.width - first.width).abs(), lessThanOrEqualTo(3),
              reason: '$size DPR$dpr leg${side + 1}: rendered width');
          expect((second.height - first.height).abs(), lessThanOrEqualTo(1),
              reason: '$size DPR$dpr leg${side + 1}: rendered height');

          final firstSole = soles[0][side];
          final secondSole = soles[1][side];
          expect(_maskIoU(firstSole, secondSole), greaterThanOrEqualTo(0.98),
              reason: '$size DPR$dpr foot${side + 1}: sole outline IoU');
          expect(
              (secondSole.centroidX - firstSole.centroidX).abs(), lessThan(0.5),
              reason:
                  '$size DPR$dpr foot${side + 1}: rendered sole X centroid');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('共通canvasを維持しつつ歩行2コマの描画RGBAを保つ', (tester) async {
    final currentSet = TrainingHomeCharacterFrameSet.forBodyKey(null);
    const sizes = [
      Size(128, 184),
      Size(118, 169),
      Size(144, 207),
    ];
    const walkAlphaBounds = [
      Rect.fromLTRB(1, 0, 160, 302),
      Rect.fromLTRB(1, 0, 161, 302),
    ];
    const walkImageSizes = [Size(160, 303), Size(161, 303)];
    const previousNormalizationScale = 302 / 301;
    final previousCanvas = Size(
      2 *
          math.max(
            (87.0 - 7) * previousNormalizationScale,
            (166 - 87.0) * previousNormalizationScale,
          ),
      302,
    );

    Future<List<int>> renderPixels(
      TrainingHomeCharacterFrame frame,
      Size size,
      double dpr,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: TrainingHomeCharacterFrameImage(
              frame: frame,
              width: size.width,
              height: size.height,
            ),
          ),
        ),
      ));
      await tester.runAsync(
          () => precacheImage(AssetImage(frame.asset), key.currentContext!));
      await tester.pump();
      final image = (await tester.runAsync(() =>
          (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
              .toImage(pixelRatio: dpr)))!;
      final bytes = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
          .buffer
          .asUint8List();
      image.dispose();
      return bytes;
    }

    for (var i = 0; i < currentSet.walkFrames.length; i++) {
      final frame = currentSet.walkFrames[i];
      final source = SametarohAssets.journeyFrames[i];
      final imageSize = walkImageSizes[i];
      final bounds = walkAlphaBounds[i];
      final alpha = Rect.fromLTRB(
        bounds.left * source.sourceSize.width / imageSize.width,
        bounds.top * source.sourceSize.height / imageSize.height,
        bounds.right * source.sourceSize.width / imageSize.width,
        bounds.bottom * source.sourceSize.height / imageSize.height,
      );
      final imageLeft = (previousCanvas.width - alpha.width) / 2 - alpha.left;
      final previousFrame = TrainingHomeCharacterFrame(
        asset: source.asset,
        sourceSize: source.sourceSize,
        canvasSize: previousCanvas,
        imageOffset: Offset(imageLeft, 302 - alpha.bottom),
        visibleBounds:
            Rect.fromLTWH(imageLeft + alpha.left, 0, alpha.width, 302),
      );

      expect(frame.sourceSize, source.sourceSize);
      expect(frame.canvasSize, currentSet.canvasSize,
          reason: 'walk${i + 1}: shared idle/walk canvas contract');
      expect(frame.renderCanvasSize, previousCanvas,
          reason: 'walk${i + 1}: retain the prior raster viewport inside it');
      expect(
        currentSet.idleFrames.every(
            (idleFrame) => idleFrame.canvasSize == currentSet.canvasSize),
        isTrue,
        reason: 'walk${i + 1}: idle frames use the same shared canvas',
      );
      for (final size in sizes) {
        for (final dpr in [1.0, 2.0, 3.0]) {
          final previousPixels = await renderPixels(previousFrame, size, dpr);
          final currentPixels = await renderPixels(frame, size, dpr);
          expect(currentPixels, equals(previousPixels),
              reason: 'walk${i + 1} $size DPR$dpr rendered RGBA');
        }
      }
    }
  });
}
