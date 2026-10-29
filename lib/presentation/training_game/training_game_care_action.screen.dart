import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/training_game_models.dart';
import 'sametaroh_asset.dart';
import 'sametaroh_clean_warp.dart';
import 'training_care_scene.dart';
import 'training_game_theme.dart';

/// ④-a〜④-eのお世話実行中画面を共通レイアウトで表示します。
class TrainingGameCareActionScreen extends StatefulWidget {
  /// 表示対象のお世話行動を指定して画面を作成します。
  const TrainingGameCareActionScreen({
    required this.actionType,
    this.bodyKey,
    this.onCompletionSound,
    super.key,
  });

  /// この画面で実施するお世話行動です。
  final TrainingActionType actionType;

  /// 表示専用の体形。未指定・未知値では既存ノーマルを使います。
  final String? bodyKey;

  /// 完了ポーズの表示に合わせて再生するSEです。
  final VoidCallback? onCompletionSound;

  @override
  State<TrainingGameCareActionScreen> createState() =>
      _TrainingGameCareActionScreenState();
}

/// お世話画面内の完了演出の状態を管理します。
class _TrainingGameCareActionScreenState
    extends State<TrainingGameCareActionScreen> with TickerProviderStateMixin {
  static const _actionDuration = Duration(seconds: 5);
  static const _completionEffectDuration = Duration(milliseconds: 720);
  Timer? _actionTimer;
  late final AnimationController _actionProgressController;
  late final AnimationController _completionEffectController;
  late final Animation<double> _completionScale;
  bool _isCompleting = false;
  bool _showCompletionFrame = false;
  String? _completionAsset;
  Future<void>? _completionPrecache;
  int _completionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _actionProgressController = AnimationController(
      vsync: this,
      duration: _actionDuration,
    );
    _completionEffectController = AnimationController(
      vsync: this,
      duration: _completionEffectDuration,
    );
    _completionScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1.14,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 62,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.14,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 38,
      ),
    ]).animate(_completionEffectController);
    _startActionProgress();
  }

  void _startActionProgress() {
    _actionProgressController
      ..stop()
      ..value = 0
      ..forward();
    _actionTimer?.cancel();
    _actionTimer = Timer(_actionDuration, _completeAction);
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _actionProgressController.dispose();
    _completionEffectController.dispose();
    _completionGeneration++;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareCompletionFrame();
  }

  @override
  void didUpdateWidget(covariant TrainingGameCareActionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionType == widget.actionType &&
        oldWidget.bodyKey == widget.bodyKey) {
      return;
    }
    _completionGeneration++;
    _isCompleting = false;
    _showCompletionFrame = false;
    _completionAsset = null;
    _completionEffectController.reset();
    _prepareCompletionFrame();
    _startActionProgress();
  }

  void _prepareCompletionFrame() {
    final presentation = _CareActionPresentation.forType(
      widget.actionType,
      bodyKey: widget.bodyKey,
    );
    final completionAsset = presentation.completionFrame.asset;
    if (_completionAsset == completionAsset) return;
    _completionAsset = completionAsset;
    _completionGeneration++;
    final completionScene = TrainingCareScene.forAction(
      widget.actionType,
      completed: true,
    );
    _completionPrecache = widget.actionType == TrainingActionType.rest
        ? Future.wait<void>([
            _precacheCompletionFrame(presentation.completionFrame),
            _precacheAsset(completionScene!.asset),
          ]).then((_) {})
        : _precacheCompletionFrame(presentation.completionFrame);
  }

  Future<void> _precacheCompletionFrame(SametarohFrame frame) async {
    await _precacheAsset(frame.asset);
    if (SametarohCleanWarp.supports(frame)) {
      try {
        await SametarohCleanWarp.prepare(frame);
      } catch (_) {
        // 補正描画の失敗時は元画像へフォールバックして完了を継続します。
      }
    }
  }

  /// 完了フレームを先読みし、切り替え時の空白を防ぎます。
  Future<void> _precacheAsset(String asset) async {
    try {
      await precacheImage(AssetImage(asset), context);
    } catch (_) {
      // 失敗時はImage.assetの通常読み込みに任せて処理を継続します。
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _CareActionPresentation.forType(
      widget.actionType,
      bodyKey: widget.bodyKey,
    );
    return TrainingGameTheme(
      child: PopScope(
        canPop: !_isCompleting,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('お世話 ｜ ${presentation.title}'),
            leading: IconButton(
              // 完了演出の準備中は、行動確定前に閉じられないようにします。
              onPressed: _isCompleting && !_showCompletionFrame
                  ? null
                  : () => Navigator.pop(context, _showCompletionFrame),
              icon: const Icon(Icons.close),
              tooltip: _showCompletionFrame ? '完了して戻る' : 'お世話を中止',
            ),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isCompleting
                ? (_showCompletionFrame
                    ? () => Navigator.pop(context, true)
                    : null)
                : _completeAction,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildIllustration(presentation),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff4f4f4),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        presentation.progressLabel,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildActionSeekBar(),
                    SizedBox(height: 12.h),
                    Text(
                      presentation.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, height: 1.5),
                    ),
                    if (_showCompletionFrame || _isCompleting) ...[
                      SizedBox(height: 12.h),
                      Text(
                        _showCompletionFrame ? 'タップして戻る' : '完了しています…',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(_CareActionPresentation presentation) {
    final scene = TrainingCareScene.forAction(
      widget.actionType,
      completed: _showCompletionFrame,
      isChild: widget.bodyKey == SametarohAssets.childBodyKey,
    );
    // 背景がある場合は参考図内の共通キャンバスへ既存のcontain表示を収めます。
    final width = scene?.characterRect.width ?? presentation.viewport.width.w;
    final height =
        scene?.characterRect.height ?? presentation.viewport.height.h;
    final character = _showCompletionFrame
        ? SametarohFrameImage(
            frame: presentation.completionFrame,
            width: width,
            height: height,
            fit: presentation.fit,
            alignment: Alignment.bottomCenter,
          )
        : SametarohAnimatedImage(
            frames: presentation.frames,
            width: width,
            height: height,
            fit: presentation.fit,
            alignment: Alignment.bottomCenter,
            semanticLabel: presentation.illustrationLabel,
          );
    final presentedCharacter = _buildCompletionCharacter(character);
    final illustration = scene == null
        ? Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: presentedCharacter),
          )
        : TrainingCareSceneView(scene: scene, character: presentedCharacter);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        illustration,
        if (_showCompletionFrame)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _completionEffectController,
                builder: (context, _) => CustomPaint(
                  painter: _CareActionCompletionEffectPainter(
                    progress: _completionEffectController.value,
                    scene: scene,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionSeekBar() {
    return AnimatedBuilder(
      animation: _actionProgressController,
      child: SizedBox(
        height: 24.h,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _CareActionSeekBarPainter(
              progress: _actionProgressController,
            ),
          ),
        ),
      ),
      builder: (context, child) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'お世話の進行状況',
        value: '${(_actionProgressController.value * 100).round()}%',
        child: child,
      ),
    );
  }

  Widget _buildCompletionCharacter(Widget character) {
    if (!_showCompletionFrame) return character;
    return AnimatedBuilder(
      animation: _completionEffectController,
      child: character,
      builder: (context, child) => Transform.scale(
        scale: _completionScale.value,
        child: child,
      ),
    );
  }

  /// 完了フレームを表示してから、行動結果を育成画面へ返します。
  Future<void> _completeAction() async {
    if (_isCompleting) return;
    _actionTimer?.cancel();
    _actionProgressController.stop();
    final generation = _completionGeneration;
    final completionPrecache = _completionPrecache;
    setState(() {
      _isCompleting = true;
      _actionProgressController.value = 1;
    });
    await completionPrecache;
    if (!mounted || generation != _completionGeneration) return;
    setState(() => _showCompletionFrame = true);
    _completionEffectController.forward(from: 0);
    widget.onCompletionSound?.call();
  }
}

/// 5秒の自動進行を、つまみ付きのシークバーとして表示します。
class _CareActionSeekBarPainter extends CustomPainter {
  _CareActionSeekBarPainter({required this.progress})
      : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 8.0;
    const trackHeight = 4.0;
    const thumbRadius = 6.0;
    final trackWidth = math.max(0.0, size.width - inset * 2).toDouble();
    final trackTop = (size.height - trackHeight) / 2;
    final normalizedProgress = progress.value.clamp(0.0, 1.0).toDouble();
    final progressWidth = trackWidth * normalizedProgress;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, trackTop, trackWidth, trackHeight),
      const Radius.circular(trackHeight),
    );
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, trackTop, progressWidth, trackHeight),
      const Radius.circular(trackHeight),
    );
    canvas
      ..drawRRect(trackRect, Paint()..color = const Color(0xffd9e8e6))
      ..drawRRect(activeRect, Paint()..color = const Color(0xff178d83));
    final thumbCenter = Offset(inset + progressWidth, size.height / 2);
    canvas
      ..drawCircle(
        thumbCenter,
        thumbRadius,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(
        thumbCenter,
        thumbRadius,
        Paint()
          ..color = const Color(0xff178d83)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _CareActionSeekBarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// キャラクターの周りに一度だけ広がる光の輪ときらめきを描画します。
class _CareActionCompletionEffectPainter extends CustomPainter {
  const _CareActionCompletionEffectPainter({
    required this.progress,
    required this.scene,
  });

  final double progress;
  final TrainingCareScene? scene;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final eased = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final opacity = (1 - eased).clamp(0.0, 1.0).toDouble();
    final sceneSize = TrainingCareScene.sourceSize;
    final fittedScene = scene == null
        ? null
        : applyBoxFit(BoxFit.contain, sceneSize, size).destination;
    final sceneScale =
        fittedScene == null ? 1.0 : fittedScene.width / sceneSize.width;
    final sceneOffset = fittedScene == null
        ? Offset.zero
        : Offset(
            (size.width - fittedScene.width) / 2,
            (size.height - fittedScene.height) / 2,
          );
    final characterRect = scene?.characterRect;
    final center = characterRect == null
        ? Offset(size.width / 2, size.height / 2)
        : sceneOffset + characterRect.center * sceneScale;
    final characterWidth = characterRect == null
        ? size.shortestSide * 0.4
        : characterRect.width * sceneScale;
    final characterHeight = characterRect == null
        ? size.shortestSide * 0.4
        : characterRect.height * sceneScale;
    final characterExtent =
        math.min(characterWidth, characterHeight).toDouble();
    final radius = characterExtent * (0.3 + eased * 0.52);
    final alpha = (opacity * 180).round();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.fromARGB(alpha, 255, 199, 78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + opacity * 3,
    );

    for (var index = 0; index < 8; index++) {
      final angle = -math.pi / 2 + index * math.pi / 4;
      final distance = radius * (1.08 + (index.isEven ? 0.12 : 0));
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius * 0.82),
        center + direction * (distance + characterExtent * 0.08),
        Paint()
          ..color = Color.fromARGB((alpha * 0.75).round(), 255, 199, 78)
          ..strokeWidth = 2,
      );
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      _drawSparkle(
        canvas,
        point,
        characterExtent * 0.055 * opacity,
        alpha,
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, int alpha) {
    if (radius <= 0 || alpha <= 0) return;
    final path = Path();
    for (var point = 0; point < 8; point++) {
      final angle = -math.pi / 2 + point * math.pi / 4;
      final pointRadius = point.isEven ? radius : radius * 0.28;
      final position = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (point == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromARGB(alpha, 255, 200, 78)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CareActionCompletionEffectPainter oldDelegate,
  ) =>
      oldDelegate.progress != progress;
}

/// お世話画面で行動ごとに差し替える表示情報です。
class _CareActionPresentation {
  /// 表示情報を作成します。
  const _CareActionPresentation({
    required this.title,
    required this.frames,
    required this.completionFrame,
    required this.viewport,
    required this.fit,
    required this.illustrationLabel,
    required this.progressLabel,
    required this.description,
  });

  final String title;
  final List<SametarohFrame> frames;
  final SametarohFrame completionFrame;
  final Size viewport;
  final BoxFit fit;
  final String illustrationLabel;
  final String progressLabel;
  final String description;

  /// お世話種別に対応する画面文言と素材表示情報を返します。
  factory _CareActionPresentation.forType(
    TrainingActionType type, {
    String? bodyKey,
  }) {
    return switch (type) {
      TrainingActionType.work => _CareActionPresentation(
          title: '仕事',
          frames: SametarohAssets.careFramesFor(
            TrainingActionType.work,
            bodyKey: bodyKey,
          ),
          completionFrame: SametarohAssets.completionFrameFor(
            TrainingActionType.work,
            bodyKey: bodyKey,
          ),
          viewport: const Size(270, 280),
          fit: BoxFit.contain,
          illustrationLabel: '仕事中',
          progressLabel: '仕事中…',
          description: '今日の仕事をがんばっています。',
        ),
      TrainingActionType.meal => _CareActionPresentation(
          title: 'ごはん',
          frames: SametarohAssets.careFramesFor(
            TrainingActionType.meal,
            bodyKey: bodyKey,
          ),
          completionFrame: SametarohAssets.completionFrameFor(
            TrainingActionType.meal,
            bodyKey: bodyKey,
          ),
          viewport: const Size(250, 260),
          fit: BoxFit.contain,
          illustrationLabel: '食事中',
          progressLabel: '食事中…',
          description: 'おいしく食べて、おなかいっぱい！',
        ),
      TrainingActionType.clean => _CareActionPresentation(
          title: '掃除',
          frames: SametarohAssets.careFramesFor(
            TrainingActionType.clean,
            bodyKey: bodyKey,
          ),
          completionFrame: SametarohAssets.completionFrameFor(
            TrainingActionType.clean,
            bodyKey: bodyKey,
          ),
          viewport: const Size(160, 280),
          fit: BoxFit.contain,
          illustrationLabel: '掃除中',
          progressLabel: '掃除中…',
          description: 'お部屋がきれいになって、気分すっきり！',
        ),
      TrainingActionType.rest => _CareActionPresentation(
          title: '休養',
          frames: SametarohAssets.careFramesFor(
            TrainingActionType.rest,
            bodyKey: bodyKey,
          ),
          completionFrame: SametarohAssets.completionFrameFor(
            TrainingActionType.rest,
            bodyKey: bodyKey,
          ),
          viewport: const Size(320, 240),
          fit: BoxFit.contain,
          illustrationLabel: '休養・ケア中',
          progressLabel: 'ケア中…',
          description: 'ゆっくり休んで、また元気に！',
        ),
      TrainingActionType.squat => _CareActionPresentation(
          title: '筋トレ',
          frames: SametarohAssets.careFramesFor(
            TrainingActionType.squat,
            bodyKey: bodyKey,
          ),
          completionFrame: SametarohAssets.completionFrameFor(
            TrainingActionType.squat,
            bodyKey: bodyKey,
          ),
          viewport: const Size(170, 280),
          fit: BoxFit.contain,
          illustrationLabel: '筋トレ中',
          progressLabel: 'トレーニング中…',
          description: '日々のトレーニングを重ねて、たくましい鮫太郎を目指しましょう！',
        ),
      TrainingActionType.tackle ||
      TrainingActionType.passAndRun =>
        throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。'),
    };
  }
}
