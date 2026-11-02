import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PositionProvider extends TrainingGameProvider {
  final data = <String, dynamic>{
    'id': 7,
    'cycle_no': 1,
    'lock_version': 0,
    'stage_code': 'training',
    'status': 'playing',
    'started_at': '2026-10-23T12:00:00.000Z',
    'presence_cycle_token': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    'server_time': '2026-10-23T12:00:00.000Z',
    'elapsed_seconds': 0,
    'work_available': true,
    'actions_today': 0,
    'parameters': {
      'hunger': 100,
      'cleanliness': 100,
      'condition': 100,
      'work': 20
    },
    'cooldowns': <String, dynamic>{}
  };
  int writes = 0;
  bool loseResponse = false;
  bool failBook = false;
  Completer<void>? gate;
  Completer<void>? readGate;
  bool snapshotBeforeReadGate = false;
  bool failAfterReadGate = false;
  int nullTokenReads = 0;
  final readStarted = Completer<void>();
  final presenceTokens = <String?>[];
  @override
  Future<void> notifyTrainingPresence({int? expectedSessionVersion}) async {
    presenceTokens.add(presenceCycleToken);
  }

  @override
  Future<Map<String, dynamic>> start(
          {required String stageCode,
          required Map<String, double> parameters,
          bool forceRestart = false,
          int? expectedSessionVersion}) async =>
      Map.from(data);
  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    final snapshot = Map<String, dynamic>.from(data);
    if (readGate != null && !readStarted.isCompleted) readStarted.complete();
    await readGate?.future;
    if (failAfterReadGate) throw StateError('old request failed');
    final result =
        snapshotBeforeReadGate ? snapshot : Map<String, dynamic>.from(data);
    if (nullTokenReads > 0) {
      nullTokenReads--;
      result['presence_cycle_token'] = null;
    }
    return result;
  }

  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      failBook
          ? throw StateError('book unavailable')
          : data['status'] == 'positive_end'
              ? ['wing']
              : [];
  @override
  Future<Map<String, dynamic>> debugPositionOptions(
          {int? expectedSessionVersion}) async =>
      {
        'positions': [
          {'position_code': 'wing', 'name': 'ウイング'}
        ],
        'current_game': Map<String, dynamic>.from(data)
      };
  @override
  Future<Map<String, dynamic>> debugPositionCommand(
      {required Map<String, dynamic> target,
      required bool complete,
      String? positionCode,
      int? expectedSessionVersion}) async {
    writes++;
    await gate?.future;
    data['lock_version'] = (data['lock_version'] as int) + 1;
    data['position_code'] = complete ? 'wing' : positionCode;
    if (complete) {
      data['status'] = 'positive_end';
      data['stage_code'] = 'first_team';
    }
    if (loseResponse) throw StateError('response lost');
    return Map.from(data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });
  Future<TrainingGameController> open(PositionProvider p) async {
    final c = TrainingGameController(serverProvider: p);
    addTearDown(c.onClose);
    await c.debugStartAtTraining();
    return c;
  }

  test('同一秒に育成を再開始しても新しい周期で直ちに在室連絡する', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.setTrainingPresence(true);
    p.presenceTokens.clear();
    p.data['presence_cycle_token'] = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    await c.debugStartAtTraining();
    await Future<void>.delayed(Duration.zero);
    expect(p.presenceTokens, contains('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'));
  }, skip: !AppEnvironment.showsTrainingDebugUi);

  test('再開始前に開始した取得の古い応答で周期を戻さない', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.readGate = Completer<void>();
    p.snapshotBeforeReadGate = true;
    final oldFetch = c.retryRestoreServerState();
    await p.readStarted.future;
    p.data['presence_cycle_token'] = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    await c.debugStartAtTraining();
    p.readGate!.complete();
    await oldFetch;
    expect(p.presenceCycleToken, 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
  }, skip: !AppEnvironment.showsTrainingDebugUi);

  test('再開始前の取得失敗で新しい周期をエラーにしない', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.readGate = Completer<void>();
    p.failAfterReadGate = true;
    final oldFetch = c.retryRestoreServerState();
    await p.readStarted.future;
    p.data['presence_cycle_token'] = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    await c.debugStartAtTraining();
    p.readGate!.complete();
    await oldFetch;
    expect(c.isServerStateReady.value, isTrue);
    expect(c.serverErrorMessage.value, isEmpty);
  }, skip: !AppEnvironment.showsTrainingDebugUi);

  test('不完全な周期情報の応答でメーターを上書きしない', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.data['presence_cycle_token'] = null;
    p.data['parameters'] = {
      'hunger': 0,
      'cleanliness': 0,
      'condition': 0,
      'work': 0
    };
    await c.retryRestoreServerState();
    expect(p.presenceCycleToken, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(c.meters['清潔'], 100);
  }, skip: !AppEnvironment.showsTrainingDebugUi);

  test('不完全な周期情報は一度再取得して時計を再開する', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.nullTokenReads = 1;
    await c.retryRestoreServerState();
    expect(p.nullTokenReads, 0);
    expect(c.isServerStateReady.value, isTrue);
    expect(c.serverErrorMessage.value, isEmpty);
    expect(p.presenceCycleToken, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
  }, skip: !AppEnvironment.showsTrainingDebugUi);

  test('固定と解除はサーバー結果だけを表示し、完了時に図鑑を更新する', () async {
    final p = PositionProvider();
    final c = await open(p);
    var options = await c.loadDebugPositionOptions();
    await c.applyDebugPosition(
        Map<String, dynamic>.from(options['current_game'] as Map),
        complete: false,
        positionCode: 'wing');
    expect(c.debugResolvedPosition, 'ウイング');
    options = await c.loadDebugPositionOptions();
    await c.applyDebugPosition(
        Map<String, dynamic>.from(options['current_game'] as Map),
        complete: false);
    expect(c.debugResolvedPosition, '判定前');
    options = await c.loadDebugPositionOptions();
    await c.applyDebugPosition(
        Map<String, dynamic>.from(options['current_game'] as Map),
        complete: true);
    expect(c.ended.value, true);
    expect(c.clearPosition.value, 'ウイング');
    expect(c.unlockedPositions, ['wing']);
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('応答だけ失っても書込みを再送せず読取りで完了を復元する', () async {
    final p = PositionProvider()..loseResponse = true;
    final c = await open(p);
    final options = await c.loadDebugPositionOptions();
    await c.applyDebugPosition(
        Map<String, dynamic>.from(options['current_game'] as Map),
        complete: true);
    expect(p.writes, 1);
    expect(c.ended.value, true);
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('図鑑読取り失敗でも確定した完了を保存する', () async {
    final p = PositionProvider();
    final c = await open(p);
    final options = await c.loadDebugPositionOptions();
    p.failBook = true;
    await c.applyDebugPosition(
        Map<String, dynamic>.from(options['current_game'] as Map),
        complete: true);
    expect(c.ended.value, true);
    expect(c.clearPosition.value, 'ウイング');
    expect(MySharedPref.getTrainingGameLocalState(), isNotNull);
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('書込み中は二重操作と時間加算とお世話を受け付けない', () async {
    final p = PositionProvider()..gate = Completer<void>();
    final c = await open(p);
    final options = await c.loadDebugPositionOptions();
    final target = Map<String, dynamic>.from(options['current_game'] as Map);
    final first =
        c.applyDebugPosition(target, complete: false, positionCode: 'wing');
    await Future<void>.delayed(Duration.zero);
    expect(c.debugPositionBusy.value, true);
    expect(await c.prepareWork(), false);
    c.stageIndex.value = 1;
    final seconds = c.secondsInStage.value;
    c.tickTutorialTimer();
    expect(c.secondsInStage.value, seconds);
    expect(c.canPerform(TrainingActionType.rest), false);
    c.advanceTime(24);
    expect(c.elapsedHours.value, 0);
    await expectLater(
        c.applyDebugPosition(target, complete: true), throwsStateError);
    p.gate!.complete();
    await first;
    expect(p.writes, 1);
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('ミニゲームの準備読取り中は固定操作を開始しない', () async {
    final p = PositionProvider();
    final c = await open(p);
    p.readGate = Completer<void>();
    final preparation = c.prepareMiniGame(TrainingActionType.tackle);
    await Future<void>.delayed(Duration.zero);
    await expectLater(c.loadDebugPositionOptions(), throwsStateError);
    expect(p.writes, 0);
    p.readGate!.complete();
    await preparation;
    c.finishMiniGamePreparation();
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('古い確認対象は送信せず拒否する', () async {
    final p = PositionProvider();
    final c = await open(p);
    final options = await c.loadDebugPositionOptions();
    final target = Map<String, dynamic>.from(options['current_game'] as Map)
      ..['cycle_no'] = 999;
    await expectLater(
        c.applyDebugPosition(target, complete: true), throwsStateError);
    expect(p.writes, 0);
  }, skip: !AppEnvironment.showsTrainingDebugUi);
  test('通常版はControllerとProvider双方で専用操作を拒否する', () async {
    final c = TrainingGameController();
    addTearDown(c.onClose);
    await expectLater(c.loadDebugPositionOptions(), throwsStateError);
    await expectLater(
        TrainingGameProvider().debugPositionOptions(), throwsStateError);
    await expectLater(
        TrainingGameProvider().debugPositionCommand(target: {}, complete: true),
        throwsStateError);
  }, skip: AppEnvironment.showsTrainingDebugUi);
}
