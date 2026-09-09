import 'dart:async';

import 'package:flutter/material.dart';

import 'models/training_game_models.dart';

/// 鮫太朗の状態別イラストをまとめたアセット定義です。
abstract final class SametarohAssets {
  static const normalFrames = <SametarohFrame>[
    SametarohFrame(
      asset: 'assets/images/sametaroh/normal_sameraroh_1.png',
      sourceSize: Size(144, 323),
      canvasSize: Size(166, 323),
    ),
    SametarohFrame(
      asset: 'assets/images/sametaroh/normal_sametaroh_2.png',
      sourceSize: Size(166, 323),
      canvasSize: Size(166, 323),
    ),
  ];

  static const journeyFrames = <SametarohFrame>[
    SametarohFrame(
      asset: 'assets/images/sametaroh/walk_sametaroh_1.png',
      sourceSize: Size(160, 303),
      canvasSize: Size(161, 303),
    ),
    SametarohFrame(
      asset: 'assets/images/sametaroh/walk_sametaroh_2.png',
      sourceSize: Size(161, 303),
      canvasSize: Size(161, 303),
    ),
  ];

  static const initialFrames = <TrainingActionType, SametarohFrame>{
    TrainingActionType.meal: SametarohFrame(
      asset: 'assets/images/sametaroh/eating_sametaroh_start.png',
      sourceSize: Size(292, 295),
      canvasSize: Size(292, 309),
    ),
  };

  static const careFrames = <TrainingActionType, List<SametarohFrame>>{
    TrainingActionType.meal: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/eating_sametaroh_1.png',
        sourceSize: Size(289, 309),
        canvasSize: Size(292, 309),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/eating_sametaroh_2.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(292, 309),
      ),
    ],
    TrainingActionType.clean: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/claening_sametaroh_1.png',
        sourceSize: Size(157, 314),
        canvasSize: Size(175, 314),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/cleaning_sametaroh_2.png',
        sourceSize: Size(156, 314),
        canvasSize: Size(175, 314),
      ),
    ],
    TrainingActionType.rest: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/sleeping_sametaroh_1.png',
        sourceSize: Size(448, 267),
        canvasSize: Size(448, 301),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/sleeping_sametaroh_2.png',
        sourceSize: Size(420, 301),
        canvasSize: Size(448, 301),
      ),
    ],
    TrainingActionType.squat: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/training_sametarohj_1.png',
        sourceSize: Size(171, 315),
        canvasSize: Size(201, 315),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/training_sametaroh_2.png',
        sourceSize: Size(198, 315),
        canvasSize: Size(201, 315),
      ),
    ],
    TrainingActionType.work: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/working_sametaroh_1.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(309, 349),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/working_sametaroh_2.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(309, 349),
      ),
    ],
  };

  static const completionFrames = <TrainingActionType, SametarohFrame>{
    TrainingActionType.meal: SametarohFrame(
      asset: 'assets/images/sametaroh/eating_complete_sametaroh.png',
      sourceSize: Size(289, 305),
      canvasSize: Size(292, 309),
    ),
    TrainingActionType.clean: SametarohFrame(
      asset: 'assets/images/sametaroh/cleaning_complete_sametaroh.png',
      sourceSize: Size(175, 302),
      canvasSize: Size(175, 314),
    ),
    TrainingActionType.rest: SametarohFrame(
      asset: 'assets/images/sametaroh/sleeping_complete_sametaroh.png',
      sourceSize: Size(425, 299),
      canvasSize: Size(448, 301),
    ),
    TrainingActionType.squat: SametarohFrame(
      asset: 'assets/images/sametaroh/training_complete_sametaroh.png',
      sourceSize: Size(201, 302),
      canvasSize: Size(201, 315),
    ),
    TrainingActionType.work: SametarohFrame(
      asset: 'assets/images/sametaroh/warking_complete_sametaroh.png',
      sourceSize: Size(309, 349),
      canvasSize: Size(309, 349),
    ),
  };

  static List<SametarohFrame> careFramesFor(TrainingActionType type) {
    final frames = careFrames[type];
    if (frames == null) {
      throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。');
    }
    return frames;
  }

  static SametarohFrame completionFrameFor(TrainingActionType type) {
    final frame = completionFrames[type];
    if (frame == null) {
      throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。');
    }
    return frame;
  }
}

