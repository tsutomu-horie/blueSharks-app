import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game_new_game.controller.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StartProvider extends TrainingGameProvider {
  Map<String, dynamic>? current;
  int starts = 0;
  int fetches = 0;
  String? requestedStage;
  Map<String, double>? requestedParameters;
  bool requestedRestart = false;
  bool loseResponse = false;
  bool failStart = false;
  bool failFetch = false;
  String responseStage = 'child';
  Completer<void>? fetchGate;
  Completer<void>? startGate;

  @override
  Future<Map<String, dynamic>?> fetchCurrent({int? expectedSessionVersion}) async {
    fetches++;
    await fetchGate?.future;
    if (failFetch) throw StateError('offline');
    return current;
  }

  @override
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async {
    starts++;
    requestedStage = stageCode;
    requestedParameters = parameters;
    requestedRestart = forceRestart;
    await startGate?.future;
    if (failStart) throw StateError('offline');
    current = {
      'id': 8,
      'cycle_no': (current?['cycle_no'] as int? ?? 0) + 1,
      'stage_code': responseStage,
      'status': 'playing',
      'parameters': parameters,
    };
    if (loseResponse) throw TimeoutException('response lost after save');
    return current!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  test('新規開始はchildと既存初期値を保存し、旧サイクルのローカル状態を破棄する', () async {
    await MySharedPref.setTrainingGameLocalState('{"cycle_no":0}');
    await MySharedPref.setTrainingGameDebugElapsedSeconds(500);
    final provider = _StartProvider();
    final controller = TrainingGameNewGameController(provider: provider);
    final state = await controller.startNewGame();
    expect(provider.starts, 1);
    expect(provider.requestedStage, 'child');
    expect(provider.requestedParameters, {
      'hunger': 100, 'cleanliness': 50, 'condition': 50, 'work': 0,
      'tendency_fw': 0, 'tendency_command': 0, 'tendency_backs': 0,
      'tendency_bulk': 0, 'tendency_tech': 0,
    });
    expect(provider.requestedRestart, isFalse);
    expect(state?['stage_code'], 'child');
    expect(state?['_new_cycle'], isTrue);
    expect(MySharedPref.getTrainingGameLocalState(), isNull);
    expect(MySharedPref.getTrainingGameDebugElapsedSeconds(), 0);
    expect(controller.isStarting.value, isFalse);
  });

  for (final stage in ['egg', 'child', 'training', 'growth', 'first_team']) {
    test('既存playing/$stageは再作成せず、保存済み状態を維持する', () async {
      const saved = '{"cycle_no":4,"seconds_in_stage":80}';
      await MySharedPref.setTrainingGameLocalState(saved);
      final provider = _StartProvider()
        ..current = {'id': 8, 'cycle_no': 4, 'stage_code': stage, 'status': 'playing'};
      final controller = TrainingGameNewGameController(provider: provider);
      final result = await controller.startNewGame();
      expect(provider.starts, 0);
      expect(result?['stage_code'], stage);
      expect(result?.containsKey('_new_cycle'), isFalse);
      expect(MySharedPref.getTrainingGameLocalState(), saved);
    });
  }

  test('終了後の次サイクルもchildから開始する', () async {
    final provider = _StartProvider()
      ..current = {'id': 8, 'cycle_no': 4, 'stage_code': 'first_team', 'status': 'completed'};
    final result = await TrainingGameNewGameController(provider: provider).startNewGame();
    expect(provider.starts, 1);
    expect(result?['cycle_no'], 5);
    expect(result?['stage_code'], 'child');
  });

  test('通信中の重複呼出しと成功後の重複callbackでは開始APIを二重送信しない', () async {
    final gate = Completer<void>();
    final provider = _StartProvider()..startGate = gate;
    final controller = TrainingGameNewGameController(provider: provider);
    final pending = controller.startNewGame();
    expect(await controller.startNewGame(), isNull);
    gate.complete();
    final result = await pending;
    expect(await controller.startNewGame(), result);
    expect(provider.starts, 1);
  });

  test('通信失敗では状態を消さず、再試行で開始できる', () async {
    await MySharedPref.setTrainingGameLocalState('keep');
    final provider = _StartProvider()..failStart = true;
    final controller = TrainingGameNewGameController(provider: provider);
    expect(await controller.startNewGame(), isNull);
    expect(controller.errorMessage.value, isNotEmpty);
    expect(controller.isStarting.value, isFalse);
    expect(MySharedPref.getTrainingGameLocalState(), 'keep');
    provider.failStart = false;
    expect((await controller.startNewGame())?['stage_code'], 'child');
    expect(controller.errorMessage.value, isEmpty);
  });

  test('現在cycleの確認に失敗したときは推測で新規開始しない', () async {
    final provider = _StartProvider()..failFetch = true;
    final controller = TrainingGameNewGameController(provider: provider);
    expect(await controller.startNewGame(), isNull);
    expect(provider.starts, 0);
  });

  test('サーバーがeggを返す場合は幼体開始成功と判定しない', () async {
    final provider = _StartProvider()..responseStage = 'egg';
    final controller = TrainingGameNewGameController(provider: provider);
    expect(await controller.startNewGame(), isNull);
    expect(provider.current?['stage_code'], 'egg');
    expect(controller.errorMessage.value, contains('開始状態を確認できません'));
  });

  for (final restart in [false, true]) {
    test('保存後に応答消失しても再試行ではcycleを再作成しない restart=$restart', () async {
      final provider = _StartProvider()..loseResponse = true;
      if (restart) {
        provider.current = {'id': 8, 'cycle_no': 3, 'stage_code': 'training', 'status': 'playing'};
      }
      final controller = TrainingGameNewGameController(provider: provider);
      expect(await controller.startNewGame(forceRestart: restart), isNull);
      final savedCycle = provider.current?['cycle_no'];
      final state = await controller.startNewGame(forceRestart: restart);
      expect(provider.starts, 1);
      expect(state?['cycle_no'], savedCycle);
      expect(state?['stage_code'], 'child');
      expect(state?['_new_cycle'], isTrue);
    });
  }

  test('明示的やり直しはchildで開始し、連続callbackでも一度だけ', () async {
    final provider = _StartProvider()
      ..current = {'id': 8, 'cycle_no': 3, 'stage_code': 'egg', 'status': 'playing'};
    final controller = TrainingGameNewGameController(provider: provider);
    final state = await controller.startNewGame(forceRestart: true);
    await controller.startNewGame(forceRestart: true);
    expect(provider.requestedRestart, isTrue);
    expect(provider.starts, 1);
    expect(state?['stage_code'], 'child');
    expect(state?['cycle_no'], 4);
  });

  test('現在状態を取得中に破棄されても開始APIを呼ばない', () async {
    final gate = Completer<void>();
    final provider = _StartProvider()..fetchGate = gate;
    final controller = TrainingGameNewGameController(provider: provider);
    final pending = controller.startNewGame();
    await Future<void>.delayed(Duration.zero);
    controller.onDelete();
    gate.complete();
    expect(await pending, isNull);
    expect(provider.starts, 0);
  });

  test('開始API待機中の画面破棄では遅延結果を返さずローカル状態を消さない', () async {
    await MySharedPref.setTrainingGameLocalState('keep');
    final gate = Completer<void>();
    final provider = _StartProvider()..startGate = gate;
    final controller = TrainingGameNewGameController(provider: provider);
    final pending = controller.startNewGame();
    await Future<void>.delayed(Duration.zero);
    controller.onDelete();
    gate.complete();
    expect(await pending, isNull);
    expect(MySharedPref.getTrainingGameLocalState(), 'keep');
  });

  test('現在状態の取得中にログイン会員が変わっても開始を送らない', () async {
    final gate = Completer<void>();
    final provider = _StartProvider()..fetchGate = gate;
    final controller = TrainingGameNewGameController(provider: provider);
    final pending = controller.startNewGame();
    await Future<void>.delayed(Duration.zero);
    await AuthToken.notifySessionChangedForTesting();
    gate.complete();
    expect(await pending, isNull);
    expect(provider.starts, 0);
  });

  test('成功済み状態もログイン会員をまたいで再利用しない', () async {
    final provider = _StartProvider();
    final controller = TrainingGameNewGameController(provider: provider);
    expect(await controller.startNewGame(), isNotNull);
    await AuthToken.notifySessionChangedForTesting();
    expect(await controller.startNewGame(), isNull);
    expect(provider.starts, 1);
    expect(controller.errorMessage.value, contains('ログイン状態が変わりました'));
  });
}
