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
  static const _completionScaleDuration = Duration(milliseconds: 1000);
  static const _completionEffectDuration = Duration(milliseconds: 1400);
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
    ]).animate(
      CurvedAnimation(
        parent: _completionEffectController,
        curve: Interval(
          0,
          _completionScaleDuration.inMilliseconds /
              _completionEffectDuration.inMilliseconds,
        ),
      ),
    );
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

  /// 画面タップ1回につき、進捗を1秒分進めて残り時間も合わせて短縮します。
  void _advanceActionProgressByOneSecond() {
    if (_isCompleting) return;

    // キャラクターのコマ送りは独立したタイマーに任せ、時間とバーだけを進めます。
    final progressPerTap = 1 / _actionDuration.inSeconds;
    final nextProgress = (_actionProgressController.value + progressPerTap)
        .clamp(0.0, 1.0)
        .toDouble();
    if (nextProgress >= 1) {
      _completeAction();
      return;
    }

    final remainingDuration = Duration(
      microseconds:
          (_actionDuration.inMicroseconds * (1 - nextProgress)).round(),
    );
    _actionTimer?.cancel();
    _actionProgressController
      ..stop()
      ..value = nextProgress
      ..forward();
    _actionTimer = Timer(remainingDuration, _completeAction);
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
            title: Text(
              'お世話 ｜ ${presentation.title}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
                : _advanceActionProgressByOneSecond,
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
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _showCompletionFrame
                          ? 'タップして戻る'
                          : _isCompleting
                              ? '完了しています…'
                              : 'タップで短縮できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    isChild: widget.bodyKey == SametarohAssets.childBodyKey,
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
      builder: (context, child) =>
          Transform.scale(scale: _completionScale.value, child: child),
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

/// 完了時に光の輪・紙吹雪・星を重ねて達成感を伝えます。
class _CareActionCompletionEffectPainter extends CustomPainter {
  const _CareActionCompletionEffectPainter({
    required this.progress,
    required this.scene,
    required this.isChild,
  });
  final double progress;
  final TrainingCareScene? scene;
  final bool isChild;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final fitted = applyBoxFit(
      BoxFit.contain,
      TrainingCareScene.sourceSize,
      size,
    ).destination;
    final scale = fitted.width / TrainingCareScene.sourceSize.width;
    final offset = Offset(
      (size.width - fitted.width) / 2,
      (size.height - fitted.height) / 2,
    );
    final rect = scene?.characterRect;
    final center = rect == null
        ? Offset(size.width / 2, size.height / 2)
        : offset + rect.center * scale;
    final extent = rect == null
        ? size.shortestSide * 0.4
        : math.min(rect.width, rect.height) * scale;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // 幼体素材は透明余白を含むため、粒の大きさと広がりを中心基準で縮小します。
    if (isChild) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(0.65);
      canvas.translate(-center.dx, -center.dy);
    }
    // A brief halo marks completion before the confetti opens out.
    final haloLife = (progress / .58).clamp(0.0, 1.0).toDouble();
    final haloAlpha = math.sin(haloLife * math.pi) * .75;
    final haloRadius =
        extent * (.28 + Curves.easeOutCubic.transform(haloLife) * .8);
    if (haloAlpha > 0) {
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xffffd66b).withValues(alpha: 0),
              const Color(0xffffd66b).withValues(alpha: haloAlpha * .18),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, .75, 1],
          ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
      );
      for (final width in [8.0, 3.0]) {
        canvas.drawCircle(
          center,
          haloRadius,
          Paint()
            ..color = (width == 8 ? Colors.white : const Color(0xffffc83d))
                .withValues(alpha: haloAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width,
        );
      }
    }
    // Uneven spacing and a short second wave avoid a rigid circular wreath.
    for (var i = 0; i < 44; i++) {
      final delay = i >= 28 ? .18 + (i % 4) * .022 : (i % 4) * .018;
      final life =
          ((progress - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
      if (life <= 0 || life >= 1) continue;
      final burst = Curves.easeOutCubic.transform(
        (life / .65).clamp(0.0, 1.0).toDouble(),
      );
      final angle =
          -math.pi / 2 + i * math.pi * 2 / 44 + math.sin(i * 2.4) * .09;
      final distance = extent * (.46 + burst * (.42 + (i % 5) * .09));
      final position = center +
          Offset(
            math.cos(angle) * distance + math.sin(life * 7 + i) * life * 7,
            math.sin(angle) * distance -
                math.sin(life * math.pi) * 12 +
                life * life * 27,
          );
      final alpha =
          (Curves.easeOut.transform((life * 9).clamp(0.0, 1.0).toDouble()) *
              (1 -
                  Curves.easeIn.transform(
                    ((life - .55) / .45).clamp(0.0, 1.0).toDouble(),
                  )));
      final isStar = i % 3 == 0;
      final particleScale =
          (.55 + .45 * math.sin(math.min(life * 5, math.pi / 2))) *
              (1 - life * .18);
      final color = (isStar
              ? const Color(0xffffc83d)
              : [
                  const Color(0xffffc83d),
                  const Color(0xff168ac2),
                  const Color(0xffff8994),
                ][i % 3])
          .withValues(alpha: alpha);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(
        isStar
            ? math.sin(life * 4 + i) * .18
            : angle + life * (i.isEven ? 3 : -3),
      );
      canvas.scale(
        particleScale,
        particleScale * (isStar ? 1 : .65 + .35 * math.cos(life * 9 + i).abs()),
      );
      final path = Path();
      if (isStar) {
        final radius = i % 6 == 0 ? 17.0 : 11.0;
        for (var j = 0; j < 8; j++) {
          final a = -math.pi / 2 + j * math.pi / 4;
          final r = j.isEven ? radius : radius * .28;
          if (j == 0) {
            path.moveTo(math.cos(a) * r, math.sin(a) * r);
          } else {
            path.lineTo(math.cos(a) * r, math.sin(a) * r);
          }
        }
        path.close();
      } else {
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-2.7, -5.5, 5.4, i.isEven ? 11 : 8),
            const Radius.circular(1.5),
          ),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }
    // Delayed, larger sparkles give the burst a second beat.
    final sparkleLife = ((progress - .2) / .68).clamp(0.0, 1.0).toDouble();
    final sparkleAlpha = math.sin(sparkleLife * math.pi);
    if (sparkleAlpha > 0) {
      for (var i = 0; i < 5; i++) {
        final angle = -math.pi * .92 + i * math.pi * .46;
        final point = center +
            Offset(math.cos(angle), math.sin(angle)) *
                extent *
                (1.02 + sparkleLife * .2);
        final r = (i.isEven ? 19.0 : 14.0) * math.sin(sparkleLife * math.pi);
        final path = Path();
        for (var j = 0; j < 8; j++) {
          final a = -math.pi / 2 + j * math.pi / 4;
          final v = point +
              Offset(math.cos(a), math.sin(a)) * (j.isEven ? r : r * .22);
          if (j == 0) {
            path.moveTo(v.dx, v.dy);
          } else {
            path.lineTo(v.dx, v.dy);
          }
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: sparkleAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffffc83d).withValues(alpha: sparkleAlpha),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _CareActionCompletionEffectPainter oldDelegate,
  ) =>
      oldDelegate.progress != progress ||
      oldDelegate.scene != scene ||
      oldDelegate.isChild != isChild;
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
