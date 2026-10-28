import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    Get.testMode = true;
  });

  test('サーバー確定のfirst_team遷移は一軍の進化ウィンドウへ進む', () async {
    final provider = _FirstTeamTransitionProvider();
    Get.routing.args = provider.state('growth');
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isServerStateReady.value, isTrue);
    expect(controller.stageIndex.value, 3);
    controller.setCooldownEnabled(TrainingActionType.meal, false);
    controller.daysInStage.value = 7;
    controller.perform(TrainingActionType.meal);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.syncedStageCodes, isNotEmpty);
    expect(provider.syncedStageCodes, everyElement('first_team'));
    expect(provider.syncedActionCodes, contains('meal'));
    expect(controller.stageIndex.value, 4);
    expect(controller.currentStage.name, '一軍');
    expect(controller.evolutionStage.value, 4);
  });

  test('再起動時のサーバー進化イベントを表示し、確認時にACKする', () async {
    final provider = _PendingProgressEventProvider();
    Get.routing.args = provider.state();
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(controller.stageIndex.value, 3);
    expect(controller.evolutionStage.value, 3);
    expect(provider.acknowledgedEventIds, isEmpty);

    await controller.advanceEvolution();

    expect(provider.acknowledgedEventIds, ['offline-growth-event']);
    expect(controller.evolutionStage.value, isNull);
  });

  test('旧版の端末進行日数を初回起動時にサーバーへ移行する', () async {
    final provider = _LegacyProgressImportProvider();
    Get.routing.args = provider.state();
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(provider.importedDaysInStage, 0);
    expect(controller.isServerStateReady.value, isTrue);
  });

  test('筋トレは各50未満ならControllerが案内して同期しない', () async {
    final provider = _FirstTeamTransitionProvider(meterValue: 49);
    Get.routing.args = provider.state('training');
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isServerStateReady.value, isTrue);

    controller.perform(TrainingActionType.squat);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.syncedActionCodes, isEmpty);
    expect(controller.careFeedbackVersion.value, 0);
    expect(controller.careFeedback, isEmpty);
    expect(
      controller.logs.first,
      '食事・清潔・体調が50未満です。'
      'ごはん・掃除・休養で50以上に整えてから筋トレしましょう。',
    );
  });

  test('各50ちょうどならControllerの既存筋トレ同期経路を通る', () async {
    final provider = _FirstTeamTransitionProvider(meterValue: 50);
    Get.routing.args = provider.state('training');
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isServerStateReady.value, isTrue);

    controller.perform(TrainingActionType.squat);
    expect(controller.careFeedbackVersion.value, 1);
    expect(controller.careFeedback, {'食事': -12.0, '清潔': -8.0, '体調': -6.0});
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.syncedActionCodes, ['training']);
  });

  test('ミニゲーム結果もホームのパラメーター変動演出へ渡す', () async {
    final provider = _FirstTeamTransitionProvider(meterValue: 80);
    Get.routing.args = provider.state('training');
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => true,
      clearPendingActions: () async => true,
      archivePendingActions: (_) async => true,
    );
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isServerStateReady.value, isTrue);

    controller.completeMiniGame(
      TrainingActionType.passAndRun,
      MiniGameResult.passAndRun(outboundScore: 0, inboundScore: 0),
    );

    expect(controller.careFeedbackVersion.value, 1);
    expect(controller.careFeedback['仕事'], 2.5);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.syncedActionCodes, ['pass_run']);
  });

  test('進化演出中のOS割り込み後も、次へ進むと16倍速の時間が再開する', () {
    final controller = TrainingGameController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 1;
    controller.evolutionStage.value = 1;
    controller.timeSpeed.value = 16;

    controller.pauseLocalProgress();
    expect(controller.isTutorialTimeActive, isFalse);

    controller.advanceEvolution();
    expect(controller.isTutorialTimeActive, isTrue);

    controller.tickTutorialTimer();
    expect(controller.secondsInStage.value, 16);
  });

  test('進化演出がない状態では、次へ操作で停止状態を解除しない', () {
    final controller = TrainingGameController();
    controller.isServerStateReady.value = true;
    controller.stageIndex.value = 1;
    controller.pauseLocalProgress();

    controller.advanceEvolution();

    expect(controller.isTutorialTimeActive, isFalse);
  });
}

