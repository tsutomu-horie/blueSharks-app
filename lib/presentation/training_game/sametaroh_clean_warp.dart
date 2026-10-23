import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sametaroh_asset.dart';
import 'sametaroh_grounded_profiles.dart';
import 'sametaroh_registration_layers.dart';

/// A connected actor surface with independently preserved foreground equipment.
class SametarohCleanWarp extends StatelessWidget {
  const SametarohCleanWarp(
      {required this.frame, this.semanticLabel, super.key});
  final String? semanticLabel;
  final SametarohFrame frame;
  static final _sources = <String, Future<ui.Image>>{};
  static final _rendered = <String, Future<ui.Image>>{};
  static final _ready = <String, ui.Image>{};
  static Future<ui.Image> _cached(Map<String, Future<ui.Image>> cache,
      String asset, Future<ui.Image> Function() create) {
    return cache.putIfAbsent(
        asset,
        () => create().catchError((Object error) {
              cache.remove(asset);
              throw error;
            }));
  }

  static bool _repairsFootOutline(SametarohFrame frame) =>
      frame.asset.contains('/sametaroh/claening_') ||
      frame.asset.contains('/sametaroh/cleaning_') ||
      frame.asset.endsWith('/cleaning_complete_sametaroh.png') ||
      frame.asset.contains('/sh/clean_');
  static bool supports(SametarohFrame frame) =>
      groundedProfiles.containsKey(frame.asset);
  static Future<ui.Image> prepareActor(SametarohFrame frame) =>
      _cached(_sources, frame.asset, () async {
        final data = await rootBundle.load(frame.asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final source = (await codec.getNextFrame()).image;
        codec.dispose();
        if (!registeredFrameLayers.containsKey(frame.asset)) return source;
        final p = groundedProfiles[frame.asset]!;
        final layers = registeredFrameLayers[frame.asset]!;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        if (frame.asset.contains('clean') || frame.asset.contains('claening')) {
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(
              0, p.waist, source.width.toDouble(), source.height.toDouble()));
          canvas.clipPath(registrationPath(layers.staticClip),
              doAntiAlias: false);
          canvas.translate(p.axis * 2, 0);
          canvas.scale(-1, 1);
          canvas.clipPath(registrationPath(layers.dynamicClip),
              doAntiAlias: false);
          if (_repairsFootOutline(frame)) {
            // Reconstruct occluded soles only; never reflect the opposite tail.
            final soles = Path();
            for (var i = 0; i < p.rows.length; i += 9) {
              final y = p.rows[i];
              soles.addRect(Rect.fromLTRB(
                  p.rows[i + 1] - 1, y - 1, p.rows[i + 2] + 1, y + 2));
              soles.addRect(Rect.fromLTRB(
                  p.rows[i + 3] - 1, y - 1, p.rows[i + 4] + 1, y + 2));
            }
            canvas.clipPath(soles, doAntiAlias: false);
          }
          canvas.drawImage(source, Offset.zero, Paint());
          canvas.restore();
        }
        canvas.clipPath(registrationPath(layers.dynamicClip),
            doAntiAlias: false);
        canvas.drawImage(source, Offset.zero, Paint());
        final picture = recorder.endRecording();
        final image = await picture.toImage(source.width, source.height);
        picture.dispose();
        source.dispose();
        return image;
      });
  static SametarohFrame _first(String asset) => [
        ...SametarohAssets.suppliedFrames.values,
        ...SametarohAssets.careFrames.values.expand((f) => f),
        ...SametarohAssets.completionFrames.values,
      ].firstWhere((f) => f.asset == asset);
  static Future<ui.Image> prepare(SametarohFrame frame) =>
      _cached(_rendered, frame.asset, () async {
        final p = groundedProfiles[frame.asset]!;
        final image = await prepareActor(frame);
        final reference = await prepareActor(_first(p.first));
        final w = frame.canvasSize.width.ceil(),
            h = frame.canvasSize.height.ceil();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.translate((frame.canvasSize.width - image.width) / 2,
            frame.canvasSize.height - image.height);
        _BodyMesh(image, frame, p).paint(canvas, frame.sourceSize);
        final picture = recorder.endRecording();
        final warped = await picture.toImage(w, h);
        picture.dispose();
        final rr = ui.PictureRecorder();
        Canvas(rr).drawImage(
            reference,
            Offset((frame.canvasSize.width - reference.width) / 2,
                frame.canvasSize.height - reference.height),
            Paint());
        final rp = rr.endRecording();
        final canonical = await rp.toImage(w, h);
        rp.dispose();
        if (frame.asset.contains('work')) {
          canonical.dispose();
          _ready[frame.asset] = warped;
          return warped;
        }
        final bytes =
            (await warped.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        final alpha =
            (await canonical.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        final floor =
            (p.targetFloor + frame.canvasSize.height - reference.height)
                .round();
        // Normalize the contact coverage in this same actor image. No separate leg
        // layer, horizontal clip or torso/leg seam is introduced. Upper coverage
        // transitions smoothly; source color is premultiplied by the final alpha.
        final clean =
            frame.asset.contains('clean') || frame.asset.contains('claening');
        final contactStart = floor - (clean ? 36 : 14);
        final transitionHeight = clean ? 12 : 8;
        for (var y = contactStart.clamp(0, h);
            y < (floor + 3).clamp(0, h);
            y++) {
          final t = ((y - contactStart) / transitionHeight).clamp(0.0, 1.0);
          final blend = t * t * (3 - 2 * t);
          for (var x = 0; x < w; x++) {
            final i = (y * w + x) * 4;
            bool footPixel(int r, int g, int b, int alpha) {
              if (alpha == 0) return false;
              final red = r * 255 / alpha,
                  green = g * 255 / alpha,
                  blue = b * 255 / alpha;
              final repair = _repairsFootOutline(frame);
              // The original broom/sole antialias boundary is (66,119,155).
              // It is sole coverage, not a transparent hole.
              return red < (repair ? 80 : 60) &&
                  green > 45 &&
                  green < (repair ? 145 : 140) &&
                  blue > 110 &&
                  blue > green + (repair ? 25 : 35);
            }

            final sourceFoot =
                footPixel(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
            final targetFoot =
                footPixel(alpha[i], alpha[i + 1], alpha[i + 2], alpha[i + 3]);
            // Preserve non-foot pixels, including resting equipment.
            if (!sourceFoot && !targetFoot) continue;
            final a = (bytes[i + 3] * (1 - blend) +
                    (targetFoot ? alpha[i + 3] : 0) * blend)
                .round();
            bytes[i] = (24 * a / 255).round();
            bytes[i + 1] = (83 * a / 255).round();
            bytes[i + 2] = (149 * a / 255).round();
            bytes[i + 3] = a;
          }
        }
        final result = Completer<ui.Image>();
        ui.decodeImageFromPixels(
            bytes, w, h, ui.PixelFormat.rgba8888, result.complete);
        warped.dispose();
        canonical.dispose();
        final rendered = await result.future;
        _ready[frame.asset] = rendered;
        return rendered;
      });
  @override
  Widget build(BuildContext context) {
    final p = groundedProfiles[frame.asset]!;
    final layers = registeredFrameLayers[frame.asset];
    final squat =
        p.first.contains('squat') || p.first.contains('training_sametaroh');
    final done =
        frame.asset.contains('_done') || frame.asset.contains('complete');
    final propX = squat && done
        ? groundedProfiles[p.first]!.axis -
            p.axis +
            (frame.sourceSize.width - p.targetWidth) / 2
        : p.upperX;
    return FutureBuilder<ui.Image>(
      key: ValueKey(frame.asset),
      initialData: _ready[frame.asset],
      future: prepare(frame),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox.fromSize(
              size: frame.sourceSize,
              child: Image.asset(frame.asset,
                  fit: BoxFit.fill, semanticLabel: semanticLabel),
            ),
          );
        }
        return Semantics(
          label: semanticLabel,
          image: true,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                child: snapshot.hasData
                    ? RawImage(image: snapshot.data, fit: BoxFit.fill)
                    : const SizedBox.shrink()),
            if (layers != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(propX, 0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox.fromSize(
                      size: frame.sourceSize,
                      child: ClipPath(
                        clipper: _BroomClip(layers.staticClip),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(frame.asset,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                            excludeFromSemantics: true),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _BroomClip extends CustomClipper<Path> {
  const _BroomClip(this.runs);
  final List<int> runs;
  @override
  Path getClip(Size size) => registrationPath(runs);
  @override
  bool shouldReclip(_BroomClip old) => old.runs != runs;
}

class _BodyMesh extends CustomPainter {
  _BodyMesh(this.image, this.frame, this.profile);
  final ui.Image image;
  final SametarohFrame frame;
  final GroundedProfile profile;
  @override
  void paint(Canvas canvas, Size size) {
    final p = profile;
    final positions = <Offset>[], texture = <Offset>[];
    final indices = <int>[];
    const cols = 6;
    final isWork = frame.asset.contains('work');
    final compensation = (image.width - p.targetWidth) / 2;
    final targetFloor = p.targetFloor + image.height - p.targetHeight;
    for (var y = 0; y <= image.height; y++) {
      final t = ((y - p.waist) / (p.floor - 16 - p.waist)).clamp(0.0, 1.0);
      final smooth = t * t * (3 - 2 * t);
      final footDx =
          (p.rows.isNotEmpty ? p.rows[5] - p.rows[1] + compensation : p.upperX);
      final dx = isWork
          ? p.upperX + (frame.registrationX - p.upperX) * smooth
          : p.upperX + (footDx - p.upperX) * smooth;
      List<double>? row;
      if (p.rows.isNotEmpty) {
        var nearest = 0;
        var distance = double.infinity;
        for (var j = 0; j < p.rows.length; j += 9) {
          final d = (p.rows[j] - y).abs();
          if (d < distance) {
            distance = d;
            nearest = j;
          }
        }
        row = p.rows.sublist(nearest, nearest + 9);
      }
      final sources = row == null
          ? [
              0.0,
              image.width * .2,
              image.width * .4,
              image.width * .6,
              image.width * .8,
              image.width.toDouble()
            ]
          : [0.0, ...row.sublist(1, 5), image.width.toDouble()];
      final c =
          ((y - (p.waist + 5)) / (p.floor - 16 - p.waist - 5)).clamp(0.0, 1.0);
      final blend = c * c * (3 - 2 * c);
      for (var col = 0; col < cols; col++) {
        final x = sources[col];
        final target = row != null && col > 0 && col < 5
            ? row[col + 4] + compensation
            : x + dx;
        positions.add(Offset((x + dx) * (1 - blend) + target * blend,
            y + (isWork ? 0 : (targetFloor - p.floor) * smooth)));
        texture.add(Offset(x, y.toDouble()));
      }
      if (y < image.height) {
        for (var col = 0; col < cols - 1; col++) {
          final i = y * cols + col;
          indices.addAll([i, i + 1, i + cols, i + 1, i + cols + 1, i + cols]);
        }
      }
    }
    final vertices = ui.Vertices(ui.VertexMode.triangles, positions,
        textureCoordinates: texture, indices: indices);
    canvas.drawVertices(
        vertices,
        BlendMode.srcOver,
        Paint()
          ..shader = ui.ImageShader(
              image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage)
          ..filterQuality = FilterQuality.low);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(_BodyMesh old) => old.image != image || old.frame != frame;
}