/// 1枚の素材を共通キャンバスへ配置するための情報です。
class SametarohFrame {
  const SametarohFrame({
    required this.asset,
    required this.sourceSize,
    required this.canvasSize,
  });

  final String asset;
  final Size sourceSize;
  final Size canvasSize;
}

/// 指定されたフレームを一定間隔で切り替えて表示します。
class SametarohAnimatedImage extends StatefulWidget {
  const SametarohAnimatedImage({
    required this.frames,
    required this.width,
    required this.height,
    this.initialFrame,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    super.key,
  });

  final List<SametarohFrame> frames;
  final double width;
  final double height;
  final SametarohFrame? initialFrame;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  State<SametarohAnimatedImage> createState() =>
      _SametarohAnimatedImageState();
}

class _SametarohAnimatedImageState extends State<SametarohAnimatedImage> {
  static const frameDuration = Duration(milliseconds: 650);

  Timer? _timer;
  int _frameIndex = 0;
  int _precacheGeneration = 0;
  bool _isReady = false;
  bool _showInitialFrame = false;

  @override
  void initState() {
    super.initState();
    _showInitialFrame = widget.initialFrame != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_precacheAndStart());
  }

  @override
  void didUpdateWidget(covariant SametarohAnimatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final framesChanged = oldWidget.frames != widget.frames;
    final initialFrameChanged =
        oldWidget.initialFrame?.asset != widget.initialFrame?.asset;
    if (framesChanged || initialFrameChanged) {
      _frameIndex = 0;
      _isReady = false;
      _showInitialFrame = widget.initialFrame != null;
      unawaited(_precacheAndStart());
    }
  }

  /// 初期フレームを先に表示し、残りのフレームを先読みしてから再生します。
  Future<void> _precacheAndStart() async {
    final generation = ++_precacheGeneration;
    _timer?.cancel();
    _timer = null;
    final initialFrame = widget.initialFrame;
    if (initialFrame != null) {
      await _precacheFrame(initialFrame);
      if (!mounted || generation != _precacheGeneration) return;
      setState(() => _isReady = true);
    }
    await Future.wait<void>(widget.frames.map(_precacheFrame));
    if (!mounted || generation != _precacheGeneration) return;
    if (!_isReady) setState(() => _isReady = true);
    _startTimer();
  }

  /// 1枚の先読み失敗が、他フレームの先読みを中断しないようにします。
  Future<void> _precacheFrame(SametarohFrame frame) async {
    try {
      await precacheImage(AssetImage(frame.asset), context);
    } catch (_) {
      // 失敗した素材は通常のImageProviderの読み込みに任せて再生します。
    }
  }

  void _startTimer() {
    if (widget.frames.length < 2 || _timer != null) return;
    _timer = Timer.periodic(frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_showInitialFrame) {
          _showInitialFrame = false;
          _frameIndex = 0;
        } else {
          _frameIndex = (_frameIndex + 1) % widget.frames.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      final initialFrame = widget.initialFrame;
      if (initialFrame != null) {
        return SametarohFrameImage(
          frame: initialFrame,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          semanticLabel: widget.semanticLabel,
        );
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final frame = _showInitialFrame && widget.initialFrame != null
        ? widget.initialFrame!
        : widget.frames[_frameIndex];
    return SametarohFrameImage(
      frame: frame,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel,
    );
  }
}

/// 共通キャンバス上に1枚の鮫太朗素材を描画します。
class SametarohFrameImage extends StatelessWidget {
  const SametarohFrameImage({
    required this.frame,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    super.key,
  });

  final SametarohFrame frame;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        child: SizedBox(
          width: frame.canvasSize.width,
          height: frame.canvasSize.height,
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: frame.sourceSize.width,
              height: frame.sourceSize.height,
              child: Image.asset(
                frame.asset,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
