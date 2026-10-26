import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sametaroh_asset.dart';

typedef TrainingHomeWalkPreparation = Future<bool> Function(
  BuildContext context,
);

/// Idle中のキャラクターを、ときどき短く歩かせるための表示枠です。
///
/// [prepareWalk] が終わるまでキャラクターの位置と表示状態は変えません。
class TrainingHomeRoamingCharacter extends StatefulWidget {
  const TrainingHomeRoamingCharacter({
    required this.builder,
    required this.width,
    required this.height,
    this.prepareWalk,
    this.preparationKey,
    this.travelDistance = 32,
    this.idleDuration = const Duration(seconds: 6),
    this.walkDuration = const Duration(milliseconds: 1400),
    this.enabled = true,
    this.random,
    super.key,
  });

  /// 第二引数は現在の歩行状態です。
  final Widget Function(BuildContext context, bool isWalking) builder;
  final TrainingHomeWalkPreparation? prepareWalk;

  /// 歩行素材のセットが切り替わったとき、古い先読みを無効にします。
  final Object? preparationKey;
  final double width;
  final double height;
  final double travelDistance;
  final Duration idleDuration;
  final Duration walkDuration;
  final bool enabled;
  final math.Random? random;

  @override
  State<TrainingHomeRoamingCharacter> createState() =>
      _TrainingHomeRoamingCharacterState();
}

