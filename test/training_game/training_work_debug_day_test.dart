import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  test('一軍確定後の＋1日は時間保存応答で終了意思を失わず正常完了を一度保存する', () async {
    final provider = DebugDayProvider()
      ..stageCode = 'first_team'
      ..positionCode = 'fullback'
      ..timeGate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.retryRestoreServerState();
    expect(controller.position, 'フルバック');
    controller.advanceTime(24);
    expect(controller.ended.value, isTrue);
    controller.advanceTime(24);
    await Future<void>.delayed(Duration.zero);
    expect(provider.normalStatuses, isEmpty);
    provider.timeGate!.complete();
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.timeSaves, 1);
    expect(provider.dailyResets, 1);
    expect(provider.normalStatuses, ['positive_end']);
    expect(controller.ended.value, isTrue);
    expect(controller.clearPosition.value, 'フルバック');
    expect(controller.endingSyncError.value, isEmpty);
  });

  for (final failTime in [true, false]) {
    test('完了時の${failTime ? '時間保存' : '日次解除'}失敗では完了を送らず再試行エラーを残す', () async {
      final provider = DebugDayProvider()
        ..stageCode = 'first_team'
        ..positionCode = 'fullback'
        ..failTimeSync = failTime
        ..failDailyReset = !failTime;
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.retryRestoreServerState();
      controller.advanceTime(24);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(provider.normalStatuses, isEmpty);
      expect(controller.ended.value, isTrue);
      expect(controller.endingSyncError.value, isNotEmpty);
      expect(controller.canResolveDebugTimeSave, isTrue);
    });
  }

  test('完了時間保存中の本人セッション変更では終了を送信しない', () async {
    final provider = DebugDayProvider()
      ..stageCode = 'first_team'
      ..positionCode = 'fullback'
      ..timeGate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.retryRestoreServerState();
    controller.advanceTime(24);
    await Future<void>.delayed(Duration.zero);
    await AuthToken.notifySessionChangedForTesting();
    provider.timeGate!.complete();
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.normalStatuses, isEmpty);
    expect(provider.dailyResets, 0);
  });

  test('終了保存の拒否を成功扱いせずサーバーの育成中状態とエラーを残す', () async {
    final provider = DebugDayProvider()
      ..stageCode = 'first_team'
      ..positionCode = 'fullback'
      ..failEnding = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.retryRestoreServerState();
    controller.advanceTime(24);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.normalStatuses, ['positive_end']);
    expect(provider.serverStatus, 'playing');
    expect(controller.ended.value, isFalse);
    expect(controller.endingSyncError.value, isNotEmpty);
  });

  test('時間保存応答が新周期なら旧周期の終了要求を持ち越さない', () async {
    final provider = DebugDayProvider()
      ..stageCode = 'first_team'
      ..positionCode = 'fullback'
      ..timeGate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.retryRestoreServerState();
    controller.advanceTime(24);
    await Future<void>.delayed(Duration.zero);
    provider.cycleNo = 2;
    provider.timeGate!.complete();
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.normalStatuses, isNot(contains('positive_end')));
    expect(controller.ended.value, isFalse);
    expect(controller.clearPosition.value, isNull);
  });

  test('日付をまたがない時間加算も専用APIへ保存し、日次履歴は解除しない', () async {
    final provider = DebugDayProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    expect(provider.timeSaves, 1);
    expect(provider.dailyResets, 0);
    expect(controller.meters, expectedMeters);
    expect(controller.elapsedHours.value, 1);
  });

  test('時間加算保存中は追加加算と行動を重ねず、保存後は再照会で値を維持する', () async {
    final provider = DebugDayProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    controller.advanceTime(6);
    controller.perform(TrainingActionType.rest);
    expect(controller.elapsedHours.value, 1);
    expect({
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble()
    }, expectedMeters);
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    expect(provider.timeSaves, 1);
    expect(controller.meters, expectedMeters);
  });

  test('日付をまたがない時間保存の拒否を隠さず、同じ加算後の値を再試行する', () async {
    final provider = DebugDayProvider()..failTimeSync = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    expect(await controller.prepareWork(), isFalse);
    expect(controller.workAvailabilityError.value, contains('時間変更を保存できませんでした'));
    expect(provider.dailyResets, 0);
    controller.advanceTime(1);
    expect(controller.elapsedHours.value, 1);
    provider.failTimeSync = false;
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    expect(provider.timeSaves, 2);
    expect(provider.dailyResets, 0);
    expect(controller.meters, expectedMeters);
  });

  test('時間加算後にControllerを再作成しても進行カウンターと値が残る', () async {
    final provider = DebugDayProvider();
    final controller = TrainingGameController(serverProvider: provider);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    controller.onClose();
    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();
    expect(restored.elapsedHours.value, 1);
    expect(restored.meters, expectedMeters);
    expect(restored.clockLabel, contains('01:00:00'));
  });

  test('時間保存の遅延中にバックグラウンド同期と復帰取得を重ねても順序を守る', () async {
    final provider = DebugDayProvider()..timeGate = Completer<void>();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    await Future<void>.delayed(Duration.zero);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    final restore = controller.retryRestoreServerState();
    await Future<void>.delayed(Duration.zero);
    expect(provider.normalSaves, 0);
    expect(provider.currentReads, 0);
    provider.timeGate!.complete();
    await restore;
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.normalSaves, 1);
    expect(provider.timeSaves, 1);
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);
    expect(controller.elapsedHours.value, 1);
  });

  test('専用保存後に応答だけ失われても再取得で確認し加算を再送しない', () async {
    final provider = DebugDayProvider()..loseTimeResponse = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    expect(provider.timeSaves, 1);
    expect(provider.dailyResets, 0);
    expect(controller.elapsedHours.value, 1);
    expect(controller.meters, expectedMeters);
    expect(controller.canPerform(TrainingActionType.rest), isTrue);
  });

  test('保存結果が別状態なら明示再取得で保留を終了し、再送も日次解除もしない', () async {
    final provider = DebugDayProvider()..loseChangedTimeResponse = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    expect(await controller.prepareWork(), isFalse);
    expect(controller.canResolveDebugTimeSave, isTrue);
    expect(provider.timeSaves, 1);
    await controller.retryRestoreServerState();
    expect(provider.timeSaves, 1);
    expect(provider.dailyResets, 0);
    expect(controller.canResolveDebugTimeSave, isFalse);
    expect(controller.meters['食事'], provider.payload()['parameters']['hunger']);
    expect(controller.elapsedHours.value, 1);
    expect(controller.canPerform(TrainingActionType.rest), isTrue);
  });

  test('時間保存失敗中はホーム遷移を保存成功扱いせず、復帰操作を残す', () async {
    final provider = DebugDayProvider()..failTimeSync = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.advanceTime(1);
    expect(await controller.syncBeforeReturningHome(), isFalse);
    expect(controller.isReturningHome.value, isFalse);
    expect(controller.canResolveDebugTimeSave, isTrue);
    expect(provider.normalSaves, 0);
    await controller.retryRestoreServerState();
    expect(controller.canResolveDebugTimeSave, isFalse);
  });

  test('仕事後に＋1日を押してすぐ再照会しても、日次解除後の仕事を開始できる', () async {
    final provider = DebugDayProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.canWorkToday, isFalse);

    controller.advanceTime(24);
    final expectedMeters = {
      for (final e in controller.meters.entries)
        e.key: e.value.truncateToDouble(),
    };
    expect(await controller.prepareWork(), isTrue);
    expect(provider.dailyResets, 1);
    expect(controller.meters, expectedMeters);
    controller.finishWorkPreparation();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.workActions, 2);
  });

  for (final failTimeSync in [true, false]) {
    test('${failTimeSync ? '時間同期' : '日次解除'}失敗を1日1回制限と誤表示せず、次の仕事押下で解除を再試行する',
        () async {
      final provider = DebugDayProvider()
        ..failTimeSync = failTimeSync
        ..failDailyReset = !failTimeSync;
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.debugStartAtTraining();
      controller.perform(TrainingActionType.work);
      await TrainingGameProvider.waitForPendingSync();
      controller.advanceTime(24);
      final expectedMeters = {
        for (final e in controller.meters.entries)
          e.key: e.value.truncateToDouble(),
      };

      expect(await controller.prepareWork(), isFalse);
      expect(controller.workAvailabilityError.value, contains('時間変更'));
      expect({
        for (final e in controller.meters.entries)
          e.key: e.value.truncateToDouble()
      }, expectedMeters);
      provider.failDailyReset = false;
      provider.failTimeSync = false;
      expect(await controller.prepareWork(), isTrue);
      expect(provider.dailyResets, failTimeSync ? 1 : 2);
      expect(controller.meters, expectedMeters);
      controller.finishWorkPreparation();
    });
  }

  test('仕事の保存保留を日次制限と誤表示しない', () async {
    final provider = DebugDayProvider()..rateLimitWork = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    controller.advanceTime(24);

    expect(await controller.prepareWork(), isFalse);
    expect(controller.workAvailabilityError.value, contains('同期待ち'));
    expect(provider.dailyResets, 0);
  });

  testWidgets('デバコマの＋1時間から保存し、再照会後も減衰した表示を維持する', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final provider = DebugDayProvider();
    final controller = _ManualController(serverProvider: provider);
    await tester.runAsync(controller.debugStartAtTraining);
    final before = controller.meters['食事']!;
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(home: TrainingGameScreen()),
    ));
    await tester.tap(find.byTooltip('デバッグコマンド'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('＋1時間'));
      expect(await controller.prepareWork(), isTrue);
      controller.finishWorkPreparation();
    });
    await tester.pumpAndSettle();
    expect(provider.timeSaves, 1);
    expect(provider.dailyResets, 0);
    expect(controller.meters['食事'], lessThan(before));
    expect(controller.meters['食事'], provider.payload()['parameters']['hunger']);
    expect(controller.elapsedHours.value, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('＋1日の日次解除を再試行してから仕事中の画面を表示し、中止では仕事を実行しない', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final provider = DebugDayProvider()..failTimeSync = true;
    final controller = _ManualController(serverProvider: provider);
    await tester.runAsync(() async {
      await controller.debugStartAtTraining();
      controller.perform(TrainingActionType.work);
      await TrainingGameProvider.waitForPendingSync();
    });
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(home: TrainingGameScreen()),
    ));
    await tester.runAsync(() async {
      controller.advanceTime(24);
      await tester.tap(find.widgetWithText(TextButton, '仕事'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.workAvailabilityError.value, contains('時間変更'));
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(find.textContaining('時間変更を保存できませんでした'), findsOneWidget);
    expect(find.text('仕事は1日1回までです。'), findsNothing);

    // エラーのSnackBarが下部の仕事ボタンを覆っている間は押さない。
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));

    provider.failTimeSync = false;
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, '仕事'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
    expect(find.text('仕事中…'), findsOneWidget);
    expect(provider.workActions, 1);
    await tester.tap(find.byTooltip('お世話を中止'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(provider.workActions, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

class _ManualController extends TrainingGameController {
  _ManualController({required super.serverProvider});

  // 周期clockと起動時通信を省き、可否照会・時間操作・仕事処理は実装を使用します。
  @override
  // ignore: must_call_super
  void onInit() {}
}

class DebugDayProvider extends TrainingGameProvider {
  String stageCode = 'training';
  String? positionCode;
  String serverStatus = 'playing';
  int cycleNo = 1;
  bool failEnding = false;
  final normalStatuses = <String?>[];
  int dailyResets = 0;
  int timeSaves = 0;
  int normalSaves = 0;
  int currentReads = 0;
  Completer<void>? timeGate;
  bool loseTimeResponse = false;
  bool loseChangedTimeResponse = false;
  int workActions = 0;
  bool failDailyReset = false;
  bool failTimeSync = false;
  bool rateLimitWork = false;
  int _lockVersion = 0;
  bool _workAvailable = true;
  final _startedAt = DateTime.now().toUtc();
  Map<String, double> _parameters = {
    'hunger': 100,
    'cleanliness': 100,
    'condition': 100,
    'work': 20,
  };

  Map<String, dynamic> payload() => {
        'id': 7,
        'cycle_no': cycleNo,
        'lock_version': _lockVersion,
        'stage_code': stageCode,
        'position_code': positionCode,
        'branch_code': positionCode == null ? null : 'FW',
        'status': serverStatus,
        'started_at': _startedAt.toIso8601String(),
        'server_time': _startedAt.toIso8601String(),
        'elapsed_seconds': 0,
        'work_available': _workAvailable,
        'actions_today': _workAvailable ? 0 : 1,
        'play_floor': 20,
        'parameters': Map<String, double>.from(_parameters),
        'cooldowns': <String, dynamic>{},
      };

  @override
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async =>
      payload();

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    currentReads++;
    return serverStatus == 'playing' ? payload() : null;
  }

  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      [];

  @override
  Future<Map<String, dynamic>> syncDebugTime({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
    int? elapsedSeconds,
    int? daysInStage,
    bool? dayCared,
    int? expectedSessionVersion,
  }) async {
    timeSaves++;
    await timeGate?.future;
    expect(lockVersion, _lockVersion);
    if (failTimeSync) {
      throw TrainingGameApiException(statusCode: 404, message: 'Not Found');
    }
    _parameters = {
      for (final e in parameters.entries) e.key: e.value.truncateToDouble()
    };
    _lockVersion++;
    if (loseChangedTimeResponse) {
      _parameters['hunger'] = _parameters['hunger']! - 1;
      throw TimeoutException('changed response lost');
    }
    if (loseTimeResponse) throw TimeoutException('response lost');
    return payload();
  }

  @override
  Future<Map<String, dynamic>> resetDebugDailyActionUsage(
      {int? expectedSessionVersion}) async {
    dailyResets++;
    if (failDailyReset) {
      throw TrainingGameApiException(statusCode: 404, message: 'Not Found');
    }
    _workAvailable = true;
    return payload();
  }

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
    String? status,
    String? endingType,
    String? actionResultCode,
    String? actionResultPolicy,
    int? actionAttemptCount,
    int? actionSuccessCount,
    int? actionSuccessfulReactionTotalUs,
    TackleSettings? actionTackleSettings,
    double? actionScore,
    double? actionEffectMultiplier,
    bool debugBypassCooldown = false,
  }) async {
    normalSaves++;
    normalStatuses.add(status);
    if (failEnding && status == 'positive_end') {
      throw TrainingGameApiException(
          statusCode: 422, message: 'Ending rejected');
    }
    if (actionCode == 'work' && rateLimitWork) {
      throw TrainingGameApiException(
          statusCode: 429,
          message: 'Too Many Attempts',
          retryAfter: const Duration(seconds: 65));
    }
    expect(lockVersion, _lockVersion);
    _lockVersion++;
    serverStatus = status ?? 'playing';
    // 通常同期はサーバー正本。端末パラメータをそのまま採用しません。
    if (actionCode == 'work') {
      workActions++;
      _workAvailable = false;
    }
    return payload();
  }
}
