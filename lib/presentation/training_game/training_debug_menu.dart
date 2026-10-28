import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

/// テスト用操作を用途別に並べます。保存・権限判定は既存処理に委ねます。
class TrainingDebugMenu extends StatelessWidget {
  const TrainingDebugMenu({
    super.key,
    required this.controller,
    required this.onAdvanceTime,
    required this.onStartEgg,
    required this.onStartTraining,
  });

  final TrainingGameController controller;
  final VoidCallback onAdvanceTime;
  final VoidCallback onStartEgg;
  final VoidCallback onStartTraining;

  @override
  Widget build(BuildContext context) => Obx(() => IgnorePointer(
      ignoring: controller.debugPositionBusy.value,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() => ListTile(
                      title: Text(
                        '現在：${controller.day.value}日目 ／ ${controller.currentStage.name} ${controller.daysInStage.value}/${controller.currentStage.days ?? '-'}日',
                      ),
                      subtitle: Text(
                        '${controller.clockLabel}\n分岐：${controller.branch ?? '判定前'} ／ ポジション：${controller.position}\n確定位置：${controller.debugResolvedPosition}',
                      ),
                    )),
                const Divider(),
                const ListTile(
                  title: Text('時間操作'),
                  subtitle: Text('倍速・停止は卵／幼少期の時間に適用します。本編の時間加算は下の操作です。'),
                ),
                Obx(() => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final speed in [0, 1, 4, 16])
                            ChoiceChip(
                              label: Text(speed == 0 ? '⏸ 停止' : '×$speed'),
                              selected: controller.timeSpeed.value == speed,
                              onSelected: (_) {
                                controller.setTimeSpeed(speed);
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    )),
                Obx(() => controller.stageIndex.value >= 2
                    ? Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_calendar),
                            title: const Text('経過時間を指定'),
                            subtitle:
                                const Text('指定した分数を加算します。自然減衰・段階移行も処理されます。'),
                            onTap: () {
                              Navigator.pop(context);
                              onAdvanceTime();
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final hours in [1, 6, 24])
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      controller.advanceTime(hours);
                                    },
                                    child:
                                        Text(hours == 24 ? '＋1日' : '＋$hours時間'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink()),
                const Divider(),
                const ListTile(
                  title: Text('行動別クールタイム'),
                  subtitle:
                      Text('ONで待ち時間を適用、OFFで解除を要求します。サーバーに拒否された操作は保存されません。'),
                ),
                ...TrainingGameController.actions
                    .where((action) =>
                        TrainingGameController.isCooldownAction(action.type))
                    .map((action) => Obx(() => SwitchListTile(
                          dense: true,
                          title: Text(action.label),
                          subtitle: Text(
                              '${TrainingGameController.careCooldown.inSeconds}秒'),
                          value: controller.isCooldownEnabled(action.type),
                          onChanged: (enabled) => controller.setCooldownEnabled(
                              action.type, enabled),
                        ))),
                ExpansionTile(
                  title: const Text('仕事・練習の待ち時間（詳細）'),
                  subtitle: const Text('通常はOFF。仕事の1日1回制限とは別の設定です。'),
                  children: [
                    ...TrainingGameController.actions
                        .where((action) =>
                            !TrainingGameController.isCooldownAction(
                                action.type))
                        .map((action) => Obx(() => SwitchListTile(
                              dense: true,
                              title: Text(action.label),
                              value: controller.isCooldownEnabled(action.type),
                              onChanged: (enabled) => controller
                                  .setCooldownEnabled(action.type, enabled),
                            ))),
                  ],
                ),
                const Divider(),
                if (AppEnvironment.showsTrainingDebugUi) ...[
                  ListTile(
                    leading: const Icon(Icons.push_pin),
                    title: const Text('進化先ポジションを固定・解除'),
                    subtitle: const Text('現在の育成周期だけに適用。次の周期には引き継ぎません。'),
                    onTap: () => _positionCommand(context, false),
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('育成完了までスキップ'),
                    subtitle: const Text('固定済み位置、又は現在の傾向から確定する位置で正常完了します。'),
                    onTap: () => _positionCommand(context, true),
                  ),
                  const Divider(),
                ],
                const ListTile(title: Text('開始状態の変更')),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('🥚 段階1（卵）から開始'),
                  subtitle: const Text('現在の育成をやり直します。'),
                  onTap: () => _confirm(
                      context, '卵から開始', '現在の育成を終了し、卵からやり直します。', onStartEgg),
                ),
                ListTile(
                  leading: const Icon(Icons.skip_next),
                  title: const Text('段階3（育成期）から開始'),
                  subtitle: const Text('現在の育成を初期パラメータでやり直します。'),
                  onTap: () => _confirm(context, '育成期から開始',
                      '現在の育成を終了し、育成期の初期パラメータでやり直します。', onStartTraining),
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
      )));

  Future<void> _positionCommand(BuildContext context, bool complete) async {
    try {
      final options = await controller.loadDebugPositionOptions();
      if (!context.mounted) return;
      final target = Map<String, dynamic>.from(options['current_game'] as Map);
      final positions = (options['positions'] as List).cast<Map>();
      String? selected = target['position_code'] as String?;
      if (!positions.any((p) => p['position_code'] == selected)) {
        selected = null;
      }
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
                builder: (dialogContext, setState) => AlertDialog(
                  title: Text(complete ? '育成完了までスキップ' : '進化先を固定・解除'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('対象：育成ID ${target['id']} / 周期 ${target['cycle_no']}\n'
                        '${complete ? '現在の育成を正常完了し、履歴・図鑑へ登録します。' : '指定位置は現在周期の傾向値より優先します。解除時は現在の傾向から大別を再判定し、位置は未確定へ戻します。'}\n'
                        'テスト専用アカウントであることを確認してください。'),
                    if (!complete)
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selected ?? '',
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('固定解除（未確定へ戻す）')),
                          ...positions.map((p) => DropdownMenuItem(
                              value: p['position_code'] as String,
                              child: Text(p['name'] as String)))
                        ],
                        onChanged: (value) => setState(
                            () => selected = value == '' ? null : value),
                      ),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('キャンセル')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('実行する')),
                  ],
                ),
              ));
      if (confirmed != true || !context.mounted) return;
      await controller.applyDebugPosition(target,
          complete: complete, positionCode: selected);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text('デバッグ操作を実行できませんでした'),
                content: Text('$error'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('閉じる'))
                ],
              ));
    }
  }

  Future<void> _confirm(BuildContext context, String title, String effect,
      VoidCallback action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
            '対象：現在開いている育成データ（${controller.currentStage.name}）\n$effect\nテスト用データであることを確認してください。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('実行する')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.pop(context);
    action();
  }
}
