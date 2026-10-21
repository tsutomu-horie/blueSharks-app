import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_debug_growth.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_debug_growth_dialog.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> optionsJson() => {
      'branches': [
        {'code': 'FW', 'name': 'フォワード型'},
        {'code': 'COMMAND', 'name': '司令塔型'},
        {'code': 'BACKS', 'name': 'バックス型'}
      ],
      'current_game': {
        'id': 7,
        'cycle_no': 3,
        'lock_version': 4,
        'stage_code': 'training',
        'started_at': '2026-10-20T00:00:00.000Z'
      },
    };

class GrowthProvider extends TrainingGameProvider {
  int starts = 0;
  int reads = 0;
  String branch = 'FW';
  bool changed = false;
  bool loseResponse = false;
  bool failOptions = false;
  Completer<void>? gate;
  Completer<void>? readGate;
  Map<String, dynamic> payload() => {
        'id': 7,
        'cycle_no': changed ? 4 : 3,
        'lock_version': changed ? 5 : 4,
        'stage_code': changed ? 'growth' : 'training',
        'status': 'playing',
        'started_at':
            changed ? '2026-10-21T00:00:00.000Z' : '2026-10-20T00:00:00.000Z',
        'server_time': '2026-10-21T00:00:00.000Z',
        'elapsed_seconds': changed ? 0 : 86400,
        'branch_code': changed ? branch : null,
        'position_code': null,
        'work_available': false,
        'actions_today': 2,
        'cooldowns': <String, dynamic>{},
        'parameters': {
          'hunger': 100,
          'cleanliness': 100,
          'condition': 100,
          'work': 20
        },
      };
  @override
  Future<Map<String, dynamic>> start(
          {required String stageCode,
          required Map<String, double> parameters,
          bool forceRestart = false,
          int? expectedSessionVersion}) async =>
      payload();
  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      ['prop'];
  @override
  Future<Map<String, dynamic>> fetchDebugGrowthOptions(
      {int? expectedSessionVersion}) async {
    if (failOptions) throw StateError('API not available');
    return optionsJson();
  }

  @override
  Future<Map<String, dynamic>> startDebugGrowth(Map<String, dynamic> selection,
      {int? expectedSessionVersion}) async {
    starts++;
    expect(selection['confirm_replace'], true);
    expect(selection['expected_cycle_no'], 3);
    await gate?.future;
    branch = selection['branch_code'];
    changed = true;
    if (loseResponse) throw TimeoutException('response lost');
    return payload();
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    reads++;
    final result = payload();
    await readGate?.future;
    return result;
  }
}

