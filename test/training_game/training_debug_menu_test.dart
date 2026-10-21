import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_debug_menu.dart';

class _MenuController extends TrainingGameController {
  final advancedHours = <int>[];
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  void advanceTime(int hours) => advancedHours.add(hours);
}

void main() {
  late _MenuController controller;
  late List<String> callbacks;

  setUp(() {
    controller = _MenuController()..stageIndex.value = 2;
    callbacks = [];
    Get.testMode = true;
  });
  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TrainingDebugMenu(
                      controller: controller,
                      onAdvanceTime: () => callbacks.add('minutes'),
                      onStartEgg: () => callbacks.add('egg'),
                      onStartTraining: () => callbacks.add('training'),
                      onReset: () => callbacks.add('reset'),
                    ),
                  ),
                  child: const Text('開く'),
                ),
              )),
    ));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('開くだけでは状態変更せず、現在値と速度の選択を表示する', (tester) async {
    await open(tester);
    expect(callbacks, isEmpty);
    expect(controller.advancedHours, isEmpty);
    expect(find.textContaining('現在：'), findsOneWidget);
    expect(find.textContaining('分岐：判定前'), findsOneWidget);
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((chip) => chip.selected);
    expect(selected.map((chip) => (chip.label as Text).data), ['×1']);
    await tester.tap(find.text('×16'));
    await tester.pumpAndSettle();
    expect(controller.timeSpeed.value, 16);
    expect(find.byType(TrainingDebugMenu), findsNothing);
  });

  testWidgets('現在段階の日数を維持し、小さい画面でも閉じる操作へ到達する', (tester) async {
    controller.daysInStage.value = 3;
    await open(tester);
    expect(find.textContaining('3/'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(ListTile, '閉じる'));
    expect(find.byType(TrainingDebugMenu), findsNothing);
    expect(callbacks, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final hours in [1, 6, 24]) {
    testWidgets('定型時間$hoursは従来の時間加算を一度だけ呼ぶ', (tester) async {
      await open(tester);
      await tapVisible(tester, find.text(hours == 24 ? '＋1日' : '＋$hours時間'));
      expect(controller.advancedHours, [hours]);
      expect(callbacks, isEmpty);
    });
  }

  testWidgets('分数指定は既存入力へ進み、幼少期では本編加算を表示しない', (tester) async {
    await open(tester);
    await tapVisible(tester, find.text('経過時間を指定'));
    expect(callbacks, ['minutes']);
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    controller.stageIndex.value = 1;
    await tester.pump();
    expect(find.text('経過時間を指定'), findsNothing);
    expect(find.text('＋6時間'), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(4));
  });

  testWidgets('待ち時間は全行動を維持し、詳細を開いて切り替えられる', (tester) async {
    await open(tester);
    expect(find.byType(SwitchListTile), findsNWidgets(4));
    final clean = find.byType(SwitchListTile).at(1);
    await tapVisible(tester, clean);
    expect(controller.isCooldownEnabled(TrainingActionType.clean), false);
    await tapVisible(tester, find.text('仕事・練習の待ち時間（詳細）'));
    expect(find.byType(SwitchListTile), findsNWidgets(7));
    final work = find.widgetWithText(SwitchListTile, '仕事');
    await tapVisible(tester, work);
    expect(controller.isCooldownEnabled(TrainingActionType.work), true);
    expect(callbacks, isEmpty);
    expect(controller.advancedHours, isEmpty);
  });

  for (final entry in {
    '🥚 段階1（卵）から開始': 'egg',
    '段階3（育成期）から開始': 'training',
    '初回プレイ状態へ初期化': 'reset'
  }.entries) {
    testWidgets('${entry.key}は対象確認・取消・明示実行を区別する', (tester) async {
      await open(tester);
      await tapVisible(tester, find.widgetWithText(ListTile, entry.key));
      expect(find.textContaining('対象：現在開いている育成データ'), findsOneWidget);
      expect(callbacks, isEmpty);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(callbacks, isEmpty);
      await tapVisible(tester, find.widgetWithText(ListTile, entry.key));
      await tester.tap(find.text('実行する'));
      await tester.pumpAndSettle();
      expect(callbacks, [entry.value]);
      expect(find.byType(TrainingDebugMenu), findsNothing);
    });
  }
}