class _TrainingHomeRoamingCharacterState
    extends State<TrainingHomeRoamingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _idleTimer;
  bool _isWalking = false;
  late final math.Random _random = widget.random ?? math.Random();
  double _maxOffset = 0;
  double _speedScale = 1;
  int _preparationGeneration = 0;
  double _fromOffset = 0;
  double _toOffset = 0;
  double _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.walkDuration,
    );
    if (widget.enabled) _scheduleNextWalk();
  }

  @override
  void didUpdateWidget(covariant TrainingHomeRoamingCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.walkDuration != widget.walkDuration) {
      _controller.duration = widget.walkDuration;
    }
    final preparationChanged =
        oldWidget.preparationKey != widget.preparationKey;
    final enabledChanged = oldWidget.enabled != widget.enabled;
    if (preparationChanged || (enabledChanged && !widget.enabled)) {
      _preparationGeneration++;
      _idleTimer?.cancel();
      _idleTimer = null;
      _controller.stop();
      _isWalking = false;
      _speedScale = 1;
      _fromOffset = 0;
      _toOffset = 0;
      _currentOffset = 0;
    }
    if (enabledChanged && widget.enabled) {
      _scheduleNextWalk();
      return;
    }
    if (preparationChanged && widget.enabled) _scheduleNextWalk();
  }

  void _scheduleNextWalk() {
    _idleTimer?.cancel();
    if (!widget.enabled) return;
    _idleTimer = Timer(widget.idleDuration, _startWalk);
  }

  Future<void> _startWalk() async {
    if (!mounted || !widget.enabled || _isWalking) return;
    final generation = ++_preparationGeneration;
    try {
      final prepared = await widget.prepareWalk?.call(context) ?? true;
      if (!prepared) {
        if (mounted && widget.enabled && generation == _preparationGeneration) {
          _scheduleNextWalk();
        }
        return;
      }
    } catch (_) {
      if (mounted && widget.enabled && generation == _preparationGeneration) {
        _scheduleNextWalk();
      }
      return;
    }
    if (!mounted || !widget.enabled || generation != _preparationGeneration) {
      return;
    }

    if (_maxOffset <= 0 || widget.travelDistance <= 0) {
      _scheduleNextWalk();
      return;
    }
    _fromOffset = _currentOffset.clamp(-_maxOffset, _maxOffset).toDouble();
    final edgeMargin = math.min(widget.travelDistance * 0.35, _maxOffset);
    final goRight = _fromOffset <= -_maxOffset + edgeMargin
        ? true
        : _fromOffset >= _maxOffset - edgeMargin
            ? false
            : _random.nextBool();
    final available =
        goRight ? _maxOffset - _fromOffset : _fromOffset + _maxOffset;
    final maxStep = math.min(available, widget.travelDistance * 1.25);
    final distance = maxStep * (0.35 + _random.nextDouble() * 0.65);
    _toOffset = _fromOffset + (goRight ? distance : -distance);
    // 長い一歩ほど速くし、既存速度の1.25倍（若干早歩き）を上限にします。
    _speedScale = 0.65 + 0.6 * distance / (widget.travelDistance * 1.25);
    _controller.duration = Duration(
      microseconds: math.max(
        1,
        (widget.walkDuration.inMicroseconds *
                distance /
                widget.travelDistance /
                _speedScale)
            .round(),
      ),
    );
    setState(() => _isWalking = true);
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || !widget.enabled) return;
    _currentOffset = _toOffset;
    setState(() => _isWalking = false);
    _scheduleNextWalk();
  }

  @override
  void dispose() {
    _preparationGeneration++;
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxOffset = math.max(
            0.0,
            math.min(
              widget.travelDistance,
              (constraints.maxWidth - widget.width) / 2,
            ),
          );
          _maxOffset = maxOffset;
          final fromOffset =
              _fromOffset.clamp(-maxOffset, maxOffset).toDouble();
          final toOffset = _toOffset.clamp(-maxOffset, maxOffset).toDouble();
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final offset =
                      fromOffset + (toOffset - fromOffset) * _controller.value;
                  return Positioned(
                    left: (constraints.maxWidth - widget.width) / 2 + offset,
                    bottom: 0,
                    width: widget.width,
                    height: widget.height,
                    child: _TrainingHomeWalkTempo(
                      speedScale: _isWalking ? _speedScale : 1,
                      child: Builder(
                        builder: (context) =>
                            widget.builder(context, _isWalking),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainingHomeWalkTempo extends InheritedWidget {
  const _TrainingHomeWalkTempo({
    required this.speedScale,
    required super.child,
  });

  final double speedScale;

  @override
  bool updateShouldNotify(_TrainingHomeWalkTempo oldWidget) =>
      speedScale != oldWidget.speedScale;
}

/// 既存PNGの透明余白を吸収し、idle／walk間で実際の絵の高さと足元を揃えます。
class TrainingHomeCharacterFrameSet {
  // Preserve the pre-normalization walk raster inside the shared 161px
  // external canvas. The legacy-width viewport is centered within it.
  static const _normalWalkRenderWidth = 2 * 80 * 302 / 301;

  TrainingHomeCharacterFrameSet._({
    required this.bodyKey,
    required this.idleFrames,
    required this.walkFrames,
    required this.canvasSize,
  });

  static final Map<String, TrainingHomeCharacterFrameSet> _cache = {};

  // PNGのアルファ境界。描画された部分だけを基準に拡大率と足元を揃えます。
  static const _opaquePixels = <String, _OpaqueAssetPixels>{
    'assets/images/sametaroh/normal_sameraroh_1.png': _OpaqueAssetPixels(
      imageSize: Size(144, 323),
      bounds: Rect.fromLTRB(1, 20, 144, 322),
    ),
    'assets/images/sametaroh/normal_sametaroh_2.png': _OpaqueAssetPixels(
      imageSize: Size(166, 323),
      bounds: Rect.fromLTRB(7, 21, 166, 322),
    ),
    'assets/images/sametaroh/walk_sametaroh_1.png': _OpaqueAssetPixels(
      imageSize: Size(160, 303),
      bounds: Rect.fromLTRB(1, 0, 160, 302),
    ),
    'assets/images/sametaroh/walk_sametaroh_2.png': _OpaqueAssetPixels(
      imageSize: Size(161, 303),
      bounds: Rect.fromLTRB(1, 0, 161, 302),
    ),
    'assets/images/training_game/main/pr/idle_1.png': _OpaqueAssetPixels(
      imageSize: Size(224, 356),
      bounds: Rect.fromLTRB(6, 6, 217, 350),
    ),
    'assets/images/training_game/main/pr/idle_2.png': _OpaqueAssetPixels(
      imageSize: Size(224, 354),
      bounds: Rect.fromLTRB(6, 5, 217, 348),
    ),
    'assets/images/training_game/main/pr/move_1.png': _OpaqueAssetPixels(
      imageSize: Size(196, 312),
      bounds: Rect.fromLTRB(6, 6, 191, 306),
    ),
    'assets/images/training_game/main/pr/move_2.png': _OpaqueAssetPixels(
      imageSize: Size(196, 312),
      bounds: Rect.fromLTRB(5, 6, 190, 306),
    ),
    'assets/images/training_game/main/sh/idle_1.png': _OpaqueAssetPixels(
      imageSize: Size(194, 345),
      bounds: Rect.fromLTRB(8, 8, 186, 337),
    ),
    'assets/images/training_game/main/sh/idle_2.png': _OpaqueAssetPixels(
      imageSize: Size(194, 345),
      bounds: Rect.fromLTRB(8, 8, 186, 337),
    ),
    'assets/images/training_game/main/sh/move_1.png': _OpaqueAssetPixels(
      imageSize: Size(172, 306),
      bounds: Rect.fromLTRB(7, 7, 165, 299),
    ),
    'assets/images/training_game/main/sh/move_2.png': _OpaqueAssetPixels(
      imageSize: Size(170, 306),
      bounds: Rect.fromLTRB(6, 7, 164, 299),
    ),
    'assets/images/training_game/main/wtb/idle_1.png': _OpaqueAssetPixels(
      imageSize: Size(160, 342),
      bounds: Rect.fromLTRB(6, 5, 153, 336),
    ),
    'assets/images/training_game/main/wtb/idle_2.png': _OpaqueAssetPixels(
      imageSize: Size(175, 340),
      bounds: Rect.fromLTRB(5, 5, 169, 334),
    ),
    'assets/images/training_game/main/wtb/move_1.png': _OpaqueAssetPixels(
      imageSize: Size(175, 342),
      bounds: Rect.fromLTRB(5, 6, 169, 336),
    ),
    'assets/images/training_game/main/wtb/move_2.png': _OpaqueAssetPixels(
      imageSize: Size(175, 342),
      bounds: Rect.fromLTRB(6, 6, 170, 336),
    ),
  };

  factory TrainingHomeCharacterFrameSet.forBodyKey(String? bodyKey) {
    final normalizedKey = SametarohAssets.supportedBodyKeys.contains(bodyKey)
        ? bodyKey!
        : 'normal';
    return _cache.putIfAbsent(
      normalizedKey,
      () => TrainingHomeCharacterFrameSet._create(normalizedKey),
    );
  }

  static TrainingHomeCharacterFrameSet _create(String bodyKey) {
    final String? assetBodyKey = bodyKey == 'normal' ? null : bodyKey;
    final idle = SametarohAssets.idleFramesForBodyKey(assetBodyKey);
    final walk = SametarohAssets.journeyFramesForBodyKey(assetBodyKey);
    final rawFrames = [...idle, ...walk];
    final inputs = rawFrames.map((frame) {
      final pixels = _opaquePixels[frame.asset];
      if (pixels == null) {
        throw StateError('Missing alpha bounds for ${frame.asset}');
      }
      final visibleHeight = frame.sourceSize.height *
          pixels.bounds.height /
          pixels.imageSize.height;
      return _FrameWithPixels(frame: frame, pixels: pixels)
        ..visibleHeight = visibleHeight;
    }).toList();
    final targetVisibleHeight =
        inputs.map((item) => item.visibleHeight).reduce(math.max);
    for (final item in inputs) {
      // Normal idle art already has one shared source scale. Keep it fixed so
      // a 1px alpha-bounds difference cannot resize the legs between poses.
      item.scale = bodyKey == 'normal' && item.frame.footAnchorX != null
          ? 1
          : targetVisibleHeight / item.visibleHeight;
    }

    final normalizedSizes = [
      for (final item in inputs) item.frame.sourceSize * item.scale,
    ];
    final normalizedOpaqueWidths = [
      for (var i = 0; i < inputs.length; i++)
        normalizedSizes[i].width *
            inputs[i].pixels.bounds.width /
            inputs[i].pixels.imageSize.width,
    ];
    // 待機は箒等のない足元中心、歩行は踏み替えを含む従来の外形を維持。
    // 足を揃えた後も尻尾・腕を切らない共通キャンバス幅を確保する。
    final registeredWidths = <double>[
      for (var i = 0; i < inputs.length; i++)
        if (inputs[i].frame.footAnchorX case final anchor?)
          2 *
              math.max(
                (anchor - inputs[i].pixels.bounds.left) * inputs[i].scale,
                (inputs[i].pixels.bounds.right - anchor) * inputs[i].scale,
              )
        else
          normalizedOpaqueWidths[i],
    ];
    final canvasSize = Size(
      registeredWidths.reduce(math.max),
      targetVisibleHeight,
    );
    final normalizedFrames = <TrainingHomeCharacterFrame>[];
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final sourceSize = normalizedSizes[i];
      final renderCanvasSize = bodyKey == 'normal' && i >= idle.length
          ? Size(_normalWalkRenderWidth, targetVisibleHeight)
          : canvasSize;
      final renderCanvasOffsetX =
          (canvasSize.width - renderCanvasSize.width) / 2;
      final sourceAlpha = Rect.fromLTRB(
        input.pixels.bounds.left *
            sourceSize.width /
            input.pixels.imageSize.width,
        input.pixels.bounds.top *
            sourceSize.height /
            input.pixels.imageSize.height,
        input.pixels.bounds.right *
            sourceSize.width /
            input.pixels.imageSize.width,
        input.pixels.bounds.bottom *
            sourceSize.height /
            input.pixels.imageSize.height,
      );
      final anchor = input.frame.footAnchorX;
      final imageLeft = anchor == null
          ? (renderCanvasSize.width - sourceAlpha.width) / 2 - sourceAlpha.left
          : canvasSize.width / 2 - anchor * input.scale - renderCanvasOffsetX;
      final imageTop = targetVisibleHeight - sourceAlpha.bottom;
      final visibleBounds = Rect.fromLTWH(
        renderCanvasOffsetX + imageLeft + sourceAlpha.left,
        imageTop + sourceAlpha.top,
        sourceAlpha.width,
        sourceAlpha.height,
      );
      normalizedFrames.add(
        TrainingHomeCharacterFrame(
          asset: input.frame.asset,
          sourceSize: sourceSize,
          canvasSize: canvasSize,
          renderCanvasSize:
              renderCanvasSize == canvasSize ? null : renderCanvasSize,
          imageOffset: Offset(imageLeft, imageTop),
          visibleBounds: visibleBounds,
        ),
      );
    }
    return TrainingHomeCharacterFrameSet._(
      bodyKey: bodyKey,
      idleFrames: List.unmodifiable(normalizedFrames.take(idle.length)),
      walkFrames: List.unmodifiable(normalizedFrames.skip(idle.length)),
      canvasSize: canvasSize,
    );
  }

  final String bodyKey;
  final List<TrainingHomeCharacterFrame> idleFrames;
  final List<TrainingHomeCharacterFrame> walkFrames;
  final Size canvasSize;
  Future<bool>? _precacheFuture;

  List<TrainingHomeCharacterFrame> framesFor({required bool walking}) =>
      walking ? walkFrames : idleFrames;

  /// idleとwalkの全素材を先読みし、移動開始前に完了したかを返します。
  Future<bool> precache(BuildContext context) {
    return _precacheFuture ??= _precacheAll(context).then((loaded) {
      if (!loaded) _precacheFuture = null;
      return loaded;
    });
  }

  Future<bool> _precacheAll(BuildContext context) async {
    final results = await Future.wait([
      for (final frame in [...idleFrames, ...walkFrames])
        _precacheFrame(context, frame),
    ]);
    return results.every((loaded) => loaded);
  }

  Future<bool> _precacheFrame(
    BuildContext context,
    TrainingHomeCharacterFrame frame,
  ) async {
    var loaded = true;
    try {
      await precacheImage(
        AssetImage(frame.asset),
        context,
        onError: (exception, stackTrace) => loaded = false,
      );
      if (loaded && TrainingHomeIdleRegistration.supports(frame)) {
        await TrainingHomeIdleRegistration.prepare(frame);
      }
    } catch (_) {
      loaded = false;
    }
    return loaded;
  }
}

class TrainingHomeCharacterFrame {
  const TrainingHomeCharacterFrame({
    required this.asset,
    required this.sourceSize,
    required this.canvasSize,
    this.renderCanvasSize,
    required this.imageOffset,
    required this.visibleBounds,
  });

  final String asset;
  final Size sourceSize;
  final Size canvasSize;

  /// Optional centered raster viewport inside the shared canvas.
  final Size? renderCanvasSize;

  /// Image origin in [renderCanvasSize], or [canvasSize] when it is null.
  final Offset imageOffset;

  /// Shared canvas内で、実際に描かれる不透明部分の範囲です。
  final Rect visibleBounds;
}

class _FrameWithPixels {
  _FrameWithPixels({required this.frame, required this.pixels});

  final SametarohFrame frame;
  final _OpaqueAssetPixels pixels;
  double visibleHeight = 0;
  double scale = 1;
}

class _OpaqueAssetPixels {
  const _OpaqueAssetPixels({required this.imageSize, required this.bounds});

  final Size imageSize;
  final Rect bounds;
}

/// 正規化した1フレームを同じキャンバスへ配置します。
class TrainingHomeCharacterFrameImage extends StatelessWidget {
  const TrainingHomeCharacterFrameImage({
    required this.frame,
    required this.width,
    required this.height,
    this.semanticLabel,
    super.key,
  });

  final TrainingHomeCharacterFrame frame;
  final double width;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (TrainingHomeIdleRegistration.supports(frame)) {
      return SizedBox(
          width: width,
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            child: SizedBox.fromSize(
                size: frame.canvasSize,
                child: TrainingHomeIdleRegistration(
                    frame: frame, semanticLabel: semanticLabel)),
          ));
    }
    final renderCanvasSize = frame.renderCanvasSize ?? frame.canvasSize;
    final renderedCanvas = SizedBox(
      width: renderCanvasSize.width,
      height: renderCanvasSize.height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: frame.imageOffset.dx,
              top: frame.imageOffset.dy,
              width: frame.sourceSize.width,
              height: frame.sourceSize.height,
              child: Image.asset(
                frame.asset,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                semanticLabel: semanticLabel,
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: renderedCanvas,
      ),
    );
  }
}

/// Registers only WTB stationary feet inside one connected actor image.
/// SH keeps its original RGBA with the frame set’s whole-image translation.
/// The ankle coverage blends continuously; no independent foot layer is used.
class TrainingHomeIdleRegistration extends StatelessWidget {
  const TrainingHomeIdleRegistration(
      {required this.frame, this.semanticLabel, super.key});
  final TrainingHomeCharacterFrame frame;
  final String? semanticLabel;
  static final _pending = <String, Future<ui.Image>>{};
  static final _ready = <String, ui.Image>{};
  static bool supports(TrainingHomeCharacterFrame frame) =>
      frame.asset.contains('/wtb/idle_');

  static Future<ui.Image> _canvas(TrainingHomeCharacterFrame frame) async {
    final data = await rootBundle.load(frame.asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final source = (await codec.getNextFrame()).image;
    codec.dispose();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
        source,
        Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
        frame.imageOffset & frame.sourceSize,
        Paint()..filterQuality = FilterQuality.low);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
        frame.canvasSize.width.ceil(), frame.canvasSize.height.ceil());
    picture.dispose();
    source.dispose();
    return image;
  }

  static Future<ui.Image> prepare(TrainingHomeCharacterFrame frame) {
    final ready = _ready[frame.asset];
    if (ready != null) return Future.value(ready);
    return _pending.putIfAbsent(
        frame.asset,
        () => _prepare(frame).catchError((Object error) {
              _pending.remove(frame.asset);
              throw error;
            }));
  }

  static Future<ui.Image> _prepare(TrainingHomeCharacterFrame frame) async {
    final first =
        TrainingHomeCharacterFrameSet.forBodyKey('wtb').idleFrames.first;
    final source = await _canvas(frame);
    if (frame.asset == first.asset) {
      _ready[frame.asset] = source;
      return source;
    }
    final canonical = await prepare(first);
    final bytes = (await source.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final reference =
        (await canonical.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
    final w = source.width, h = source.height;
    bool sole(List<int> pixels, int i) {
      final alpha = pixels[i + 3];
      if (alpha == 0) return false;
      final r = pixels[i] * 255 / alpha,
          g = pixels[i + 1] * 255 / alpha,
          b = pixels[i + 2] * 255 / alpha;
      return r < 40 && g > 45 && g < 125 && b > 110;
    }

    for (var y = h - 50; y < h; y++) {
      final t = ((y - (h - 50)) / 14).clamp(0.0, 1.0);
      final blend = t * t * (3 - 2 * t);
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        if (!sole(bytes, i) && !sole(reference, i)) continue;
        for (var c = 0; c < 4; c++) {
          bytes[i + c] =
              (bytes[i + c] * (1 - blend) + reference[i + c] * blend).round();
        }
      }
    }
    final complete = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        bytes, w, h, ui.PixelFormat.rgba8888, complete.complete);
    final result = await complete.future;
    source.dispose();
    _ready[frame.asset] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final first =
        TrainingHomeCharacterFrameSet.forBodyKey('wtb').idleFrames.first;
    return FutureBuilder<ui.Image>(
      key: ValueKey(frame.asset),
      initialData: _ready[frame.asset] ?? _ready[first.asset],
      future: prepare(frame),
      builder: (context, snapshot) => snapshot.hasData
          ? Semantics(
              label: semanticLabel,
              image: true,
              child: RawImage(image: snapshot.data, fit: BoxFit.fill))
          : ClipRect(
              child: Stack(children: [
              Positioned(
                left: first.imageOffset.dx,
                top: first.imageOffset.dy,
                width: first.sourceSize.width,
                height: first.sourceSize.height,
                child: Image.asset(first.asset,
                    fit: BoxFit.fill, semanticLabel: semanticLabel),
              )
            ])),
    );
  }
}