class _FirstTeamTransitionProvider extends TrainingGameProvider {
  _FirstTeamTransitionProvider({this.meterValue = 80});

  final double meterValue;
  final syncedStageCodes = <String>[];
  final syncedActionCodes = <String?>[];

  Map<String, dynamic> state(String stageCode) => {
        'id': 7,
        'cycle_no': 3,
        'lock_version': syncedStageCodes.length,
        'stage_code': stageCode,
        'status': 'playing',
        'started_at': '2026-10-20T00:00:00Z',
        'elapsed_seconds': 0,
        'actions_today': 0,
        'work_available': false,
        'branch_code': null,
        'position_code': null,
        'parameters': {
          'hunger': meterValue,
          'cleanliness': meterValue,
          'condition': meterValue,
          'work': 80.0,
          'tendency_fw': 0.0,
          'tendency_command': 0.0,
          'tendency_backs': 0.0,
          'tendency_bulk': 0.0,
          'tendency_tech': 0.0,
        },
        'cooldowns': <String, dynamic>{},
        if (stageCode == 'growth')
          'stage_progress': {'next_stage_code': 'first_team'},
      };

  @override
  Future<Map<String, dynamic>> sync({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
    required int cycleNo,
    String? positionCode,
    String? branchCode,
    String? actionCode,
    String? actionIdempotencyKey,
    int? expectedSessionVersion,
    double? actionScore,
    double? actionEffectMultiplier,
    String? actionResultCode,
    String? actionResultPolicy,
    int? actionAttemptCount,
    int? actionSuccessCount,
    int? actionSuccessfulReactionTotalUs,
    TackleSettings? actionTackleSettings,
    bool debugBypassCooldown = false,
    String status = 'playing',
  }) async {
    syncedStageCodes.add(stageCode);
    syncedActionCodes.add(actionCode);
    return state(stageCode);
  }
}

class _PendingProgressEventProvider extends TrainingGameProvider {
  final acknowledgedEventIds = <String>[];

  Map<String, dynamic> state({bool pending = true, int lockVersion = 7}) => {
        'id': 7,
        'cycle_no': 3,
        'lock_version': lockVersion,
        'stage_code': 'growth',
        'status': 'playing',
        'started_at': '2026-10-20T00:00:00Z',
        'elapsed_seconds': 24 * 3600,
        'actions_today': 0,
        'work_available': false,
        'branch_code': 'FW',
        'position_code': null,
        'parameters': {
          'hunger': 80.0,
          'cleanliness': 80.0,
          'condition': 80.0,
          'work': 30.0,
          'tendency_fw': 60.0,
          'tendency_command': 20.0,
          'tendency_backs': 10.0,
          'tendency_bulk': 0.0,
          'tendency_tech': 0.0,
        },
        'stage_progress': {
          'server_managed': true,
          'days_in_stage': 0,
          'day_cared': false,
          'next_stage_code': 'first_team',
        },
        if (pending)
          'pending_progress_event': {
            'id': 'offline-growth-event',
            'type': 'evolution',
            'from_stage_code': 'training',
            'to_stage_code': 'growth',
            'reason': 'cared_day',
          },
        'cooldowns': <String, dynamic>{},
      };

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      state();

  @override
  Future<Map<String, dynamic>> acknowledgeProgressEvent({
    required String eventId,
    required int cycleNo,
    required int lockVersion,
    int? expectedSessionVersion,
  }) async {
    acknowledgedEventIds.add(eventId);
    return state(pending: false, lockVersion: lockVersion + 1);
  }
}

class _LegacyProgressImportProvider extends _PendingProgressEventProvider {
  int importedDaysInStage = -1;

  @override
  Map<String, dynamic> state({bool pending = true, int lockVersion = 7}) {
    final data = super.state(pending: false, lockVersion: lockVersion);
    (data['stage_progress'] as Map)['legacy_progress_import_pending'] = true;
    return data;
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrent({
    int? expectedSessionVersion,
  }) async =>
      state();

  @override
  Future<Map<String, dynamic>> importLegacyProgress({
    required int cycleNo,
    required int lockVersion,
    required String stageCode,
    required int daysInStage,
    required bool dayCared,
    int? expectedSessionVersion,
  }) async {
    importedDaysInStage = daysInStage;
    final data = state(lockVersion: lockVersion + 1);
    (data['stage_progress'] as Map)['legacy_progress_import_pending'] = false;
    return data;
  }
}
