import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  Future<TrainingGameController> openWithInitialState(
    _RateLimitedTrainingGameProvider provider,
  ) async {
    Get.testMode = true;
    Get.routing.args = provider._payload();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    return controller;
  }

  for (final v2 in [false, true]) {
    test(
        'tackle metadata survives queue restart v2=$v2 and retains operation ID',
        () async {
      final provider =
          _RateLimitedTrainingGameProvider(rateLimitFirstAction: false);
      final pendingKey = 'tackle-restart-$v2';
      final raw = jsonEncode([
        {
          'action_code': 'tackle',
          'revision': 1,
          'idempotency_key': pendingKey,
          'player_id': 7,
          'cycle_no': 1,
          'game_started_at': provider._startedAt.toIso8601String(),
          'may_have_been_applied': true,
          'result': {
            'type': 'tackle',
            'summary': 'tackle result',
            'score': v2 ? .75 : .5,
            'effect_multiplier': .25,
            'result_code': 'D',
            if (v2) ...{
              'result_policy': 'tackle_v2_750_penalty_mean',
              'attempt_count': 3,
              'success_count': 0,
              'successful_reaction_total_us': 0
            }
          },
        }
      ]);
      await MySharedPref.setTrainingGamePendingActions(raw);
      final controller = await openWithInitialState(provider);
      expect(controller.pendingSyncActionCount, 1);
      await controller.retryPendingSync();
      expect(provider.idempotencyKeys, [pendingKey]);
      expect(
          provider.tackleMetadata.single,
          v2
              ? {
                  'result_policy': 'tackle_v2_750_penalty_mean',
                  'attempt_count': 3,
                  'success_count': 0,
                  'successful_reaction_total_us': 0,
                }
              : <String, dynamic>{});
    });
  }
  for (final corruption in ['missing_total', 'rank', 'multiplier', 'score']) {
    test('invalid tackle $corruption preserves journal without sending',
        () async {
      final provider =
          _RateLimitedTrainingGameProvider(rateLimitFirstAction: false);
      final raw = jsonEncode([
        {
          'action_code': 'tackle',
          'revision': 1,
          'idempotency_key': 'partial-tackle',
          'player_id': 7,
          'cycle_no': 1,
          'game_started_at': provider._startedAt.toIso8601String(),
          'may_have_been_applied': true,
          'result': {
            'type': 'tackle',
            'summary': 'partial',
            'score': corruption == 'score' ? .5 : .75,
            'effect_multiplier': corruption == 'multiplier' ? 1 : .25,
            'result_code': corruption == 'rank' ? 'C' : 'D',
            'result_policy': 'tackle_v2_750_penalty_mean',
            'attempt_count': 3,
            'success_count': 0,
            if (corruption != 'missing_total') 'successful_reaction_total_us': 0
          },
        }
      ]);
      await MySharedPref.setTrainingGamePendingActions(raw);
      final controller = await openWithInitialState(provider);
      expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
      expect(provider.actionCodes, isEmpty);
      expect(MySharedPref.getTrainingGamePendingActions(), raw);
      expect(controller.syncStatusMessage.value, contains('読み取れません'));
    });
  }

  test('取得済み状態で通常起動しても結果不明journalを同じ操作IDで復元する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
    );
    const pendingKey = 'previous-process-clean';
    await MySharedPref.setTrainingGamePendingActions(jsonEncode([
      {
        'action_code': 'clean',
        'revision': 1,
        'idempotency_key': pendingKey,
        'player_id': 7,
        'cycle_no': 1,
        'game_started_at': provider._startedAt.toIso8601String(),
        'may_have_been_applied': true,
      },
    ]));
    await MySharedPref.setTrainingGameLocalState(jsonEncode({
      'player_id': 7,
      'cycle_no': 1,
      'has_unsynced_state': true,
      'cleanliness': 140,
    }));

    final controller = await openWithInitialState(provider);

    expect(controller.pendingSyncActionCount, 1);
    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.meters['清潔'], 20);
    expect(provider.currentFetches, 0);
    controller.perform(TrainingActionType.tackle);
    expect(provider.actionCodes, isEmpty);

    await controller.retryPendingSync();

    expect(provider.idempotencyKeys, [pendingKey]);
    expect(controller.meters['清潔'], 60);
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
  });

  test('取得済み状態で通常起動しても破損journalの確認待ちを維持する', () async {
    final provider = _RateLimitedTrainingGameProvider();
    await MySharedPref.setTrainingGamePendingActionsRecovery(jsonEncode({
      'player_id': 7,
      'cycle_no': 1,
      'game_started_at': provider._startedAt.toIso8601String(),
    }));

    final controller = await openWithInitialState(provider);

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.canRetryPendingSync, isTrue);
    expect(provider.currentFetches, 0);
    controller.perform(TrainingActionType.tackle);
    expect(provider.actionCodes, isEmpty);
    expect(MySharedPref.getTrainingGamePendingActionsRecovery(), isNotNull);
  });

  test('未確定操作により退出できなくても再試行後に育成時計が再開する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
      stageCode: 'child',
    );
    await MySharedPref.setTrainingGamePendingActions(jsonEncode([
      {
        'action_code': 'clean',
        'revision': 1,
        'idempotency_key': 'cancelled-exit-clean',
        'player_id': 7,
        'cycle_no': 1,
        'game_started_at': provider._startedAt.toIso8601String(),
        'may_have_been_applied': true,
      },
    ]));
    final controller = await openWithInitialState(provider);
    expect(controller.isTutorialTimeActive, isTrue);

    expect(await controller.syncBeforeReturningHome(), isFalse);
    await controller.retryPendingSync();

    expect(controller.isReturningHome.value, isFalse);
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);
    expect(controller.isTutorialTimeActive, isTrue);
    final secondsBefore = controller.secondsInStage.value;
    controller.tickTutorialTimer();
    expect(controller.secondsInStage.value, greaterThan(secondsBefore));
  });

  test('クールタイム解除時は連続した掃除の効果がサーバー応答後も残る', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
      enforceCooldown: true,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.meters['清潔'], 60);

    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.debugBypassFlags, [true, true]);
    expect(provider.appliedActionCount, 2);
    expect(controller.meters['清潔'], 100);
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);
  });

  test('送信待ち中に設定を戻しても操作時の解除要求を保持する', () async {
    final provider = _RateLimitedTrainingGameProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    controller.setCooldownEnabled(TrainingActionType.clean, true);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.debugBypassFlags, [true, true]);
    expect(provider.appliedActionCount, 1);
    expect(controller.meters['清潔'], 60);
  });

  test('解除要求が拒否されたときは効果を戻し、成功扱いにしない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
      rejectCooldown: true,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.appliedActionCount, 0);
    expect(controller.meters['清潔'], 20);
    expect(controller.syncStatus.value, TrainingSyncStatus.rejected);
    expect(controller.syncStatusMessage.value, contains('クールタイム解除'));
    expect(controller.syncStatusMessage.value, contains('保存されていません'));
    expect(controller.pendingSyncActionCount, 0);
  });

  test('429時は行動を保持して再送し、後続操作の状態を戻さない', () async {
    final provider = _RateLimitedTrainingGameProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    controller.perform(TrainingActionType.tackle);

    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean', 'clean', 'tackle']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.idempotencyKeys[1], isNot(provider.idempotencyKeys[2]));
    expect(provider.currentFetches, 1);
    expect(controller.isServerStateReady.value, isTrue);
    expect(controller.serverErrorMessage.value, isEmpty);
    expect(controller.meters['清潔'], 48);
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
  });

  test('送信中に追加した後続操作はController破棄後もjournalから復元できる', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
      holdFirstSync: true,
    );
    final followerJournalWritten = Completer<void>();
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (value) async {
        final saved = await MySharedPref.setTrainingGamePendingActions(value);
        if (value.contains('"action_code":"tackle"') &&
            !followerJournalWritten.isCompleted) {
          followerJournalWritten.complete();
        }
        return saved;
      },
    );

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.setCooldownEnabled(TrainingActionType.tackle, false);
    controller.perform(TrainingActionType.clean);
    await provider.firstSyncStarted.future;
    controller.perform(TrainingActionType.tackle);
    await followerJournalWritten.future;

    expect(MySharedPref.getTrainingGamePendingActions(),
        contains('"action_code":"tackle"'));
    controller.onClose();
    provider.releaseFirstSync.complete();
    await TrainingGameProvider.waitForPendingSync();

    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();
    expect(restored.pendingSyncActionCount, 2);
    await restored.retryPendingSync();

    expect(provider.actionCodes, ['clean', 'clean', 'tackle']);
    expect(provider.appliedActionCount, 2);
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
  });

  test('ログインセッション切替時は429保留操作を破棄し、再送しない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      alwaysRateLimited: true,
      retryAfter: const Duration(seconds: 30),
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await provider.firstRateLimitObserved.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.syncStatus.value, TrainingSyncStatus.rateLimited);
    await AuthToken.notifySessionChangedForTesting();
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(controller.pendingSyncActionCount, 0);
    expect(controller.syncStatus.value, TrainingSyncStatus.sessionChanged);
    expect(controller.syncStatusMessage.value, contains('前のアカウント'));
  });

  test('画面破棄時は429待機をキャンセルし、それ以上送信しない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      alwaysRateLimited: true,
      retryAfter: const Duration(seconds: 30),
    );
    final controller = TrainingGameController(serverProvider: provider);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await provider.firstRateLimitObserved.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    controller.onClose();
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(controller.pendingSyncActionCount, 0);
    expect(MySharedPref.getTrainingGamePendingActions(), isNotNull);
  });

  test('連続429は初回を含む3回で停止し、未送信と表示する', () async {
    final provider = _RateLimitedTrainingGameProvider(alwaysRateLimited: true);
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean', 'clean', 'clean']);
    expect(provider.idempotencyKeys.toSet(), hasLength(1));
    expect(controller.pendingSyncActionCount, 1);
    expect(controller.syncStatus.value, TrainingSyncStatus.stopped);
    expect(controller.syncStatusMessage.value, contains('未送信のまま保留中'));
    expect(controller.syncStatusMessage.value, contains('2回'));
    expect(controller.syncStatusMessage.value, contains('65秒'));
  });

  test('結果不明時は同じ操作IDで再確認する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      ambiguousFirstAction: true,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.syncStatusMessage.value, contains('未送信とは断定できません'));
    expect(controller.canRetryPendingSync, isTrue);
    expect(controller.canDiscardPendingSync, isFalse);
    expect(provider.appliedActionCount, 1);
    final meterAfterFirstAttempt = controller.meters['清潔'];

    // 未確定の間は新しい操作IDを発行するアクションを受け付けない。
    await controller.acknowledgeSyncNotice();
    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    controller.perform(TrainingActionType.clean);
    expect(controller.meters['清潔'], meterAfterFirstAttempt);
    expect(provider.actionCodes, ['clean']);

    await controller.retryPendingSync();

    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.appliedActionCount, 1);
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);
    expect(controller.syncStatusMessage.value, isEmpty);
  });

  test('再起動後も結果不明操作の同じIDを復元して再確認する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      ambiguousFirstAction: true,
    );
    final firstController = TrainingGameController(serverProvider: provider);

    await firstController.debugStartAtTraining();
    firstController.setCooldownEnabled(TrainingActionType.clean, false);
    firstController.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    final savedQueue = MySharedPref.getTrainingGamePendingActions();
    expect(savedQueue, isNotNull);
    expect(savedQueue, contains(provider.idempotencyKeys.single!));
    expect(provider.appliedActionCount, 1);
    firstController.onClose();

    final restoredController = TrainingGameController(serverProvider: provider);
    addTearDown(restoredController.onClose);
    await restoredController.retryRestoreServerState();

    expect(
        restoredController.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(restoredController.canRetryPendingSync, isTrue);
    await restoredController.retryPendingSync();

    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.appliedActionCount, 1);
    expect(restoredController.syncStatus.value, TrainingSyncStatus.idle);
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
    expect(provider.debugBypassFlags, [true, true]);
  });

  test('識別情報のない破損ジャーナルは保留操作として停止する', () async {
    const corruptQueue =
        '[{"action_code":"clean","revision":1,"idempotency_key":"broken","may_have_been_applied":true}]';
    expect(
        await MySharedPref.setTrainingGamePendingActions(corruptQueue), isTrue);
    final provider = _RateLimitedTrainingGameProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.retryRestoreServerState();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.syncStatusMessage.value, contains('読み取れません'));
    expect(controller.canRetryPendingSync, isTrue);
    expect(provider.actionCodes, isEmpty);
    expect(MySharedPref.getTrainingGamePendingActions(), corruptQueue);
  });

  test('破損journalは原文を保全し、未送信と断定せずサーバー状態を確認して復旧する', () async {
    const corruptQueue =
        '[{"action_code":"clean","revision":1,"idempotency_key":"broken","may_have_been_applied":true}]';
    expect(
        await MySharedPref.setTrainingGamePendingActions(corruptQueue), isTrue);
    final provider = _RateLimitedTrainingGameProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.retryRestoreServerState();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.canRetryPendingSync, isTrue);
    await controller.retryPendingSync();

    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
    final archived = jsonDecode(
      MySharedPref.getTrainingGamePendingActionsArchive()!,
    ) as List<dynamic>;
    expect(archived, contains(corruptQueue));
    expect(controller.syncStatus.value, TrainingSyncStatus.rejected);
    expect(controller.syncStatusMessage.value, contains('適用有無は未確定'));
    expect(controller.syncStatusMessage.value, isNot(contains('未送信操作')));
    expect(controller.canDiscardPendingSync, isFalse);
    expect(provider.actionCodes, isEmpty);
    await controller.acknowledgeSyncNotice();
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);
  });

  test('破損journal復旧中に置き換わったjournalを消さず、確認状態を保持する', () async {
    const corruptQueue =
        '[{"action_code":"clean","revision":1,"idempotency_key":"broken","may_have_been_applied":true}]';
    expect(
        await MySharedPref.setTrainingGamePendingActions(corruptQueue), isTrue);
    final provider = _RateLimitedTrainingGameProvider(
      holdFetchOnCount: 4,
      rateLimitFirstAction: false,
    );
    final archiveStarted = Completer<void>();
    final releaseArchive = Completer<void>();
    final first = TrainingGameController(
      serverProvider: provider,
      archivePendingActions: (raw) async {
        if (!archiveStarted.isCompleted) archiveStarted.complete();
        await releaseArchive.future;
        return MySharedPref.archiveTrainingGamePendingActions(raw);
      },
    );
    addTearDown(first.onClose);
    final second = TrainingGameController(serverProvider: provider);
    addTearDown(second.onClose);

    await first.retryRestoreServerState();
    await second.retryRestoreServerState();
    final recovery = first.retryPendingSync();
    await archiveStarted.future;

    await second.retryPendingSync();
    expect(second.syncStatus.value, TrainingSyncStatus.stopped);
    expect(second.syncStatusMessage.value, contains('別の画面'));

    final replacement = jsonEncode([
      {
        'action_code': 'clean',
        'revision': 2,
        'idempotency_key': 'replacement-action',
        'player_id': 7,
        'cycle_no': 1,
        'game_started_at': DateTime.utc(2026, 10, 20).toIso8601String(),
        'debug_bypass_cooldown': true,
        'may_have_been_applied': false,
        'requires_game_instance_check': false,
      },
    ]);
    expect(
        await MySharedPref.setTrainingGamePendingActions(replacement), isTrue);
    releaseArchive.complete();
    await recovery;

    expect(MySharedPref.getTrainingGamePendingActions(), replacement);
    expect(first.syncStatus.value, TrainingSyncStatus.rejected);
    expect(first.canDiscardPendingSync, isFalse);
    expect(MySharedPref.getTrainingGamePendingActionsRecovery(), isNotNull);
    expect(provider.actionCodes, isEmpty);

    final acknowledgement = first.acknowledgeSyncNotice();
    await provider.heldFetchStarted.future;
    await first.acknowledgeSyncNotice();
    expect(provider.currentFetches, 4);
    first.perform(TrainingActionType.tackle);
    expect(provider.actionCodes, isEmpty);
    expect(first.pendingSyncActionCount, 0);
    expect(first.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    provider.releaseHeldFetch.complete();
    await acknowledgement;
    expect(MySharedPref.getTrainingGamePendingActions(), replacement);
    expect(first.pendingSyncActionCount, 1);
    expect(first.syncStatus.value, TrainingSyncStatus.stopped);

    await first.retryPendingSync();
    expect(provider.actionCodes, ['clean']);
    expect(provider.idempotencyKeys.single, 'replacement-action');
  });

  test('破損journalの確認待ちは再起動後も未確定のまま復元する', () async {
    const corruptQueue =
        '[{"action_code":"clean","revision":1,"idempotency_key":"broken","may_have_been_applied":true}]';
    expect(
        await MySharedPref.setTrainingGamePendingActions(corruptQueue), isTrue);
    final provider = _RateLimitedTrainingGameProvider();
    final first = TrainingGameController(serverProvider: provider);
    await first.retryRestoreServerState();
    await first.retryPendingSync();
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
    expect(MySharedPref.getTrainingGamePendingActionsRecovery(), isNotNull);
    first.onClose();

    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();
    expect(restored.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(restored.canDiscardPendingSync, isFalse);
    expect(restored.canRetryPendingSync, isTrue);

    await restored.retryPendingSync();
    expect(restored.syncStatus.value, TrainingSyncStatus.rejected);
    await restored.acknowledgeSyncNotice();
    expect(MySharedPref.getTrainingGamePendingActionsRecovery(), isNull);
    expect(restored.syncStatus.value, TrainingSyncStatus.idle);
  });

  test('復旧確認中の通信失敗後にサーバー状態を再取得して続行できる', () async {
    const corruptQueue =
        '[{"action_code":"clean","revision":1,"idempotency_key":"broken","may_have_been_applied":true}]';
    expect(
        await MySharedPref.setTrainingGamePendingActions(corruptQueue), isTrue);
    final provider = _RateLimitedTrainingGameProvider(
      failFetchOnCount: 3,
      rateLimitFirstAction: false,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.retryRestoreServerState();
    await controller.retryPendingSync();
    expect(controller.syncStatus.value, TrainingSyncStatus.rejected);
    await controller.acknowledgeSyncNotice();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.canRetryPendingSync, isTrue);
    expect(controller.isServerStateReady.value, isFalse);
    expect(MySharedPref.getTrainingGamePendingActionsRecovery(), isNull);

    await controller.retryPendingSync();
    expect(controller.syncStatus.value, TrainingSyncStatus.rejected);
    expect(controller.isServerStateReady.value, isTrue);
    expect(controller.canRetryPendingSync, isFalse);
    await controller.acknowledgeSyncNotice();
    expect(controller.syncStatus.value, TrainingSyncStatus.idle);

    final nextController = TrainingGameController(serverProvider: provider);
    addTearDown(nextController.onClose);
    await nextController.retryRestoreServerState();
    nextController.setCooldownEnabled(TrainingActionType.tackle, false);
    nextController.perform(TrainingActionType.tackle);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.actionCodes, ['tackle']);
  });

  test('再試行前の保存失敗でも以前の不明結果を保ち、429後の再起動で復元する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      ambiguousThenRateLimited: true,
      retryAfter: const Duration(seconds: 65),
    );
    var failNextWrite = false;
    final first = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (value) async {
        if (failNextWrite) {
          failNextWrite = false;
          return false;
        }
        return MySharedPref.setTrainingGamePendingActions(value);
      },
    );
    addTearDown(first.onClose);

    await first.debugStartAtTraining();
    first.setCooldownEnabled(TrainingActionType.clean, false);
    first.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(first.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(first.canDiscardPendingSync, isFalse);

    failNextWrite = true;
    await first.retryPendingSync();
    expect(provider.actionCodes, ['clean']);
    expect(first.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(first.syncStatusMessage.value, contains('先行操作の適用有無は未確定'));
    expect(first.canDiscardPendingSync, isFalse);

    await first.retryPendingSync();
    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys.toSet(), hasLength(1));
    expect(first.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(first.canDiscardPendingSync, isFalse);
    first.onClose();

    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();
    expect(restored.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(restored.canDiscardPendingSync, isFalse);
    expect(restored.syncStatusMessage.value, contains('操作結果が未確定'));
  });

  test('端末保存に失敗した操作は送信しない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
    );
    final controller = TrainingGameController(
      serverProvider: provider,
      writePendingActions: (_) async => false,
    );
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, isEmpty);
    expect(controller.pendingSyncActionCount, 1);
    expect(controller.syncStatus.value, TrainingSyncStatus.stopped);
    expect(controller.syncStatusMessage.value, contains('送信していません'));
  });

  test('成功応答後に端末記録を更新できなくても再起動後に同じIDで確認する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      rateLimitFirstAction: false,
    );
    final firstController = TrainingGameController(
      serverProvider: provider,
      clearPendingActions: () async => false,
    );
    addTearDown(firstController.onClose);

    await firstController.debugStartAtTraining();
    firstController.setCooldownEnabled(TrainingActionType.clean, false);
    firstController.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(provider.appliedActionCount, 1);
    expect(firstController.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    final savedBeforeExit = MySharedPref.getTrainingGamePendingActions();
    expect(savedBeforeExit, contains(provider.idempotencyKeys.single!));
    expect(savedBeforeExit, contains('"may_have_been_applied":true'));
    firstController.onClose();

    final restoredController = TrainingGameController(serverProvider: provider);
    addTearDown(restoredController.onClose);
    await restoredController.retryRestoreServerState();
    await restoredController.retryPendingSync();

    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.appliedActionCount, 1);
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
  });

  test('同一PlayerとCycleでも初期化後の旧操作は隔離して再送しない', () async {
    final provider = _RateLimitedTrainingGameProvider(alwaysRateLimited: true);
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.pendingSyncActionCount, 1);
    expect(provider.actionCodes, ['clean', 'clean', 'clean']);

    await controller.resetDebugGame();

    final quarantined = MySharedPref.getTrainingGamePendingActions();
    expect(quarantined, contains('"quarantined":true'));
    expect(controller.pendingSyncActionCount, 0);
    expect(controller.canRetryPendingSync, isFalse);
    await controller.retryPendingSync();
    expect(provider.actionCodes, ['clean', 'clean', 'clean']);

    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();
    expect(restored.pendingSyncActionCount, 0);
    expect(restored.canRetryPendingSync, isFalse);
    expect(provider.actionCodes, ['clean', 'clean', 'clean']);
  });

  test('429待機中にサーバー初期化された操作は再送前に隔離する', () async {
    final provider = _RateLimitedTrainingGameProvider(alwaysRateLimited: true);
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await provider.firstRateLimitObserved.future;
    await provider.resetDebugState();
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(controller.pendingSyncActionCount, 0);
    expect(controller.syncStatusMessage.value, contains('隔離しました'));
    expect(MySharedPref.getTrainingGamePendingActions(),
        contains('"quarantined":true'));
  });

  test('lock_versionの409は状態を再取得し、同じ操作IDを保持する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      lockConflictFirstAction: true,
      rateLimitFirstAction: false,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.pendingSyncActionCount, 1);
    expect(controller.syncStatusMessage.value, contains('最新状態を取得しました'));
    expect(provider.currentFetches, 2);

    await controller.retryPendingSync();

    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.syncLockVersions, [0, 1]);
    expect(provider.appliedActionCount, 1);
  });

  test('意味を特定できない409でも保留操作を消さない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      genericConflictFirstAction: true,
      rateLimitFirstAction: false,
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(controller.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(controller.pendingSyncActionCount, 1);
    expect(controller.canRetryPendingSync, isTrue);
    expect(MySharedPref.getTrainingGamePendingActions(),
        contains(provider.idempotencyKeys.single!));
    expect(provider.actionCodes, ['clean']);
  });

  test('複数Controllerで同じjournal操作を同時に復元・送信しない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      ambiguousFirstAction: true,
    );
    final firstController = TrainingGameController(serverProvider: provider);
    addTearDown(firstController.onClose);

    await firstController.debugStartAtTraining();
    firstController.setCooldownEnabled(TrainingActionType.clean, false);
    firstController.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.appliedActionCount, 1);

    final secondController = TrainingGameController(serverProvider: provider);
    addTearDown(secondController.onClose);
    await secondController.retryRestoreServerState();
    await secondController.retryPendingSync();

    expect(secondController.pendingSyncActionCount, 0);
    expect(provider.actionCodes, ['clean']);
    secondController.setCooldownEnabled(TrainingActionType.tackle, false);
    secondController.perform(TrainingActionType.tackle);
    await TrainingGameProvider.waitForPendingSync();

    final journalAfterSecondController =
        MySharedPref.getTrainingGamePendingActions();
    expect(
        journalAfterSecondController, contains(provider.idempotencyKeys[0]!));
    expect(provider.actionCodes, ['clean']);
    expect(secondController.syncStatus.value, TrainingSyncStatus.stopped);
    expect(secondController.syncStatusMessage.value, contains('別の画面'));

    await firstController.retryPendingSync();
    expect(provider.actionCodes, ['clean', 'clean']);
    expect(provider.idempotencyKeys[0], provider.idempotencyKeys[1]);
    expect(provider.appliedActionCount, 1);

    await secondController.retryPendingSync();
    secondController.perform(TrainingActionType.tackle);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.actionCodes, ['clean', 'clean', 'tackle']);
    expect(provider.appliedActionCount, 2);
  });

  test('別Controllerが先行journal操作を処理中は後続操作を受け付けない', () async {
    final provider = _RateLimitedTrainingGameProvider(
      retryAfter: const Duration(seconds: 65),
    );
    final firstController = TrainingGameController(serverProvider: provider);

    await firstController.debugStartAtTraining();
    firstController.setCooldownEnabled(TrainingActionType.clean, false);
    firstController.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(firstController.pendingSyncActionCount, 1);
    expect(provider.actionCodes, ['clean']);

    final secondController = TrainingGameController(serverProvider: provider);
    addTearDown(secondController.onClose);
    await secondController.retryRestoreServerState();
    secondController.setCooldownEnabled(TrainingActionType.tackle, false);
    secondController.perform(TrainingActionType.tackle);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(secondController.pendingSyncActionCount, 0);
    expect(secondController.syncStatus.value, TrainingSyncStatus.stopped);
    expect(secondController.syncStatusMessage.value, contains('別の画面'));

    firstController.onClose();
  });

  test('曖昧な先行結果は再試行時の429後も再起動後に不明のまま保持する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      ambiguousThenRateLimited: true,
      retryAfter: const Duration(seconds: 65),
    );
    final firstController = TrainingGameController(serverProvider: provider);

    await firstController.debugStartAtTraining();
    firstController.setCooldownEnabled(TrainingActionType.clean, false);
    firstController.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(firstController.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(firstController.canDiscardPendingSync, isFalse);

    await firstController.retryPendingSync();
    expect(provider.actionCodes, ['clean', 'clean']);
    expect(firstController.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    firstController.onClose();

    final restored = TrainingGameController(serverProvider: provider);
    addTearDown(restored.onClose);
    await restored.retryRestoreServerState();

    expect(restored.syncStatus.value, TrainingSyncStatus.outcomeUnknown);
    expect(restored.canDiscardPendingSync, isFalse);
    expect(restored.syncStatusMessage.value, contains('操作結果が未確定'));
    expect(restored.syncStatusMessage.value, isNot(contains('未送信の保留操作')));
    expect(provider.appliedActionCount, 1);
  });

  test('Retry-Afterが自動待機上限を超える場合は待たずに停止する', () async {
    final provider = _RateLimitedTrainingGameProvider(
      retryAfter: const Duration(seconds: 65),
    );
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);

    await controller.debugStartAtTraining();
    controller.setCooldownEnabled(TrainingActionType.clean, false);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();

    expect(provider.actionCodes, ['clean']);
    expect(controller.syncStatus.value, TrainingSyncStatus.stopped);
    expect(controller.canDiscardPendingSync, isTrue);
    expect(controller.syncStatusMessage.value, contains('未送信のまま保留中'));
    await controller.discardPendingSync();
    expect(MySharedPref.getTrainingGamePendingActions(), isNull);
    expect(controller.pendingSyncActionCount, 0);
  });

  test('Retry-After は秒数と HTTP-date を大文字小文字を問わず解釈する', () {
    expect(
      TrainingGameProvider.parseRetryAfterHeader({'Retry-After': '2'}),
      const Duration(seconds: 2),
    );
    expect(
      TrainingGameProvider.parseRetryAfterHeader(
        {'RETRY-AFTER': 'Wed, 21 Oct 2015 07:28:00 GMT'},
        now: DateTime.utc(2015, 10, 21, 7, 27, 58),
      ),
      const Duration(seconds: 2),
    );
    expect(
      TrainingGameProvider.parseRetryAfterHeader({'retry-after': 'invalid'}),
      isNull,
    );
  });
}