/// 先読みした素材を使い、状態変更の最初のフレームからidle/walkを切り替えます。
class TrainingHomeCharacterAnimation extends StatefulWidget {
  const TrainingHomeCharacterAnimation({
    required this.frameSet,
    required this.isWalking,
    required this.width,
    required this.height,
    this.frameDuration = const Duration(milliseconds: 650),
    this.semanticLabel,
    super.key,
  });

  final TrainingHomeCharacterFrameSet frameSet;
  final bool isWalking;
  final double width;
  final double height;
  final Duration frameDuration;
  final String? semanticLabel;

  @override
  State<TrainingHomeCharacterAnimation> createState() =>
      _TrainingHomeCharacterAnimationState();
}

class _TrainingHomeCharacterAnimationState
    extends State<TrainingHomeCharacterAnimation> {
  Timer? _frameTimer;
  int _frameIndex = 0;
  double _speedScale = 1;

  @override
  void initState() {
    super.initState();
    _startFrameTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheFrames();
    final speed = context
            .dependOnInheritedWidgetOfExactType<_TrainingHomeWalkTempo>()
            ?.speedScale ??
        1;
    if (_speedScale != speed) {
      _speedScale = speed;
      _startFrameTimer();
    }
  }

  @override
  void didUpdateWidget(covariant TrainingHomeCharacterAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frameSet != widget.frameSet ||
        oldWidget.isWalking != widget.isWalking ||
        oldWidget.frameDuration != widget.frameDuration) {
      _frameIndex = 0;
      _startFrameTimer();
      if (oldWidget.frameSet != widget.frameSet) _precacheFrames();
    }
  }

  void _precacheFrames() {
    unawaited(() async {
      await widget.frameSet.precache(context);
    }());
  }

  void _startFrameTimer() {
    _frameTimer?.cancel();
    final frames = widget.frameSet.framesFor(walking: widget.isWalking);
    if (frames.length < 2) return;
    final duration = Duration(
      microseconds: math.max(
        1,
        (widget.frameDuration.inMicroseconds /
                (widget.isWalking ? _speedScale : 1))
            .round(),
      ),
    );
    _frameTimer = Timer.periodic(duration, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = (_frameIndex + 1) % frames.length);
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frameSet.framesFor(walking: widget.isWalking);
    final frame = frames[_frameIndex % frames.length];
    return TrainingHomeCharacterFrameImage(
      frame: frame,
      width: widget.width,
      height: widget.height,
      semanticLabel: widget.semanticLabel,
    );
  }
}

/// 幼体の既存立ち絵を、足元を固定した小さな呼吸で表示します。
///
/// 新しい絵は使わず、拡縮の支点を下中央に置いて足元の位置を保ちます。
class TrainingHomeIdleMotion extends StatefulWidget {
  const TrainingHomeIdleMotion({
    required this.child,
    this.enabled = true,
    this.cycleDuration = const Duration(milliseconds: 1800),
    this.scaleDelta = 0.012,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final Duration cycleDuration;
  final double scaleDelta;

  @override
  State<TrainingHomeIdleMotion> createState() => _TrainingHomeIdleMotionState();
}

class _TrainingHomeIdleMotionState extends State<TrainingHomeIdleMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    );
    _breath = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TrainingHomeIdleMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleDuration != widget.cycleDuration) {
      _controller.duration = widget.cycleDuration;
    }
    if (oldWidget.enabled == widget.enabled) return;
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: 1 + (widget.enabled ? widget.scaleDelta * _breath.value : 0),
          child: child,
        ),
      );
}
