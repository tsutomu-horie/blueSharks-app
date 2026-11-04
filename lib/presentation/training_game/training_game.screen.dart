import 'dart:async';
import 'dart:math' as math;

import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

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
import 'training_home_decoration.dart';
import 'training_presentation_layout.dart';
import 'mini_games/mini_game_selection_frame.dart';
import 'training_home_roaming_character.dart';
import 'training_sync_indicator.dart';
import 'training_debug_menu.dart';
import 'training_home_floor_litter.dart';
import 'training_hud_guide.dart';
import 'training_evolution_reveal.dart';
import 'training_evolution_page_switcher.dart';
import 'training_dex_dialog.dart';
import 'training_game_theme.dart';
import 'training_screen_transitions.dart';
import 'training_retirement_warning_panel.dart';
import 'models/training_retirement_warning.dart';

/// 参照HTMLのスマートフォン画面部分だけをアプリ用に再現します。
class TrainingGameScreen extends GetView<TrainingGameController> {
  static const _meterGuideItems = <String, TrainingHudGuideItem>{
    '食事': TrainingHudGuideItem.food,
    '仕事': TrainingHudGuideItem.work,
    '清潔': TrainingHudGuideItem.cleanliness,
    '体調': TrainingHudGuideItem.condition,
  };

  /// 育成ゲーム画面を作成します。
  const TrainingGameScreen(
      {super.key,
      this.evolutionSoundFactory = createTrainingEvolutionSound,
      this.homeTapSoundFactory = createTrainingHomeTapSound,
      this.careCompletionSound});

  final TrainingGameSoundService Function() evolutionSoundFactory;
  final TrainingGameSoundService Function() homeTapSoundFactory;
  final VoidCallback? careCompletionSound;

  String? get _bodyKey => SametarohAssets.bodyKeyForBranch(controller.branch);