class _RateLimitedTrainingGameProvider extends TrainingGameProvider {
  _RateLimitedTrainingGameProvider({
    this.alwaysRateLimited = false,
    this.retryAfter = Duration.zero,
    this.ambiguousFirstAction = false,
    this.rateLimitFirstAction = true,
    this.lockConflictFirstAction = false,
    this.genericConflictFirstAction = false,
    this.enforceCooldown = false,
    this.rejectCooldown = false,
    this.ambiguousThenRateLimited = false,
    this.holdFirstSync = false,
    this.holdFetchOnCount,
    this.failFetchOnCount,
    this.stageCode = 'training',
  });

  final bool alwaysRateLimited;
  final Duration retryAfter;
  final bool ambiguousFirstAction;
  final bool rateLimitFirstAction;
  final bool lockConflictFirstAction;
  final bool genericConflictFirstAction;
  final bool enforceCooldown;
  final bool rejectCooldown;
  final bool ambiguousThenRateLimited;
  final bool holdFirstSync;
  final int? holdFetchOnCount;
  final int? failFetchOnCount;
  final String stageCode;
  final firstRateLimitObserved = Completer<void>();
  final firstSyncStarted = Completer<void>();
  final releaseFirstSync = Completer<void>();
  final heldFetchStarted = Completer<void>();
  final releaseHeldFetch = Completer<void>();
  final actionCodes = <String>[];
  final tackleMetadata = <Map<String, dynamic>>[];
  final idempotencyKeys = <String?>[];
  final syncLockVersions = <int>[];
  final debugBypassFlags = <bool>[];
  final _processedActionKeys = <String>{};
  var appliedActionCount = 0;
  var currentFetches = 0;
  var _lockVersion = 0;
  var _startedAt = DateTime.utc(2026, 10, 20);
  double _cleanliness = 20;

