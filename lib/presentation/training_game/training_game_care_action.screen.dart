import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/training_game_models.dart';
import 'sametaroh_asset.dart';

/// ④-bの食事内容として選択できるメニュー種別です。
enum _MealKind {
  heartyProtein,
  lightBalanced,
}

/// ④-a〜④-eのお世話実行中画面を共通レイアウトで表示します。
class TrainingGameCareActionScreen extends StatefulWidget {
  /// 表示対象のお世話行動を指定して画面を作成します。
  const TrainingGameCareActionScreen({
    required this.actionType,
    super.key,
  });

  /// この画面で実施するお世話行動です。
  final TrainingActionType actionType;

  @override
  State<TrainingGameCareActionScreen> createState() =>
      _TrainingGameCareActionScreenState();
}

/// お世話画面内の食事選択状態を管理します。
class _TrainingGameCareActionScreenState
    extends State<TrainingGameCareActionScreen> {
  _MealKind _selectedMealKind = _MealKind.heartyProtein;
  bool _isCompleting = false;
  bool _showCompletionFrame = false;
  String? _completionAsset;
  Future<void>? _completionPrecache;
  int _completionGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareCompletionFrame();
  }

  @override
  void didUpdateWidget(covariant TrainingGameCareActionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionType == widget.actionType) return;
    _isCompleting = false;
    _showCompletionFrame = false;
    _completionAsset = null;
    _prepareCompletionFrame();
  }

  void _prepareCompletionFrame() {
    final presentation = _CareActionPresentation.forType(widget.actionType);
    final completionAsset = presentation.completionFrame.asset;
    if (_completionAsset == completionAsset) return;
    _completionAsset = completionAsset;
    _completionGeneration++;
    _completionPrecache = _precacheAsset(completionAsset);
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
    final presentation = _CareActionPresentation.forType(widget.actionType);
    return PopScope(
      canPop: !_isCompleting,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('お世話 ｜ ${presentation.title}'),
          leading: IconButton(
            // 完了フレーム表示中は、行動確定前に閉じられないようにします。
            onPressed: _isCompleting
                ? null
                : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
            tooltip: 'お世話を中止',
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: presentation.backgroundColor,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _showCompletionFrame
                            ? SametarohFrameImage(
                                frame: presentation.completionFrame,
                                width: presentation.viewport.width.w,
                                height: presentation.viewport.height.h,
                                fit: presentation.fit,
                                alignment: Alignment.bottomCenter,
                              )
                            : SametarohAnimatedImage(
                                frames: presentation.frames,
                                width: presentation.viewport.width.w,
                                height: presentation.viewport.height.h,
                                initialFrame: presentation.initialFrame,
                                fit: presentation.fit,
                                alignment: Alignment.bottomCenter,
                                semanticLabel: presentation.illustrationLabel,
                              ),
                        SizedBox(height: 14.h),
                        Text(
                          presentation.illustrationLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
                if (widget.actionType == TrainingActionType.meal) ...[
                  SizedBox(height: 12.h),
                  _buildMealKindSelector(),
                ],
                SizedBox(height: 12.h),
                Text(
                  presentation.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    // 効果の反映は呼び出し元のControllerへ集約します。
                    onPressed: _isCompleting ? null : _completeAction,
                    child: Text(_isCompleting ? '反映中…' : '完了する'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 完了フレームを表示してから、行動結果を育成画面へ返します。
  Future<void> _completeAction() async {
    if (_isCompleting) return;
    final generation = _completionGeneration;
    final completionPrecache = _completionPrecache;
    setState(() => _isCompleting = true);
    await completionPrecache;
    if (!mounted || generation != _completionGeneration) return;
    setState(() => _showCompletionFrame = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted && generation == _completionGeneration) {
      Navigator.pop(context, true);
    }
  }

  /// ④-bで選ぶ食事内容を表示します。
  Widget _buildMealKindSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '食事内容を選ぶ',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildMealKindButton(
                kind: _MealKind.heartyProtein,
                label: 'がっつり／高タンパク',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMealKindButton(
                kind: _MealKind.lightBalanced,
                label: '軽め／バランス',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 食事内容ごとの選択ボタンを作成します。
  Widget _buildMealKindButton({
    required _MealKind kind,
    required String label,
  }) {
    final isSelected = _selectedMealKind == kind;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMealKind = kind),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff3f3f3f),
        backgroundColor: isSelected
            ? const Color(0xffffe2ad)
            : const Color(0xfffffbf4),
        side: BorderSide(
          color: isSelected ? const Color(0xffbc7610) : const Color(0xffc9c9c9),
          width: isSelected ? 2 : 1,
        ),
        minimumSize: Size(0, 52.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
      ),
    );
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
    this.initialFrame,
    required this.illustrationLabel,
    required this.progressLabel,
    required this.description,
    required this.backgroundColor,
  });

  final String title;
  final List<SametarohFrame> frames;
  final SametarohFrame completionFrame;
  final Size viewport;
  final BoxFit fit;
  final SametarohFrame? initialFrame;
  final String illustrationLabel;
  final String progressLabel;
  final String description;
  final Color backgroundColor;

  /// お世話種別に対応する画面文言と素材表示情報を返します。
  factory _CareActionPresentation.forType(TrainingActionType type) {
    return switch (type) {
      TrainingActionType.work => _CareActionPresentation(
          title: '仕事',
          frames: SametarohAssets.careFrames[TrainingActionType.work]!,
          completionFrame:
              SametarohAssets.completionFrames[TrainingActionType.work]!,
          viewport: const Size(270, 280),
          fit: BoxFit.contain,
          illustrationLabel: '仕事中',
          progressLabel: '仕事中…',
          description: '今日の仕事をがんばっています。完了すると仕事が回復します。',
          backgroundColor: Color(0xffe7edf5),
        ),
      TrainingActionType.meal => _CareActionPresentation(
          title: 'ごはん',
          frames: SametarohAssets.careFrames[TrainingActionType.meal]!,
          completionFrame:
              SametarohAssets.completionFrames[TrainingActionType.meal]!,
          initialFrame:
              SametarohAssets.initialFrames[TrainingActionType.meal],
          viewport: const Size(250, 260),
          fit: BoxFit.contain,
          illustrationLabel: '食事中',
          progressLabel: '食事中…',
          description: 'しっかり食べて、食事メーターを回復します。',
          backgroundColor: Color(0xfffff1db),
        ),
      TrainingActionType.clean => _CareActionPresentation(
          title: '掃除',
          frames: SametarohAssets.careFrames[TrainingActionType.clean]!,
          completionFrame:
              SametarohAssets.completionFrames[TrainingActionType.clean]!,
          viewport: const Size(160, 280),
          fit: BoxFit.contain,
          illustrationLabel: '掃除中',
          progressLabel: '掃除中…',
          description: 'お部屋をきれいにして、清潔メーターを回復します。',
          backgroundColor: Color(0xffe4f3ed),
        ),
      TrainingActionType.rest => _CareActionPresentation(
          title: '休養',
          frames: SametarohAssets.careFrames[TrainingActionType.rest]!,
          completionFrame:
              SametarohAssets.completionFrames[TrainingActionType.rest]!,
          viewport: const Size(320, 240),
          fit: BoxFit.contain,
          illustrationLabel: '休養・ケア中',
          progressLabel: 'ケア中…',
          description: 'ゆっくり休んで、体調メーターを回復します。',
          backgroundColor: Color(0xffeee9f8),
        ),
      TrainingActionType.squat => _CareActionPresentation(
          title: '筋トレ',
          frames: SametarohAssets.careFrames[TrainingActionType.squat]!,
          completionFrame:
              SametarohAssets.completionFrames[TrainingActionType.squat]!,
          viewport: const Size(170, 280),
          fit: BoxFit.contain,
          illustrationLabel: '筋トレ中',
          progressLabel: 'トレーニング中…',
          description: '日課の筋トレで、フォワードと体格の傾向を伸ばします。',
          backgroundColor: Color(0xffffe9e6),
        ),
      TrainingActionType.tackle || TrainingActionType.passAndRun =>
        throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。'),
    };
  }
}