class _SessionSwitchingStore extends InMemorySharedPreferencesStore {
  _SessionSwitchingStore() : super.empty();
  bool switchOnRemove = false;
  @override
  Future<bool> remove(String key) async {
    final removed = await super.remove(key);
    if (switchOnRemove && key.endsWith('trainingGameDebugElapsedSeconds')) {
      switchOnRemove = false;
      await AuthToken.notifySessionChangedForTesting();
      await MySharedPref.setTrainingGameLocalState('new-member-state');
    }
    return removed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  for (final branch in ['FW', 'COMMAND', 'BACKS']) {
    test('サーバー確認済みの$branchで成長期を開始する', () async {
      final provider = GrowthProvider();
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.debugStartAtTraining();
      final options = await controller.fetchDebugGrowthOptions();
      await controller.debugStartGrowth(options, branch);
      expect(controller.stageIndex.value, 3);
      expect(controller.branch,
          {'FW': 'A フォワード型', 'COMMAND': 'B 司令塔型', 'BACKS': 'C バックス型'}[branch]);
      expect(controller.position, '判定前');
      expect(controller.day.value, 1);
      expect(controller.elapsedHours.value, 0);
      expect(controller.canWorkToday, false);
      expect(controller.ended.value, false);
      expect(provider.starts, 1);
    });
  }

  test('開始中の二重開始、行動、時間加算を抑止する', () async {
    final provider = GrowthProvider()..gate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    final options = await controller.fetchDebugGrowthOptions();
    final starting = controller.debugStartGrowth(options, 'FW');
    await Future<void>.delayed(Duration.zero);
    expect(controller.isStartingDebugGrowth.value, true);
    await expectLater(
        controller.debugStartGrowth(options, 'BACKS'), throwsStateError);
    controller.perform(TrainingActionType.rest);
    controller.advanceTime(1);
    expect(controller.elapsedHours.value, 0);
    provider.gate!.complete();
    await starting;
    expect(provider.starts, 1);
    expect(controller.isStartingDebugGrowth.value, false);
  });

  test('開始前から取得中の旧状態を待ち、新サイクルを旧応答で戻さない', () async {
    final provider = GrowthProvider()..readGate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    final options = await controller.fetchDebugGrowthOptions();
    final restoring = controller.retryRestoreServerState();
    await Future<void>.delayed(Duration.zero);
    final starting = controller.debugStartGrowth(options, 'FW');
    await Future<void>.delayed(Duration.zero);
    expect(provider.starts, 0);
    provider.readGate!.complete();
    await restoring;
    await starting;
    expect(controller.stageIndex.value, 3);
    expect(controller.branch, 'A フォワード型');
  });

  test('端末保存の消去中に会員が変わっても新会員の保存を消さない', () async {
    final provider = GrowthProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    final options = await controller.fetchDebugGrowthOptions();
    final store = _SessionSwitchingStore()..switchOnRemove = true;
    SharedPreferencesStorePlatform.instance = store;
    await expectLater(
        controller.debugStartGrowth(options, 'FW'), throwsStateError);
    expect(MySharedPref.getTrainingGameLocalState(), 'new-member-state');
    expect(provider.starts, 1);
    expect(provider.reads, 0);
  });

  test('応答喪失では開始要求を再送せず現在状態を取得する', () async {
    final provider = GrowthProvider()..loseResponse = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    final options = await controller.fetchDebugGrowthOptions();
    await expectLater(
        controller.debugStartGrowth(options, 'BACKS'), throwsStateError);
    expect(provider.starts, 1);
    expect(provider.reads, 1);
    expect(controller.stageIndex.value, 3);
    expect(controller.branch, 'C バックス型');
    expect(controller.isStartingDebugGrowth.value, false);
  });

  test('不明な分岐や置換対象なしでは開始しない', () {
    expect(() => TrainingDebugGrowthOptions.fromJson({}), throwsStateError);
    expect(
        () =>
            TrainingDebugGrowthOptions.fromJson(optionsJson()).request('prop'),
        throwsStateError);
  });

  testWidgets('分岐選択後に置換対象と影響を表示し、取消では開始しない', (tester) async {
    final provider = GrowthProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await tester.runAsync(controller.debugStartAtTraining);
    await tester.pumpWidget(
        MaterialApp(home: TrainingDebugGrowthDialog(controller: controller)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '確認へ'))
            .onPressed,
        isNull);
    await tester.tap(find.text('司令塔型'));
    await tester.pump();
    await tester.tap(find.text('確認へ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('開始先：成長期／司令塔型'), findsOneWidget);
    expect(find.textContaining('当日の仕事制限は引き継ぎます'), findsOneWidget);
    expect(provider.starts, 0);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(provider.starts, 0);
  });

  testWidgets('サーバー未対応なら選択・開始を許可せず、通常開始へ代替しない', (tester) async {
    final provider = GrowthProvider()..failOptions = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await tester.runAsync(controller.debugStartAtTraining);
    await tester.pumpWidget(
        MaterialApp(home: TrainingDebugGrowthDialog(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.textContaining('サーバーの対応状況'), findsOneWidget);
    expect(find.text('確認へ'), findsNothing);
    expect(find.text('成長期から開始する'), findsNothing);
    expect(provider.starts, 0);
  });

  testWidgets('確認後だけ開始し、連打しても一度だけ送る', (tester) async {
    final provider = GrowthProvider()..gate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await tester.runAsync(controller.debugStartAtTraining);
    await tester.pumpWidget(
        MaterialApp(home: TrainingDebugGrowthDialog(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('バックス型'));
    await tester.pump();
    await tester.tap(find.text('確認へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('成長期から開始する'));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '開始を確認中…'))
            .onPressed,
        isNull);
    provider.gate!.complete();
    await tester.pumpAndSettle();
    expect(provider.starts, 1);
  });
}
