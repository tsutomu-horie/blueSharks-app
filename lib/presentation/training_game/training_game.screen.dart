import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/training_game.controller.dart';
import 'training_game_care_action.screen.dart';
import 'mini_games/mini_game_selection_thumbnail.dart';
import 'mini_games/models/mini_game_result.dart';
import 'mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'mini_games/tackle/tackle_game.screen.dart';
import 'models/training_game_models.dart';

/// 参照HTMLのスマートフォン画面部分だけをアプリ用に再現します。
class TrainingGameScreen extends GetView<TrainingGameController> {
  /// 育成ゲーム画面を作成します。
  const TrainingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
          () => controller.isServerStateReady.value
              ? controller.evolutionStage.value != null
                  ? _buildEvolutionFlow()
                  : controller.ended.value
                      ? _buildEndingFlow(context)
                      : Column(
                          children: [
                            _buildStatusBar(context),
                            _buildHud(context),
                            Expanded(child: _buildRoom(context)),
                            _buildCareBar(context),
                          ],
                        )
              : controller.serverErrorMessage.value.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildConnectionError(),
        ),
      ),
    );
  }

  /// 通信必須の育成ゲームで、接続失敗時に再試行を案内します。
  Widget _buildConnectionError() {
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
              onPressed: controller.retryRestoreServerState,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  /// ⑧〜⑪の育成完了後フローを表示します。
  Widget _buildEvolutionFlow() {
    final stage = controller.currentStage;
    final visual = switch (controller.evolutionStage.value) {
      1 => '🐣\n幼少へ進化',
      2 => '🦈\n育成期へ進化',
      3 => '🦈\n成長期へ進化',
      _ => '✨\n進化演出',
    };
    return _buildEndingPage(
      title: '進化',
      visual: visual,
      message: '段階「${stage.name}」へ進みました。',
      buttonLabel: '次へ',
      onPressed: controller.advanceEvolution,
    );
  }

  /// ⑧〜⑪の育成完了後フローを表示します。
  Widget _buildEndingFlow(BuildContext context) {
    final isPositive = controller.clearPosition.value != null;
    final step = controller.endingStep.value;
    if (step == 0 && isPositive) {
      return _buildEndingPage(
        title: '進化',
        visual: '✨\n進化演出',
        buttonLabel: '次へ',
        onPressed: controller.advanceEndingStep,
      );
    }
    if (step == 1 && isPositive) {
      return _buildEndingPage(
        title: 'ポジション確定',
        visual: '🦈\nユニフォーム姿',
        message: controller.position,
        buttonLabel: '次へ',
        onPressed: controller.advanceEndingStep,
      );
    }
    if (step <= 2) {
      // 引退時は固定の鮫ではなく、現在の育成段階に対応する見た目を表示します。
      final endingVisual = isPositive
          ? '🦈\n旅立ち'
          : '${controller.characterLabel}\n引退';
      return _buildEndingPage(
        title: '旅立ち',
        visual: endingVisual,
        message: isPositive ? '育成した鮫太朗が旅立ちます。' : '育成を終え、次の卵へ進みます。',
        buttonLabel: isPositive ? '図鑑へ登録' : '次の卵へ',
        onPressed: isPositive ? controller.advanceEndingStep : _openNewEgg,
      );
    }
    return _buildDexPage();
  }

  /// ⑪図鑑・クリア履歴の5列グリッドを表示します。
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
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('図鑑・クリア履歴',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: GridView.builder(
              itemCount: positions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: .78,
              ),
              itemBuilder: (_, index) {
                final unlocked =
                    controller.isPositionUnlocked(positions[index]) ||
                        positions[index] == controller.clearPosition.value;
                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.white : const Color(0xfff1f1f1),
                    border: Border.all(color: const Color(0xffd8d8d8)),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(unlocked ? '🦈' : '👤',
                          style: TextStyle(
                              fontSize: 26.sp,
                              color: unlocked ? null : Colors.grey)),
                      SizedBox(height: 2.h),
                      Text(positions[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 8.sp,
                              color: unlocked ? Colors.black : Colors.grey,
                              fontWeight: unlocked
                                  ? FontWeight.w700
                                  : FontWeight.normal)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
                onPressed: _openNewEgg, child: const Text('次の卵へ')),
          ),
        ],
      ),
    );
  }

  /// 次の育成を開始する前に、卵獲得画面へ遷移します。
  void _openNewEgg() => _openEgg(debugRestart: false);

  /// デバッグ用に現在の育成を卵から再開始します。
  void _openDebugEgg() => _openEgg(debugRestart: true);

  /// 卵獲得画面へ遷移し、必要に応じてデバッグ再開始を引き渡します。
  void _openEgg({required bool debugRestart}) {
    // サーバー上の新規育成作成は、卵獲得画面の「はじめる」後に実行します。
    Get.offNamed(
      Routes.TRAINING_GAME_NEW,
      arguments: {'debugRestart': debugRestart},
    );
  }

  /// 完了後フローの共通画面を作成します。
  Widget _buildEndingPage({
    required String title,
    required String visual,
    required String buttonLabel,
    required VoidCallback onPressed,
    String? message,
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
              child: Text(visual,
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
            child:
                ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }

  /// 参照画面上部のステータスバーとホーム戻り操作を表示します。
  Widget _buildStatusBar(BuildContext context) {
    return Container(
      color: const Color(0xffe9e9e9),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '鮫太朗育成',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => _showDebugMenu(context),
                tooltip: 'デバッグコマンド',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                icon: Icon(Icons.bug_report_outlined, size: 18.sp),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                controller.clockLabel,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 12.w),
              Text(
                '▮▮▮ ᯤ 🔋',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4つの可視パラメータと退出ボタンを表示します。
  Widget _buildHud(BuildContext context) {
    return Container(
      color: const Color(0xfffafafa),
      padding: EdgeInsets.all(8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: const ['食事', '仕事', '清潔', '体調']
                    .map((name) => _buildMeterByName(name))
                    .toList(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 52.w,
            height: 52.w,
            child: ElevatedButton(
              onPressed: _returnHomeAfterSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff5ee05e),
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text('🚪', style: TextStyle(fontSize: 22.sp)),
            ),
          ),
        ],
      ),
    );
  }

  /// 最新状態の同期完了後にホームへ戻ります。
  Future<void> _returnHomeAfterSync() async {
    controller.pauseLocalProgress();
    await controller.syncNow().then((_) {
      Get.back<void>();
    }).catchError((_) {
      // 通信失敗時も画面を閉じ、次回起動時の再同期へ委ねます。
      Get.back<void>();
    });
  }

  /// メーター1項目を作成します。
  Widget _buildMeterByName(String name) {
    return _buildMeter(MapEntry(name, controller.meters[name]!));
  }

  /// メーター1項目を作成します。
  Widget _buildMeter(MapEntry<String, double> entry) {
    const normalMeterMaximum = 100.0;
    const overageMeterMaximum = 50.0;
    final value = entry.value;
    // 通常メーターと超過メーターを、それぞれ左端から右へ伸ばします。
    final normalValue = value.clamp(0, normalMeterMaximum).toDouble();
    final overageValue =
        (value - normalMeterMaximum).clamp(0, overageMeterMaximum).toDouble();
    final color = value <= 19
        ? const Color(0xffd03b3b)
        : value < 50
            ? const Color(0xffeda100)
            : value < 80
                ? const Color(0xff7ec8f0)
                : const Color(0xff5ee05e);
    return Row(
      children: [
        SizedBox(
          width: 25.w,
          child: Text(entry.key, style: TextStyle(fontSize: 10.sp)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // それぞれの上限を基準に、ゲージの実幅へ変換します。
              final normalWidth =
                  constraints.maxWidth * (normalValue / normalMeterMaximum);
              final overageWidth =
                  constraints.maxWidth * (overageValue / overageMeterMaximum);
              return Container(
                height: 12.h,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xffedf0f2),
                  border: Border.all(color: const Color(0xff252a2e)),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  children: [
                    // 通常値は0〜100をゲージ左端から表示します。
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: normalWidth,
                      child: ColoredBox(color: color),
                    ),
                    if (overageWidth > 0)
                      Positioned(
                        // 超過値は斜線を使わず、赤色のゲージとして左端から表示します。
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: overageWidth,
                        child: const ColoredBox(color: Color(0xffd03b3b)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 22.w,
          child: Text(
            '${entry.value.round()}',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10.sp),
          ),
        ),
      ],
    );
  }

  /// 壁・床・図鑑・キャラクター・練習ボタンを配置します。
  Widget _buildRoom(BuildContext context) {
    final canTrain =
        controller.stageIndex.value >= 2 && !controller.ended.value;
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Expanded(child: Container(color: const Color(0xffd8d8d8))),
              Expanded(child: Container(color: const Color(0xff8a5a2b))),
            ],
          ),
        ),
        Positioned(
          top: 70.h,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '壁',
              style: TextStyle(
                color: const Color(0xff8d8d8d),
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
        Positioned(
          top: 235.h,
          left: 60.w,
          child: Text(
            '床',
            style: TextStyle(
              color: const Color(0xfff0e3d4),
              fontSize: 15.sp,
            ),
          ),
        ),
        Positioned(
          left: 12.w,
          bottom: 12.h,
          child: IconButton(
            onPressed: () => _showDex(context),
            icon: Text('📙', style: TextStyle(fontSize: 26.sp)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 126.h,
          child: Column(
            children: [
              _buildCharacterBadge(),
              Text(
                controller.characterLabel,
                style: TextStyle(fontSize: controller.characterFontSize.sp),
              ),
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
        Positioned(
          right: 8.w,
          bottom: 4.h,
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
  Widget _buildTrainingMenuButton(
    BuildContext context,
    bool enabled,
  ) {
    return ElevatedButton(
      onPressed: enabled ? () => _showMiniGameSelection(context) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
      child: Column(
        children: [
          Text(
            '練習',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          Text(
            '練習 / MG',
            style: TextStyle(fontSize: 9.sp, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// 2種のルールを集約した⑤ミニゲーム選択画面を表示します。
  Future<void> _showMiniGameSelection(BuildContext context) async {
    final selected = await showModalBottomSheet<TrainingActionType>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ミニゲームを選ぶ',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              _buildMiniGameCard(
                context: sheetContext,
                type: TrainingActionType.tackle,
                title: '① タックル',
                tag: 'タイミング・反応系',
                thumbnailType: MiniGameSelectionThumbnailType.tackle,
                description:
                    '踏み込み（フェイント）の反対＝相手が実際に動く方向を、0.5秒以内に上／下タップ。全3セットの平均反応速度でスコア化。',
              ),
              SizedBox(height: 10.h),
              _buildMiniGameCard(
                context: sheetContext,
                type: TrainingActionType.passAndRun,
                title: '② パス＆ラン',
                tag: 'フリック・パス回し系',
                thumbnailType: MiniGameSelectionThumbnailType.passAndRun,
                description:
                    '縦2レーンを上下に並走。仲間にボールを当てると成功。外れたボールは2秒間パス不可。15秒×往復2セットです。',
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await _handleAction(context, selected);
  }

  /// ミニゲーム選択画面のルールカードを作成します。
  Widget _buildMiniGameCard({
    required BuildContext context,
    required TrainingActionType type,
    required String title,
    required String tag,
    required MiniGameSelectionThumbnailType thumbnailType,
    required String description,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xfff5f7fa),
          border: Border.all(color: const Color(0xffc8d0d9)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xfff6f2ff),
                    border: Border.all(color: const Color(0xffc9bfe0)),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                        fontSize: 11.sp, color: const Color(0xff6b5aa0)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            MiniGameSelectionThumbnail(type: thumbnailType),
            SizedBox(height: 10.h),
            Text(
              description,
              style: TextStyle(
                  fontSize: 14.sp, height: 1.55, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            careActions.map((type) => _buildCareButton(context, type)).toList(),
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
    return TextButton(
      onPressed: enabled ? () => _handleAction(context, type) : null,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: EdgeInsets.zero,
      ),
      child: Column(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xff7ec8f0),
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(action.icon, style: TextStyle(fontSize: 23.sp)),
                if (type == TrainingActionType.squat &&
                    controller.stageIndex.value == 1)
                  Positioned(
                    right: -8.w,
                    bottom: -4.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: const Color(0xffb26a00),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${controller.trainingCount.value}/15',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(action.label, style: TextStyle(fontSize: 10.sp)),
          if (controller.cooldownLabel(type).isNotEmpty)
            Text(
              controller.cooldownLabel(type),
              style: TextStyle(fontSize: 9.sp, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  /// お世話は専用画面の完了操作後、ミニゲームはプレイ結果の受領後に反映します。
  Future<void> _handleAction(
    BuildContext context,
    TrainingActionType type,
  ) async {
    if (type == TrainingActionType.tackle ||
        type == TrainingActionType.passAndRun) {
      final screen = type == TrainingActionType.tackle
          ? const TackleGameScreen()
          : const PassAndRunGameScreen();
      final result = await Navigator.of(context).push<MiniGameResult>(
        MaterialPageRoute(builder: (_) => screen),
      );
      if (result != null) {
        controller.completeMiniGame(type, result);
      }
      return;
    }
    if (type == TrainingActionType.work) {
      if (controller.isWorkPreparationPending) return;
      final canWork = await controller.prepareWork();
      if (!context.mounted) {
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
          builder: (_) => TrainingGameCareActionScreen(actionType: type),
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
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * .85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '現在：${controller.day.value}日目　／　${controller.currentStage.name} ${controller.daysInStage.value}/${controller.currentStage.days ?? '-'}日',
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (controller.stageIndex.value < 2) ...[
              ListTile(
                leading: const Icon(Icons.pause),
                title: const Text('⏸ 停止'),
                onTap: () {
                  controller.setTimeSpeed(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('▶ ×1'),
                onTap: () {
                  controller.setTimeSpeed(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward),
                title: const Text('×4'),
                onTap: () {
                  controller.setTimeSpeed(4);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.double_arrow),
                title: const Text('×16'),
                onTap: () {
                  controller.setTimeSpeed(16);
                  Navigator.pop(context);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.pause),
                title: const Text('⏸ 停止'),
                onTap: () {
                  controller.setTimeSpeed(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('▶ ×1'),
                onTap: () {
                  controller.setTimeSpeed(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward),
                title: const Text('×4'),
                onTap: () {
                  controller.setTimeSpeed(4);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.double_arrow),
                title: const Text('×16'),
                onTap: () {
                  controller.setTimeSpeed(16);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text('経過時間を指定'),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(_showAdvanceTimeDialog(context));
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('＋1時間'),
                onTap: () {
                  Navigator.pop(context);
                  controller.advanceTime(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('＋6時間'),
                onTap: () {
                  Navigator.pop(context);
                  controller.advanceTime(6);
                },
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: const Text('＋1日'),
                onTap: () {
                  Navigator.pop(context);
                  controller.advanceTime(24);
                },
              ),
            ],
            // デバッグ時だけ、行動ごとのクールタイム適用状態を切り替えます。
            Obx(
              () => Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.timer),
                    title: Text('行動別クールタイム'),
                    subtitle: Text('正式値調整用。既定値はお世話のみ有効です。'),
                  ),
                  ...TrainingGameController.actions.map(
                    (action) => SwitchListTile(
                      dense: true,
                      title: Text(action.label),
                      subtitle: Text(
                        TrainingGameController.isCooldownAction(action.type)
                            ? '${TrainingGameController.careCooldown.inSeconds}秒'
                            : '通常は無効（デバッグで変更可能）',
                      ),
                      value: controller.isCooldownEnabled(action.type),
                      onChanged: (enabled) => controller.setCooldownEnabled(
                        action.type,
                        enabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('🥚 段階1（卵）から開始'),
              onTap: () {
                Navigator.pop(context);
                _openDebugEgg();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('初回プレイ状態へ初期化'),
              subtitle: const Text('サーバー・端末の履歴を削除して、初期パラメータで開始します'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_resetDebugGame(context));
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('段階3（育成期）から開始'),
              onTap: () {
                Navigator.pop(context);
                controller.debugStartAtTraining();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('閉じる'),
              onTap: () => Navigator.pop(context),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// デバッグ対象を初期パラメータで再作成し、現在の育成画面へ反映します。
  Future<void> _resetDebugGame(BuildContext context) async {
    final initialState = await controller.resetDebugGame();
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
        () => Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 64.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .8,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: const Color(0xff1f6feb),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 9.w),
                      Expanded(
                        child: Text(
                          '📙 ずかん（${controller.unlockedPositions.length}/10 登録）',
                          style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    controller.unlockedPositions.isEmpty
                        ? '一軍で待っている10のポジション。\nいまはまだすべて未解放です。育て方しだいで、どれか1つに到達します。'
                        : '一軍で待っている10のポジション。\n解放したポジションは登録済みとして表示されます。',
                    style: TextStyle(
                      color: const Color(0xff5b6672),
                      fontSize: 12.5.sp,
                      height: 1.75,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _dexPositions.map((position) {
                          final unlocked =
                              controller.isPositionUnlocked(position.name);
                          return _buildDexCard(position, unlocked);
                        }).toList(),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// シミュレータHTMLの図鑑カードと同じ構成でポジションを表示します。
  Widget _buildDexCard(_DexPosition position, bool unlocked) {
    final borderColor =
        unlocked ? const Color(0xff1f6feb) : const Color(0xffdfe4ea);
    final backgroundColor =
        unlocked ? const Color(0xffe8f0fe) : const Color(0xfffafbfc);
    return Opacity(
      opacity: unlocked ? 1 : .75,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xff8a8f96),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    position.number,
                    style: TextStyle(color: Colors.white, fontSize: 10.5.sp),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    position.name,
                    style:
                        TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  unlocked ? '✅ 登録済み' : '🔒 未解放',
                  style: TextStyle(
                    color: unlocked
                        ? const Color(0xff1f6feb)
                        : const Color(0xff5b6672),
                    fontSize: 11.sp,
                    fontWeight: unlocked ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            _buildDexDetail('役割', position.role),
            _buildDexDetail('資質', position.talent),
          ],
        ),
      ),
    );
  }

  /// 図鑑カード内の説明行を表示します。
  Widget _buildDexDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(color: Color(0xff5b6672)),
            ),
            TextSpan(text: value),
          ],
        ),
        style: TextStyle(fontSize: 11.5.sp, height: 1.65),
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

/// 図鑑に表示するポジション説明です。
class _DexPosition {
  const _DexPosition({
    required this.number,
    required this.name,
    required this.role,
    required this.talent,
  });

  final String number;
  final String name;
  final String role;
  final String talent;
}

/// シミュレータHTMLの10ポジション定義を図鑑表示用に整理します。
const _dexPositions = <_DexPosition>[
  _DexPosition(
      number: '1・3',
      name: 'プロップ',
      role: 'スクラム最前列。組み合いを支える土台',
      talent: '体重と押す力'),
  _DexPosition(
      number: '2', name: 'フッカー', role: '最前列の中央。ボールを掻き出す', talent: '正確性と技術'),
  _DexPosition(
      number: '4・5',
      name: 'ロック',
      role: '第2列。スクラムとラインアウトを支える',
      talent: '上背とパワー'),
  _DexPosition(
      number: '6・7',
      name: 'フランカー',
      role: '第3列の両サイド。接点へ最速で到達',
      talent: '運動量・タックル・スピード'),
  _DexPosition(
      number: '8', name: 'ナンバーエイト', role: '第3列の中央。ボールを持ち出す', talent: 'パワーと判断力'),
  _DexPosition(
      number: '9',
      name: 'スクラムハーフ',
      role: 'フォワードとバックスの接続点',
      talent: 'テンポ・展開の速さ'),
  _DexPosition(
      number: '10',
      name: 'スタンドオフ',
      role: '攻撃の司令塔。陣形とテンポを決める',
      talent: '判断力・状況把握'),
  _DexPosition(
      number: '12・13',
      name: 'センター',
      role: '中央で突破し、防御では相手を止める',
      talent: '突進力とコンタクト耐性'),
  _DexPosition(
      number: '11・14', name: 'ウイング', role: '最外側のフィニッシャー', talent: '純粋なスピード'),
  _DexPosition(
      number: '15',
      name: 'フルバック',
      role: '最後尾。攻撃の起点になる',
      talent: '空中戦・キック処理・広い視野'),
];
