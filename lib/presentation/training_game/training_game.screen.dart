import 'dart:async';

import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/training_game.controller.dart';
import 'training_game_care_action.screen.dart';
import 'mini_games/mini_game_selection_sheet.dart';
import 'mini_games/models/mini_game_result.dart';
import 'mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'mini_games/tackle/tackle_game.screen.dart';
import 'models/training_game_models.dart';
import 'sametaroh_asset.dart';
import 'training_home_background.dart';
import 'training_home_controls.dart';
import 'training_home_roaming_character.dart';
import 'training_sync_indicator.dart';
import 'training_debug_menu.dart';
import 'training_evolution_reveal.dart';
import 'training_dex_dialog.dart';

/// 参照HTMLのスマートフォン画面部分だけをアプリ用に再現します。
class TrainingGameScreen extends GetView<TrainingGameController> {
  /// 育成ゲーム画面を作成します。
  const TrainingGameScreen({super.key});

  String? get _bodyKey => SametarohAssets.bodyKeyForBranch(controller.branch);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !controller.isReturningHome.value,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Obx(() {
              final shouldShowEvolution =
                  controller.evolutionStage.value != null &&
                      (!controller.ended.value ||
                          controller.clearPosition.value != null);
              final content = controller.isServerStateReady.value
                  ? shouldShowEvolution
                      ? _buildEvolutionFlow()
                      : controller.ended.value
                          ? _buildEndingFlow(context)
                          : Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: TrainingHomeBackground(),
                                      ),
                                      Column(
                                        children: [
                                          if (controller.syncStatusMessage.value
                                                  .isNotEmpty &&
                                              controller.syncStatus.value !=
                                                  TrainingSyncStatus.syncing)
                                            _buildSyncStatusBanner(context),
                                          _buildHud(context),
                                          Expanded(child: _buildRoom(context)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _buildCareBar(context),
                              ],
                            )
                  : controller.serverErrorMessage.value.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildConnectionError();
              return Stack(
                children: [
                  content,
                  if (controller.isReturningHome.value)
                    _buildReturningHomeOverlay(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// ホーム遷移中は画面操作を抑止し、ロード中であることを表示します。
  Widget _buildReturningHomeOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: ColoredBox(
          color: Colors.black26,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 22.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 14.h),
                    Text(
                      'ホームへ移動中…',
                      style: TextStyle(
                        fontSize: 16.sp,
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

  /// 通信必須の育成ゲームで、接続失敗時に再試行を案内します。
  Widget _buildConnectionError() {
    final sessionChanged =
        controller.syncStatus.value == TrainingSyncStatus.sessionChanged;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.serverErrorMessage.value,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: sessionChanged
                  ? () => Get.back<void>()
                  : controller.retryRestoreServerState,
              child: Text(sessionChanged ? '閉じる' : '再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusBanner(BuildContext context) {
    final status = controller.syncStatus.value;
    return Container(
      width: double.infinity,
      color: const Color(0xfffff2cc),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.syncStatusMessage.value,
            style: TextStyle(fontSize: 12.sp),
          ),
          if (controller.canResolveDebugTimeSave)
            TextButton(
              onPressed: controller.retryRestoreServerState,
              child: const Text('サーバーの状態を再取得'),
            ),
          if (status == TrainingSyncStatus.stopped ||
              status == TrainingSyncStatus.rateLimited ||
              status == TrainingSyncStatus.rejected ||
              status == TrainingSyncStatus.outcomeUnknown)
            Wrap(
              spacing: 8.w,
              children: [
                if (controller.canRetryPendingSync)
                  TextButton(
                    onPressed: controller.retryPendingSync,
                    child: Text(status == TrainingSyncStatus.outcomeUnknown
                        ? controller.pendingSyncActionCount > 0
                            ? '同じ操作IDで再確認'
                            : 'サーバー状態を再確認'
                        : '再試行'),
                  ),
                if (controller.canDiscardPendingSync &&
                    (status == TrainingSyncStatus.stopped ||
                        status == TrainingSyncStatus.rateLimited))
                  TextButton(
                    onPressed: controller.discardPendingSync,
                    child: const Text('未送信操作を破棄'),
                  ),
                if (status == TrainingSyncStatus.rejected)
                  TextButton(
                    onPressed: controller.acknowledgeSyncNotice,
                    child: const Text('確認して続ける'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// ⑧〜⑪の育成完了後フローを表示します。
  Widget _buildEvolutionFlow() {
    final stage = controller.currentStage;
    final evolutionStage = controller.evolutionStage.value;
    final isLastStage =
        controller.stageIndex.value == TrainingGameController.stages.length - 1;
    final isKnownEarlierEvolution = evolutionStage != null &&
        evolutionStage > 0 &&
        evolutionStage < TrainingGameController.stages.length - 1;
    final isFirstTeam = isLastStage &&
        !isKnownEarlierEvolution &&
        (!controller.ended.value || controller.clearPosition.value != null);
    final visual = isFirstTeam
        ? '🦈\n一軍'
        : switch (evolutionStage) {
            1 => '🐣\n幼少へ進化',
            2 => '🦈\n育成期へ進化',
            3 => '🦈\n成長期へ進化',
            _ => '${stage.name}\n進化',
          };
    final currentBodyFrame =
        SametarohAssets.idleFramesForBodyKey(_bodyKey).first;
    final visualWidget = isFirstTeam
        ? _buildFirstTeamEvolutionReveal()
        : switch (evolutionStage) {
            1 => _buildSuppliedStatic(SametarohAssets.newbornFrame),
            2 => TrainingEvolutionReveal(
                key: const ValueKey('training-evolution-2'),
                beforeFrame: SametarohAssets.newbornFrame,
                afterFrame: currentBodyFrame,
                beforeScale: 0.62,
              ),
            3 => TrainingEvolutionReveal(
                key: const ValueKey('training-evolution-3'),
                beforeFrame: SametarohAssets.normalFrames.first,
                afterFrame: currentBodyFrame,
                // 分岐未確定時も通常形を保ち、成長の差はサイズで見せます。
                beforeScale: 0.7,
              ),
            _ => _buildSuppliedStatic(currentBodyFrame),
          };
    final message = isFirstTeam
        ? 'ついに、一軍の舞台へ！'
        : switch (evolutionStage) {
            2 => '成長した鮫太郎と、いろんなことに挑戦してみましょう！！',
            3 => '成長した鮫太郎と、いろんなことに挑戦してみましょう！！',
            _ => '段階「${stage.name}」へ進みました。',
          };
    return _buildEndingPage(
      title: '進化',
      visual: visual,
      visualWidget: visualWidget,
      message: message,
      buttonLabel: '次へ',
      onPressed: controller.advanceEvolution,
    );
  }

  /// 一軍への進化を、確定済みポジション姿へ切り替える既存演出で表示します。
  Widget _buildFirstTeamEvolutionReveal() {
    final currentBodyFrame =
        SametarohAssets.idleFramesForBodyKey(_bodyKey).first;
    final confirmedFirstTeamFrame =
        SametarohAssets.positionFrameFor(controller.position);
    return TrainingEvolutionReveal(
      key: const ValueKey('training-evolution-4'),
      beforeFrame: currentBodyFrame,
      // 未確定時は推測ユニフォームを避け、現在の姿で成長演出します。
      afterFrame: confirmedFirstTeamFrame ?? currentBodyFrame,
      beforeScale: confirmedFirstTeamFrame == null ? 0.7 : 0.82,
    );
  }

  /// ⑧〜⑪の育成完了後フローを表示します。
  Widget _buildEndingFlow(BuildContext context) {
    final isPositive = controller.clearPosition.value != null;
    final step = controller.endingStep.value;
    if (step == 0 && isPositive) {
      return _buildEndingPage(
        title: '進化',
        visual: '🦈\n一軍',
        visualWidget: _buildFirstTeamEvolutionReveal(),
        message: 'ついに、一軍の舞台へ！',
        buttonLabel: '次へ',
        onPressed: controller.advanceEndingStep,
        guardRapidTap: true,
      );
    }
    if (step == 1 && isPositive) {
      return _buildEndingPage(
        title: 'ポジション確定',
        visual: '🦈\nユニフォーム姿',
        visualWidget: _buildPositionStatic(controller.position),
        message: controller.position,
        buttonLabel: '次へ',
        onPressed: controller.advanceEndingStep,
        guardRapidTap: true,
      );
    }
    if (step <= 2) {
      // 引退時は固定の鮫ではなく、現在の育成段階に対応する見た目を表示します。
      final endingVisual =
          isPositive ? '🦈\n旅立ち' : '${controller.characterLabel}\n引退';
      final endingFrames = isPositive
          ? SametarohAssets.journeyFramesForBodyKey(_bodyKey)
          : controller.stageIndex.value >= 2
              ? SametarohAssets.idleFramesForBodyKey(_bodyKey)
              : null;
      final hasBody = _bodyKey != null;
      final endingFit = isPositive || hasBody ? BoxFit.contain : BoxFit.cover;
      final endingWidth = isPositive
          ? 250.w
          : hasBody
              ? 160.w
              : 128.w;
      final isSyncPending = controller.isEndingSyncPending.value;
      final syncError = controller.endingSyncError.value;
      final canStartNextCycle = !isSyncPending && syncError.isEmpty;
      return _buildEndingPage(
        title: '旅立ち',
        visual: endingVisual,
        visualWidget: endingFrames == null
            ? controller.stageIndex.value == 1
                ? _buildSuppliedStatic(SametarohAssets.newbornFrame)
                : null
            : SametarohAnimatedImage(
                frames: endingFrames,
                width: endingWidth,
                height: 250.h,
                fit: endingFit,
                alignment: isPositive || hasBody
                    ? Alignment.bottomCenter
                    : Alignment.center,
                semanticLabel: isPositive ? '旅立つ鮫太朗' : '鮫太朗',
              ),
        message: [
          '鮫太郎と過ごした日々を胸に、新たな出会いへ。',
          if (isSyncPending) '終了状態を保存しています…',
          if (syncError.isNotEmpty) syncError,
        ].join('\n\n'),
        buttonLabel: syncError.isNotEmpty
            ? controller.syncStatus.value ==
                        TrainingSyncStatus.outcomeUnknown &&
                    controller.pendingSyncActionCount > 0
                ? '同じ操作IDで再確認'
                : controller.syncStatus.value ==
                        TrainingSyncStatus.outcomeUnknown
                    ? 'サーバー状態を再確認'
                    : '再試行'
            : isPositive
                ? '図鑑へ登録'
                : '次の卵へ',
        onPressed: !canStartNextCycle
            ? syncError.isNotEmpty
                ? controller.retryEndingSync
                : null
            : isPositive
                ? controller.advanceEndingStep
                : _openNewEgg,
      );
    }
    return _buildDexPage();
  }

  /// ⑪育成完了後の図鑑・クリア履歴を2列5行で表示します。
  Widget _buildDexPage() {
    const positions = [
      'プロップ',
      'フッカー',
      'ロック',
      'フランカー',
      'ナンバーエイト',
      'スクラムハーフ',
      'スタンドオフ',
      'ウイング',
      'センター',
      'フルバック',
    ];
    // 保存済み履歴と今回の到達結果を合わせ、表示中の更新もObxで反映します。
    final unlockedStates = positions
        .map(
          (position) =>
              controller.isPositionUnlocked(position) ||
              position == controller.clearPosition.value,
        )
        .toList();
    final registeredCount = unlockedStates.where((unlocked) => unlocked).length;

    return Stack(
      key: const ValueKey('training-completion-history'),
      children: [
        const Positioned.fill(
          child: TrainingHomeBackground(imageFit: BoxFit.cover),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
          child: Column(
            children: [
              Container(
                key: const ValueKey('training-completion-title-pill'),
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: TrainingHomeStyle.border),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Text(
                  '図鑑・クリア履歴',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TrainingHomeStyle.navy,
                    fontFamily: 'LINESeedJP',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                key: const ValueKey('training-completion-count-pill'),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xffe4f4fb),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  '到達 $registeredCount/10',
                  key: const ValueKey('training-completion-registered-count'),
                  style: TextStyle(
                    color: TrainingHomeStyle.navy,
                    fontFamily: 'LINESeedJP',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const rowCount = 5;
                    final rowHeight =
                        (constraints.maxHeight - 8.h * (rowCount - 1)) /
                            rowCount;
                    final portraitHeight =
                        (rowHeight * .66).clamp(38.h, 72.h).toDouble();

                    return GridView.builder(
                      key: const ValueKey('training-completion-history-grid'),
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: positions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        mainAxisExtent: rowHeight,
                      ),
                      itemBuilder: (_, index) {
                        final position = positions[index];
                        final unlocked = unlockedStates[index];
                        final frame = SametarohAssets.positionFrameFor(
                          position,
                        );
                        final portrait = frame == null
                            ? const SizedBox.shrink()
                            : SametarohFrameImage(
                                frame: frame,
                                width: 64.w,
                                height: portraitHeight,
                                alignment: Alignment.bottomCenter,
                                semanticLabel: position,
                              );

                        return Container(
                          key: ValueKey('training-completion-position-$index'),
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xffd4e2ec)),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Semantics(
                            label: '$position、${unlocked ? '到達済み' : '未到達'}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Center(
                                    child: unlocked
                                        ? portrait
                                        : ColorFiltered(
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xffc5cbd2),
                                              BlendMode.srcIn,
                                            ),
                                            child: Opacity(
                                              opacity: .72,
                                              child: portrait,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  position,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TrainingHomeStyle.navy,
                                    fontFamily: 'LINESeedJP',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  key: const ValueKey('training-completion-next-egg'),
                  onPressed: _openNewEgg,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TrainingHomeStyle.navy,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xffb8deee)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '次の卵へ',
                    style: TextStyle(
                      color: TrainingHomeStyle.navy,
                      fontFamily: 'LINESeedJP',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 次の育成を開始する前に、卵獲得画面へ遷移します。
  void _openNewEgg() => _openEgg(debugRestart: false, newCycle: true);

  /// デバッグ用に現在の育成を卵から再開始します。
  void _openDebugEgg() => _openEgg(debugRestart: true, newCycle: true);

  /// 卵獲得画面へ遷移し、必要に応じてデバッグ再開始を引き渡します。
  void _openEgg({required bool debugRestart, required bool newCycle}) {
    // サーバー上の新規育成作成は、卵獲得画面の「はじめる」後に実行します。
    Get.offNamed(
      Routes.TRAINING_GAME_NEW,
      arguments: {
        'debugRestart': debugRestart,
        'newCycle': newCycle,
      },
    );
  }

  /// 完了後フローの共通画面を作成します。
  Widget _buildEndingPage({
    required String title,
    required String visual,
    required String buttonLabel,
    required VoidCallback? onPressed,
    String? message,
    Widget? visualWidget,
    bool guardRapidTap = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 18.h),
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffe2e5e8),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: visualWidget ??
                  Text(visual,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30.sp, height: 1.5)),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
          ],
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: guardRapidTap
                ? _EndingStepAdvanceButton(
                    label: buttonLabel,
                    onPressed: onPressed,
                  )
                : ElevatedButton(
                    onPressed: onPressed,
                    child: Text(buttonLabel),
                  ),
          ),
        ],
      ),
    );
  }

  /// パラメータと退出ボタン、検証環境限定の開発操作を表示します。
  Widget _buildHud(BuildContext context) {
    return Stack(
      children: [
        _buildHudContent(context),
        if (controller.syncStatus.value == TrainingSyncStatus.syncing)
          Positioned(
            top: 16.h + 52.w + 3.h,
            right: 22.w,
            child: const IgnorePointer(child: TrainingSyncIndicator()),
          ),
      ],
    );
  }

  Widget _buildHudContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TrainingHomeStyle.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.7,
                crossAxisSpacing: 20,
                mainAxisSpacing: 8,
                padding: EdgeInsets.zero,
                children: const ['食事', '仕事', '清潔', '体調']
                    .map((name) => _buildMeterByName(name))
                    .toList(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  key: const ValueKey('training-home-exit'),
                  onPressed: controller.isReturningHome.value
                      ? null
                      : () => _returnHomeAfterSync(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TrainingHomeStyle.navy,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: controller.isReturningHome.value
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Tooltip(
                          message: '戻る',
                          child: Icon(Icons.arrow_back, size: 20)),
                ),
              ),
              if (AppEnvironment.showsTrainingDebugUi) ...[
                SizedBox(height: 36.h),
                IconButton(
                  onPressed: () => _showDebugMenu(context),
                  tooltip: 'デバッグコマンド',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                  icon: Icon(Icons.bug_report_outlined, size: 18.sp),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 最新状態の同期完了後にホームへ戻ります。
  Future<void> _returnHomeAfterSync(BuildContext context) async {
    if (controller.isReturningHome.value) return;
    var synchronized = false;
    try {
      synchronized = await controller.syncBeforeReturningHome();
    } catch (_) {
      // 未確定の操作がある間は画面を閉じず、状態確認または破棄を案内します。
    }
    if (!synchronized) return;
    // 戻る操作で先に画面が閉じられても、別画面を誤って閉じないようにします。
    if (context.mounted &&
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        Get.currentRoute == Routes.TRAINING_GAME) {
      Get.back<void>();
    }
  }

  /// メーター1項目を作成します。
  Widget _buildMeterByName(String name) {
    return _buildMeter(MapEntry(name, controller.meters[name]!));
  }

  /// 通常100・超過50の表示と数値をまとめます。
  Widget _buildMeter(MapEntry<String, double> entry) => DefaultTextStyle.merge(
        style: const TextStyle(
            fontFamily: 'LINESeedJP', color: TrainingHomeStyle.navy),
        child: TrainingHomeMeter(name: entry.key, value: entry.value),
      );

  /// 支給屋外背景・図鑑・キャラクター・練習ボタンを配置します。
  Widget _buildRoom(BuildContext context) {
    final canTrain =
        controller.stageIndex.value >= 2 && !controller.ended.value;
    return Stack(
      children: [
        Positioned(
          left: 12.w,
          bottom: 12.h,
          child: TextButton.icon(
            key: const ValueKey('training-home-dex'),
            onPressed: () => _showDex(context),
            style: _homeAuxiliaryStyle,
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('ずかん'),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 126.h,
          child: TrainingHomeRoamingCharacter(
            enabled: canTrain,
            width: 220.w,
            height: 224.h,
            travelDistance: 28.w,
            preparationKey: _bodyKey ?? 'normal',
            prepareWalk: (context) =>
                TrainingHomeCharacterFrameSet.forBodyKey(_bodyKey)
                    .precache(context),
            builder: (context, isWalking) => Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (AppEnvironment.showsTrainingDebugUi)
                    _buildCharacterBadge(),
                  _buildCharacterVisual(isWalking: isWalking),
                  if (AppEnvironment.showsTrainingDebugUi)
                    Text(
                      controller.currentStage.name,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xff0b3a5b),
                        backgroundColor: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8.w,
          bottom: 12.h,
          child: _buildTrainingMenuButton(context, canTrain),
        ),
        if (controller.ended.value)
          Positioned.fill(
            child: Center(
              child: Container(
                margin: EdgeInsets.all(24.w),
                padding: EdgeInsets.all(14.w),
                color: Colors.white.withOpacity(.94),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.clearPosition.value == null
                          ? 'ゲームオーバー'
                          : '育成完了',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8.h),
                    Text(controller.endingMessage.value,
                        textAlign: TextAlign.center),
                    SizedBox(height: 10.h),
                    ElevatedButton(
                      onPressed: _openNewEgg,
                      child: const Text('卵からやりなおす'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 確定した大別の立ち絵を表示し、未判定はノーマルを保持します。
  Widget _buildCharacterVisual({bool isWalking = false}) {
    if (controller.stageIndex.value == 1) {
      return TrainingHomeIdleMotion(
        child: _buildSuppliedStatic(
          SametarohAssets.newbornFrame,
          width: 92,
          height: 184,
        ),
      );
    }
    if (controller.stageIndex.value < 2) {
      return Text(
        controller.characterLabel,
        style: TextStyle(fontSize: controller.characterFontSize.sp),
      );
    }
    final bodyKey = _bodyKey;
    final frames = TrainingHomeCharacterFrameSet.forBodyKey(bodyKey);
    return TrainingHomeCharacterAnimation(
      key: ValueKey<String>(bodyKey ?? 'normal'),
      frameSet: frames,
      isWalking: isWalking,
      width: 128.w,
      height: 184.h,
      semanticLabel: '鮫太朗',
    );
  }

  Widget _buildSuppliedStatic(
    SametarohFrame frame, {
    double width = 250,
    double height = 250,
  }) =>
      SametarohFrameImage(
        frame: frame,
        width: width.w,
        height: height.h,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      );

  Widget? _buildPositionStatic(String position) {
    final frame = SametarohAssets.positionFrameFor(position);
    return frame == null ? null : _buildSuppliedStatic(frame);
  }

  /// 分岐後の暫定ポジション表示を作成します。
  Widget _buildCharacterBadge() {
    final label = controller.stageIndex.value == 0
        ? 'チュートリアル①（卵）'
        : controller.stageIndex.value == 1
            ? 'チュートリアル②（幼少）'
            : controller.clearPosition.value ??
                controller.branch ??
                'ノーマル鮫太朗（分岐前）';
    final branchColor = switch (controller.branch) {
      'A フォワード型' => const Color(0xff0ca30c),
      'B 司令塔型' => const Color(0xff1f6feb),
      'C バックス型' => const Color(0xffeb6834),
      _ => const Color(0xff8a8f96),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: controller.stageIndex.value < 2
            ? const Color(0xffb26a00)
            : branchColor,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 分岐後の暫定ポジション表示を作成します。
  Widget _buildPositionBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xff1f6feb),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        controller.position,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// ⑤ミニゲーム選択画面を開く練習ボタンを作成します。
  ButtonStyle get _homeAuxiliaryStyle => TextButton.styleFrom(
        foregroundColor: TrainingHomeStyle.navy,
        backgroundColor: Colors.white,
        disabledForegroundColor: const Color(0xff888888),
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontFamily: 'LINESeedJP', fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );

  Widget _buildTrainingMenuButton(BuildContext context, bool enabled) =>
      TextButton.icon(
        onPressed: enabled ? () => _showMiniGameSelection(context) : null,
        style: _homeAuxiliaryStyle,
        icon: const Icon(Icons.sports_rugby_outlined, size: 16),
        label: const Text('練習 / MG'),
      );

  /// 選択画面を閉じた後、既存のゲーム開始処理へ渡します。
  Future<void> _showMiniGameSelection(BuildContext context) async {
    final selected = await showMiniGameSelectionSheet(context);
    if (selected == null || !context.mounted) return;
    await _handleAction(context, selected);
  }

  /// 5種類のお世話ボタンを参照画面と同じ下部配置で表示します。
  Widget _buildCareBar(BuildContext context) {
    const careActions = [
      TrainingActionType.meal,
      TrainingActionType.clean,
      TrainingActionType.squat,
      TrainingActionType.work,
      TrainingActionType.rest,
    ];
    return SizedBox(
      key: const ValueKey('training-home-footer'),
      height: TrainingHomeStyle.footerHeight,
      child: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xffe0e0e0)))),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: careActions
              .where((type) =>
                  controller.stageIndex.value != 1 ||
                  SametarohAssets.childCareActions.contains(type))
              .map((type) => Expanded(child: _buildCareButton(context, type)))
              .toList(),
        ),
      ),
    );
  }

  /// お世話ボタン1つを作成します。
  Widget _buildCareButton(BuildContext context, TrainingActionType type) {
    final action = TrainingGameController.actions.firstWhere(
      (item) => item.type == type,
    );
    final tutorialActionAllowed = controller.stageIndex.value == 0
        ? type == TrainingActionType.clean || type == TrainingActionType.rest
        : controller.stageIndex.value == 1
            ? type != TrainingActionType.work &&
                type != TrainingActionType.tackle &&
                type != TrainingActionType.passAndRun
            : true;
    final squatRequirementMet =
        ['食事', '清潔', '体調'].every((name) => controller.meters[name]! >= 50);
    final enabled = !controller.ended.value &&
        tutorialActionAllowed &&
        controller.canPerform(type) &&
        !(type == TrainingActionType.squat &&
            (controller.stageIndex.value < 1 || !squatRequirementMet)) &&
        !(type == TrainingActionType.work && controller.stageIndex.value < 2);
    return TrainingHomeCareButton(
      key: ValueKey('training-home-care-${type.name}'),
      type: type,
      label: action.label,
      remaining: controller.cooldownRemaining(type),
      onPressed: enabled ? () => _handleAction(context, type) : null,
      trainingCount:
          type == TrainingActionType.squat && controller.stageIndex.value == 1
              ? controller.trainingCount.value
              : null,
    );
  }

  /// お世話は専用画面の完了操作後、ミニゲームはプレイ結果の受領後に反映します。
  Future<void> _handleAction(
    BuildContext context,
    TrainingActionType type,
  ) async {
    // 幼体から保持された古いcallbackでも、仕事の照会・画面を開きません。
    if (controller.stageIndex.value < 2 && type == TrainingActionType.work) {
      return;
    }
    if (type == TrainingActionType.tackle ||
        type == TrainingActionType.passAndRun) {
      final settings = await controller.prepareMiniGame(type);
      if (settings == null) return;
      if (!context.mounted) {
        controller.finishMiniGamePreparation();
        return;
      }
      try {
        final screen = type == TrainingActionType.tackle
            ? TackleGameScreen(settings: settings.tackle)
            : PassAndRunGameScreen(settings: settings.passRun);
        final result = await Navigator.of(context).push<MiniGameResult>(
          MaterialPageRoute(builder: (_) => screen),
        );
        if (result != null) controller.completeMiniGame(type, result);
      } finally {
        controller.finishMiniGamePreparation();
      }
      return;
    }
    if (type == TrainingActionType.work) {
      if (controller.isWorkPreparationPending) return;
      final canWork = await controller.prepareWork();
      if (!context.mounted || controller.stageIndex.value < 2) {
        controller.finishWorkPreparation();
        return;
      }
      if (!canWork) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              controller.workAvailabilityError.value.isNotEmpty
                  ? controller.workAvailabilityError.value
                  : '仕事は1日1回までです。',
            ),
          ),
        );
        return;
      }
    }
    bool? completed;
    try {
      completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TrainingGameCareActionScreen(
            actionType: type,
            bodyKey: controller.stageIndex.value == 1
                ? SametarohAssets.childBodyKey
                : _bodyKey,
          ),
        ),
      );
    } finally {
      if (type == TrainingActionType.work) controller.finishWorkPreparation();
    }
    if (completed == true) controller.perform(type);
  }

  /// 集約したデバッグコマンドを表示します。
  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrainingDebugMenu(
        controller: controller,
        onAdvanceTime: () => unawaited(_showAdvanceTimeDialog(context)),
        onStartEgg: _openDebugEgg,
        onReset: () => unawaited(_resetDebugGame(context)),
        onStartTraining: () => unawaited(controller.debugStartAtTraining()),
      ),
    );
  }

  /// デバッグ対象を初期パラメータで再作成し、現在の育成画面へ反映します。
  Future<void> _resetDebugGame(BuildContext context) async {
    final initialState = await controller.resetDebugGame();
    if (!context.mounted) return;
    if (initialState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('初期化に失敗しました。通信状態を確認してください。')),
      );
      return;
    }
    // Controllerへ初期状態を反映済みのため、同一画面の表示を継続します。
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('初回プレイ状態へ初期化しました。')),
    );
  }

  /// デバッグ用に指定した分数だけ本編時間を進めます。
  Future<void> _showAdvanceTimeDialog(BuildContext context) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => const _AdvanceTimeDialog(),
    );
    if (minutes != null) controller.advanceTimeMinutes(minutes);
  }

  /// 10ポジションの図鑑を表示します。
  void _showDex(BuildContext context) {
    // 表示時に最新履歴を取得し、完了を待たずダイアログ側をリアクティブ更新します。
    unawaited(controller.refreshUnlockedPositions().catchError((_) {
      // 取得に失敗した場合は、Controllerが保持している直近の履歴を表示します。
    }));
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.45),
      builder: (_) => Obx(
        () => TrainingDexDialog(
          registeredCount: controller.unlockedPositions.length,
          isPositionUnlocked: controller.isPositionUnlocked,
        ),
      ),
    );
  }
}

/// デバッグ用の経過時間入力ダイアログです。
class _AdvanceTimeDialog extends StatefulWidget {
  /// 経過時間入力ダイアログを作成します。
  const _AdvanceTimeDialog();

  @override
  State<_AdvanceTimeDialog> createState() => _AdvanceTimeDialogState();
}

/// 経過時間入力欄のライフサイクルを管理します。
class _AdvanceTimeDialogState extends State<_AdvanceTimeDialog> {
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '60');
  }

  @override
  void dispose() {
    // ダイアログのWidget破棄後に入力欄を破棄し、親画面の再描画と競合させません。
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('経過時間を指定'),
      content: TextField(
        controller: _minutesController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: '加算する分数',
          suffixText: '分',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('加算'),
        ),
      ],
    );
  }

  /// 入力値を検証し、育成画面へ指定分数を返します。
  void _submit() {
    final value = int.tryParse(_minutesController.text.trim());
    if (value == null || value <= 0) return;
    Navigator.pop(context, value);
  }
}

/// 完了後の次画面を連打で飛ばさないよう、短時間だけ操作を抑止します。
class _EndingStepAdvanceButton extends StatefulWidget {
  const _EndingStepAdvanceButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_EndingStepAdvanceButton> createState() =>
      _EndingStepAdvanceButtonState();
}

class _EndingStepAdvanceButtonState extends State<_EndingStepAdvanceButton> {
  static const _debounce = Duration(milliseconds: 450);

  Timer? _unlockTimer;
  bool _locked = false;

  void _advance() {
    final onPressed = widget.onPressed;
    if (_locked || onPressed == null) return;

    setState(() => _locked = true);
    _unlockTimer = Timer(_debounce, () {
      if (mounted) setState(() => _locked = false);
    });
    onPressed();
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _locked ? null : _advance,
      child: Text(widget.label),
    );
  }
}