  Map<String, dynamic> _payload() => {
        'id': 7,
        'cycle_no': 1,
        'lock_version': _lockVersion,
        'stage_code': stageCode,
        'status': 'playing',
        'started_at': _startedAt.toIso8601String(),
        'elapsed_seconds': 0,
        'actions_today': 0,
        'parameters': {
          'hunger': 20.0,
          'cleanliness': _cleanliness,
          'condition': 20.0,
          'work': 20.0,
          'tendency_fw': 0.0,
          'tendency_command': 0.0,
          'tendency_backs': 0.0,
          'tendency_bulk': 0.0,
          'tendency_tech': 0.0,
        },
        'cooldowns': <String, dynamic>{},
      };

  @override
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async =>
      _payload();

  @override
  Future<Map<String, dynamic>?> fetchCurrent({
    int? expectedSessionVersion,
  }) async {
    currentFetches++;
    if (currentFetches == failFetchOnCount) {
      throw StateError('Simulated fetch failure');
    }
    if (currentFetches == holdFetchOnCount) {
      heldFetchStarted.complete();
      await releaseHeldFetch.future;
    }
    return _payload();
  }

  @override
  Future<List<String>> fetchUnlockedPositions({
    int? expectedSessionVersion,
  }) async =>
      <String>[];

  @override
  Future<Map<String, dynamic>> resetDebugState({
    int? expectedSessionVersion,
  }) async {
    _startedAt = _startedAt.add(const Duration(days: 1));
    _lockVersion = 0;
    _cleanliness = 20;
    _processedActionKeys.clear();
    return _payload();
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
    double? actionScore,
    double? actionEffectMultiplier,
    String? actionResultCode,
    String? actionResultPolicy,
    int? actionAttemptCount,
    int? actionSuccessCount,
    int? actionSuccessfulReactionTotalUs,
    bool debugBypassCooldown = false,
    String status = 'playing',
  }) async {
    tackleMetadata.add({
      if (actionResultPolicy != null) 'result_policy': actionResultPolicy,
      if (actionAttemptCount != null) 'attempt_count': actionAttemptCount,
      if (actionSuccessCount != null) 'success_count': actionSuccessCount,
      if (actionSuccessfulReactionTotalUs != null)
        'successful_reaction_total_us': actionSuccessfulReactionTotalUs,
    });
    actionCodes.add(actionCode!);
    idempotencyKeys.add(actionIdempotencyKey);
    syncLockVersions.add(lockVersion);
    debugBypassFlags.add(debugBypassCooldown);
    if (actionCodes.length == 1 && !firstRateLimitObserved.isCompleted) {
      firstRateLimitObserved.complete();
    }
    if (actionCodes.length == 1) {
      if (!firstSyncStarted.isCompleted) firstSyncStarted.complete();
      if (holdFirstSync) await releaseFirstSync.future;
    }
    if (actionCodes.length == 1 && lockConflictFirstAction) {
      _lockVersion++;
      throw const TrainingGameApiException(
        statusCode: 409,
        message: '育成状態が別端末で更新されています。',
      );
    }
    if (actionCodes.length == 1 && genericConflictFirstAction) {
      throw const TrainingGameApiException(
        statusCode: 409,
        message: 'Conflict',
      );
    }
    if (ambiguousThenRateLimited && actionCodes.length > 1) {
      throw TrainingGameApiException(
        statusCode: 429,
        message: 'Too Many Requests',
        retryAfter: retryAfter,
      );
    }

    if (alwaysRateLimited ||
        (actionCodes.length == 1 &&
            rateLimitFirstAction &&
            !(ambiguousFirstAction || ambiguousThenRateLimited))) {
      throw TrainingGameApiException(
        statusCode: 429,
        message: 'Too Many Requests',
        retryAfter: retryAfter,
      );
    }

    if (rejectCooldown ||
        (enforceCooldown && appliedActionCount > 0 && !debugBypassCooldown)) {
      throw const TrainingGameApiException(
        statusCode: 422,
        message: 'このアクションはクールタイム中です。',
      );
    }

    final key = actionIdempotencyKey!;
    if (!_processedActionKeys.add(key)) return _payload();

    if (actionCode == 'clean') {
      _cleanliness = (_cleanliness + 40).clamp(0, 150);
    }
    if (actionCode == 'tackle') {
      _cleanliness = (_cleanliness - 12).clamp(0, 150);
    }
    appliedActionCount++;
    _lockVersion++;
    if ((ambiguousFirstAction || ambiguousThenRateLimited) &&
        actionCodes.length == 1) {
      throw TrainingGameApiException(
        statusCode: 408,
        message: 'Request Timeout after server applied the action',
      );
    }
    return _payload();
  }
}
