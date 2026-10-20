import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/training_game_models.dart';
import 'sametaroh_asset.dart';
import 'training_care_scene.dart';

/// ④-a〜④-eのお世話実行中画面を共通レイアウトで表示します。
class TrainingGameCareActionScreen extends StatefulWidget {
  /// 表示対象のお世話行動を指定して画面を作成します。
  const TrainingGameCareActionScreen({
    required this.actionType,
    this.bodyKey,
    super.key,
  });

  /// この画面で実施するお世話行動です。
  final TrainingActionType actionType;

  /// 表示専用の体形。未指定・未知値では既存ノーマルを使います。
  final String? bodyKey;

  @override
  State<TrainingGameCareActionScreen> createState() =>
      _TrainingGameCareActionScreenState();
}

/// お世話画面内の完了演出の状態を管理します。
class _TrainingGameCareActionScreenState
    extends State<TrainingGameCareActionScreen> {
  static const _actionDuration = Duration(seconds: 5);
  Timer? _actionTimer;
  Timer? _completionTimer;
  bool _isCompleting = false;
  bool _showCompletionFrame = false;
  String? _completionAsset;
  Future<void>? _completionPrecache;
  int _completionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _startActionTimer();
  }

  void _startActionTimer() {
    _actionTimer?.cancel();
    _actionTimer = Timer(_actionDuration, _completeAction);
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _completionTimer?.cancel();
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
    _completionTimer?.cancel();
    _completionGeneration++;
    _isCompleting = false;
    _showCompletionFrame = false;
    _completionAsset = null;
    _prepareCompletionFrame();
    _startActionTimer();
  }

  void _prepareCompletionFrame() {
    final presentation = _CareActionPresentation.forType(widget.actionType,
        bodyKey: widget.bodyKey);
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
            _precacheAsset(completionAsset),
            _precacheAsset(completionScene!.asset),
          ]).then((_) {})
        : _precacheAsset(completionAsset);
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
    final presentation = _CareActionPresentation.forType(widget.actionType,
        bodyKey: widget.bodyKey);
    return PopScope(
      canPop: !_isCompleting,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('お世話 ｜ ${presentation.title}'),
          leading: IconButton(
            // 完了フレーム表示中は、行動確定前に閉じられないようにします。
            onPressed:
                _isCompleting ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
            tooltip: 'お世話を中止',
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isCompleting ? null : _completeAction,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xfff4f4f4),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      presentation.progressLabel,
                      style:
                          TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    presentation.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, height: 1.5),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _isCompleting
                        ? '完了しました'
                        : '5秒で自動完了します。画面タップでスキップ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      // 効果の反映は呼び出し元のControllerへ集約します。
                      onPressed: _isCompleting ? null : _completeAction,
                      child: Text(_isCompleting ? '反映中…' : 'スキップ'),
                    ),
                  ),
                ],
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
    return scene == null
        ? Center(child: FittedBox(fit: BoxFit.scaleDown, child: character))
        : TrainingCareSceneView(scene: scene, character: character);
  }

  /// 完了フレームを表示してから、行動結果を育成画面へ返します。
  Future<void> _completeAction() async {
    if (_isCompleting) return;
    _actionTimer?.cancel();
    final generation = _completionGeneration;
    final completionPrecache = _completionPrecache;
    setState(() => _isCompleting = true);
    await completionPrecache;
    if (!mounted || generation != _completionGeneration) return;
    setState(() => _showCompletionFrame = true);
    _completionTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && generation == _completionGeneration) {
        Navigator.pop(context, true);
      }
    });
  }
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
  factory _CareActionPresentation.forType(TrainingActionType type,
      {String? bodyKey}) {
    return switch (type) {
      TrainingActionType.work => _CareActionPresentation(
          title: '仕事',
          frames: SametarohAssets.careFramesFor(TrainingActionType.work,
              bodyKey: bodyKey),
          completionFrame: SametarohAssets.completionFrameFor(
              TrainingActionType.work,
              bodyKey: bodyKey),
          viewport: const Size(270, 280),
          fit: BoxFit.contain,
          illustrationLabel: '仕事中',
          progressLabel: '仕事中…',
          description: '今日の仕事をがんばっています。完了すると仕事が回復します。',
        ),
      TrainingActionType.meal => _CareActionPresentation(
          title: 'ごはん',
          frames: SametarohAssets.careFramesFor(TrainingActionType.meal,
              bodyKey: bodyKey),
          completionFrame: SametarohAssets.completionFrameFor(
              TrainingActionType.meal,
              bodyKey: bodyKey),
          viewport: const Size(250, 260),
          fit: BoxFit.contain,
          illustrationLabel: '食事中',
          progressLabel: '食事中…',
          description: 'しっかり食べて、食事メーターを回復します。',
        ),
      TrainingActionType.clean => _CareActionPresentation(
          title: '掃除',
          frames: SametarohAssets.careFramesFor(TrainingActionType.clean,
              bodyKey: bodyKey),
          completionFrame: SametarohAssets.completionFrameFor(
              TrainingActionType.clean,
              bodyKey: bodyKey),
          viewport: const Size(160, 280),
          fit: BoxFit.contain,
          illustrationLabel: '掃除中',
          progressLabel: '掃除中…',
          description: 'お部屋をきれいにして、清潔メーターを回復します。',
        ),
      TrainingActionType.rest => _CareActionPresentation(
          title: '休養',
          frames: SametarohAssets.careFramesFor(TrainingActionType.rest,
              bodyKey: bodyKey),
          completionFrame: SametarohAssets.completionFrameFor(
              TrainingActionType.rest,
              bodyKey: bodyKey),
          viewport: const Size(320, 240),
          fit: BoxFit.contain,
          illustrationLabel: '休養・ケア中',
          progressLabel: 'ケア中…',
          description: 'ゆっくり休んで、体調メーターを回復します。',
        ),
      TrainingActionType.squat => _CareActionPresentation(
          title: '筋トレ',
          frames: SametarohAssets.careFramesFor(TrainingActionType.squat,
              bodyKey: bodyKey),
          completionFrame: SametarohAssets.completionFrameFor(
              TrainingActionType.squat,
              bodyKey: bodyKey),
          viewport: const Size(170, 280),
          fit: BoxFit.contain,
          illustrationLabel: '筋トレ中',
          progressLabel: 'トレーニング中…',
          description: '日課の筋トレで、フォワードと体格の傾向を伸ばします。',
        ),
      TrainingActionType.tackle ||
      TrainingActionType.passAndRun =>
        throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。'),
    };
  }
}