  @override
  Widget build(BuildContext context) {
    return TrainingGameTheme(
      child: Obx(
        () => PopScope(
          canPop: !controller.isReturningHome.value,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              bottom: false,
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
                            : _buildHome(context)
                    : controller.serverErrorMessage.value.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _buildConnectionError();
                final pageKey = !controller.isServerStateReady.value
                    ? 'connection'
                    : shouldShowEvolution
                        ? 'evolution-${controller.evolutionStage.value}'
                        : controller.ended.value
                            ? controller.clearPosition.value != null &&
                                    controller.endingStep.value == 0
                                ? 'evolution-ending-0'
                                : 'ending-${controller.endingStep.value}'
                            : 'home';
                return Stack(
                  children: [
                    TrainingEvolutionPageSwitcher(
                      pageKey: pageKey,
                      child: pageKey == 'home'
                          ? content
                          : SafeArea(top: false, child: content),
                    ),
                    if (controller.isReturningHome.value)
                      _buildReturningHomeOverlay(),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// 縦幅が足りない横画面では、ホーム全体をスクロールして操作を保ちます。
  Widget _buildHome(BuildContext context) {
    final syncBanner = controller.syncStatusMessage.value.isNotEmpty &&
            controller.syncStatus.value != TrainingSyncStatus.syncing
        ? _buildSyncStatusBanner(context)
        : null;
    // Build reactive children here so the surrounding Obx tracks their reads.
    final topPadding = 12.h.clamp(8.0, 16.0);
    final hud = Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: _buildHud(context),
    );
    final room = _buildRoom(context);
    final footer = _buildCareBar(context);
    final textExtra =
        (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0.0, 28.0);
    final minimumHeight = MediaQuery.paddingOf(context).bottom +
        topPadding +
        154.h.clamp(144.0, 208.0) +
        textExtra * 4 +
        TrainingHomeStyle.footerHeight.h.clamp(112.0, 180.0) +
        304.h.clamp(130.0, 420.0);
    return LayoutBuilder(builder: (context, constraints) {
      final bannerHeight = syncBanner == null
          ? 0.0
          : constraints.maxHeight >= minimumHeight
              ? (constraints.maxHeight - minimumHeight).clamp(24.0, 200.0)
              : 64.0;
      final height =
          math.max(constraints.maxHeight, minimumHeight + bannerHeight);
      final content = Column(children: [
        Expanded(
            child: Stack(children: [
          const Positioned.fill(child: TrainingHomeBackground()),
          Column(children: [
            if (syncBanner != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bannerHeight),
                child: SingleChildScrollView(child: syncBanner),
              ),
            hud,
            Expanded(child: room),
          ]),
        ])),
        footer,
      ]);
      if (height <= constraints.maxHeight) return content;
      return SingleChildScrollView(
          child: SizedBox(height: height, child: content));
    });
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
                    child: const Text('再試行'),
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
            1 => _buildPresentationStatic(SametarohAssets.newbornFrame),
            2 => TrainingEvolutionReveal(
                key: const ValueKey('training-evolution-2'),
                beforeFrame: SametarohAssets.newbornFrame,
                afterFrame: currentBodyFrame,
                beforeScale: 1,
                beforeSize: _presentationBodySize,
                afterSize: _presentationBodySize,
                soundFactory: evolutionSoundFactory,
                afterVisual: _buildEvolutionHomeFirstFrame(_bodyKey),
              ),
            3 => TrainingEvolutionReveal(
                key: const ValueKey('training-evolution-3'),
                beforeFrame: SametarohAssets.normalFrames.first,
                afterFrame: currentBodyFrame,
                // 分岐未確定時も通常形を保ち、成長の差はサイズで見せます。
                beforeScale: 1,
                beforeSize: _presentationBodySize,
                afterSize: _presentationBodySize,
                soundFactory: evolutionSoundFactory,
                afterVisual: _buildEvolutionHomeFirstFrame(_bodyKey),
              ),
            _ => _buildPresentationStatic(currentBodyFrame),
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
      afterVisual: confirmedFirstTeamFrame == null
          ? _buildEvolutionHomeFirstFrame(_bodyKey, size: _presentationBodySize)
          : _buildPositionStatic(controller.position),
      beforeScale: 1,
      beforeSize: _presentationBodySize,
      afterSize: confirmedFirstTeamFrame == null
          ? _presentationBodySize
          : _presentationFrameSize(confirmedFirstTeamFrame),
      firstTeam: true,
      soundFactory: evolutionSoundFactory,
    );
  }

  /// ホーム初フレームを使い、一軍の仮表示では指定した演出サイズにそろえます。
  Widget _buildEvolutionHomeFirstFrame(String? bodyKey, {Size? size}) {
    final frame =
        TrainingHomeCharacterFrameSet.forBodyKey(bodyKey).idleFrames.first;
    return TrainingHomeCharacterFrameImage(
      frame: frame,
      width: size?.width ?? _presentationBodySize.width,
      height: size?.height ?? _presentationBodySize.height,
      semanticLabel: '鮫太朗',
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
      final endingSize = endingFrames == null
          ? _presentationBodySize
          : _presentationFrameSize(endingFrames.first);
      final isSyncPending = controller.isEndingSyncPending.value;
      final syncError = controller.endingSyncError.value;
      final canStartNextCycle = !isSyncPending && syncError.isEmpty;
      return _buildEndingPage(
        title: '旅立ち',
        visual: endingVisual,
        visualWidget: endingFrames == null
            ? controller.stageIndex.value == 1
                ? _buildPresentationStatic(SametarohAssets.newbornFrame)
                : null
            : SametarohAnimatedImage(
                frames: endingFrames,
                width: endingSize.width,
                height: endingSize.height,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
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
                decoration: const ShapeDecoration(
                  color: TrainingHomeStyle.navy,
                  shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                child: Text(
                  '図鑑・クリア履歴',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
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
                decoration: const ShapeDecoration(
                  color: Color(0xffe4f4fb),
                  shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                child: Text(
                  '到達 $registeredCount/10',
                  key: const ValueKey('training-completion-registered-count'),
                  style: TextStyle(
                    color: TrainingHomeStyle.navy,
                    fontFamily: 'LINESeedJP',
                    fontSize: 14.sp,
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

                        return MiniGameSelectionFrame(
                          key: ValueKey('training-completion-position-$index'),
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 3.h,
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
                                    fontSize: 12.sp,
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
                    side: const BorderSide(
                        color: TrainingHomeStyle.navy, width: 2),
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
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
    final evolution =
        visualWidget is TrainingEvolutionReveal ? visualWidget : null;
    final pageDuration = evolution == null
        ? const Duration(milliseconds: 900)
        : TrainingEvolutionReveal.pageDuration(evolution.firstTeam);
    final seconds = pageDuration.inMilliseconds / 1000;
    final hold = evolution?.firstTeam == true ? .3 : 0.0;
    final revealSeconds =
        TrainingEvolutionReveal.visualDuration.inMilliseconds / 1000;
    return TrainingEndingEntrance(
        duration: pageDuration,
        soundFactory: evolution?.soundFactory,
        soundEffect: evolution == null
            ? null
            : evolution.firstTeam
                ? TrainingGameSoundEffect.evolutionFirstTeam
                : TrainingGameSoundEffect.evolutionNormal,
        key: ValueKey(
            'ending-entrance-${controller.evolutionStage.value}-${controller.endingStep.value}-$title'),
        builder: (context, animation) => Column(children: [
              SizedBox(
                height: 67,
                child: trainingPresentationAppBar(
                  primary: false,
                  icon: title == '進化'
                      ? Icons.auto_awesome
                      : title == 'ポジション確定'
                          ? Icons.emoji_events
                          : Icons.directions_walk,
                  title: TrainingEndingItem(
                    animation: animation,
                    start: evolution == null
                        ? .2
                        : (revealSeconds + .05 + hold) / seconds,
                    span: evolution == null ? .3 : .3 / seconds,
                    child: Text(title),
                  ),
                ),
              ),
              Expanded(
                  child: TrainingPresentationBody(
                illustration: evolution?.drivenBy(animation, pageDuration) ??
                    TrainingEndingItem(
                      animation: animation,
                      start: 0,
                      child: visualWidget ??
                          Text(visual,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 30.sp,
                                  height: 1.5,
                                  color: TrainingHomeStyle.navy)),
                    ),
                panel: MiniGameSelectionFrame(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: ElevatedButtonTheme(
                    data: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                      backgroundColor: TrainingHomeStyle.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    )),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (message != null) ...[
                        TrainingEndingItem(
                          animation: animation,
                          start: evolution == null
                              ? .45
                              : (revealSeconds + .2 + hold) / seconds,
                          span: evolution == null ? .3 : .3 / seconds,
                          child: Text(message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16.sp.clamp(14.0, 20.0),
                                  fontWeight: FontWeight.w700,
                                  color: TrainingHomeStyle.navy)),
                        ),
                        SizedBox(height: 14.h),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: TrainingEndingItem(
                          animation: animation,
                          start: evolution == null
                              ? .7
                              : (revealSeconds + .4 + hold) / seconds,
                          span: evolution == null ? .3 : .3 / seconds,
                          child: guardRapidTap
                              ? _EndingStepAdvanceButton(
                                  label: buttonLabel, onPressed: onPressed)
                              : ElevatedButton(
                                  onPressed: onPressed,
                                  child: Text(buttonLabel)),
                        ),
                      ),
                    ]),
                  ),
                ),
              )),
            ]));
  }

  /// パラメータと退出ボタン、検証環境限定の開発操作を表示します。
  Widget _buildHud(BuildContext context) {
    return Stack(
      children: [
        _buildHudContent(context),
        if (controller.syncStatus.value == TrainingSyncStatus.syncing)
          Positioned(
            top: 50,
            right: 22.w,
            child: const IgnorePointer(child: TrainingSyncIndicator()),
          ),
      ],
    );
  }

  Widget _buildHudContent(BuildContext context) {
    final textExtra =
        (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0.0, 28.0);
    final panelHeight = 154.h.clamp(144.0, 208.0) + textExtra * 4;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 0, 10.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TrainingHomeFrame(
              key: const ValueKey('training-home-parameter-panel'),
              header: true,
              padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
              child: SizedBox(
                height: panelHeight - 40,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Column(children: [
                        Expanded(child: SizedBox()),
                        Divider(height: 1, color: Color(0xffd2dbe5)),
                        Expanded(child: SizedBox()),
                      ]),
                    ),
                    const Positioned.fill(
                      child: Row(children: [
                        Expanded(child: SizedBox()),
                        VerticalDivider(width: 1, color: Color(0xffd2dbe5)),
                        Expanded(child: SizedBox()),
                      ]),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisExtent: (panelHeight - 56) / 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 16,
                      padding: EdgeInsets.zero,
                      children: const ['食事', '仕事', '清潔', '体調']
                          .map((name) => _buildMeterByName(name, context))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TrainingHomeFrame(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: TextButton(
                    key: const ValueKey('training-home-exit'),
                    onPressed: controller.isReturningHome.value
                        ? null
                        : () => _returnHomeAfterSync(context),
                    style: TextButton.styleFrom(
                      foregroundColor: TrainingHomeStyle.navy,
                      padding: EdgeInsets.zero,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                    child: controller.isReturningHome.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Tooltip(
                            message: '戻る',
                            child: Icon(Icons.arrow_back, size: 28)),
                  ),
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
  Widget _buildMeterByName(String name, BuildContext context) {
    final entry = MapEntry(name, controller.meters[name]!);
    final guideItem = _meterGuideItems[name];
    if (controller.stageIndex.value < 1 || guideItem == null) {
      return _buildMeter(entry);
    }

    final value = controller.careFeedbackPending.value
        ? controller.careFeedbackStartValues[name] ?? entry.value
        : entry.value;
    void showGuide() {
      unawaited(TrainingHudGuide.show(
        context,
        guideItem,
        unlocked: name != '仕事' || controller.stageIndex.value >= 2,
      ));
    }

    return Semantics(
      key: ValueKey<String>('training-home-meter-${guideItem.name}'),
      label: '$name ${value.round()}',
      button: true,
      enabled: true,
      onTap: showGuide,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: showGuide,
        borderRadius: BorderRadius.circular(4),
        child: ExcludeSemantics(child: _buildMeter(entry)),
      ),
    );
  }

  /// 通常100・超過50の表示と数値をまとめます。
  Widget _buildMeter(MapEntry<String, double> entry) => DefaultTextStyle.merge(
        style: const TextStyle(
            fontFamily: 'LINESeedJP', color: TrainingHomeStyle.navy),
        child: TrainingHomeMeter(
          name: entry.key,
          value: controller.careFeedbackPending.value
              ? controller.careFeedbackStartValues[entry.key] ?? entry.value
              : entry.value,
          feedbackVersion: controller.careFeedbackConfirmedVersion.value,
          delta: controller.careFeedback[entry.key] ?? 0,
          feedbackStartValue: controller.careFeedbackStartValues[entry.key],
        ),
      );

  /// 支給屋外背景・図鑑・キャラクター・練習ボタンを配置します。
  Widget _buildRoom(BuildContext context) {
    final canTrain =
        controller.stageIndex.value >= 2 && !controller.ended.value;
    final warningCount = controller.retirementWarnings.length;
    return LayoutBuilder(builder: (context, roomConstraints) {
      final characterBottom = 108.h;
      final warningMinimum = warningCount > 1 ? 110.0 : 64.0;
      // 小画面でも警告の操作領域を確保し、キャラクターと重ねません。
      final characterHeight = warningCount == 0
          ? 184.h
          : (roomConstraints.maxHeight -
                  characterBottom -
                  warningMinimum -
                  24.h)
              .clamp(0.0, 184.h);
      return Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              final warnings = controller.retirementWarnings;
              if (warnings.isEmpty) return const SizedBox.shrink();
              final collapsed = {
                for (final warning in warnings)
                  warning.episode:
                      controller.isRetirementWarningCollapsed(warning),
              };
              return LayoutBuilder(builder: (context, constraints) {
                final availableHeight = constraints.maxHeight -
                    characterBottom -
                    characterHeight -
                    24.h;
                final minimumHeight = warnings.length == 1 ? 64.0 : 110.0;
                final height = availableHeight.clamp(
                    minimumHeight,
                    constraints.maxHeight < minimumHeight
                        ? minimumHeight
                        : constraints.maxHeight);
                Widget panel(TrainingRetirementWarning warning) =>
                    TrainingRetirementWarningPanel(
                      warning: warning,
                      collapsed: collapsed[warning.episode]!,
                      onCollapse: () =>
                          controller.collapseRetirementWarning(warning),
                      onExpand: () =>
                          controller.expandRetirementWarning(warning),
                    );
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding:
                        EdgeInsets.only(top: 12.h, left: 12.w, right: 12.w),
                    child: SizedBox(
                      height: height,
                      child: warnings.length == 1
                          ? panel(warnings.first)
                          : TrainingRetirementWarningsPanel(
                              warnings: warnings,
                              collapsed:
                                  collapsed.values.every((value) => value),
                              onCollapse: () =>
                                  controller.setRetirementWarningsCollapsed(
                                      warnings, true),
                              onExpand: () =>
                                  controller.setRetirementWarningsCollapsed(
                                      warnings, false),
                            ),
                    ),
                  ),
                );
              });
            }),
          ),
          Positioned.fill(
            child: TrainingHomeFloorLitter(
              cleanliness: controller.meters['清潔']!,
              characterFootClearance: characterBottom,
              controlsClearance: 64.h > 12.h + 44 ? 64.h : 12.h + 44,
            ),
          ),
          Positioned(
            left: 12.w,
            bottom: 12.h,
            child: TrainingHomeFrame(
              child: SizedBox(
                width: 144.w.clamp(125.0, 230.0),
                height: 44,
                child: TextButton(
                  key: const ValueKey('training-home-dex'),
                  onPressed: () => _showDex(context),
                  style: _homeAuxiliaryStyle,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.menu_book, size: 24),
                      SizedBox(width: 10),
                      Text('ずかん'),
                      SizedBox(width: 16),
                      Icon(Icons.chevron_right, size: 20),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: characterBottom,
            child: TrainingHomeRoamingCharacter(
              soundFactory: homeTapSoundFactory,
              reactToTap:
                  controller.stageIndex.value >= 1 && !controller.ended.value,
              enabled: canTrain,
              width: 220.w,
              height: characterHeight,
              travelDistance: 28.w,
              preparationKey: _bodyKey ?? 'normal',
              prepareWalk: (context) =>
                  TrainingHomeCharacterFrameSet.forBodyKey(_bodyKey)
                      .precache(context),
              builder: (context, isWalking) => Align(
                alignment: Alignment.bottomCenter,
                child: _buildCharacterVisual(isWalking: isWalking),
              ),
            ),
          ),
          Positioned(
            right: 12.w,
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
                  child: SingleChildScrollView(
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
                  )),
                ),
              ),
            ),
        ],
      );
    });
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

  // 小さかった進化後184と大きかった旅立ち250の中間サイズです。
  Size get _presentationBodySize => Size(
        128.w * TrainingPresentationBody.characterHeight / 184,
        TrainingPresentationBody.characterHeight.h,
      );

  Size _presentationFrameSize(SametarohFrame frame) => Size(
        TrainingPresentationBody.characterHeight.h *
            frame.canvasSize.aspectRatio,
        TrainingPresentationBody.characterHeight.h,
      );

  Widget _buildPresentationStatic(SametarohFrame frame) {
    final size = _presentationFrameSize(frame);
    return SametarohFrameImage(
        frame: frame,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter);
  }

  Widget? _buildPositionStatic(String position) {
    final frame = SametarohAssets.positionFrameFor(position);
    if (frame == null) return null;
    final size = _presentationFrameSize(frame);
    return SametarohFrameImage(
      frame: frame,
      width: size.width,
      height: size.height,
      alignment: Alignment.bottomCenter,
    );
  }

  /// ⑤ミニゲーム選択画面を開く練習ボタンを作成します。
  ButtonStyle get _homeAuxiliaryStyle => TextButton.styleFrom(
        foregroundColor: TrainingHomeStyle.navy,
        disabledForegroundColor: const Color(0xff8192a6),
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(
          fontFamily: 'LINESeedJP',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      );

  Widget _buildTrainingMenuButton(BuildContext context, bool enabled) {
    void openMiniGameSelection() {
      unawaited(_showMiniGameSelection(context));
    }

    final VoidCallback? onTap = enabled ? openMiniGameSelection : null;
    void showGuide() {
      unawaited(TrainingHudGuide.show(
        context,
        TrainingHudGuideItem.miniGame,
        unlocked: enabled,
      ));
    }

    final button = TrainingHomeFrame(
      child: SizedBox(
        width: 144.w.clamp(125.0, 230.0),
        height: 44,
        child: TextButton(
          onPressed: onTap,
          style: _homeAuxiliaryStyle,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sports_rugby, size: 24),
              SizedBox(width: 8),
              Text('練習 / MG'),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ]),
          ),
        ),
      ),
    );
    if (controller.stageIndex.value < 1 || controller.ended.value) {
      return button;
    }

    return TrainingHudGuidePressTarget(
      key: const ValueKey('training-home-training-menu-guide-target'),
      semanticsLabel: '練習 / MG',
      progressDelay: const Duration(milliseconds: 250),
      onTap: onTap,
      onLongPressGuide: showGuide,
      child: button,
    );
  }

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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      key: const ValueKey('training-home-footer'),
      height:
          TrainingHomeStyle.footerHeight.h.clamp(112.0, 180.0) + bottomPadding,
      child: TrainingHomeRibbon(
        footer: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 22 + bottomPadding),
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
    final enabled = !controller.ended.value &&
        tutorialActionAllowed &&
        controller.canPerform(type) &&
        !(type == TrainingActionType.squat &&
            controller.stageIndex.value < 1) &&
        !(type == TrainingActionType.work && controller.stageIndex.value < 2);
    return TrainingHomeCareButton(
      cooldownDuration: controller.cooldownDuration(type),
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

  /// 筋トレ条件や仕事の案内をタップで閉じられるように表示します。
  void _showDismissibleMessage(
    BuildContext context,
    String message, {
    bool removeCurrent = false,
  }) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (removeCurrent) messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: messenger.hideCurrentSnackBar,
          child: SizedBox(width: double.infinity, child: Text(message)),
        ),
      ),
    );
  }

  /// お世話は専用画面の完了操作後、ミニゲームはプレイ結果の受領後に反映します。
  Future<void> _handleAction(
    BuildContext context,
    TrainingActionType type,
  ) async {
    if (type == TrainingActionType.squat) {
      final requirementMessage = controller.squatRequirementMessage;
      if (requirementMessage != null) {
        _showDismissibleMessage(
          context,
          requirementMessage,
          removeCurrent: true,
        );
        return;
      }
    }
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
        _showDismissibleMessage(
          context,
          controller.workAvailabilityError.value.isNotEmpty
              ? controller.workAvailabilityError.value
              : '仕事は1日1回までです。',
        );
        return;
      }
    }
    final finishSquat =
        type == TrainingActionType.squat ? controller.beginSquatScene() : null;
    if (type == TrainingActionType.squat && finishSquat == null) return;
    final feedbackBefore = controller.careFeedbackVersion.value;
    if (careCompletionSound != null) {
      unawaited(TrainingGameSoundService.instance
          .prepare(TrainingGameSoundEffect.careCompleted)
          .then((_) {}));
    }
    bool? completed;
    try {
      final route = TrainingCareRoute<bool>(
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        builder: (_) => TrainingGameCareActionScreen(
          actionType: type,
          bodyKey: controller.stageIndex.value == 1
              ? SametarohAssets.childBodyKey
              : _bodyKey,
          onCompletionSound: careCompletionSound,
        ),
      );
      completed = await Navigator.of(context).push<bool>(route);
      // popの結果は退場開始時に届くため、ホームが現れるまで効果反映を待ちます。
      await route.completed;
    } finally {
      if (type == TrainingActionType.work) controller.finishWorkPreparation();
      finishSquat?.call(completed == true);
    }
    if (completed == true && type != TrainingActionType.squat) {
      controller.perform(type);
    }
    if (context.mounted &&
        controller.careFeedbackVersion.value != feedbackBefore &&
        controller.careFeedback.values.any((delta) => delta > 0)) {
      unawaited(TrainingGameSoundService.instance
          .play(TrainingGameSoundEffect.parameterRecovered));
    }
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
        onStartTraining: () => unawaited(controller.debugStartAtTraining()),
      ),
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
