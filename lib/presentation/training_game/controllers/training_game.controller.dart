import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

import '../mini_games/models/mini_game_result.dart';
import '../models/training_action_gate.dart';
import '../models/mini_game_settings.dart';
import '../models/training_game_models.dart';
import '../models/training_workout_requirement.dart';

enum TrainingSyncStatus {
  idle,
  syncing,
  rateLimited,
  stopped,
  queueFull,
  outcomeUnknown,
  rejected,
  sessionChanged,
}

class _PendingTrainingAction {
  _PendingTrainingAction({
    required this.type,
    required this.result,
    required this.revision,
    required this.idempotencyKey,
    required this.sessionVersion,
    required this.playerId,
    required this.cycleNo,
    required this.gameStartedAt,
    required this.debugBypassCooldown,
  });

  final TrainingActionType type;
  final MiniGameResult? result;
  final int revision;
  final String idempotencyKey;
  final int sessionVersion;
  final int? playerId;
  final int? cycleNo;
  final DateTime? gameStartedAt;
  final bool debugBypassCooldown;
  DateTime? retryNotBefore;
  bool mayHaveBeenApplied = false;
  bool requiresGameInstanceCheck = false;

  Map<String, dynamic> toJson() => {
        'action_code': TrainingGameController._actionCode(type),
        'revision': revision,
        'idempotency_key': idempotencyKey,
        'player_id': playerId,
        'cycle_no': cycleNo,
        'game_started_at': gameStartedAt?.toUtc().toIso8601String(),
        'debug_bypass_cooldown': debugBypassCooldown,
        'may_have_been_applied': mayHaveBeenApplied,
        'requires_game_instance_check': requiresGameInstanceCheck,
        'retry_not_before': retryNotBefore?.toIso8601String(),
        if (result != null)
          'result': {
            'type': result!.type.name,
            'summary': result!.summary,
            'score': result!.score,
            'effect_multiplier': result!.effectMultiplier,
            'result_code': result!.resultCode,
            ...?result!.tackleResult?.toJson(),
          },
      };
}

enum _CorruptJournalRecoveryResult {
  completed,
  journalChanged,
  archiveFailed,
  markerFailed,
  clearFailed,
  sessionChanged,
}

/// 育成ゲームの進行状態と行動結果を管理します。
class TrainingGameController extends GetxController
    with WidgetsBindingObserver {
  static Future<void> _pendingActionPersistence = Future<void>.value();
  static final Map<String, Object> _pendingActionClaims = {};
  static final Map<String, Object> _pendingGameQueueClaims = {};
  static const maxQueuedSyncActions = 8;
  static const maxAutomatic429Retries = 2;
  static const maxAutomatic429Wait = Duration(seconds: 65);

  static Future<T> _serializePendingActionPersistence<T>(
    Future<T> Function() operation,
  ) {
    final write = _pendingActionPersistence.then<T>((_) => operation());
    _pendingActionPersistence = write.then<void>((_) {}, onError: (_, __) {});
    return write;
  }

  /// 回数上限を設けず、連打だけを抑制するための暫定クールタイムです。
  /// 仕様では秒数が調整項目のため、正式値確定時にここだけ変更します。
  static const careCooldown = Duration(seconds: 60);

  /// 画面遷移時に表示するロード時間の下限・上限です。
  static const transitionLoadingMinMilliseconds = 1500;
  static const transitionLoadingMaxMilliseconds = 3000;

  /// 1.5〜3秒の範囲から画面遷移用のロード時間を生成します。
  static Duration randomTransitionLoadingDuration() {
    final range =
        transitionLoadingMaxMilliseconds - transitionLoadingMinMilliseconds + 1;
    return Duration(
      milliseconds: transitionLoadingMinMilliseconds + Random().nextInt(range),
    );
  }

  /// 育成期におけるゲーム内1日の経過時間です。
  static const mainDayHours = 24;

  /// 新しい育成サイクルの表示パラメータ初期値です。
  static const initialMeters = <String, double>{
    '食事': 100,
    '清潔': 50,
    '体調': 50,
    '仕事': 0,
  };

  /// 新しい育成サイクルの傾向値初期値です。
  static const initialTrends = <String, double>{
    'FW': 0,
    'CMD': 0,
    'RUN': 0,
    'BULK': 0,
    'TECH': 0,
  };

  /// 各段階の表示定義です。
  static const stages = <TrainingStageDefinition>[
    TrainingStageDefinition(
      name: '卵',
      description: 'まずは清潔と休養を整えて、誕生を待ちましょう。',
      unlockHours: 0,
    ),
    TrainingStageDefinition(
      name: '幼少',
      description: '基本のお世話を覚えながら、少しずつ体を動かします。',
      unlockHours: 0,
    ),
    TrainingStageDefinition(
      name: '育成期',
      description: '練習の積み重ねが、将来のポジションを決めます。',
      unlockHours: 0,
      days: 7,
    ),
    TrainingStageDefinition(
      name: '成長期',
      description: '育て方の傾向から、適性ポジションが見え始めます。',
      unlockHours: 0,
      days: 7,
    ),
    TrainingStageDefinition(
      name: '一軍',
      description: '最終ポジションが確定し、育成を完了します。',
      unlockHours: 0,
    ),
  ];

  /// 画面に表示する行動一覧です。
  static const actions = <TrainingActionDefinition>[
    TrainingActionDefinition(
      type: TrainingActionType.meal,
      label: 'ごはん',
      description: '体調を回復します',
      icon: '🍖',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.clean,
      label: '掃除',
      description: '清潔を整えます',
      icon: '🧹',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.rest,
      label: '休養',
      description: '体調を回復します',
      icon: '🛏️',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.squat,
      label: '筋トレ',
      description: 'FW・BULKが伸びます',
      icon: '🏋️',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.tackle,
      label: 'タックル',
      description: 'FW・TECHが伸びます',
      icon: '🛡️',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.passAndRun,
      label: 'パス＆ラン',
      description: 'RUN・CMDが伸びます',
      icon: '🏉',
    ),
    TrainingActionDefinition(
      type: TrainingActionType.work,
      label: '仕事',
      description: 'CMD・TECHが伸びます',
      icon: '💼',
    ),
  ];

  /// 仕様上、通常のクールタイム対象となる行動かを返します。
  static bool isCooldownAction(TrainingActionType type) =>
      type == TrainingActionType.meal ||
      type == TrainingActionType.clean ||
      type == TrainingActionType.rest ||
      type == TrainingActionType.squat;

  // 段階1のチュートリアル用初期値を、サーバー応答前にも表示します。
  final meters = Map<String, double>.from(initialMeters).obs;
  final trends = Map<String, double>.from(initialTrends).obs;
  final stageIndex = 0.obs;
  final elapsedHours = 0.obs;
  final totalElapsedSeconds = 0.obs;
  final mainElapsedSeconds = 0.obs;
  final day = 1.obs;
  final selectedSpeed = 1.obs;
  final logs = <String>[].obs;
  final ended = false.obs;
  final endingMessage = ''.obs;
  final isEndingSyncPending = false.obs;
  final endingSyncError = ''.obs;
  final clearPosition = RxnString();
  final _serverBranchCode = RxnString();
  final _serverPositionCode = RxnString();
  final unlockedPositions = <String>[].obs;
  final endingStep = 0.obs;
  final evolutionStage = RxnInt();
  final secondsInStage = 0.obs;
  final daysInStage = 0.obs;
  final actionsToday = 0.obs;
  final cooldownTick = 0.obs;
  final cooldownEnabled = <TrainingActionType, bool>{
    TrainingActionType.meal: true,
    TrainingActionType.clean: true,
    TrainingActionType.rest: true,
    TrainingActionType.squat: true,
    TrainingActionType.work: false,
    TrainingActionType.tackle: false,
    TrainingActionType.passAndRun: false,
  }.obs;
  final trainingCount = 0.obs;
  final timeSpeed = 1.obs;
  final isServerStateReady = false.obs;
  final isReturningHome = false.obs;
  final syncStatus = TrainingSyncStatus.idle.obs;
  final syncStatusMessage = ''.obs;
  final serverErrorMessage = ''.obs;
  final workAvailabilityError = ''.obs;
  // 仕事の実施可否は端末時計ではなく、APIが返すサーバー判定だけを使用します。
  bool _isWorkAvailable = false;
  bool _isWorkSyncPending = false;
  bool _isWorkPreparationPending = false;
  int? _pendingStageIndex;
  bool _pendingStageSyncQueued = false;
  int _lowConditionTraining = 0;
  bool _dayCared = false;
  final _zeroHours = <String, int>{'食事': 0, '清潔': 0, '体調': 0, '仕事': 0};
  final _tutorialZeroSeconds = <String, int>{'食事': 0, '清潔': 0, '体調': 0};
  final _actionGate = TrainingActionGate(
    now: () => ServerTimeClock.instance.now,
  );
  Timer? _tutorialTimer;
  Timer? _mainTimer;
  int _serverElapsedSeconds = 0;
  int _elapsedTimeOffsetSeconds = 0;
  int? _activeMainProgressBaseSeconds;
  int _processedActiveMainHours = 0;
  bool _waitingForServerRestore = false;
  bool _restoreLocalCountersOnNextServerState = true;
  final _mainClockTick = 0.obs;
  bool _isAppInBackground = false;
  Future<void> _syncChain = Future<void>.value();
  Future<void> _restoreChain = Future<void>.value();
  final _queuedActions = <_PendingTrainingAction>[];
  _PendingTrainingAction? _activeSyncAction;
  final Object _pendingActionClaimOwner = Object();
  String? _pendingGameQueueClaimKey;
  final Set<String> _claimedPendingActionKeys = {};
  final Future<bool> Function(String) _writePendingActions;
  final Future<bool> Function() _clearPendingActions;
  final Future<bool> Function(String) _archivePendingActions;
  bool _hasCorruptPendingActionQueue = false;
  String? _corruptPendingActionRaw;
  bool _hasForeignPendingAction = false;
  bool _corruptPendingActionsNeedServerRefresh = false;
  bool _pendingJournalRecoveryAwaitingAck = false;
  bool _isAcknowledgingSyncNotice = false;
  bool _syncRequested = false;
  bool _syncRunning = false;
  bool _syncActionInFlight = false;
  DateTime? _syncRetryNotBefore;
  bool _syncRequestMayHaveBeenApplied = false;
  Future<void>? _debugTimeSync;
  bool _debugTimeSavePending = false;
  bool _debugDailyResetPending = false;
  String _debugTimeSyncError = '';
  bool _syncBlockedUntilServerRestore = false;
  bool _hasUnsyncedLocalState = false;
  int _localStateRevision = 0;
  bool _isDisposed = false;
  bool _sessionInvalidated = false;
  bool _hasUnknownSyncOutcome = false;
  late final int _ownedSessionVersion;
  Timer? _retryWaitTimer;
  Completer<bool>? _retryWaitCompleter;
  final TrainingGameProvider _serverProvider;

  TrainingGameController({
    TrainingGameProvider? serverProvider,
    Future<bool> Function(String)? writePendingActions,
    Future<bool> Function()? clearPendingActions,
    Future<bool> Function(String)? archivePendingActions,
  })  : _serverProvider = serverProvider ?? TrainingGameProvider(),
        _writePendingActions =
            writePendingActions ?? MySharedPref.setTrainingGamePendingActions,
        _clearPendingActions =
            clearPendingActions ?? MySharedPref.clearTrainingGamePendingActions,
        _archivePendingActions = archivePendingActions ??
            MySharedPref.archiveTrainingGamePendingActions {
    _squatStageSubscription = stageIndex.listen((_) => _squatSceneGeneration++);
    _ownedSessionVersion = AuthToken.sessionVersion;
    AuthToken.addSessionChangeListener(_handleAuthSessionChanged);
  }
  // 育成の識別値が元に戻っても、進行中のお世話の権限は復活させません。
  int _squatSceneGeneration = 0;
  late final StreamSubscription<int> _squatStageSubscription;
  int? _playerId;
  int? get _serverPlayerId => _playerId;
  set _serverPlayerId(int? value) {
    if (_playerId != value) _squatSceneGeneration++;
    _playerId = value;
  }

  int? _cycleNo;
  int? get _serverCycleNo => _cycleNo;
  set _serverCycleNo(int? value) {
    if (_cycleNo != value) _squatSceneGeneration++;
    _cycleNo = value;
  }

  DateTime? _gameStartedAt;
  DateTime? get _serverGameStartedAt => _gameStartedAt;
  set _serverGameStartedAt(DateTime? value) {
    if (_gameStartedAt != value) _squatSceneGeneration++;
    _gameStartedAt = value;
  }

  int _serverLockVersion = 0;
  double? _serverRequiredWorkValue;
  int? _serverRequiredElapsedHours;
  String? _serverNextStageCode;
  int _playFloor = 0;

  /// 現在の段階定義を返します。
  TrainingStageDefinition get currentStage => stages[stageIndex.value];

  /// サーバー時刻で当日の仕事が未実施かを返します。
  bool get canWorkToday =>
      _isWorkAvailable && !_isWorkSyncPending && _pendingStageIndex == null;

  /// 仕事の可否照会または専用画面への遷移中かを返します。
  bool get isWorkPreparationPending => _isWorkPreparationPending;

  int get pendingSyncActionCount =>
      _queuedActions.length + (_syncActionInFlight ? 1 : 0);

  bool get canRetryPendingSync =>
      !_isDisposed &&
      !_sessionInvalidated &&
      AuthToken.sessionVersion == _ownedSessionVersion &&
      (syncStatus.value != TrainingSyncStatus.outcomeUnknown ||
          isServerStateReady.value ||
          _hasCorruptPendingActionQueue ||
          _corruptPendingActionsNeedServerRefresh ||
          _hasForeignPendingAction) &&
      !_syncRunning &&
      (_queuedActions.isNotEmpty ||
          _syncRequested ||
          _hasForeignPendingAction ||
          _hasCorruptPendingActionQueue ||
          _corruptPendingActionsNeedServerRefresh) &&
      (syncStatus.value == TrainingSyncStatus.stopped ||
          syncStatus.value == TrainingSyncStatus.outcomeUnknown);

  bool get canDiscardPendingSync =>
      !_isDisposed &&
      !_sessionInvalidated &&
      AuthToken.sessionVersion == _ownedSessionVersion &&
      (!_syncRunning || _retryWaitTimer != null) &&
      !_hasUnknownSyncOutcome &&
      (_queuedActions.isNotEmpty || _syncRequested);

  bool _ownsSession(int expectedVersion) =>
      !_isDisposed &&
      !_sessionInvalidated &&
      expectedVersion == _ownedSessionVersion &&
      AuthToken.sessionVersion == expectedVersion;

  Future<void> _handleAuthSessionChanged(int sessionVersion) async {
    if (_isDisposed || sessionVersion == _ownedSessionVersion) return;
    final hadUnknownOutcome = _hasUnknownSyncOutcome;
    _sessionInvalidated = true;
    _cancelRetryWait();
    _queuedActions.clear();
    _releaseAllPendingActionClaims();
    _releasePendingGameQueueClaim();
    _hasForeignPendingAction = false;
    _syncRequested = false;
    _syncRequestMayHaveBeenApplied = false;
    _syncBlockedUntilServerRestore = true;
    _hasUnsyncedLocalState = false;
    _hasUnknownSyncOutcome = false;
    _syncActionInFlight = false;
    _isWorkSyncPending = false;
    _isWorkPreparationPending = false;
    _actionGate.clear();
    isServerStateReady.value = false;
    final message = hadUnknownOutcome
        ? 'ログイン状態が変わったため、結果不明の操作を破棄しました。前回操作は前のアカウントへ反映された可能性があります。'
        : 'ログイン状態が変わったため、未送信操作を破棄しました。通信中だった操作は前のアカウントへ反映された可能性があります。';
    syncStatus.value = TrainingSyncStatus.sessionChanged;
    syncStatusMessage.value = message;
    serverErrorMessage.value = message;
    await MySharedPref.clearTrainingGameLocalState();
    await MySharedPref.clearTrainingGameStartedAt();
    await MySharedPref.clearTrainingGameDebugElapsedSeconds();
  }

  Future<bool> _waitForRetry(Duration duration) {
    final completer = Completer<bool>();
    _retryWaitCompleter = completer;
    _retryWaitTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future.whenComplete(() {
      _retryWaitTimer?.cancel();
      _retryWaitTimer = null;
      if (identical(_retryWaitCompleter, completer)) {
        _retryWaitCompleter = null;
      }
    });
  }

  void _cancelRetryWait() {
    _retryWaitTimer?.cancel();
    _retryWaitTimer = null;
    final completer = _retryWaitCompleter;
    _retryWaitCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  bool _matchesPendingActionCycle(Object? value, int playerId, int cycleNo) {
    if (value is! Map) return false;
    final storedPlayerId = value['player_id'];
    final storedCycleNo = value['cycle_no'];
    return storedPlayerId is num &&
        storedCycleNo is num &&
        storedPlayerId.toInt() == playerId &&
        storedCycleNo.toInt() == cycleNo;
  }

  DateTime? _gameStartedAtFrom(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  String _currentPendingActionRecoveryMarker() => jsonEncode({
        'player_id': _serverPlayerId,
        'cycle_no': _serverCycleNo,
        'game_started_at': _serverGameStartedAt?.toUtc().toIso8601String(),
      });

  bool _hasPendingActionRecoveryMarkerForCurrentGame() {
    final raw = MySharedPref.getTrainingGamePendingActionsRecovery();
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return true;
      final playerId = decoded['player_id'];
      final cycleNo = decoded['cycle_no'];
      final startedAt = _gameStartedAtFrom(decoded['game_started_at']);
      if (playerId is! num || cycleNo is! num || startedAt == null) {
        return true;
      }
      return playerId.toInt() == _serverPlayerId &&
          cycleNo.toInt() == _serverCycleNo &&
          _sameGameInstance(startedAt, _serverGameStartedAt);
    } catch (_) {
      // 読めない停止マーカーは、安全側に倒して解除しません。
      return true;
    }
  }

  bool _sameGameInstance(DateTime? first, DateTime? second) =>
      first != null && second != null && first.isAtSameMomentAs(second);

  String? get _currentPendingGameQueueKey {
    final playerId = _serverPlayerId;
    final cycleNo = _serverCycleNo;
    if (playerId == null || cycleNo == null) return null;
    final startedAt = _serverGameStartedAt?.toUtc().toIso8601String() ?? '';
    return '$playerId:$cycleNo:$startedAt';
  }

  bool _pendingGameQueueIsClaimedByAnotherController() {
    final key = _currentPendingGameQueueKey;
    final owner = key == null ? null : _pendingGameQueueClaims[key];
    return owner != null && !identical(owner, _pendingActionClaimOwner);
  }

  bool _claimPendingGameQueue() {
    final key = _currentPendingGameQueueKey;
    if (key == null) return false;
    final owner = _pendingGameQueueClaims[key];
    if (owner != null && !identical(owner, _pendingActionClaimOwner)) {
      _hasForeignPendingAction = true;
      return false;
    }
    _pendingGameQueueClaims[key] = _pendingActionClaimOwner;
    _pendingGameQueueClaimKey = key;
    _hasForeignPendingAction = false;
    return true;
  }

  void _releasePendingGameQueueClaim() {
    final key = _pendingGameQueueClaimKey;
    if (key != null &&
        identical(_pendingGameQueueClaims[key], _pendingActionClaimOwner)) {
      _pendingGameQueueClaims.remove(key);
    }
    _pendingGameQueueClaimKey = null;
  }

  bool _claimPendingAction(String key) {
    final owner = _pendingActionClaims[key];
    if (owner != null && !identical(owner, _pendingActionClaimOwner)) {
      return false;
    }
    _pendingActionClaims[key] = _pendingActionClaimOwner;
    _claimedPendingActionKeys.add(key);
    return true;
  }

  bool _ownsPendingActionClaim(String key) =>
      identical(_pendingActionClaims[key], _pendingActionClaimOwner);

  void _releasePendingActionClaim(String key) {
    if (identical(
      _pendingActionClaims[key],
      _pendingActionClaimOwner,
    )) {
      _pendingActionClaims.remove(key);
    }
    _claimedPendingActionKeys.remove(key);
  }

  void _releaseAllPendingActionClaims() {
    for (final key in _claimedPendingActionKeys.toList()) {
      _releasePendingActionClaim(key);
    }
  }

  bool _hasPersistedPendingActionsFor(Map<String, dynamic> player) {
    final raw = MySharedPref.getTrainingGamePendingActions();
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return true;
      final playerId = (player['id'] as num?)?.toInt();
      final cycleNo = (player['cycle_no'] as num?)?.toInt();
      if (playerId == null || cycleNo == null) return true;
      for (final entry in decoded) {
        if (entry is! Map) return true;
        final storedPlayerId = entry['player_id'];
        final storedCycleNo = entry['cycle_no'];
        if (storedPlayerId is! num || storedCycleNo is! num) return true;
        if (storedPlayerId.toInt() == playerId &&
            storedCycleNo.toInt() == cycleNo) {
          return true;
        }
      }
      return false;
    } catch (_) {
      // 壊れたキューは未送信と断定せず、ローカル状態で上書きしません。
      return true;
    }
  }

  _PendingTrainingAction? _pendingActionFromJson(Object? value) {
    if (value is! Map) return null;
    final actionCode = value['action_code']?.toString();
    final type = actionCode == null ? null : _actionTypeFromCode(actionCode);
    final key = value['idempotency_key']?.toString();
    final playerId = (value['player_id'] as num?)?.toInt();
    final cycleNo = (value['cycle_no'] as num?)?.toInt();
    final revision = (value['revision'] as num?)?.toInt();
    final mayHaveBeenApplied = value['may_have_been_applied'];
    final gameStartedAt = _gameStartedAtFrom(value['game_started_at']);
    final requiresGameInstanceCheck =
        value['requires_game_instance_check'] == true ||
            mayHaveBeenApplied == true;
    if (type == null ||
        key == null ||
        key.isEmpty ||
        playerId == null ||
        cycleNo == null ||
        revision == null ||
        mayHaveBeenApplied is! bool ||
        gameStartedAt == null) {
      return null;
    }

    MiniGameResult? result;
    final rawResult = value['result'];
    if (rawResult != null) {
      if (rawResult is! Map) return null;
      final resultTypeName = rawResult['type']?.toString();
      final resultType = MiniGameType.values.where(
        (candidate) => candidate.name == resultTypeName,
      );
      final score = (rawResult['score'] as num?)?.toDouble();
      final multiplier = (rawResult['effect_multiplier'] as num?)?.toDouble();
      final summary = rawResult['summary']?.toString();
      if (resultType.isEmpty ||
          score == null ||
          multiplier == null ||
          summary == null) {
        return null;
      }
      final tackleMetadata = TackleResultMetadata.fromJson(rawResult);
      if (tackleMetadata != null &&
          (resultType.first != MiniGameType.tackle ||
              !score.isFinite ||
              (score - tackleMetadata.penaltyMeanSeconds).abs() > 0.000000001 ||
              rawResult['result_code'] != tackleMetadata.rank ||
              !multiplier.isFinite ||
              (multiplier - tackleMetadata.effectMultiplier).abs() >
                  0.000000001)) {
        throw const FormatException('Inconsistent tackle pending result');
      }
      result = MiniGameResult(
        type: resultType.first,
        summary: summary,
        score: score,
        effectMultiplier: multiplier,
        resultCode: rawResult['result_code']?.toString(),
        tackleResult: tackleMetadata,
      );
    }

    final pending = _PendingTrainingAction(
      type: type,
      result: result,
      revision: revision,
      idempotencyKey: key,
      sessionVersion: _ownedSessionVersion,
      playerId: playerId,
      cycleNo: cycleNo,
      gameStartedAt: gameStartedAt,
      debugBypassCooldown: value['debug_bypass_cooldown'] == true,
    )
      ..mayHaveBeenApplied = mayHaveBeenApplied
      ..requiresGameInstanceCheck = requiresGameInstanceCheck;
    final retryNotBefore = value['retry_not_before']?.toString();
    if (retryNotBefore != null) {
      pending.retryNotBefore = DateTime.tryParse(retryNotBefore);
      if (pending.retryNotBefore == null) return null;
    }
    return pending;
  }

  Future<void> _restorePersistedPendingActions() async {
    final raw = MySharedPref.getTrainingGamePendingActions();
    final playerId = _serverPlayerId;
    final cycleNo = _serverCycleNo;
    _hasForeignPendingAction = _pendingGameQueueIsClaimedByAnotherController();
    if (_hasPendingActionRecoveryMarkerForCurrentGame()) {
      _pendingJournalRecoveryAwaitingAck = true;
      _corruptPendingActionsNeedServerRefresh = true;
      _hasUnknownSyncOutcome = true;
      _hasUnsyncedLocalState = true;
      if (raw != null) {
        _corruptPendingActionRaw = raw;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! List) {
            throw const FormatException('Pending queue is not a list');
          }
        } catch (_) {
          _hasCorruptPendingActionQueue = true;
        }
      }
      if (!_hasForeignPendingAction && !_claimPendingGameQueue()) {
        _hasForeignPendingAction = true;
      }
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value =
          '以前の破損した操作記録は未確定のまま保全されています。サーバー状態の再確認後、確認して続けてください。';
      return;
    }
    if (raw == null || playerId == null || cycleNo == null) {
      if (_hasForeignPendingAction) {
        _hasUnsyncedLocalState = true;
        syncStatus.value = TrainingSyncStatus.stopped;
        syncStatusMessage.value =
            '別の画面で同じ育成の操作を処理中です。順序を守るため、この画面の操作を止めています。処理終了後に再試行してください。';
      }
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List)
        throw const FormatException('Pending queue is not a list');
      final restored = <_PendingTrainingAction>[];
      var foundStaleGeneration = false;
      for (final entry in decoded) {
        if (entry is! Map)
          throw const FormatException('Invalid pending action');
        final storedPlayerId = entry['player_id'];
        final storedCycleNo = entry['cycle_no'];
        if (storedPlayerId is! num || storedCycleNo is! num) {
          throw const FormatException('Pending action identity is missing');
        }
        if (storedPlayerId.toInt() != playerId ||
            storedCycleNo.toInt() != cycleNo) {
          continue;
        }
        if (entry['quarantined'] == true) continue;
        final storedStartedAt = _gameStartedAtFrom(entry['game_started_at']);
        if (!_sameGameInstance(storedStartedAt, _serverGameStartedAt)) {
          foundStaleGeneration = true;
          final staleKey = entry['idempotency_key']?.toString();
          if (staleKey != null) _releasePendingActionClaim(staleKey);
          continue;
        }
        final pending = _pendingActionFromJson(entry);
        if (pending == null)
          throw const FormatException('Invalid pending action');
        if (!_claimPendingAction(pending.idempotencyKey)) {
          _hasForeignPendingAction = true;
          continue;
        }
        if (!_claimPendingGameQueue()) {
          _releasePendingActionClaim(pending.idempotencyKey);
          _hasForeignPendingAction = true;
          continue;
        }
        if (restored.every(
          (existing) => existing.idempotencyKey != pending.idempotencyKey,
        )) {
          restored.add(pending);
        }
      }
      final staleInMemory = _queuedActions
          .where((action) => !_pendingActionMatchesCurrentGame(action))
          .toList();
      if (staleInMemory.isNotEmpty) {
        foundStaleGeneration = true;
        _queuedActions.removeWhere(
          (action) => !_pendingActionMatchesCurrentGame(action),
        );
        for (final action in staleInMemory) {
          _releasePendingActionClaim(action.idempotencyKey);
        }
      }
      for (final action in restored) {
        if (_queuedActions.every(
          (existing) => existing.idempotencyKey != action.idempotencyKey,
        )) {
          _queuedActions.add(action);
        }
      }
      if (foundStaleGeneration) {
        try {
          await _persistPendingActions(quarantineActions: staleInMemory);
        } catch (_) {
          // A mismatched generation remains blocked by its saved start time on the next restore.
        }
      }
      if (_queuedActions.isEmpty) {
        if (_hasForeignPendingAction) {
          _syncRequested = false;
          _hasUnsyncedLocalState = true;
          syncStatus.value = TrainingSyncStatus.stopped;
          syncStatusMessage.value =
              '別の画面で同じ育成の保留操作を処理中です。順序を守るため、この画面の操作を止めています。処理終了後に再試行してください。';
          return;
        }
        if (foundStaleGeneration) {
          _syncRequested = false;
          _syncRequestMayHaveBeenApplied = false;
          _hasUnsyncedLocalState = false;
          _hasUnknownSyncOutcome = false;
          syncStatus.value = TrainingSyncStatus.idle;
          syncStatusMessage.value = '初期化前の保留操作を隔離しました。新しい状態には再送しません。';
        }
        return;
      }
      _localStateRevision = _queuedActions.fold<int>(
        _localStateRevision,
        (revision, action) =>
            action.revision > revision ? action.revision : revision,
      );
      _hasUnsyncedLocalState = true;
      _hasUnknownSyncOutcome =
          _queuedActions.any((action) => action.mayHaveBeenApplied);
      syncStatus.value = _hasUnknownSyncOutcome
          ? TrainingSyncStatus.outcomeUnknown
          : TrainingSyncStatus.stopped;
      syncStatusMessage.value = _hasUnknownSyncOutcome
          ? '前回の操作結果が未確定です。サーバー状態を再取得済みです。同じ操作IDで再確認してください。'
          : '未送信の保留操作を復元しました。同じ操作IDで再試行するか、破棄してください。';
    } catch (_) {
      _hasCorruptPendingActionQueue = true;
      _corruptPendingActionRaw = raw;
      _hasUnknownSyncOutcome = true;
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value =
          '端末に保存した操作記録を読み取れません。操作は未送信と断定できないため、新しい操作を停止しています。';
      serverErrorMessage.value = syncStatusMessage.value;
    }
  }

  Future<void> _persistPendingActions({
    List<_PendingTrainingAction> quarantineActions = const [],
    List<_PendingTrainingAction>? snapshotActions,
    bool releaseGameClaimAfterWrite = false,
  }) {
    final playerId = _serverPlayerId;
    final cycleNo = _serverCycleNo;
    if (playerId == null || cycleNo == null) return Future<void>.value();
    return _serializePendingActionPersistence(() async {
      if (_hasCorruptPendingActionQueue) {
        throw StateError('保存済みの保留操作キューを上書きできません。');
      }
      final raw = MySharedPref.getTrainingGamePendingActions();
      var saved = <dynamic>[];
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          throw const FormatException('Pending queue is not a list');
        }
        saved = decoded;
      }
      final retainedEntries = <dynamic>[];
      final quarantinedKeys = <String>{};
      for (final entry in saved) {
        if (entry is Map && entry['quarantined'] == true) {
          retainedEntries.add(entry);
          final key = entry['idempotency_key']?.toString();
          if (key != null) quarantinedKeys.add(key);
          continue;
        }
        final key = entry is Map ? entry['idempotency_key']?.toString() : null;
        final ownedByThisController =
            key != null && _claimedPendingActionKeys.contains(key);
        if (_matchesPendingActionCycle(entry, playerId, cycleNo) &&
            !_recordMatchesCurrentGame(entry)) {
          if (entry is Map) {
            retainedEntries.add(_quarantinePendingActionEntry(
              entry,
              'game_instance_changed',
            ));
            if (key != null) quarantinedKeys.add(key);
          } else {
            retainedEntries.add(entry);
          }
          continue;
        }
        if (ownedByThisController &&
            entry is Map &&
            !_matchesPendingActionCycle(entry, playerId, cycleNo)) {
          retainedEntries.add(_quarantinePendingActionEntry(
            entry,
            'game_identity_changed',
          ));
          quarantinedKeys.add(key);
          continue;
        }
        if (ownedByThisController) continue;
        retainedEntries.add(entry);
      }
      final currentActions = <_PendingTrainingAction>[];
      final seenKeys = <String>{};
      void addCurrent(_PendingTrainingAction? action) {
        if (action == null ||
            action.playerId != playerId ||
            action.cycleNo != cycleNo ||
            !_pendingActionMatchesCurrentGame(action) ||
            !seenKeys.add(action.idempotencyKey)) {
          return;
        }
        if (!_claimPendingAction(action.idempotencyKey)) return;
        currentActions.add(action);
      }

      if (snapshotActions != null) {
        for (final action in snapshotActions) {
          addCurrent(action);
        }
      } else {
        addCurrent(_activeSyncAction);
        for (final action in _queuedActions) {
          addCurrent(action);
        }
      }
      for (final action in quarantineActions) {
        if (action.idempotencyKey.isEmpty ||
            !quarantinedKeys.add(action.idempotencyKey)) {
          continue;
        }
        retainedEntries.add({
          ...action.toJson(),
          'quarantined': true,
          'quarantine_reason': 'game_identity_changed',
        });
      }
      final updated = [
        ...retainedEntries,
        ...currentActions.map((action) => action.toJson()),
      ];
      if (updated.isEmpty) {
        if (raw != null && !await _clearPendingActions()) {
          throw StateError('保留操作を端末から削除できませんでした。');
        }
      } else if (!await _writePendingActions(
        jsonEncode(updated),
      )) {
        throw StateError('保留操作を端末へ保存できませんでした。');
      }
      final currentKeys =
          currentActions.map((action) => action.idempotencyKey).toSet();
      if (_isDisposed) {
        _releaseAllPendingActionClaims();
        if (releaseGameClaimAfterWrite) _releasePendingGameQueueClaim();
      } else {
        for (final key in _claimedPendingActionKeys.toList()) {
          if (!currentKeys.contains(key)) _releasePendingActionClaim(key);
        }
        if (currentActions.isEmpty &&
            _activeSyncAction == null &&
            _queuedActions.isEmpty) {
          _releasePendingGameQueueClaim();
        }
      }
    });
  }

  Map<String, dynamic> _quarantinePendingActionEntry(
    Map entry,
    String reason,
  ) =>
      {
        ...Map<String, dynamic>.from(entry),
        'quarantined': true,
        'quarantine_reason': reason,
      };

  bool _recordMatchesCurrentGame(Object? value) {
    if (value is! Map) return false;
    final playerId = (value['player_id'] as num?)?.toInt();
    final cycleNo = (value['cycle_no'] as num?)?.toInt();
    return playerId == _serverPlayerId &&
        cycleNo == _serverCycleNo &&
        _sameGameInstance(
          _gameStartedAtFrom(value['game_started_at']),
          _serverGameStartedAt,
        );
  }

  bool _pendingActionMatchesCurrentGame(_PendingTrainingAction action) =>
      action.playerId == _serverPlayerId &&
      action.cycleNo == _serverCycleNo &&
      _sameGameInstance(action.gameStartedAt, _serverGameStartedAt);

  void _startSyncDrain() {
    if (_syncRunning || _isDisposed || !_ownsSession(_ownedSessionVersion)) {
      return;
    }
    _syncRunning = true;
    _syncChain = _drainSyncQueue().catchError((_) {
      // 同期処理の失敗状態は、_drainSyncQueue 内で利用者向けに分類します。
    });
    TrainingGameProvider.registerPendingSync(_syncChain);
    unawaited(_syncChain);
  }

  bool _pendingActionMatchesServerData(
    _PendingTrainingAction action,
    Map<String, dynamic> data,
  ) {
    final playerId = (data['id'] as num?)?.toInt();
    final cycleNo = (data['cycle_no'] as num?)?.toInt();
    final startedAt = _gameStartedAtFrom(data['started_at']);
    return action.playerId == playerId &&
        action.cycleNo == cycleNo &&
        _sameGameInstance(action.gameStartedAt, startedAt);
  }

  Future<void> _quarantinePendingActions(
    List<_PendingTrainingAction> actions,
  ) async {
    final quarantined = <String, _PendingTrainingAction>{};
    for (final action in [
      ...actions,
      if (_activeSyncAction != null) _activeSyncAction!,
      ..._queuedActions,
    ]) {
      quarantined[action.idempotencyKey] = action;
    }
    _queuedActions.clear();
    _activeSyncAction = null;
    _syncRequested = false;
    _syncActionInFlight = false;
    _syncRequestMayHaveBeenApplied = false;
    _hasUnsyncedLocalState = false;
    _hasUnknownSyncOutcome = false;
    _actionGate.clear();
    try {
      await _persistPendingActions(
        quarantineActions: quarantined.values.toList(),
      );
    } catch (_) {
      // Saved actions still carry their old game timestamp and cannot be restored for sending.
    }
    for (final key in quarantined.keys) {
      _releasePendingActionClaim(key);
    }
    syncStatus.value = TrainingSyncStatus.stopped;
    syncStatusMessage.value = '初期化前の保留操作を隔離しました。新しい状態には再送しません。';
  }

  bool _isGameLockVersionConflict(Object error) =>
      error is TrainingGameApiException &&
      error.statusCode == 409 &&
      error.message == '育成状態が別端末で更新されています。';

  Future<void> _handleGameLockVersionConflict(
    TrainingGameApiException error,
    _PendingTrainingAction? pending,
  ) async {
    _activeSyncAction = null;
    if (pending == null) {
      _syncRequested = true;
      _syncRequestMayHaveBeenApplied = true;
    } else {
      pending
        ..mayHaveBeenApplied = true
        ..requiresGameInstanceCheck = true;
      _queuedActions.insert(0, pending);
    }
    try {
      await _persistPendingActions();
    } catch (_) {
      // The pre-send journal remains; preserve the operation in memory as well.
    }
    await _handleSyncFailure(error, preservePending: true);
    try {
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (!_ownsSession(_ownedSessionVersion)) return;
      if (data == null) throw StateError('現在の育成状態を取得できません。');
      if (pending != null && !_pendingActionMatchesServerData(pending, data)) {
        _initializeServerState(data, restoreLocalStateOverride: false);
        await _quarantinePendingActions(_queuedActions.toList());
        return;
      }
      _initializeServerState(data, restoreLocalStateOverride: false);
      // 明示的な再試行の前にも開始時刻を照合し、409後の初期化を見逃しません。
      if (pending != null) pending.requiresGameInstanceCheck = true;
      try {
        await _persistPendingActions();
      } catch (_) {
        // Keep the same idempotency key in the pre-send journal.
      }
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value =
          '別端末の更新を確認しました。最新状態を取得しました。操作結果は未確定なので、同じ操作IDで再確認してください。';
    } catch (_) {
      if (!_ownsSession(_ownedSessionVersion)) return;
      isServerStateReady.value = false;
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value =
          '別端末の更新がありましたが、最新状態を取得できません。操作は同じIDで保留し、状態確認まで再送しません。';
      serverErrorMessage.value = syncStatusMessage.value;
    }
  }

  Future<bool> _checkGameInstanceBeforeRetry(
    _PendingTrainingAction pending,
  ) async {
    try {
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (!_ownsSession(_ownedSessionVersion)) return false;
      if (data == null) throw StateError('現在の育成状態を取得できません。');
      if (!_pendingActionMatchesServerData(pending, data)) {
        _initializeServerState(data, restoreLocalStateOverride: false);
        await _quarantinePendingActions([pending]);
        return false;
      }
      _initializeServerState(data, restoreLocalStateOverride: false);
      pending.requiresGameInstanceCheck = false;
      return true;
    } catch (_) {
      if (!_ownsSession(_ownedSessionVersion)) return false;
      pending.requiresGameInstanceCheck = true;
      _queuedActions.insert(0, pending);
      _hasUnknownSyncOutcome = pending.mayHaveBeenApplied;
      syncStatus.value = _hasUnknownSyncOutcome
          ? TrainingSyncStatus.outcomeUnknown
          : TrainingSyncStatus.stopped;
      syncStatusMessage.value = '再送前の育成状態を確認できません。操作は端末に保持し、確認できるまで送信しません。';
      isServerStateReady.value = false;
      serverErrorMessage.value = syncStatusMessage.value;
      try {
        await _persistPendingActions();
      } catch (_) {
        // The previously saved record still requires an instance check.
      }
      return false;
    }
  }

  Future<void> retryPendingSync() async {
    if (!canRetryPendingSync) return;
    if (_hasCorruptPendingActionQueue ||
        _corruptPendingActionsNeedServerRefresh) {
      await _recoverCorruptPendingActions();
      return;
    }
    if (_hasForeignPendingAction) {
      await _restoreServerState();
      if (!_ownsSession(_ownedSessionVersion)) return;
      if (_hasCorruptPendingActionQueue ||
          _corruptPendingActionsNeedServerRefresh) {
        return;
      }
      if (_hasForeignPendingAction) return;
      if (_queuedActions.isEmpty) {
        _hasUnsyncedLocalState = false;
        syncStatus.value = TrainingSyncStatus.idle;
        syncStatusMessage.value = '';
        return;
      }
    }
    final resolvingUnknownOutcome = _hasUnknownSyncOutcome;
    final retryNotBefore = _queuedActions.isNotEmpty
        ? _queuedActions.first.retryNotBefore
        : _syncRetryNotBefore;
    if (retryNotBefore != null && retryNotBefore.isAfter(DateTime.now())) {
      final seconds = retryNotBefore.difference(DateTime.now()).inSeconds + 1;
      syncStatusMessage.value = _hasUnknownSyncOutcome
          ? '先行操作の通信結果は不明です。今回の429による再試行待ちです。あと約$seconds秒後に同じ操作IDで再確認できます。'
          : 'サーバー指定の待機中です。あと約$seconds秒後に再試行できます。操作は未送信のまま保留しています。';
      return;
    }
    if (_queuedActions.isNotEmpty) _queuedActions.first.retryNotBefore = null;
    _syncRetryNotBefore = null;
    syncStatus.value = TrainingSyncStatus.syncing;
    syncStatusMessage.value = resolvingUnknownOutcome
        ? '前回と同じ操作IDで再確認しています。サーバー状態と応答を確認します。'
        : '保留中の操作を再試行しています。';
    if (_queuedActions.isEmpty) _syncRequested = true;
    _startSyncDrain();
    if (_syncRunning) await _syncChain;
  }

  Future<void> _recoverCorruptPendingActions() async {
    if (!_claimPendingGameQueue()) {
      _hasForeignPendingAction = true;
      syncStatus.value = TrainingSyncStatus.stopped;
      syncStatusMessage.value = '別の画面で同じ育成の操作を処理中です。破損記録には触れず、処理終了後に再確認してください。';
      return;
    }
    if (_hasCorruptPendingActionQueue) {
      final raw = _corruptPendingActionRaw ??
          MySharedPref.getTrainingGamePendingActions();
      if (raw != null) {
        final result = await _serializePendingActionPersistence(() async {
          if (!_ownsSession(_ownedSessionVersion)) {
            return _CorruptJournalRecoveryResult.sessionChanged;
          }
          bool archived;
          try {
            archived = await _archivePendingActions(raw);
          } catch (_) {
            archived = false;
          }
          if (!_ownsSession(_ownedSessionVersion)) {
            return _CorruptJournalRecoveryResult.sessionChanged;
          }
          if (!archived) return _CorruptJournalRecoveryResult.archiveFailed;

          final markerSaved =
              await MySharedPref.setTrainingGamePendingActionsRecovery(
            _currentPendingActionRecoveryMarker(),
          );
          if (!markerSaved) return _CorruptJournalRecoveryResult.markerFailed;
          _pendingJournalRecoveryAwaitingAck = true;

          if (!_ownsSession(_ownedSessionVersion)) {
            return _CorruptJournalRecoveryResult.sessionChanged;
          }
          if (MySharedPref.getTrainingGamePendingActions() != raw) {
            return _CorruptJournalRecoveryResult.journalChanged;
          }
          if (!await _clearPendingActions()) {
            return _CorruptJournalRecoveryResult.clearFailed;
          }
          return _CorruptJournalRecoveryResult.completed;
        });
        if (!_ownsSession(_ownedSessionVersion)) return;
        if (result == _CorruptJournalRecoveryResult.archiveFailed) {
          syncStatus.value = TrainingSyncStatus.outcomeUnknown;
          syncStatusMessage.value = '破損した操作記録を保全できません。原文は残したまま再送を停止しています。';
          return;
        }
        if (result == _CorruptJournalRecoveryResult.markerFailed) {
          syncStatus.value = TrainingSyncStatus.outcomeUnknown;
          syncStatusMessage.value =
              '破損記録の原文は保全しましたが、確認状態を端末に保存できません。元の記録を残して再送を停止しています。';
          return;
        }
        if (result == _CorruptJournalRecoveryResult.clearFailed) {
          syncStatus.value = TrainingSyncStatus.outcomeUnknown;
          syncStatusMessage.value =
              '破損記録の原文と確認状態を保全しましたが、元の記録を退避できません。再送は停止しています。';
          return;
        }
        if (result == _CorruptJournalRecoveryResult.sessionChanged) return;
        if (result == _CorruptJournalRecoveryResult.completed ||
            result == _CorruptJournalRecoveryResult.journalChanged) {
          _hasCorruptPendingActionQueue = false;
          _corruptPendingActionRaw = null;
          _corruptPendingActionsNeedServerRefresh = true;
        }
      }
    }

    _hasUnknownSyncOutcome = true;
    _syncBlockedUntilServerRestore = true;
    isServerStateReady.value = false;
    syncStatus.value = TrainingSyncStatus.outcomeUnknown;
    syncStatusMessage.value =
        '破損した操作記録を退避しました。以前の操作の適用有無は未確定です。再送せず、サーバー状態を確認します。';
    await _restoreServerState();
    if (!_ownsSession(_ownedSessionVersion)) return;
    if (!isServerStateReady.value) {
      _corruptPendingActionsNeedServerRefresh = true;
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value =
          '破損した操作記録は保全済みですが、サーバー状態を確認できません。通信復旧後に再確認してください。';
      return;
    }

    _corruptPendingActionsNeedServerRefresh = false;
    _hasUnknownSyncOutcome = true;
    // 既存UIの確認ボタンで、未確定結果を理解したうえで続行する意思を確認します。
    syncStatus.value = TrainingSyncStatus.rejected;
    syncStatusMessage.value =
        '破損した操作記録の原文を保全し、サーバー状態を再取得しました。以前の操作の適用有無は未確定で、自動再送していません。状態を確認して続けてください。';
  }

  Future<void> discardPendingSync() async {
    if (!canDiscardPendingSync) return;
    final discardedUnknownOutcome = _hasUnknownSyncOutcome;
    final discardedActions = List<_PendingTrainingAction>.of(_queuedActions);
    _cancelRetryWait();
    _queuedActions.clear();
    _syncRequested = false;
    _syncRetryNotBefore = null;
    _syncRequestMayHaveBeenApplied = false;
    _actionGate.clear();
    _hasUnsyncedLocalState = false;
    try {
      await _persistPendingActions();
    } catch (_) {
      _queuedActions.insertAll(0, discardedActions);
      _hasUnsyncedLocalState = true;
      syncStatus.value = TrainingSyncStatus.stopped;
      syncStatusMessage.value = '保留操作を端末から削除できなかったため、再送待ちのまま保持しています。';
      return;
    }
    await MySharedPref.clearTrainingGameLocalState();
    if (!_ownsSession(_ownedSessionVersion)) return;
    try {
      final current = await _serverProvider.fetchCurrent(
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (!_ownsSession(_ownedSessionVersion)) return;
      if (current != null) {
        _initializeServerState(current, restoreLocalStateOverride: false);
      }
      syncStatus.value = discardedUnknownOutcome
          ? TrainingSyncStatus.outcomeUnknown
          : TrainingSyncStatus.rejected;
      syncStatusMessage.value = discardedUnknownOutcome
          ? '再送待ちを破棄し、サーバー状態を再取得しました。前回操作は反映済みの可能性があり、未送信とは断定できません。'
          : '未送信の保留操作を破棄し、確認できたサーバー状態へ戻しました。';
    } catch (_) {
      _syncBlockedUntilServerRestore = true;
      isServerStateReady.value = false;
      serverErrorMessage.value =
          '保留操作は破棄しましたが、サーバー状態を確認できません。通信復旧後に状態を再取得してください。';
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value = discardedUnknownOutcome
          ? '再送待ちを破棄しましたが、前回操作の成否は不明でサーバー状態も確認できません。通信復旧後に再取得してください。'
          : serverErrorMessage.value;
      serverErrorMessage.value = syncStatusMessage.value;
    }
  }

  Future<void> acknowledgeSyncNotice() async {
    if (_isAcknowledgingSyncNotice ||
        _isDisposed ||
        !_ownsSession(_ownedSessionVersion)) {
      return;
    }
    if (syncStatus.value == TrainingSyncStatus.rejected ||
        syncStatus.value == TrainingSyncStatus.outcomeUnknown) {
      // 不明な操作のキーを捨てると、前回の処理有無を後から照合できません。
      // サーバー状態を確認し、同じ操作IDで結果を再確認するまで解除しません。
      if (syncStatus.value == TrainingSyncStatus.outcomeUnknown) return;
      if (!isServerStateReady.value) return;
      _isAcknowledgingSyncNotice = true;
      try {
        final acknowledgeJournalRecovery = _pendingJournalRecoveryAwaitingAck;
        if (acknowledgeJournalRecovery) {
          final cleared =
              await MySharedPref.clearTrainingGamePendingActionsRecovery();
          if (!_ownsSession(_ownedSessionVersion)) return;
          if (!cleared) {
            syncStatusMessage.value =
                '確認状態を端末から削除できません。操作を停止したまま、もう一度確認してください。';
            return;
          }
          _pendingJournalRecoveryAwaitingAck = false;
          _hasUnknownSyncOutcome = true;
          _syncBlockedUntilServerRestore = true;
          syncStatus.value = TrainingSyncStatus.outcomeUnknown;
          syncStatusMessage.value =
              '保全したjournalを再確認しています。保留操作の読み込みが終わるまで次の操作を停止しています。';
          await _restoreServerState();
          if (!_ownsSession(_ownedSessionVersion)) return;
          if (!isServerStateReady.value) {
            _corruptPendingActionsNeedServerRefresh = true;
            _hasUnknownSyncOutcome = true;
            syncStatus.value = TrainingSyncStatus.outcomeUnknown;
            syncStatusMessage.value = '保留操作の再取得に失敗しました。通信復旧後にもう一度状態を確認してください。';
            return;
          }
          if (_hasCorruptPendingActionQueue ||
              _corruptPendingActionsNeedServerRefresh ||
              _hasForeignPendingAction) {
            return;
          }
          if (_queuedActions.isNotEmpty || _activeSyncAction != null) {
            return;
          }
          _hasUnknownSyncOutcome = false;
          _syncBlockedUntilServerRestore = false;
          syncStatus.value = TrainingSyncStatus.idle;
          syncStatusMessage.value = '';
          _releasePendingGameQueueClaim();
          return;
        }
        _hasUnknownSyncOutcome = false;
        syncStatus.value = TrainingSyncStatus.idle;
        syncStatusMessage.value = '';
        if (_queuedActions.isEmpty &&
            _activeSyncAction == null &&
            !_syncRequested &&
            !_syncRunning) {
          _releasePendingGameQueueClaim();
        }
      } finally {
        _isAcknowledgingSyncNotice = false;
      }
    }
  }

  /// 仕事画面を開く直前に、サーバー時刻による実施可否を取得します。
  Future<bool> prepareWork() async {
    if (debugPositionBusy.value || _isWorkPreparationPending) {
      return false;
    }
    _isWorkPreparationPending = true;
    var prepared = false;
    workAvailabilityError.value = '';
    try {
      final debugTimeSync = _debugTimeSync;
      if (debugTimeSync != null) {
        await debugTimeSync;
      } else if (_debugTimeSavePending) {
        await _queueDebugTimeSync();
      }
      if (!_ownsSession(_ownedSessionVersion)) {
        workAvailabilityError.value = 'ログイン状態を確認して、育成画面を開き直してください。';
        return false;
      }
      if (_debugTimeSavePending) {
        workAvailabilityError.value = _debugTimeSyncError;
        return false;
      }
      if (_isWorkSyncPending) {
        workAvailabilityError.value = '前回の仕事が同期待ちです。画面上部の同期状態を確認してください。';
        return false;
      }
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (data == null || !_ownsSession(_ownedSessionVersion)) return false;
      // 可否と同じ応答に含まれるlock_version・パラメータも更新し、
      // 他端末操作後に古い状態で仕事を送信しないようにします。
      if (!_initializeServerState(data)) {
        workAvailabilityError.value = '育成段階を確認中です。状態を確認してからもう一度お試しください。';
        return false;
      }
      prepared = canWorkToday;
      if (!prepared && _pendingStageIndex != null) {
        workAvailabilityError.value = '育成段階の更新が完了するまでお待ちください。';
      }
      return prepared;
    } catch (_) {
      if (_ownsSession(_ownedSessionVersion)) {
        workAvailabilityError.value = '仕事の実施可否を確認できませんでした。通信状態を確認してください。';
        logs.insert(0, '仕事の実施可否を確認できませんでした。通信状態を確認してください。');
      }
      return false;
    } finally {
      if (!prepared) _isWorkPreparationPending = false;
    }
  }

  bool _isMiniGamePreparationPending = false;
  bool _isMiniGameOpen = false;
  int? _miniGamePlayerId;
  int? _miniGameCycleNo;
  DateTime? _miniGameStartedAt;

  /// Each play fetches fresh settings. Network failure must not launch with
  /// stale cached admin values; an old server response uses the fixed defaults.
  Future<MiniGameSettings?> prepareMiniGame(TrainingActionType type) async {
    if (_isMiniGamePreparationPending ||
        _isMiniGameOpen ||
        (type != TrainingActionType.tackle &&
            type != TrainingActionType.passAndRun)) {
      return null;
    }
    _isMiniGamePreparationPending = true;
    cooldownTick.value++;
    try {
      if (!_ownsSession(_ownedSessionVersion) ||
          !isServerStateReady.value ||
          pendingSyncActionCount > 0 ||
          _syncRunning ||
          _syncRequested ||
          _debugTimeSavePending ||
          _pendingStageIndex != null ||
          _hasUnknownSyncOutcome ||
          syncStatus.value != TrainingSyncStatus.idle ||
          !_canPerformAction(type)) {
        logs.insert(0, '育成状態の同期が完了してからミニゲームを開始してください。');
        return null;
      }
      final playerId = _serverPlayerId;
      final cycleNo = _serverCycleNo;
      final startedAt = _serverGameStartedAt;
      final data = await _serverProvider.fetchCurrent(
          expectedSessionVersion: _ownedSessionVersion);
      if (!_ownsSession(_ownedSessionVersion)) return null;
      if (data == null) {
        logs.insert(0, '育成状態を確認できませんでした。育成画面を開き直してください。');
        return null;
      }
      if (!_initializeServerState(data) ||
          _serverPlayerId != playerId ||
          _serverCycleNo != cycleNo ||
          !_sameGameInstance(_serverGameStartedAt, startedAt) ||
          stageIndex.value < 2 ||
          ended.value ||
          !_canPerformAction(type)) {
        logs.insert(0, '育成状態が変わりました。状態を確認してから開始してください。');
        return null;
      }
      _miniGamePlayerId = playerId;
      _miniGameCycleNo = cycleNo;
      _miniGameStartedAt = startedAt;
      _isMiniGameOpen = true;
      return MiniGameSettings.fromJson(data['mini_game_settings']);
    } catch (_) {
      if (_ownsSession(_ownedSessionVersion)) {
        logs.insert(0, 'ミニゲームの設定を取得できませんでした。通信状態を確認して再試行してください。');
      }
      return null;
    } finally {
      _isMiniGamePreparationPending = false;
      cooldownTick.value++;
    }
  }

  void finishMiniGamePreparation() {
    _isMiniGameOpen = false;
    _miniGamePlayerId = null;
    _miniGameCycleNo = null;
    _miniGameStartedAt = null;
  }

  /// 仕事の専用画面を閉じた後、次の仕事開始を可能にします。
  void finishWorkPreparation() => _isWorkPreparationPending = false;

  /// 指定行動のクールタイムが終了しているかを返します。
  bool canPerform(TrainingActionType type) {
    cooldownTick.value;
    return !_isMiniGamePreparationPending && _canPerformAction(type);
  }

  /// 筋トレ前に不足している状態があれば、表示用の案内を返します。
  String? get squatRequirementMessage =>
      TrainingWorkoutRequirement.messageFor(meters);

  bool _canPerformAction(TrainingActionType type) {
    cooldownTick.value;
    if (debugPositionBusy.value ||
        _pendingStageIndex != null ||
        (_debugTimeSavePending && type != TrainingActionType.work))
      return false;
    return _actionGate.canPerform(
      type,
      clientCooldownEnabled: isCooldownEnabled(type),
      bypassServerCooldown: _bypassesServerCooldown(type),
    );
  }

  /// 指定行動のクールタイム設定を返します。
  bool isCooldownEnabled(TrainingActionType type) =>
      cooldownEnabled[type] ?? false;

  /// デバッグメニューから指定行動のクールタイムを切り替えます。
  /// OFFの場合は開発環境のAPIにも解除を通知します。
  void setCooldownEnabled(TrainingActionType type, bool enabled) {
    cooldownEnabled[type] = enabled;
    _actionGate.setClientCooldownEnabled(type, enabled);
    cooldownTick.value++;
  }

  /// 指定行動の残りクールタイムを返します。
  Duration cooldownRemaining(TrainingActionType type) {
    cooldownTick.value;
    return _actionGate.remaining(
      type,
      clientCooldownEnabled: isCooldownEnabled(type),
      bypassServerCooldown: _bypassesServerCooldown(type),
    );
  }

  /// 画面に表示するクールタイムを返します。
  String cooldownLabel(TrainingActionType type) {
    final seconds = cooldownRemaining(type).inSeconds;
    return seconds <= 0 ? '' : '${seconds + 1}秒待ち';
  }

  /// 参照HTMLと同じ形式で現在時刻を表示します。
  String get clockLabel {
    _mainClockTick.value;
    final elapsedSeconds = stageIndex.value < 2
        ? totalElapsedSeconds.value
        : mainElapsedSeconds.value;
    final elapsedDays = elapsedSeconds ~/ Duration.secondsPerDay;
    final daySeconds = elapsedSeconds % Duration.secondsPerDay;
    final hours =
        (daySeconds ~/ Duration.secondsPerHour).toString().padLeft(2, '0');
    final minutes = ((daySeconds % Duration.secondsPerHour) ~/ 60)
        .toString()
        .padLeft(2, '0');
    final seconds = (daySeconds % 60).toString().padLeft(2, '0');
    return '経過 ${elapsedDays}日 $hours:$minutes:$seconds';
  }

  /// 現在の育成キャラクター表示名を返します。
  String get characterLabel {
    // 引退後も終了状態ではなく、最後に到達した育成段階の見た目を維持します。
    if (stageIndex.value == 0) return '🥚';
    if (stageIndex.value == 1) return '🐣';
    if (stageIndex.value == 2) return '🦈';
    return '🦈';
  }

  /// 成長期以降に表示する大別コードを返します。
  String? get branch {
    if (stageIndex.value < 3) return null;
    final serverBranch = _serverBranchCode.value;
    if (serverBranch != null) {
      return const {
        'FW': 'A フォワード型',
        'COMMAND': 'B 司令塔型',
        'BACKS': 'C バックス型',
      }[serverBranch];
    }
    // 分岐計算式は未確定のため、サーバーが確定した結果だけを表示します。
    return null;
  }

  /// 大別に応じたキャラクター表示サイズを返します。
  double get characterFontSize {
    if (clearPosition.value != null) return 104;
    if (ended.value) return 64;
    return switch (branch) {
      'A フォワード型' => 96,
      'B 司令塔型' => 80,
      'C バックス型' => 86,
      _ => 76,
    };
  }

  /// 最も高い傾向から暫定ポジションを判定します。
  String get position {
    if (stageIndex.value < 3) return '判定前';
    final serverPosition = _positionNameFromCode(_serverPositionCode.value);
    // 最終10ポジションへの収束条件は未確定のため、サーバー判定前に推測しません。
    return serverPosition ?? '判定前';
  }

  /// 初期表示用のログを準備します。
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    logs.add('段階1「卵」からスタート。お世話をして時間を進めましょう。');
    final initialState = Get.arguments;
    if (initialState is Map) {
      final isNewCycle = initialState['_new_cycle'] == true;
      final state = Map<String, dynamic>.from(initialState)
        ..remove('_new_cycle');
      if (isNewCycle) {
        // ルート生成中にRx値を更新すると、build中の再描画通知になります。
        // 新しいControllerの初期値はすでに初期状態なので、初回フレーム後に
        // サーバー状態だけを反映します。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isDisposed) return;
          unawaited(_restoreInitialServerState(state, forceNewCycle: true));
        });
      } else {
        // 遷移元で取得済みの状態を利用し、初期表示時の重複通信を避けます。
        unawaited(_restoreInitialServerState(state));
      }
    } else {
      unawaited(_restoreServerState());
    }
    _tutorialTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tickTutorialTimer();
    });
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      cooldownTick.value++;
      if (isServerStateReady.value &&
          !_isAppInBackground &&
          evolutionStage.value == null &&
          !ended.value) {
        _advanceActiveMainProgress();
        _updateElapsedTimeFromStart();
        _mainClockTick.value++;
      }
    });
  }

  /// 起動元が取得した状態でも、操作を許可する前に永続キューを復元します。
  Future<void> _restoreInitialServerState(
    Map<String, dynamic> state, {
    bool forceNewCycle = false,
  }) async {
    try {
      await _pendingActionPersistence;
      if (!_ownsSession(_ownedSessionVersion)) return;
      final hasPendingActions = _hasPersistedPendingActionsFor(state);
      if (!_initializeServerState(
        state,
        forceNewCycle: forceNewCycle,
        restoreLocalStateOverride: hasPendingActions ? false : null,
      )) {
        return;
      }
      isServerStateReady.value = false;
      if (forceNewCycle) {
        // 新サイクル開始レスポンスに旧クールタイムが混在していても引き継がない。
        _actionGate.clear();
        cooldownTick.value++;
      }
      await _restorePersistedPendingActions();
      if (_ownsSession(_ownedSessionVersion)) {
        isServerStateReady.value = true;
      }
    } catch (_) {
      if (_ownsSession(_ownedSessionVersion)) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '育成状態の復元に失敗しました。もう一度お試しください。';
      }
    }
  }

  /// チュートリアルタイマー1回分の進行を処理します。
  void tickTutorialTimer() {
    cooldownTick.value++;
    if (isTutorialTimeActive) {
      _advanceTutorialClock(timeSpeed.value);
      tickTutorial(timeSpeed.value);
    }
  }

  /// Controller破棄時にチュートリアルのリアルタイム進行を停止します。
  @override
  void onClose() {
    // 破棄後は待機中の再送を止め、新しい同期要求を作らないよう先に無効化します。
    _isDisposed = true;
    _squatStageSubscription.cancel();
    AuthToken.removeSessionChangeListener(_handleAuthSessionChanged);
    _cancelRetryWait();
    WidgetsBinding.instance.removeObserver(this);
    _tutorialTimer?.cancel();
    _mainTimer?.cancel();
    final pendingJournalSnapshot = <_PendingTrainingAction>[
      if (_activeSyncAction != null) _activeSyncAction!,
      ..._queuedActions,
    ];
    final hasUnsentState = _queuedActions.isNotEmpty ||
        _syncRequested ||
        _syncActionInFlight ||
        _hasUnsyncedLocalState;
    if (pendingJournalSnapshot.isNotEmpty) {
      unawaited(_persistPendingActions(
        snapshotActions: pendingJournalSnapshot,
        releaseGameClaimAfterWrite: true,
      ).catchError((Object _) {
        // 送信前に保存済みの操作だけが次のControllerで復元対象になります。
        _releaseAllPendingActionClaims();
        _releasePendingGameQueueClaim();
      }));
    } else {
      _releaseAllPendingActionClaims();
      _releasePendingGameQueueClaim();
    }
    _queuedActions.clear();
    _syncRequested = false;
    _syncActionInFlight = false;
    _syncBlockedUntilServerRestore = true;
    _hasUnsyncedLocalState = false;
    _actionGate.clear();
    if (hasUnsentState) unawaited(MySharedPref.clearTrainingGameLocalState());
    super.onClose();
  }

  /// デバッグ用に、サーバー・端末の育成データを初期パラメータ付きで初期化します。
  Future<Map<String, dynamic>?> resetDebugGame() {
    if (debugPositionBusy.value || !_ownsSession(_ownedSessionVersion)) {
      return Future<Map<String, dynamic>?>.value();
    }
    // 先行する同期を完了させてから削除し、古い状態の再保存を防ぎます。
    return TrainingGameProvider.waitForPendingSync()
        .then((_) => _serverProvider.resetDebugState(
              expectedSessionVersion: _ownedSessionVersion,
            ))
        .then<Map<String, dynamic>?>((initialState) async {
      if (!_ownsSession(_ownedSessionVersion)) return null;
      await MySharedPref.clearTrainingGameStartedAt();
      if (!_ownsSession(_ownedSessionVersion)) return null;
      await MySharedPref.clearTrainingGameDebugElapsedSeconds();
      if (!_ownsSession(_ownedSessionVersion)) return null;
      await MySharedPref.clearTrainingGameLocalState();
      if (!_ownsSession(_ownedSessionVersion)) return null;
      final oldActions = <_PendingTrainingAction>[
        if (_activeSyncAction != null) _activeSyncAction!,
        ..._queuedActions,
      ];
      _queuedActions.clear();
      _activeSyncAction = null;
      _syncRequested = false;
      _syncRequestMayHaveBeenApplied = false;
      _syncActionInFlight = false;
      _hasUnknownSyncOutcome = false;
      _releaseAllPendingActionClaims();
      // 画面遷移を挟まず、APIが返した初期状態を現在のControllerへ反映します。
      _resetLocalProgressForNewCycle();
      _initializeServerState(initialState);
      try {
        await _persistPendingActions(quarantineActions: oldActions);
      } catch (_) {
        // Old timestamps remain in the journal; restoration will still quarantine them.
      }
      if (_queuedActions.isEmpty) {
        syncStatus.value = TrainingSyncStatus.idle;
        syncStatusMessage.value =
            oldActions.isEmpty ? '' : '初期化前の保留操作を隔離しました。新しい状態には再送しません。';
      }
      return initialState;
    }, onError: (_, __) {
      // 初期化失敗時は現在のゲームを維持し、誤って画面遷移しないようにします。
      return null;
    });
  }

  /// 初期化前サイクルのローカル進行状態を破棄します。
  void _resetLocalProgressForNewCycle() {
    // Controllerが再利用された場合や、開始レスポンスに一部パラメータが
    // 含まれない場合でも、前サイクルの表示値を新サイクルへ持ち越しません。
    _resetMetersIfNeeded();
    _resetTrendsIfNeeded();
    stageIndex.value = 0;
    elapsedHours.value = 0;
    totalElapsedSeconds.value = 0;
    mainElapsedSeconds.value = 0;
    day.value = 1;
    secondsInStage.value = 0;
    daysInStage.value = 0;
    actionsToday.value = 0;
    trainingCount.value = 0;
    _isWorkAvailable = false;
    _isWorkSyncPending = false;
    _isWorkPreparationPending = false;
    _debugTimeSavePending = false;
    _debugDailyResetPending = false;
    _debugTimeSyncError = '';
    _lowConditionTraining = 0;
    _dayCared = false;
    _zeroHours.updateAll((key, value) => 0);
    _tutorialZeroSeconds.updateAll((key, value) => 0);
    _actionGate.clear();
    _releasePendingGameQueueClaim();
    _hasForeignPendingAction = false;
    _pendingStageIndex = null;
    _pendingStageSyncQueued = false;
    ended.value = false;
    endingStep.value = 0;
    endingMessage.value = '';
    isEndingSyncPending.value = false;
    endingSyncError.value = '';
    clearPosition.value = null;
    _serverBranchCode.value = null;
    _serverPositionCode.value = null;
    _serverRequiredWorkValue = null;
    _serverRequiredElapsedHours = null;
    _serverNextStageCode = null;
    _playFloor = 0;
    evolutionStage.value = null;
    _elapsedTimeOffsetSeconds = 0;
    _activeMainProgressBaseSeconds = null;
    _processedActiveMainHours = 0;
    _waitingForServerRestore = false;
    _restoreLocalCountersOnNextServerState = true;
    _queuedActions.clear();
    _syncRequested = false;
    _hasUnsyncedLocalState = false;
    _syncBlockedUntilServerRestore = false;
    isServerStateReady.value = false;
    serverErrorMessage.value = '';
  }

  /// 初期値と異なる場合だけ、可変Mapへ差し替えます。
  ///
  /// `RxMap.assignAll` は受け取ったMapを内部値として保持するため、const Mapを
  /// 直接渡すと、次回のMap更新時にunmodifiableエラーになります。
  void _resetMetersIfNeeded() {
    if (meters.length == initialMeters.length &&
        initialMeters.entries
            .every((entry) => meters[entry.key] == entry.value)) {
      return;
    }
    meters.value = Map<String, double>.from(initialMeters);
  }

  /// 初期値と異なる場合だけ、可変Mapへ差し替えます。
  void _resetTrendsIfNeeded() {
    if (trends.length == initialTrends.length &&
        initialTrends.entries
            .every((entry) => trends[entry.key] == entry.value)) {
      return;
    }
    trends.value = Map<String, double>.from(initialTrends);
  }

  /// 育成完了後の演出フローを次へ進めます。
  void advanceEndingStep() {
    if (ended.value) endingStep.value++;
  }

  /// 段階上昇時の進化演出を完了し、育成画面へ戻します。
  void advanceEvolution() {
    if (evolutionStage.value == null) return;
    final completedFirstTeamReveal = stageIndex.value == stages.length - 1 &&
        evolutionStage.value == stages.length - 1;
    evolutionStage.value = null;
    // 進化演出中にOS割り込みが発生しても、次へ進んだ時点で
    // チュートリアルのリアルタイム進行を必ず再開します。
    _isAppInBackground = false;
    _waitingForServerRestore = false;
    _resetActiveMainProgressBaseline();
    _updateElapsedTimeFromStart();
    _mainClockTick.value++;
    // サーバーで一軍への遷移が確定した後は、ポジション結果を確認して
    // 最終段階の完了同期へ進みます。
    if (stageIndex.value == stages.length - 1) {
      _advanceMainStageIfNeeded();
      // 最終段階では、この進化演出が完了フローの一軍紹介も兼ねます。
      // 確認済みポジション画面へ直接進み、同じ拡大演出を再生しません。
      if (completedFirstTeamReveal &&
          ended.value &&
          clearPosition.value != null) {
        endingStep.value = 1;
      }
    }
  }

  /// 現在の状態でチュートリアル時間を進められるかを返します。
  bool get isTutorialTimeActive =>
      !debugPositionBusy.value &&
      isServerStateReady.value &&
      !_isAppInBackground &&
      evolutionStage.value == null &&
      _pendingStageIndex == null &&
      !_waitingForServerRestore &&
      stageIndex.value < 2 &&
      !ended.value;

  /// 育成画面を離れる前にローカルのリアルタイム進行を停止します。
  void pauseLocalProgress() {
    _isAppInBackground = true;
    _waitingForServerRestore = true;
    _activeMainProgressBaseSeconds = null;
    _restoreLocalCountersOnNextServerState = true;
  }

  /// ホームへ戻る前に状態を同期し、1.5〜3秒のロード表示を維持します。
  Future<bool> syncBeforeReturningHome() async {
    if (isReturningHome.value) return false;
    isReturningHome.value = true;
    pauseLocalProgress();
    var complete = false;
    try {
      await Future.wait<void>([
        _queueSync(),
        Future<void>.delayed(randomTransitionLoadingDuration()),
      ]);
      if (!_ownsSession(_ownedSessionVersion)) return false;
      complete = !_debugTimeSavePending &&
          _queuedActions.isEmpty &&
          !_syncRequested &&
          !_syncRunning &&
          syncStatus.value == TrainingSyncStatus.idle;
      return complete;
    } finally {
      if (!complete && _ownsSession(_ownedSessionVersion)) {
        isReturningHome.value = false;
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        _isAppInBackground =
            lifecycle != null && lifecycle != AppLifecycleState.resumed;
        if (!_isAppInBackground && isServerStateReady.value) {
          _waitingForServerRestore = false;
          _resetActiveMainProgressBaseline();
        }
      }
    }
  }

  /// アプリがバックグラウンドへ移る前に育成状態を保存します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isAppInBackground = true;
      _waitingForServerRestore = true;
      _activeMainProgressBaseSeconds = null;
      _restoreLocalCountersOnNextServerState = true;
      _queueSync();
    }
    if (state == AppLifecycleState.resumed && !ended.value) {
      _isAppInBackground = false;
      if (evolutionStage.value != null) {
        // 演出中は時間を進めませんが、OS割り込み中のサーバー状態は復元します。
        unawaited(_restoreServerState());
        return;
      }
      // 復帰直後は、直前に同期したサーバー時刻から表示だけを先に再開します。
      _updateElapsedTimeFromStart();
      _mainClockTick.value++;
      // オフライン中の精算はサーバー状態の再取得へ一元化し、端末側の二重減衰を防ぎます。
      unawaited(_restoreServerState());
    }
  }

  /// サーバーに保存された育成状態を復元します。
  ///
  /// 終了済みプレイヤーが取得できないことを理由に新しい育成サイクルを開始しません。
  /// 新規開始は卵獲得画面で明示的に行います。
  Future<void> _restoreServerState() async {
    if (debugPositionBusy.value) return;
    if (!_ownsSession(_ownedSessionVersion)) return;
    serverErrorMessage.value = '';
    // 復帰イベントが短時間に複数回発生しても、取得処理を直列化します。
    _restoreChain = _restoreChain.then((_) async {
      if (!_ownsSession(_ownedSessionVersion)) return;
      // 時間保存と通常同期を完了してから、サーバー状態を読み込みます。
      await _debugTimeSync;
      if (_debugTimeSavePending) return;
      await _syncChain;
      if (!_ownsSession(_ownedSessionVersion)) return;
      // Controller破棄時に予約されたjournal書き込みも反映してから復元します。
      await _pendingActionPersistence;
      if (!_ownsSession(_ownedSessionVersion)) return;
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (!_ownsSession(_ownedSessionVersion)) return;
      if (data != null) {
        final hasPendingActions = _hasPersistedPendingActionsFor(data);
        if (!_initializeServerState(
          data,
          restoreLocalStateOverride: hasPendingActions ? false : null,
        )) {
          return;
        }
        await _restorePersistedPendingActions();
      } else if (!ended.value) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '育成データが見つかりません。ゲーム開始画面からやり直してください。';
        return;
      }
      isServerStateReady.value = true;
    }).catchError((_) {
      // 仕様どおり、通信不可時はローカル状態だけでプレイを継続しません。
      if (_ownsSession(_ownedSessionVersion)) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
      }
    });
    await _restoreChain;
  }

  /// 通信エラー画面からサーバー状態の取得を再試行します。
  Future<void> retryRestoreServerState() async {
    if (!_ownsSession(_ownedSessionVersion)) return;
    await _debugTimeSync;
    if (_debugTimeSavePending) {
      // 明示的な再取得では保留時間操作を再送せず、サーバー正本を採用します。
      // 表示時計と日数の端末加算は残し、日次履歴の解除は行いません。
      _debugTimeSavePending = false;
      _debugDailyResetPending = false;
      _debugTimeSyncError = '';
      _pendingStageIndex = null;
      _pendingStageSyncQueued = false;
      syncStatusMessage.value = '';
      cooldownTick.value++;
    }
    await _restoreServerState();
    await _saveLocalGameState();
  }

  bool get canResolveDebugTimeSave {
    cooldownTick.value;
    return _debugTimeSavePending && _debugTimeSyncError.isNotEmpty;
  }

  /// 初期状態をサーバーへ保存します。
  Future<void> _startServerState({
    required int expectedSessionVersion,
  }) async {
    final data = await _serverProvider.start(
      stageCode: _stageCode,
      parameters: _serverParameters,
      expectedSessionVersion: expectedSessionVersion,
    );
    if (!_ownsSession(expectedSessionVersion)) return;
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverCycleNo = (data['cycle_no'] as num?)?.toInt();
    _serverGameStartedAt = _gameStartedAtFrom(data['started_at']);
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    _applyServerState(data);
    _refreshUnlockedPositionsInBackground();
  }

  /// 取得済みのサーバー状態を初期表示へ反映します。
  bool _initializeServerState(
    Map<String, dynamic> data, {
    bool forceNewCycle = false,
    bool? restoreLocalStateOverride,
  }) {
    final serverCycleNo = (data['cycle_no'] as num?)?.toInt();
    final serverStartedAt = _gameStartedAtFrom(data['started_at']);
    final isNewCycle = forceNewCycle ||
        (serverCycleNo != null &&
            _serverCycleNo != null &&
            serverCycleNo != _serverCycleNo) ||
        (serverStartedAt != null &&
            _serverGameStartedAt != null &&
            !_sameGameInstance(serverStartedAt, _serverGameStartedAt));
    final hasStaleLocalCycle = _hasStaleLocalCycle(serverCycleNo);
    if (isNewCycle || hasStaleLocalCycle) {
      _resetLocalProgressForNewCycle();
      unawaited(MySharedPref.clearTrainingGameDebugElapsedSeconds());
      unawaited(MySharedPref.clearTrainingGameLocalState());
    }
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverCycleNo = serverCycleNo ?? _serverCycleNo;
    _serverGameStartedAt = serverStartedAt ?? _serverGameStartedAt;
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    if (!_applyServerState(
      data,
      restoreLocalState:
          restoreLocalStateOverride ?? (!isNewCycle && !hasStaleLocalCycle),
      restoreDebugElapsed: !isNewCycle && !hasStaleLocalCycle,
    )) {
      return false;
    }
    _syncBlockedUntilServerRestore = false;
    isServerStateReady.value = true;
    _refreshUnlockedPositionsInBackground();
    return true;
  }

  /// 現在のサーバーサイクルと異なるローカル状態だけを破棄対象にします。
  bool _hasStaleLocalCycle(int? serverCycleNo) {
    final encodedState = MySharedPref.getTrainingGameLocalState();
    if (encodedState == null || serverCycleNo == null) return false;
    try {
      final decodedState = jsonDecode(encodedState);
      if (decodedState is! Map) return true;
      return (decodedState['cycle_no'] as num?)?.toInt() != serverCycleNo;
    } catch (_) {
      return true;
    }
  }

  /// APIレスポンスの状態を画面状態へ反映します。
  bool _applyServerState(
    Map<String, dynamic> data, {
    bool restoreLocalState = true,
    bool restoreDebugElapsed = true,
  }) {
    final previousStageIndex = stageIndex.value;
    final wasUndecidedFirstTeam = previousStageIndex == stages.length - 1 &&
        _serverPositionCode.value == null &&
        !ended.value &&
        !isEndingSyncPending.value;
    final stage = data['stage_code'] as String?;
    final serverStageIndex = _stageIndexFromCode(stage);
    // 同一育成サイクルの段階は後退しない。定期取得や復帰処理で古いレスポンスが
    // 到着しても、育成期以降の表示をチュートリアルへ戻さないようにします。
    if (serverStageIndex != null && serverStageIndex < previousStageIndex) {
      return false;
    }
    if (_pendingStageIndex != null &&
        serverStageIndex != null &&
        serverStageIndex < _pendingStageIndex!) {
      return false;
    }
    _restoreServerClock(data, restoreDebugElapsed: restoreDebugElapsed);
    _restoreWorkAvailability(data);
    _restoreStageProgress(data);
    if (serverStageIndex != null) {
      final previousStage = stageIndex.value;
      stageIndex.value = serverStageIndex;
      if (_pendingStageIndex == serverStageIndex) {
        _pendingStageIndex = null;
        _pendingStageSyncQueued = false;
        if (serverStageIndex > previousStage) _showEvolutionForCurrentStage();
      }
    }
    _serverBranchCode.value = data['branch_code'] as String?;
    _serverPositionCode.value = data['position_code'] as String?;
    if (_waitingForServerRestore ||
        _activeMainProgressBaseSeconds == null ||
        previousStageIndex != stageIndex.value) {
      _resetActiveMainProgressBaseline();
      _waitingForServerRestore = false;
    }
    final parameters = data['parameters'];
    if (parameters is Map) {
      const displayMap = {
        'hunger': '食事',
        'cleanliness': '清潔',
        'condition': '体調',
        'work': '仕事'
      };
      const tendencyMap = {
        'tendency_fw': 'FW',
        'tendency_command': 'CMD',
        'tendency_backs': 'RUN',
        'tendency_bulk': 'BULK',
        'tendency_tech': 'TECH',
      };
      for (final entry in parameters.entries) {
        final value = (entry.value as num?)?.toDouble();
        if (value == null) continue;
        final displayName = displayMap[entry.key];
        final tendencyName = tendencyMap[entry.key];
        // サーバー値も画面・次回同期で仕様範囲を超えないよう正規化します。
        if (displayName != null) {
          meters[displayName] = value.clamp(0, 150).toDouble();
        }
        if (tendencyName != null) {
          trends[tendencyName] = value.clamp(0, 100).toDouble();
        }
      }
    }
    if (restoreLocalState) {
      final restoreLocalCounters = _restoreLocalCountersOnNextServerState;
      _restoreLocalGameState(
        data,
        restoreProgressCounters: restoreLocalCounters,
      );
    } else {
      // 時間保存は終了状態を送らないため、その応答だけでは終了要求を同期済みにしません。
      // 後続の終了同期が最新lock_versionでpositive/negative_endを保存します。
      _hasUnsyncedLocalState =
          _debugTimeSavePending && ended.value && isEndingSyncPending.value;
    }
    _restoreLocalCountersOnNextServerState = false;
    final serverActionsToday = (data['actions_today'] as num?)?.toInt();
    if (serverActionsToday != null) {
      actionsToday.value = serverActionsToday;
    }
    // ローカル保存値より、サーバーが現在時刻で判定した値を優先します。
    _restoreServerCooldowns(
      data['cooldowns'],
      preserveLocalCooldowns: restoreLocalState,
    );
    _restoreEndedState(data);
    // 一軍で未確定だった進化先が応答で決まった場合も、通常の進化演出へ進めます。
    // 「次へ」から既存の完了同期を使い、次のお世話や翌日を待たせません。
    if (wasUndecidedFirstTeam &&
        serverStageIndex == stages.length - 1 &&
        data['status'] == 'playing' &&
        position != '判定前' &&
        !ended.value &&
        !isEndingSyncPending.value &&
        evolutionStage.value == null) {
      _showEvolutionForCurrentStage();
    }
    return true;
  }

  /// サーバー時計と同一サイクルの経過時間だけを画面状態へ反映します。
  void _restoreServerClock(
    Map<String, dynamic> data, {
    required bool restoreDebugElapsed,
  }) {
    ServerTimeClock.instance.synchronizeFromPayload(data);
    final elapsedSeconds = (data['elapsed_seconds'] as num?)?.toInt();
    if (elapsedSeconds != null) {
      _serverElapsedSeconds = elapsedSeconds.clamp(0, 0x7fffffff).toInt();
      totalElapsedSeconds.value = _serverElapsedSeconds;
    }
    final startedAt = _parseServerDateTime(data['started_at']) ??
        MySharedPref.getTrainingGameStartedAt();
    if (startedAt == null) return;
    _elapsedTimeOffsetSeconds = restoreDebugElapsed
        ? MySharedPref.getTrainingGameDebugElapsedSeconds()
        : 0;
    unawaited(MySharedPref.setTrainingGameStartedAt(startedAt));
    _updateElapsedTimeFromStart();
  }

  /// サーバーに未保存の途中進行を、同じ育成サイクルに限って復元します。
  void _restoreLocalGameState(
    Map<String, dynamic> serverData, {
    required bool restoreProgressCounters,
  }) {
    final encodedState = MySharedPref.getTrainingGameLocalState();
    if (encodedState == null || _serverPlayerId == null) return;
    final decodedState = jsonDecode(encodedState);
    if (decodedState is! Map) return;
    final localState = Map<String, dynamic>.from(decodedState);
    if (localState['player_id'] != _serverPlayerId) return;
    final serverCycleNo = (serverData['cycle_no'] as num?)?.toInt();
    final localCycleNo = (localState['cycle_no'] as num?)?.toInt();
    // game_players.idは新しい育成サイクルでも再利用されるため、IDだけでは
    // 旧サイクルのスナップショットを識別できません。
    if (serverCycleNo == null || localCycleNo != serverCycleNo) {
      _hasUnsyncedLocalState = false;
      unawaited(MySharedPref.clearTrainingGameLocalState());
      unawaited(MySharedPref.clearTrainingGameDebugElapsedSeconds());
      return;
    }

    _hasUnsyncedLocalState = localState['has_unsynced_state'] == true;
    restoreProgressCounters = restoreProgressCounters || _hasUnsyncedLocalState;
    // 同期未完了のスナップショットだけは、通信失敗した行動結果を失わないよう復元します。
    final serverParameters = serverData['parameters'];
    final serverHasBulk = serverParameters is Map &&
        serverParameters.containsKey('tendency_bulk');
    final serverHasTech = serverParameters is Map &&
        serverParameters.containsKey('tendency_tech');
    if (_hasUnsyncedLocalState) {
      _restoreDoubleValue(localState, 'hunger', '食事', target: meters);
      _restoreDoubleValue(localState, 'cleanliness', '清潔', target: meters);
      _restoreDoubleValue(localState, 'condition', '体調', target: meters);
      _restoreDoubleValue(localState, 'work', '仕事', target: meters);
      _restoreDoubleValue(localState, 'fw', 'FW');
      _restoreDoubleValue(localState, 'command', 'CMD');
      _restoreDoubleValue(localState, 'run', 'RUN');
      _restoreDoubleValue(localState, 'bulk', 'BULK');
      _restoreDoubleValue(localState, 'tech', 'TECH');
    } else {
      // APIが未対応の補助傾向だけは、最後に保存したローカル値で補います。
      if (!serverHasBulk) _restoreDoubleValue(localState, 'bulk', 'BULK');
      if (!serverHasTech) _restoreDoubleValue(localState, 'tech', 'TECH');
    }

    // 経過時間・日次境界はサーバー応答を正とし、保存済みの端末カウンターで
    // サーバー状態を巻き戻さないようにします。
    // サーバーが返さない本編の日次カウンターは、同じ育成サイクルの
    // ローカル状態から復元します。経過秒そのものは上でサーバー値を反映済みです。
    if (restoreProgressCounters) {
      elapsedHours.value =
          _localInt(localState, 'elapsed_hours', elapsedHours.value);
      day.value = _localInt(localState, 'day', day.value);
      secondsInStage.value = _localInt(
        localState,
        'seconds_in_stage',
        secondsInStage.value,
      );
      daysInStage.value = _localInt(
        localState,
        'days_in_stage',
        daysInStage.value,
      );
      actionsToday.value =
          _localInt(localState, 'actions_today', actionsToday.value);
      trainingCount.value =
          _localInt(localState, 'training_count', trainingCount.value);
      _lowConditionTraining = _localInt(
        localState,
        'low_condition_training',
        _lowConditionTraining,
      );
      _dayCared = localState['day_cared'] == true;
      _restoreCooldowns(localState['cooldowns']);
      _restoreCounters(localState['zero_hours'], _zeroHours);
      _restoreCounters(
        localState['tutorial_zero_seconds'],
        _tutorialZeroSeconds,
      );
      ended.value = localState['ended'] == true;
      endingStep.value = _localInt(localState, 'ending_step', endingStep.value);
      endingMessage.value =
          localState['ending_message'] as String? ?? endingMessage.value;
      clearPosition.value = localState['clear_position'] as String?;
    }
  }

  /// APIレスポンスに含まれる、サーバー時刻基準の仕事可否を反映します。
  void _restoreWorkAvailability(Map<String, dynamic> data) {
    _isWorkAvailable = data['work_available'] == true;
  }

  /// 管理画面で設定された段階条件を、端末側の進行判定へ反映します。
  void _restoreStageProgress(Map<String, dynamic> data) {
    final progress = data['stage_progress'];
    if (progress is Map) {
      final requiredWork = progress['required_work_value'];
      _serverRequiredWorkValue =
          requiredWork is num ? requiredWork.toDouble() : null;
      final requiredElapsed = progress['required_elapsed_hours'];
      _serverRequiredElapsedHours =
          requiredElapsed is num ? requiredElapsed.toInt() : null;
      _serverNextStageCode = progress['next_stage_code'] as String?;
    } else {
      _serverRequiredWorkValue = null;
      _serverRequiredElapsedHours = null;
      _serverNextStageCode = null;
    }
    final playFloor = data['play_floor'];
    if (playFloor is num) {
      _playFloor = playFloor.toInt().clamp(0, 100).toInt();
    }
  }

  /// サーバーが返す終了状態をローカル表示へ反映します。
  void _restoreEndedState(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status == 'playing' && !_hasUnsyncedLocalState) {
      // 同期済みの端末スナップショットに残った終了状態を復元しません。
      ended.value = false;
      endingStep.value = 0;
      endingMessage.value = '';
      clearPosition.value = null;
      return;
    }
    if (status == 'positive_end') {
      ended.value = true;
      endingStep.value = 0;
      clearPosition.value =
          _positionNameFromCode(data['position_code']) ?? position;
      endingMessage.value = '育成完了。${clearPosition.value}として図鑑に登録されました。';
      return;
    }
    if (status == 'negative_end') {
      ended.value = true;
      endingStep.value = 2;
      clearPosition.value = null;
      final overState = data['over_state'];
      final overParameter = overState is Map && overState['schema'] == 1
          ? overState['ending_parameter']
          : null;
      final label = const {'hunger': '食事', 'work': '仕事'}[overParameter];
      endingMessage.value = label == null
          ? '育成は終了しました。卵からやりなおしてください。'
          : '$labelが過剰のまま72時間経過しました。';
    }
  }

  /// ローカルスナップショットの数値を指定したパラメータ集合へ反映します。
  void _restoreDoubleValue(
    Map<String, dynamic> state,
    String stateKey,
    String targetKey, {
    Map<String, double>? target,
  }) {
    final value = state[stateKey];
    if (value is num) (target ?? trends)[targetKey] = value.toDouble();
  }

  /// ローカルスナップショットからカウンターを復元します。
  void _restoreCounters(Object? rawCounters, Map<String, int> target) {
    if (rawCounters is! Map) return;
    for (final key in target.keys) {
      final value = rawCounters[key];
      if (value is num) target[key] = value.toInt();
    }
  }

  /// ローカルスナップショットから行動別クールタイムを復元します。
  void _restoreCooldowns(Object? rawCooldowns) {
    if (rawCooldowns is! Map) return;
    final cooldowns = <TrainingActionType, DateTime>{};
    for (final entry in rawCooldowns.entries) {
      final type = _actionTypeFromCode(entry.key.toString());
      final value = entry.value;
      if (type == null || value is! String) continue;
      final until = DateTime.tryParse(value);
      if (until != null && _serverNow().isBefore(until)) {
        cooldowns[type] = until;
      }
    }
    _actionGate.mergeServerCooldowns(cooldowns);
  }

  /// サーバーが現在時刻で判定したクールタイムを復元します。
  void _restoreServerCooldowns(
    Object? rawCooldowns, {
    required bool preserveLocalCooldowns,
  }) {
    final localCooldowns = _actionGate.snapshot(cooldownEnabled);
    final serverCooldowns = <TrainingActionType, DateTime>{};
    if (rawCooldowns is! Map) {
      if (!preserveLocalCooldowns) _actionGate.replaceServerCooldowns({});
      return;
    }
    for (final entry in rawCooldowns.entries) {
      final type = _actionTypeFromCode(entry.key.toString());
      final value = entry.value;
      if (type == null || value is! String) continue;
      final until = DateTime.tryParse(value);
      if (until != null && _serverNow().isBefore(until)) {
        serverCooldowns[type] = until;
      }
    }
    _actionGate.replaceServerCooldowns(
      serverCooldowns,
      preserveUntil: preserveLocalCooldowns ? localCooldowns : const {},
    );
    cooldownTick.value++;
  }

  /// ローカルスナップショットの整数値を安全に読み取ります。
  int _localInt(Map<String, dynamic> state, String key, int fallback) {
    final value = state[key];
    return value is num ? value.toInt() : fallback;
  }

  /// サーバーのポジションコードを画面表示用の名称へ変換します。
  String? _positionNameFromCode(Object? code) => const {
        'prop': 'プロップ',
        'hooker': 'フッカー',
        'lock': 'ロック',
        'flanker': 'フランカー',
        'number_eight': 'ナンバーエイト',
        'scrum_half': 'スクラムハーフ',
        'stand_off': 'スタンドオフ',
        'center': 'センター',
        'wing': 'ウイング',
        'fullback': 'フルバック',
      }[code];

  /// 専用APIから取得した解放済みポジションを画面状態へ反映します。
  Future<void> refreshUnlockedPositions() async {
    if (!_ownsSession(_ownedSessionVersion)) return;
    final positions = await _serverProvider.fetchUnlockedPositions(
      expectedSessionVersion: _ownedSessionVersion,
    );
    if (!_ownsSession(_ownedSessionVersion)) return;
    unlockedPositions.assignAll(positions.toSet());
  }

  /// 図鑑情報を初期表示を妨げずに更新します。
  void _refreshUnlockedPositionsInBackground() {
    unawaited(refreshUnlockedPositions().catchError((_) {
      // 図鑑取得に失敗しても育成状態の表示は継続します。
    }));
  }

  /// サーバーが受け付ける段階コードを返します。
  String get _stageCode => [
        'egg',
        'child',
        'training',
        'growth',
        'first_team',
      ][(_pendingStageIndex ?? stageIndex.value).clamp(0, 4).toInt()];

  /// サーバー段階コードを画面段階番号へ変換します。
  int? _stageIndexFromCode(Object? stageCode) => const {
        'egg': 0,
        'child': 1,
        'training': 2,
        'growth': 3,
        'first_team': 4,
      }[stageCode];

  /// DB設計のパラメータコードへ変換します。
  Map<String, double> get _serverParameters => {
        'hunger': meters['食事']!,
        'cleanliness': meters['清潔']!,
        'condition': meters['体調']!,
        'work': meters['仕事']!,
        'tendency_fw': trends['FW']!,
        'tendency_command': trends['CMD']!,
        'tendency_backs': trends['RUN']!,
        'tendency_bulk': trends['BULK']!,
        'tendency_tech': trends['TECH']!,
      };

  /// 現在状態をサーバーへ同期します。
  void _syncServer({TrainingActionType? action, MiniGameResult? result}) {
    _queueSync(action: action, miniGameResult: result);
  }

  /// 同期を順番に実行し、同時更新競合を防ぎます。
  Future<void> _queueSync({
    TrainingActionType? action,
    MiniGameResult? miniGameResult,
  }) async {
    if (_debugTimeSavePending) {
      await _debugTimeSync;
      if (_debugTimeSavePending) return;
    }
    if (!_ownsSession(_ownedSessionVersion) || _syncBlockedUntilServerRestore) {
      return Future<void>.value();
    }
    if (_pendingGameQueueIsClaimedByAnotherController()) {
      _hasForeignPendingAction = true;
      syncStatus.value = TrainingSyncStatus.stopped;
      syncStatusMessage.value = '別の画面で同じ育成の操作を処理中です。順序を守るため同期を停止しています。';
      return Future<void>.value();
    }
    if (action != null && !_claimPendingGameQueue()) {
      syncStatus.value = TrainingSyncStatus.stopped;
      syncStatusMessage.value =
          '別の画面で同じ育成の操作を処理中です。順序を守るため今回の操作を同期キューへ追加しませんでした。';
      return Future<void>.value();
    }
    if (_hasUnknownSyncOutcome) return Future<void>.value();
    if (syncStatus.value == TrainingSyncStatus.stopped ||
        syncStatus.value == TrainingSyncStatus.rateLimited ||
        syncStatus.value == TrainingSyncStatus.outcomeUnknown ||
        syncStatus.value == TrainingSyncStatus.rejected ||
        syncStatus.value == TrainingSyncStatus.sessionChanged) {
      return Future<void>.value();
    }
    if (action != null && pendingSyncActionCount >= maxQueuedSyncActions) {
      syncStatus.value = TrainingSyncStatus.queueFull;
      syncStatusMessage.value =
          '同期待ちが上限（$maxQueuedSyncActions件）です。今回の操作は実行していません。通信中の操作が確定するまでお待ちください。';
      return Future<void>.value();
    }
    // 連続操作中も各アクションを順番に保持し、効果を失わないようにします。
    if (action != null) _actionGate.markPending(action);
    _syncRequested = true;
    _hasUnsyncedLocalState = true;
    _localStateRevision++;
    if (action != null) {
      _queuedActions.add(_PendingTrainingAction(
        type: action,
        result: miniGameResult,
        revision: _localStateRevision,
        sessionVersion: _ownedSessionVersion,
        playerId: _serverPlayerId,
        cycleNo: _serverCycleNo,
        gameStartedAt: _serverGameStartedAt,
        debugBypassCooldown: _bypassesServerCooldown(action),
        idempotencyKey: '${(_serverPlayerId ?? 0).toRadixString(36)}-'
            '${(_serverCycleNo ?? 0).toRadixString(36)}-'
            '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
            '${_localStateRevision.toRadixString(36)}',
      ));
      _claimPendingAction(_queuedActions.last.idempotencyKey);
      final journalSnapshot = <_PendingTrainingAction>[
        if (_activeSyncAction != null) _activeSyncAction!,
        ..._queuedActions,
      ];
      unawaited(_persistPendingActions(snapshotActions: journalSnapshot)
          .catchError((Object _) {
        if (!_ownsSession(_ownedSessionVersion)) return;
        syncStatus.value = TrainingSyncStatus.stopped;
        syncStatusMessage.value = '操作を端末に保存できませんでした。再試行するまで追加操作を停止しています。';
      }));
    }
    syncStatus.value = TrainingSyncStatus.syncing;
    syncStatusMessage.value = '育成状態を同期しています。';
    _startSyncDrain();
    return _syncChain;
  }

  /// 保留中の同期要求を有限回だけ処理し、未確定操作を明示して停止します。
  Future<void> _drainSyncQueue() async {
    var automaticRetries = 0;
    var automaticWait = Duration.zero;
    try {
      while (_syncRequested || _queuedActions.isNotEmpty) {
        if (!_ownsSession(_ownedSessionVersion)) return;
        _syncRequested = false;
        final pending =
            _queuedActions.isEmpty ? null : _queuedActions.removeAt(0);
        final hadUnknownOutcomeBeforeSend =
            pending?.mayHaveBeenApplied ?? false;
        if (pending != null &&
            !_ownsPendingActionClaim(pending.idempotencyKey) &&
            !_claimPendingAction(pending.idempotencyKey)) {
          _queuedActions.insert(0, pending);
          syncStatus.value = TrainingSyncStatus.stopped;
          syncStatusMessage.value = '別のControllerが同じ操作を処理中です。重複送信を止めて保留しています。';
          return;
        }
        if (pending != null &&
            (pending.sessionVersion != _ownedSessionVersion ||
                pending.playerId != _serverPlayerId ||
                pending.cycleNo != _serverCycleNo ||
                !_sameGameInstance(
                  pending.gameStartedAt,
                  _serverGameStartedAt,
                ))) {
          await _quarantinePendingActions([pending]);
          return;
        }
        final retryNotBefore = pending?.retryNotBefore ??
            (pending == null ? _syncRetryNotBefore : null);
        if (retryNotBefore != null && retryNotBefore.isAfter(DateTime.now())) {
          if (pending != null) _queuedActions.insert(0, pending);
          if (pending == null) _syncRequested = true;
          syncStatus.value = TrainingSyncStatus.stopped;
          syncStatusMessage.value =
              'サーバー指定の待機が上限を超えたため自動再試行を停止しました。操作は未送信のまま保留しています。';
          return;
        }
        if (pending != null) pending.retryNotBefore = null;
        if (pending == null) _syncRetryNotBefore = null;
        if (pending != null && pending.requiresGameInstanceCheck) {
          if (!await _checkGameInstanceBeforeRetry(pending)) return;
        }
        if (pending != null) {
          _activeSyncAction = pending;
          // 送信前に結果不明として保存し、プロセス終了後も同じ操作IDを復元します。
          pending.mayHaveBeenApplied = true;
          try {
            await _persistPendingActions();
          } catch (_) {
            _activeSyncAction = null;
            pending.mayHaveBeenApplied = hadUnknownOutcomeBeforeSend;
            pending.requiresGameInstanceCheck = hadUnknownOutcomeBeforeSend ||
                pending.requiresGameInstanceCheck;
            _queuedActions.insert(0, pending);
            _syncActionInFlight = false;
            _hasUnknownSyncOutcome = hadUnknownOutcomeBeforeSend;
            syncStatus.value = hadUnknownOutcomeBeforeSend
                ? TrainingSyncStatus.outcomeUnknown
                : TrainingSyncStatus.stopped;
            syncStatusMessage.value = hadUnknownOutcomeBeforeSend
                ? '再試行前の保存に失敗しました。今回の送信はしていませんが、先行操作の適用有無は未確定のままです。同じ操作IDを保持しています。'
                : '操作を端末に保存できなかったため、サーバーへ送信していません。保存先を確認して再試行してください。';
            return;
          }
          if (!_ownsSession(_ownedSessionVersion)) return;
        }
        _syncActionInFlight = pending != null;
        try {
          await syncNow(
            action: pending?.type,
            miniGameResult: pending?.result,
            stateRevision: pending?.revision,
            idempotencyKey: pending?.idempotencyKey,
            sessionVersion: pending?.sessionVersion ?? _ownedSessionVersion,
            debugBypassCooldown: pending?.debugBypassCooldown,
          );
        } on AuthSessionChangedException {
          _syncActionInFlight = false;
          if (!_isDisposed &&
              AuthToken.sessionVersion != _ownedSessionVersion) {
            await _handleAuthSessionChanged(AuthToken.sessionVersion);
          }
          return;
        } on TrainingGameApiException catch (error) {
          _syncActionInFlight = false;
          if (!_ownsSession(_ownedSessionVersion)) return;
          if (_isGameLockVersionConflict(error)) {
            await _handleGameLockVersionConflict(error, pending);
            return;
          }
          if (error.statusCode != 429 &&
              _isDefinitelyRejected(error) &&
              !_hasUnknownSyncOutcome) {
            _activeSyncAction = null;
            await _handleSyncFailure(error);
            try {
              await _persistPendingActions();
            } catch (_) {
              // 古いジャーナルが残っても、再起動後は同じ操作IDを使います。
            }
            return;
          }
          if (error.statusCode != 429) {
            _activeSyncAction = null;
            if (pending != null) {
              pending.mayHaveBeenApplied = true;
              pending.requiresGameInstanceCheck = true;
              _queuedActions.insert(0, pending);
            } else {
              _syncRequested = true;
              _syncRequestMayHaveBeenApplied = true;
            }
            try {
              await _persistPendingActions();
            } catch (_) {
              // 送信前に保存した不明状態のジャーナルを維持します。
            }
            await _handleSyncFailure(error, preservePending: true);
            return;
          }
          final retryAfter = error.retryAfter ?? const Duration(seconds: 5);
          final requestedWait = retryAfter + const Duration(seconds: 1);
          final safeWait =
              requestedWait.isNegative ? Duration.zero : requestedWait;
          final notBefore = DateTime.now().add(safeWait);
          if (pending != null) {
            pending.mayHaveBeenApplied = hadUnknownOutcomeBeforeSend;
            pending.requiresGameInstanceCheck = true;
            pending.retryNotBefore = notBefore;
            _activeSyncAction = null;
            _queuedActions.insert(0, pending);
            try {
              await _persistPendingActions();
            } catch (_) {
              // 送信前ジャーナルが残るため、同じ操作IDでのみ再試行します。
            }
          } else {
            _syncRequested = true;
            _syncRetryNotBefore = notBefore;
          }
          syncStatus.value = TrainingSyncStatus.rateLimited;
          syncStatusMessage.value = _hasUnknownSyncOutcome
              ? '先行操作の通信結果は不明です。今回の再試行は429で未受理となり、同じ操作IDで保留しています。'
              : 'サーバーが混雑しています。操作を未送信として保留しています。';
          if (automaticRetries >= maxAutomatic429Retries ||
              automaticWait + safeWait > maxAutomatic429Wait) {
            syncStatus.value = _hasUnknownSyncOutcome
                ? TrainingSyncStatus.outcomeUnknown
                : TrainingSyncStatus.stopped;
            syncStatusMessage.value = _hasUnknownSyncOutcome
                ? '429の自動再試行上限（${maxAutomatic429Retries}回、待機合計${maxAutomatic429Wait.inSeconds}秒）に達しました。先行操作の結果は不明です。保留中の再送は同じ操作IDを使います。'
                : '429の自動再試行上限（${maxAutomatic429Retries}回、待機合計${maxAutomatic429Wait.inSeconds}秒）に達しました。操作は未送信のまま保留中です。再試行するか、破棄してください。';
            return;
          }
          automaticRetries++;
          automaticWait += safeWait;
          final waitCompleted = await _waitForRetry(safeWait);
          if (!waitCompleted || !_ownsSession(_ownedSessionVersion)) return;
          continue;
        } catch (error) {
          _syncActionInFlight = false;
          if (!_ownsSession(_ownedSessionVersion)) return;
          _activeSyncAction = null;
          if (pending != null) {
            pending.mayHaveBeenApplied = true;
            pending.requiresGameInstanceCheck = true;
            _queuedActions.insert(0, pending);
          } else {
            _syncRequested = true;
            _syncRequestMayHaveBeenApplied = true;
          }
          try {
            await _persistPendingActions();
          } catch (_) {
            // 送信前ジャーナルが残るため、同じ操作IDを失いません。
          }
          await _handleSyncFailure(error, preservePending: true);
          return;
        }
        _syncActionInFlight = false;
        if (!_ownsSession(_ownedSessionVersion)) return;
        _activeSyncAction = null;
        if (pending == null) {
          _syncRequestMayHaveBeenApplied = false;
        } else {
          pending.mayHaveBeenApplied = false;
          try {
            await _persistPendingActions();
          } catch (_) {
            pending.mayHaveBeenApplied = true;
            pending.requiresGameInstanceCheck = true;
            _queuedActions.insert(0, pending);
            _hasUnknownSyncOutcome = true;
            syncStatus.value = TrainingSyncStatus.outcomeUnknown;
            syncStatusMessage.value =
                'サーバー応答を受け取りましたが、端末の操作記録を更新できませんでした。結果を確認できるまで同じ操作IDを保持します。';
            return;
          }
        }
        _hasUnknownSyncOutcome = _syncRequestMayHaveBeenApplied ||
            _queuedActions.any((action) => action.mayHaveBeenApplied);
      }
      if (_ownsSession(_ownedSessionVersion) && _queuedActions.isEmpty) {
        _hasUnknownSyncOutcome = false;
        syncStatus.value = TrainingSyncStatus.idle;
        syncStatusMessage.value = '';
      }
    } finally {
      _syncRunning = false;
      _syncActionInFlight = false;
    }
  }

  Future<void> _handleSyncFailure(
    Object error, {
    bool preservePending = false,
  }) async {
    final knownRejected =
        _isDefinitelyRejected(error) && !_hasUnknownSyncOutcome;
    if (knownRejected) {
      if (!preservePending) {
        _queuedActions.clear();
        _syncRequested = false;
        _syncRequestMayHaveBeenApplied = false;
      }
      _syncRetryNotBefore = null;
      _actionGate.clear();
      syncStatus.value = TrainingSyncStatus.rejected;
      syncStatusMessage.value = error is TrainingGameApiException &&
              error.message.contains('クールタイム')
          ? 'サーバーがクールタイム解除を受け付けませんでした。今回の効果は保存されていません。後続の未送信操作は破棄しました。サーバー状態を確認してから続けてください。'
          : 'サーバーが操作を拒否しました。後続の未送信操作は破棄しました。サーバー状態を確認してから続けてください。';
    } else {
      _hasUnknownSyncOutcome = true;
      syncStatus.value = TrainingSyncStatus.outcomeUnknown;
      syncStatusMessage.value = isServerStateReady.value
          ? '通信結果が不明です。未送信とは断定できません。保留操作を同じ操作IDで再確認し、サーバー状態と応答を確認してください。'
          : '通信結果が不明です。未送信とは断定できません。保留操作は同じ操作IDを保持し、サーバー状態を確認できるまで再送を待ちます。通信復旧後に状態を再取得してください。';
    }
    if (!isServerStateReady.value) {
      serverErrorMessage.value = syncStatusMessage.value;
    }
  }

  bool _isDefinitelyRejected(Object error) {
    if (error is! TrainingGameApiException) return false;
    // 408や未監査の4xxは、仲介サーバーが応答した可能性もあるため不明扱いにします。
    // 409も理由ごとの意味を確認するため、結果不明として操作を保持します。
    return const {401, 403, 404, 422}.contains(error.statusCode);
  }

  /// 画面離脱時の同期をキューへ追加します。
  void syncInBackground() {
    _queueSync();
  }

  /// 画面終了前に最新状態の同期完了を待ちます。
  Future<void> syncNow({
    TrainingActionType? action,
    MiniGameResult? miniGameResult,
    int? stateRevision,
    String? idempotencyKey,
    int? sessionVersion,
    bool? debugBypassCooldown,
  }) async {
    final expectedSessionVersion = sessionVersion ?? _ownedSessionVersion;
    if (!_ownsSession(expectedSessionVersion)) return;
    // 仕事はサーバー受理前に楽観更新するため、その結果が確定するまで
    // 退室など別経路の同期で増分を送信しないようにします。
    if (debugPositionBusy.value ||
        _syncBlockedUntilServerRestore ||
        (_isWorkSyncPending && action != TrainingActionType.work)) {
      return;
    }
    if (_serverPlayerId == null) {
      await _startServerState(expectedSessionVersion: expectedSessionVersion);
      return;
    }
    // 後続の行動と区別できるよう、この通信が受け取る状態世代を記録します。
    final syncingRevision = stateRevision ?? _localStateRevision;
    // 操作時の設定を使い、待機中の設定変更や再起動後も同じ要求で再送します。
    final bypassCooldown = debugBypassCooldown ??
        (action != null && _bypassesServerCooldown(action));
    // APIに未保存の進行カウンターも、通信失敗時に失わないよう先に保持します。
    _hasUnsyncedLocalState = true;
    await _saveLocalGameState();
    if (!_ownsSession(expectedSessionVersion)) return;
    final isPositiveEnd = clearPosition.value != null;
    var deferredForRateLimit = false;
    try {
      final data = await _serverProvider.sync(
        stageCode: _stageCode,
        parameters: _serverParameters,
        lockVersion: _serverLockVersion,
        cycleNo: _serverCycleNo ?? 0,
        positionCode: _positionCode,
        branchCode: _branchCode,
        actionCode: action == null ? null : _actionCode(action),
        actionIdempotencyKey: idempotencyKey,
        expectedSessionVersion: expectedSessionVersion,
        actionScore: miniGameResult?.score,
        actionEffectMultiplier: miniGameResult?.effectMultiplier,
        actionResultCode: miniGameResult?.resultCode,
        actionResultPolicy: miniGameResult?.tackleResult?.resultPolicy,
        actionAttemptCount: miniGameResult?.tackleResult?.attemptCount,
        actionSuccessCount: miniGameResult?.tackleResult?.successCount,
        actionSuccessfulReactionTotalUs:
            miniGameResult?.tackleResult?.successfulReactionTotalUs,
        actionTackleSettings: miniGameResult?.tackleResult?.settings,
        debugBypassCooldown: bypassCooldown,
        status: isPositiveEnd
            ? 'positive_end'
            : ended.value
                ? 'negative_end'
                : 'playing',
      );
      if (!_ownsSession(expectedSessionVersion)) return;
      // 先行操作がある場合は状態全体をまだ上書きしませんが、サーバーが確定した
      // クールタイムだけは直ちに反映し、同じ行動の再送を防ぎます。
      _restoreServerCooldowns(
        data['cooldowns'],
        preserveLocalCooldowns: true,
      );
      // 古いAPIがcooldownsを返さない場合でも、サーバー側の固定ルールを
      // クライアントが一時的に無視して再送しないようにします。
      final responseCooldowns = data['cooldowns'];
      if (action != null &&
          isCooldownAction(action) &&
          (responseCooldowns is! Map ||
              !responseCooldowns.containsKey(_actionCode(action)))) {
        _actionGate.mergeServerCooldowns({
          action: _serverNow().add(careCooldown),
        });
        cooldownTick.value++;
      }
      if (syncingRevision == _localStateRevision) {
        // 同期前に保存したローカルスナップショットを再適用すると、
        // サーバーが行ったオフライン精算（下限10を含む）を古い値で上書きします。
        // 同期成功時はサーバー応答を正本として、現在のControllerの進行カウンターだけを維持します。
        final applied = _applyServerState(data, restoreLocalState: false);
        if (!applied) {
          // 同期自体は成功している可能性があるため、同じアクションを
          // 新しい冪等キーで再送せず、現在のサーバー状態を再取得します。
          Map<String, dynamic>? current;
          try {
            current = await _serverProvider.fetchCurrent(
              expectedSessionVersion: expectedSessionVersion,
            );
          } catch (_) {
            // 再取得に失敗しても、通信復旧後に再利用できるよう
            // 未同期のローカル状態は削除せず保持します。
            if (_ownsSession(expectedSessionVersion)) {
              isServerStateReady.value = false;
              serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
            }
            _hasUnsyncedLocalState = true;
            await _saveLocalGameState();
            return;
          }
          if (_ownsSession(expectedSessionVersion) && current != null) {
            final currentApplied = _initializeServerState(
              current,
              restoreLocalStateOverride: false,
            );
            if (currentApplied) {
              _hasUnsyncedLocalState = false;
              await _saveLocalGameState();
              return;
            }
          }
          // 再取得できない場合は、次回の同期対象としてローカル状態を保持します。
          _hasUnsyncedLocalState = true;
          await _saveLocalGameState();
          return;
        }
        _hasUnsyncedLocalState = false;
      }
      _serverLockVersion =
          (data['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
      _restoreWorkAvailability(data);
      // 後続行動がなければサーバー優先へ戻し、ある場合は未送信状態を保持します。
      _hasUnsyncedLocalState = syncingRevision != _localStateRevision;
      await _saveLocalGameState();
      // 図鑑はポジティブ終了時だけ再取得し、通常同期の余分な通信を省きます。
      if (isPositiveEnd && _ownsSession(expectedSessionVersion)) {
        await refreshUnlockedPositions();
      }
    } catch (error) {
      if (error is AuthSessionChangedException) rethrow;
      if (!_ownsSession(expectedSessionVersion)) return;
      if (action != null &&
          error is TrainingGameApiException &&
          _isCooldownRejection(action, error) &&
          !bypassCooldown) {
        await _handleCooldownRejection(
          action,
          expectedSessionVersion: expectedSessionVersion,
        );
        return;
      }
      if (error is TrainingGameApiException && error.statusCode == 429) {
        // レート制限は通信断ではなく未処理のリクエストです。
        // ローカル状態を保持し、キュー側でRetry-After後に同じ操作を再送します。
        deferredForRateLimit = true;
        if (!_ownsSession(expectedSessionVersion)) rethrow;
        _hasUnsyncedLocalState = true;
        await _saveLocalGameState();
        rethrow;
      }
      if (action == TrainingActionType.work) {
        // サーバーに拒否された楽観更新を捨てます。後続アクションで、
        // 拒否済み仕事のメーター増分を保存してしまうことを防ぎます。
        _isWorkAvailable = false;
        _hasUnsyncedLocalState = false;
        // _initializeServerState内のローカル復元で、同期直前の楽観更新を
        // 再適用しないよう、対象スナップショットを先に破棄します。
        await MySharedPref.clearTrainingGameLocalState();
        try {
          final serverData = await _serverProvider.fetchCurrent(
            expectedSessionVersion: expectedSessionVersion,
          );
          if (serverData != null && _ownsSession(expectedSessionVersion)) {
            _initializeServerState(serverData);
          }
        } catch (_) {
          // サーバー状態を取得できるまで画面操作を停止します。拒否済み仕事の
          // 楽観更新を残したまま、別アクションで同期することを防ぎます。
          if (_ownsSession(expectedSessionVersion)) {
            _syncBlockedUntilServerRestore = true;
            isServerStateReady.value = false;
            serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
          }
        }
        await _saveLocalGameState();
      } else if (_ownsSession(expectedSessionVersion)) {
        await _restoreAuthoritativeStateAfterSyncFailure(
          expectedSessionVersion: expectedSessionVersion,
        );
      }
      rethrow;
    } finally {
      if (action != null && !deferredForRateLimit) {
        _actionGate.clearPending(action);
      }
      if (action == TrainingActionType.work && !deferredForRateLimit) {
        _isWorkSyncPending = false;
      }
    }
  }

  /// サーバー側で拒否されたクールタイムを、通信障害として扱わず同期します。
  Future<void> _handleCooldownRejection(
    TrainingActionType action, {
    required int expectedSessionVersion,
  }) async {
    // 同じ行動が既にキューへ積まれていれば、同じ422を繰り返し発生させない。
    _queuedActions.removeWhere((pending) => pending.type == action);
    _actionGate.mergeServerCooldowns({
      action: _serverNow().add(careCooldown),
    });
    if (_ownsSession(expectedSessionVersion)) {
      logs.insert(0, '${_labelFor(action)}はサーバー側でクールタイム中です。');
    }

    try {
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: expectedSessionVersion,
      );
      if (!_ownsSession(expectedSessionVersion) || data == null) return;
      _serverLockVersion =
          (data['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
      _restoreServerCooldowns(data['cooldowns'], preserveLocalCooldowns: true);
      _restoreWorkAvailability(data);
      if (_queuedActions.isEmpty) {
        // 後続操作がなければ、拒否された操作の楽観更新を正本へ戻します。
        _initializeServerState(data, restoreLocalStateOverride: false);
        _hasUnsyncedLocalState = false;
        await _saveLocalGameState();
      }
    } catch (_) {
      // クールタイム拒否は画面を通信エラーに遷移させず、次回の状態取得で補正します。
    }
  }

  bool _isCooldownRejection(
    TrainingActionType action,
    TrainingGameApiException error,
  ) {
    return error.statusCode == 422 &&
        isCooldownAction(action) &&
        error.message.contains('クールタイム');
  }

  /// デバッグでクールタイムを解除する対象かを返します。
  bool _bypassesServerCooldown(TrainingActionType type) =>
      isCooldownAction(type) && !isCooldownEnabled(type);

  /// 同期に失敗した場合は端末側の先行変更を破棄し、サーバー状態へ戻します。
  Future<void> _restoreAuthoritativeStateAfterSyncFailure({
    required int expectedSessionVersion,
  }) async {
    _pendingStageIndex = null;
    _pendingStageSyncQueued = false;
    if (!_ownsSession(expectedSessionVersion)) return;
    await MySharedPref.clearTrainingGameLocalState();
    if (!_ownsSession(expectedSessionVersion)) return;
    try {
      final data = await _serverProvider.fetchCurrent(
        expectedSessionVersion: expectedSessionVersion,
      );
      if (_ownsSession(expectedSessionVersion) && data != null) {
        _initializeServerState(data, restoreLocalStateOverride: false);
      }
    } catch (_) {
      if (_ownsSession(expectedSessionVersion)) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
      }
    }
  }

  /// 同じ育成サイクルだけを対象に、途中進行のローカル復元情報を保存します。
  Future<void> _saveLocalGameState() {
    if (!_ownsSession(_ownedSessionVersion)) return Future<void>.value();
    final playerId = _serverPlayerId;
    if (playerId == null) return Future<void>.value();
    return MySharedPref.setTrainingGameLocalState(jsonEncode({
      'player_id': playerId,
      'cycle_no': _serverCycleNo,
      'stage_code': _stageCode,
      'has_unsynced_state': _hasUnsyncedLocalState,
      'hunger': meters['食事'],
      'cleanliness': meters['清潔'],
      'condition': meters['体調'],
      'work': meters['仕事'],
      'fw': trends['FW'],
      'command': trends['CMD'],
      'run': trends['RUN'],
      'bulk': trends['BULK'],
      'tech': trends['TECH'],
      'elapsed_hours': elapsedHours.value,
      'total_elapsed_seconds': totalElapsedSeconds.value,
      'main_elapsed_seconds': mainElapsedSeconds.value,
      'day': day.value,
      'seconds_in_stage': secondsInStage.value,
      'days_in_stage': daysInStage.value,
      'actions_today': actionsToday.value,
      'training_count': trainingCount.value,
      'low_condition_training': _lowConditionTraining,
      'day_cared': _dayCared,
      'zero_hours': _zeroHours,
      'tutorial_zero_seconds': _tutorialZeroSeconds,
      'cooldowns': {
        for (final entry in _actionGate.snapshot(cooldownEnabled).entries)
          _actionCode(entry.key): entry.value.toIso8601String(),
      },
      'ended': ended.value,
      'ending_step': endingStep.value,
      'ending_message': endingMessage.value,
      'clear_position': clearPosition.value,
    }));
  }

  /// ポジション名をDBコードへ変換します。
  String? get _positionCode => const {
        'プロップ': 'prop',
        'フッカー': 'hooker',
        'ロック': 'lock',
        'フランカー': 'flanker',
        'ナンバーエイト': 'number_eight',
        'スクラムハーフ': 'scrum_half',
        'スタンドオフ': 'stand_off',
        'センター': 'center',
        'ウイング': 'wing',
        'フルバック': 'fullback',
      }[position];

  /// 図鑑に登録済みかを返します。
  bool isPositionUnlocked(String positionName) {
    final code = const {
      'プロップ': 'prop',
      'フッカー': 'hooker',
      'ロック': 'lock',
      'フランカー': 'flanker',
      'ナンバーエイト': 'number_eight',
      'スクラムハーフ': 'scrum_half',
      'スタンドオフ': 'stand_off',
      'センター': 'center',
      'ウイング': 'wing',
      'フルバック': 'fullback',
    }[positionName];
    return code != null && unlockedPositions.contains(code);
  }

  /// 大別名をDBコードへ変換します。
  String? get _branchCode => const {
        'A フォワード型': 'FW',
        'B 司令塔型': 'COMMAND',
        'C バックス型': 'BACKS',
      }[branch];

  /// 行動種別をDBコードへ変換します。
  static String _actionCode(TrainingActionType type) => const {
        TrainingActionType.meal: 'meal',
        TrainingActionType.clean: 'clean',
        TrainingActionType.rest: 'rest',
        TrainingActionType.squat: 'training',
        TrainingActionType.work: 'work',
        TrainingActionType.tackle: 'tackle',
        TrainingActionType.passAndRun: 'pass_run',
      }[type]!;

  /// 保存済みコードを行動種別へ戻します。
  static TrainingActionType? _actionTypeFromCode(String code) => const {
        'meal': TrainingActionType.meal,
        'clean': TrainingActionType.clean,
        'rest': TrainingActionType.rest,
        'training': TrainingActionType.squat,
        'work': TrainingActionType.work,
        'tackle': TrainingActionType.tackle,
        'pass_run': TrainingActionType.passAndRun,
      }[code];

  /// 完了したミニゲームの結果を、育成アクション1回分として反映します。
  void completeMiniGame(TrainingActionType type, MiniGameResult result) {
    if (_isMiniGameOpen &&
        (_miniGamePlayerId != _serverPlayerId ||
            _miniGameCycleNo != _serverCycleNo ||
            !_sameGameInstance(_miniGameStartedAt, _serverGameStartedAt))) {
      logs.insert(0, '育成状態が変わったため、この結果を別の育成へ反映できません。');
      return;
    }
    if (type != TrainingActionType.tackle &&
        type != TrainingActionType.passAndRun) return;
    final expectedType = type == TrainingActionType.tackle
        ? MiniGameType.tackle
        : MiniGameType.passAndRun;
    if (result.type != expectedType) return;
    perform(type, miniGameResult: result);
  }

  bool _squatScenePending = false;
  bool _squatCompletionAuthorized = false;

  /// 開始条件を満たした同じ画面操作に限り、一度だけ完了を受け付けます。
  void Function(bool)? beginSquatScene() {
    if (!_ownsSession(_ownedSessionVersion) ||
        !isServerStateReady.value ||
        ended.value ||
        evolutionStage.value != null ||
        _squatScenePending ||
        squatRequirementMessage != null ||
        stageIndex.value < 1 ||
        !canPerform(TrainingActionType.squat)) return null;
    _squatScenePending = true;
    final session = _ownedSessionVersion;
    final player = _serverPlayerId;
    final cycle = _serverCycleNo;
    final startedAt = _serverGameStartedAt;
    final stage = stageIndex.value;
    final generation = _squatSceneGeneration;
    var consumed = false;
    return (completed) {
      if (consumed) return;
      consumed = true;
      _squatScenePending = false;
      if (!completed ||
          generation != _squatSceneGeneration ||
          !_ownsSession(session) ||
          player != _serverPlayerId ||
          cycle != _serverCycleNo ||
          !_sameGameInstance(startedAt, _serverGameStartedAt) ||
          stage != stageIndex.value) return;
      _squatCompletionAuthorized = true;
      try {
        perform(TrainingActionType.squat);
      } finally {
        _squatCompletionAuthorized = false;
      }
    };
  }

  /// 指定した行動を実行し、メーターと傾向値を更新します。
  void perform(TrainingActionType type, {MiniGameResult? miniGameResult}) {
    if (type == TrainingActionType.squat &&
        _squatScenePending &&
        !_squatCompletionAuthorized) return;
    if (_isMiniGamePreparationPending ||
        ended.value ||
        evolutionStage.value != null ||
        _debugTimeSavePending) {
      return;
    }
    if (!_ownsSession(_ownedSessionVersion)) {
      syncStatusMessage.value = 'ログイン状態が変わったため、この画面では操作できません。';
      return;
    }
    if (!isServerStateReady.value) {
      logs.insert(0, 'サーバー状態を確認してから操作してください。');
      return;
    }
    if (syncStatus.value == TrainingSyncStatus.rateLimited ||
        syncStatus.value == TrainingSyncStatus.stopped ||
        syncStatus.value == TrainingSyncStatus.outcomeUnknown ||
        syncStatus.value == TrainingSyncStatus.rejected ||
        syncStatus.value == TrainingSyncStatus.sessionChanged) {
      logs.insert(0, '同期状態を確認してから次の操作をしてください。');
      return;
    }
    if (_hasUnknownSyncOutcome) {
      logs.insert(0, '前回操作の結果が未確定です。同じ操作IDでの再確認が必要です。');
      return;
    }
    if (pendingSyncActionCount >= maxQueuedSyncActions) {
      syncStatus.value = TrainingSyncStatus.queueFull;
      syncStatusMessage.value =
          '同期待ちが上限（$maxQueuedSyncActions件）です。今回の操作は実行していません。同期が進むまでお待ちください。';
      return;
    }
    if (_pendingStageIndex != null ||
        _waitingForServerRestore ||
        _syncBlockedUntilServerRestore) {
      logs.insert(0, '育成状態を同期中です。しばらくお待ちください。');
      return;
    }
    if (!canPerform(type)) {
      logs.insert(0, '${_labelFor(type)}はクールタイム中です。');
      return;
    }
    final isMiniGame = type == TrainingActionType.tackle ||
        type == TrainingActionType.passAndRun;
    if (isMiniGame && stageIndex.value < 2) {
      logs.insert(0, '育成段階までは本格的な練習を始められません。');
      return;
    }
    if (type == TrainingActionType.squat && stageIndex.value < 1) {
      logs.insert(0, '幼少段階から筋トレを始められます。');
      return;
    }
    if (type == TrainingActionType.squat && !_squatCompletionAuthorized) {
      final requirementMessage = squatRequirementMessage;
      if (requirementMessage != null) {
        logs.insert(0, requirementMessage);
        return;
      }
    }
    if (type == TrainingActionType.work && !canWorkToday) {
      logs.insert(0, '仕事は1日1回までです。');
      return;
    }

    if (!_claimPendingGameQueue()) {
      syncStatus.value = TrainingSyncStatus.stopped;
      syncStatusMessage.value = '別の画面で同じ育成の操作を処理中です。順序を守るため、新しい操作を停止しています。';
      logs.insert(0, '先行操作の同期状態を確認してから続けてください。');
      return;
    }

    if (stageIndex.value < 2) {
      if (!_performTutorialAction(type)) return;
      _startCooldown(type);
      _syncServer(action: type);
      return;
    }

    final wasOverfed = meters['食事']! > 100;
    final miniGameMultiplier = miniGameResult?.effectMultiplier ?? 1.0;
    final workBeforeAction = meters['仕事']!;

    switch (type) {
      case TrainingActionType.meal:
        _changeMeter('食事', 35);
        _changeMeter('清潔', -3);
        break;
      case TrainingActionType.clean:
        _addTrend('TECH', 2, '体調');
        _changeMeter('清潔', 40);
        break;
      case TrainingActionType.rest:
        _changeMeter('体調', 40);
        _changeMeter('食事', -5);
        break;
      case TrainingActionType.squat:
        _addTrend('FW', 3, '食事', sourceOffset: 12, training: true);
        _addTrend('BULK', 2, '食事', sourceOffset: 12, training: true);
        _changeMeter('食事', -12);
        _changeMeter('清潔', -8);
        _changeMeter('体調', -6);
        break;
      case TrainingActionType.tackle:
        _addTrend('FW', 5 * miniGameMultiplier, '体調',
            sourceOffset: 12, training: true);
        _addTrend('BULK', 1 * miniGameMultiplier, '体調',
            sourceOffset: 12, training: true);
        _changeMeter('清潔', -12);
        _changeMeter('体調', -12);
        _changeMeter('食事', -8);
        _changeMeter('仕事', 10 * miniGameMultiplier);
        break;
      case TrainingActionType.passAndRun:
        _addTrend(
          'RUN',
          (workBeforeAction >= 80 ? 2 : 5) * miniGameMultiplier,
          '体調',
          sourceOffset: 10,
          training: true,
        );
        if (workBeforeAction >= 80) {
          _addTrend(
            'CMD',
            6 * miniGameMultiplier,
            '体調',
            sourceOffset: 10,
            training: true,
          );
        }
        _changeMeter('清潔', -10);
        _changeMeter('体調', -10);
        _changeMeter('食事', -10);
        _changeMeter('仕事', 10 * miniGameMultiplier);
        break;
      case TrainingActionType.work:
        _addTrend('TECH', 6, '体調', sourceOffset: 10);
        _changeMeter('食事', -10);
        _changeMeter('体調', -10);
        _changeMeter('仕事', 30);
        // 同期中は重複実行を止め、成功時の可否はサーバー応答で更新します。
        _isWorkSyncPending = true;
        break;
    }
    if (_isTraining(type) && wasOverfed) {
      _changeTrend('BULK', 1);
      _changeTrend('RUN', -.5);
    }
    logs.insert(
      0,
      miniGameResult == null
          ? '${_labelFor(type)}を実行しました。'
          : '${miniGameResult.summary}／育成結果へ反映しました。',
    );
    actionsToday.value++;
    _startCooldown(type);
    // 参照HTMLと同じく、行動後に4メーターが整っていれば当日の達成状態を保持します。
    if (_isCared) _dayCared = true;
    if (_isTraining(type) && meters['体調']! < 20) {
      _lowConditionTraining++;
    }
    if (meters['体調']! >= 80) _lowConditionTraining = 0;
    _advanceMainStageIfNeeded();
    _checkGameOver();
    _syncServer(action: type, result: miniGameResult);
  }

  final debugPositionBusy = false.obs;
  String get debugResolvedPosition =>
      _positionNameFromCode(_serverPositionCode.value) ?? '判定前';

  bool get _canDebugPosition =>
      AppEnvironment.showsTrainingDebugUi &&
      _ownsSession(_ownedSessionVersion) &&
      !debugPositionBusy.value &&
      !ended.value &&
      !_syncRunning &&
      !_syncRequested &&
      !_hasUnsyncedLocalState &&
      !_syncBlockedUntilServerRestore &&
      !_hasUnknownSyncOutcome &&
      !_hasCorruptPendingActionQueue &&
      !_hasForeignPendingAction &&
      !_isMiniGamePreparationPending &&
      !isReturningHome.value &&
      pendingSyncActionCount == 0 &&
      !_debugTimeSavePending &&
      _debugTimeSync == null &&
      !_isMiniGameOpen &&
      !_isWorkPreparationPending &&
      _pendingStageIndex == null &&
      isServerStateReady.value;

  Future<Map<String, dynamic>> loadDebugPositionOptions() async {
    await _restoreChain;
    if (!_canDebugPosition) throw StateError('同期完了後にもう一度開いてください。');
    return _serverProvider.debugPositionOptions(
        expectedSessionVersion: _ownedSessionVersion);
  }

  Future<void> applyDebugPosition(Map<String, dynamic> target,
      {required bool complete, String? positionCode}) async {
    await _restoreChain;
    if (!_canDebugPosition ||
        target['id'] != _serverPlayerId ||
        target['cycle_no'] != _serverCycleNo ||
        target['lock_version'] != _serverLockVersion ||
        !_sameGameInstance(
            _gameStartedAtFrom(target['started_at']), _serverGameStartedAt)) {
      throw StateError('対象の育成状態が変わりました。開き直してください。');
    }
    final session = _ownedSessionVersion;
    debugPositionBusy.value = true;
    try {
      Map<String, dynamic> data;
      try {
        data = await _serverProvider.debugPositionCommand(
            target: target,
            complete: complete,
            positionCode: positionCode,
            expectedSessionVersion: session);
      } catch (_) {
        // 書込みを再送せず、完了後も取得できる専用読取りで結果を照合します。
        final options = await _serverProvider.debugPositionOptions(
            expectedSessionVersion: session);
        data = Map<String, dynamic>.from(options['current_game'] as Map);
        if (data['id'] != target['id'] ||
            data['cycle_no'] != target['cycle_no'] ||
            data['started_at'] != target['started_at'] ||
            data['lock_version'] != (target['lock_version'] as int) + 1 ||
            (complete
                ? data['status'] != 'positive_end'
                : data['position_code'] != positionCode)) {
          rethrow;
        }
      }
      if (!_ownsSession(session)) return;
      if (data['id'] != target['id'] ||
          data['cycle_no'] != target['cycle_no'] ||
          data['started_at'] != target['started_at'] ||
          data['lock_version'] != (target['lock_version'] as int) + 1 ||
          (complete
              ? data['status'] != 'positive_end'
              : data['position_code'] != positionCode)) {
        throw StateError('操作結果を確認できませんでした。');
      }
      _hasUnsyncedLocalState = false;
      if (!_initializeServerState(data, restoreLocalStateOverride: false)) {
        throw StateError('操作結果を復元できませんでした。');
      }
      await _saveLocalGameState();
      if (complete) {
        try {
          await refreshUnlockedPositions();
        } catch (_) {
          if (_ownsSession(session)) {
            logs.insert(0, '育成完了を保存しました。図鑑情報は再表示時に取得します。');
          }
        }
      }
    } catch (_) {
      if (_ownsSession(session)) {
        _syncBlockedUntilServerRestore = true;
        serverErrorMessage.value = 'デバッグ操作の結果を確認できません。画面を開き直してください。';
      }
      rethrow;
    } finally {
      debugPositionBusy.value = false;
    }
  }

  /// 指定時間を進め、自然減衰と段階移行を処理します。
  void advanceTime(int hours) {
    advanceTimeMinutes(hours * 60);
  }

  /// 指定した分数を進め、自然減衰と段階移行を処理します。
  void advanceTimeMinutes(int minutes) {
    if (!AppEnvironment.showsTrainingDebugUi ||
        debugPositionBusy.value ||
        minutes <= 0 ||
        _isDisposed ||
        _debugTimeSavePending ||
        _debugTimeSync != null ||
        _syncRunning ||
        pendingSyncActionCount > 0 ||
        !_ownsSession(_ownedSessionVersion) ||
        ended.value ||
        evolutionStage.value != null ||
        _pendingStageIndex != null) {
      return;
    }
    _markLocalStateChanged();
    final previousDay = day.value;
    // デバッグ加算分も表示用の経過時間へ反映し、内部進行と時計を一致させます。
    _elapsedTimeOffsetSeconds += minutes * 60;
    unawaited(MySharedPref.setTrainingGameDebugElapsedSeconds(
        _elapsedTimeOffsetSeconds));
    // デバッグ指定分だけを明示的に反映し、端末時計との差分は使いません。
    final elapsedHours = minutes ~/ 60;
    for (var index = 0; index < elapsedHours; index++) {
      _tickMainHour();
      if (ended.value || evolutionStage.value != null) break;
    }
    _markActiveMainProgressAsProcessed();
    _updateElapsedTimeFromStart();
    _mainClockTick.value++;
    logs.insert(0, '${minutes}分経過。メーターが自然に減少しました。');
    if (_isDisposed) return;
    _debugTimeSavePending = true;
    _debugDailyResetPending = day.value > previousDay;
    cooldownTick.value++;
    unawaited(_queueDebugTimeSync());
  }

  Future<void> _queueDebugTimeSync() {
    final previousSync = _debugTimeSync ?? Future<void>.value();
    final sync = previousSync.then((_) => _syncDebugTimeAndResetDailyActions());
    _debugTimeSync = sync;
    return sync.whenComplete(() {
      if (identical(_debugTimeSync, sync)) _debugTimeSync = null;
    });
  }

  /// 加算後の値を専用APIへ保存し、日付が進んだ場合だけ日次制限も解除します。
  Future<void> _syncDebugTimeAndResetDailyActions() async {
    final expectedSessionVersion = _ownedSessionVersion;
    try {
      await TrainingGameProvider.waitForPendingSync();
      if (!_ownsSession(expectedSessionVersion)) return;
      if (pendingSyncActionCount > 0) {
        _debugTimeSyncError = '前回の操作が同期待ちです。画面上部の同期状態を確認してから、もう一度仕事を押してください。';
        return;
      }
      final parameters = Map<String, double>.from(_serverParameters);
      final lockVersion = _serverLockVersion;
      final stageCode = _stageCode;
      final playerId = _serverPlayerId;
      final cycleNo = _serverCycleNo;
      final startedAt = _serverGameStartedAt;
      Map<String, dynamic> syncedData;
      try {
        syncedData = await _serverProvider.syncDebugTime(
          stageCode: stageCode,
          parameters: parameters,
          lockVersion: lockVersion,
          expectedSessionVersion: expectedSessionVersion,
        );
      } catch (_) {
        // 保存後に応答だけ失われても、同じ加算を再送する前に現在値を照合します。
        final current = await _serverProvider.fetchCurrent(
          expectedSessionVersion: expectedSessionVersion,
        );
        final saved = current?['parameters'];
        if (current == null ||
            current['lock_version'] != lockVersion + 1 ||
            current['stage_code'] != stageCode ||
            current['id'] != playerId ||
            current['cycle_no'] != cycleNo ||
            !_sameGameInstance(
                _gameStartedAtFrom(current['started_at']), startedAt) ||
            saved is! Map ||
            !parameters.entries.every((entry) =>
                (saved[entry.key] as num?)?.toInt() == entry.value.toInt())) {
          rethrow;
        }
        syncedData = current;
      }
      if (!_ownsSession(expectedSessionVersion)) return;
      _serverLockVersion =
          (syncedData['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
      final data = _debugDailyResetPending
          ? await _serverProvider.resetDebugDailyActionUsage(
              expectedSessionVersion: expectedSessionVersion,
            )
          : syncedData;
      if (_ownsSession(expectedSessionVersion)) {
        if (data['work_available'] is! bool ||
            !_initializeServerState(data, restoreLocalStateOverride: false)) {
          throw StateError('時間変更後の育成状態を確認できませんでした。');
        }
        _debugTimeSavePending = false;
        _debugDailyResetPending = false;
        cooldownTick.value++;
        _debugTimeSyncError = '';
        syncStatusMessage.value = '';
        await _saveLocalGameState();
      }
    } catch (_) {
      if (_ownsSession(expectedSessionVersion)) {
        _debugTimeSyncError = '時間変更を保存できませんでした。通信状態と接続先を確認して、もう一度仕事を押してください。';
        syncStatusMessage.value =
            '時間変更の保存を確認できません。サーバーの状態を再取得できます。表示時計の加算は残り、保留時間操作の再送や日次履歴の解除はしません。';
        cooldownTick.value++;
        logs.insert(0, _debugTimeSyncError);
      }
    }
  }

  /// デバッグ操作として育成期の初期状態にします。
  Future<void> debugStartAtTraining() async {
    if (debugPositionBusy.value) return;
    if (_pendingStageIndex != null || !_ownsSession(_ownedSessionVersion))
      return;
    try {
      final data = await _serverProvider.start(
        stageCode: 'training',
        parameters: const {
          'hunger': 20.0,
          'cleanliness': 20.0,
          'condition': 20.0,
          'work': 20.0,
          'tendency_fw': 0.0,
          'tendency_command': 0.0,
          'tendency_backs': 0.0,
          'tendency_bulk': 0.0,
          'tendency_tech': 0.0,
        },
        forceRestart: true,
        expectedSessionVersion: _ownedSessionVersion,
      );
      if (!_ownsSession(_ownedSessionVersion)) return;
      _resetLocalProgressForNewCycle();
      _initializeServerState(data);
    } catch (_) {
      if (_ownsSession(_ownedSessionVersion)) {
        logs.insert(0, '育成期のデバッグ開始に失敗しました。');
      }
    }
  }

  /// メーターを範囲内に収めて更新します。
  void _changeMeter(String name, double amount) {
    _markLocalStateChanged();
    // プレイ中の下限は管理画面のgame_settingsをサーバーから受け取ります。
    meters[name] = (meters[name]! + amount).clamp(_playFloor, 150).toDouble();
  }

  /// 行動完了時点からクールタイムを開始します。
  void _startCooldown(TrainingActionType type) {
    _actionGate.startClientCooldown(
      type,
      enabled: isCooldownEnabled(type),
      duration: careCooldown,
    );
    cooldownTick.value++;
  }

  /// 傾向値を0未満にならないよう更新します。
  void _changeTrend(String name, double amount) {
    _markLocalStateChanged();
    // 育成傾向も仕様上の上限100を超えないようにします。
    trends[name] = (trends[name]! + amount).clamp(0, 100).toDouble();
  }

  /// サーバー同期後に端末側の状態が変更されたことを記録します。
  void _markLocalStateChanged() {}

  /// 状態係数、清潔補正、行動回数補正を適用して傾向値を加算します。
  void _addTrend(
    String name,
    double amount,
    String source, {
    double sourceOffset = 0,
    bool training = false,
  }) {
    final sourceValue = meters[source]! + sourceOffset;
    var coefficient = sourceValue >= 80
        ? 1.4
        : sourceValue >= 50
            ? 1.0
            : sourceValue >= 20
                ? .6
                : .2;
    if (meters['体調']! > 100) return;
    coefficient *= meters['清潔']! > 100
        ? .8
        : meters['清潔']! >= 80
            ? 1.1
            : 1.0;
    coefficient *= actionsToday.value + 1 <= 20
        ? 1.0
        : actionsToday.value + 1 <= 35
            ? .5
            : .2;
    _changeTrend(name, amount * coefficient);
  }

  /// チュートリアルの制限と回復量を適用します。
  bool _performTutorialAction(TrainingActionType type) {
    if (stageIndex.value == 0 &&
        type != TrainingActionType.clean &&
        type != TrainingActionType.rest) return false;
    if (stageIndex.value == 1 &&
        type == TrainingActionType.squat &&
        !_squatCompletionAuthorized &&
        !TrainingWorkoutRequirement.isMet(meters)) {
      return false;
    }

    final activeMeters =
        stageIndex.value == 0 ? ['清潔', '体調'] : ['食事', '清潔', '体調'];
    final effects = <TrainingActionType, Map<String, double>>{
      TrainingActionType.meal: {'食事': 35, '清潔': -3},
      TrainingActionType.clean: {'清潔': 40},
      TrainingActionType.rest: {'体調': 40, '食事': -5},
      TrainingActionType.squat: {'食事': -12, '清潔': -8, '体調': -6},
    }[type];
    if (effects == null) return false;
    _markLocalStateChanged();

    effects.forEach((name, amount) {
      if (activeMeters.contains(name)) {
        if (amount > 0) {
          meters[name] = (meters[name]! + 25).clamp(0, 100).toDouble();
        } else {
          _changeMeter(name, amount);
        }
      }
    });
    for (final name in activeMeters) {
      if (meters[name]! > 0) _tutorialZeroSeconds[name] = 0;
    }
    if (type == TrainingActionType.squat) trainingCount.value++;
    actionsToday.value++;
    _advanceTutorialIfNeeded();
    return true;
  }

  /// チュートリアルを参照HTMLと同じ秒単位で進めます。
  void tickTutorial(int seconds) {
    if (seconds <= 0 ||
        evolutionStage.value != null ||
        _pendingStageIndex != null) {
      return;
    }
    final decay = stageIndex.value == 0
        ? {'清潔': .7, '体調': .7}
        : {'食事': .2, '清潔': .2, '体調': .2};
    decay.forEach((name, amount) => _changeMeter(name, -amount * seconds));
    secondsInStage.value += seconds;
    totalElapsedSeconds.value += seconds;
    for (final name in decay.keys) {
      _tutorialZeroSeconds[name] =
          meters[name]! <= 0 ? _tutorialZeroSeconds[name]! + seconds : 0;
      if (_tutorialZeroSeconds[name]! >= 30) {
        // チュートリアル失敗時は進化演出を挟まず、引退画面へ直接進みます。
        _endGame(
          endingStep: 2,
          message: 'チュートリアル失敗。卵からやりなおしてください。',
        );
        return;
      }
    }
    _advanceTutorialIfNeeded();
  }

  /// チュートリアルのリアルタイム速度を設定します。
  void setTimeSpeed(int speed) {
    timeSpeed.value = speed;
  }

  /// チュートリアルの段階移行条件を判定します。
  void _advanceTutorialIfNeeded() {
    if (_pendingStageIndex != null) return;
    final ready = _hasServerStageCondition
        ? _serverStageConditionReady()
        : stageIndex.value == 0
            ? secondsInStage.value >= 180 &&
                meters['清潔']! >= 60 &&
                meters['体調']! >= 60
            : trainingCount.value >= 15 &&
                ['食事', '清潔', '体調'].every((name) => meters[name]! >= 60);
    if (!ready) return;
    _pendingStageIndex =
        _stageIndexFromCode(_serverNextStageCode) ?? stageIndex.value + 1;
    secondsInStage.value = 0;
    trainingCount.value = 0;
    actionsToday.value = 0;
    logs.insert(0, '成長しました。段階「${currentStage.name}」へ進みます。');
    _queuePendingStageSync();
  }

  /// 本編を1時間進め、日単位の進行条件を更新します。
  void _tickMainHour() {
    elapsedHours.value++;
    totalElapsedSeconds.value += Duration.secondsPerHour;
    _changeMeter('食事', meters['食事']! > 100 ? -8.4 : -4.2);
    _changeMeter('清潔', meters['清潔']! > 100 ? -2.8 : -1.4);
    _changeMeter('体調', meters['体調']! > 100 ? -4.2 : -2.1);
    _changeMeter('仕事', meters['仕事']! > 100 ? -8.4 : -4.2);
    _zeroHours.updateAll((name, hours) => meters[name]! <= 0 ? hours + 1 : 0);
    _dayCared = _dayCared ||
        ['食事', '清潔', '体調', '仕事'].every((name) => meters[name]! >= 20);
    // 育成期は実時間24時間をゲーム内の1日として扱います。
    if (elapsedHours.value % mainDayHours == 0) {
      day.value++;
      if (_dayCared) daysInStage.value++;
      _dayCared = false;
      actionsToday.value = 0;
      _advanceMainStageIfNeeded();
    }
    _checkGameOver();
  }

  /// サーバー時刻を基準に、アプリ前面中に経過した本編の時間を処理します。
  void _advanceActiveMainProgress() {
    if (debugPositionBusy.value ||
        stageIndex.value < 2 ||
        ended.value ||
        evolutionStage.value != null ||
        _pendingStageIndex != null ||
        _waitingForServerRestore) {
      return;
    }
    _activeMainProgressBaseSeconds ??= _currentServerElapsedSeconds;
    final elapsedSeconds =
        _currentServerElapsedSeconds - _activeMainProgressBaseSeconds!;
    final targetHours = elapsedSeconds < 0 ? 0 : elapsedSeconds ~/ 3600;
    while (_processedActiveMainHours < targetHours) {
      _processedActiveMainHours++;
      _tickActiveMainHour();
      if (ended.value || evolutionStage.value != null) break;
    }
  }

  /// 本編1時間分の表示・日次判定を進めます。
  void _tickActiveMainHour() {
    // 画面表示中の自然減衰はサーバー時刻から算出した時間単位で表示へ反映し、
    // バックグラウンド／復帰時はサーバー精算結果で補正します。
    _tickMainHour();
  }

  /// デバッグで手動加算した時間を、実時間処理済みとして扱います。
  void _markActiveMainProgressAsProcessed() {
    final base = _activeMainProgressBaseSeconds;
    if (base == null) return;
    final elapsedSeconds = _currentServerElapsedSeconds - base;
    _processedActiveMainHours = elapsedSeconds < 0 ? 0 : elapsedSeconds ~/ 3600;
  }

  /// 新しい本編段階または復帰後のサーバー時刻を進行基準にします。
  void _resetActiveMainProgressBaseline() {
    _activeMainProgressBaseSeconds = _currentServerElapsedSeconds;
    _processedActiveMainHours = 0;
  }

  int get _currentServerElapsedSeconds =>
      _serverElapsedSeconds +
      _elapsedTimeOffsetSeconds +
      ServerTimeClock.instance.elapsedSinceSync.inSeconds;

  /// サーバー応答の経過時間とデバッグ加算だけを、画面時計へ反映します。
  void _updateElapsedTimeFromStart() {
    mainElapsedSeconds.value = _serverElapsedSeconds +
        _elapsedTimeOffsetSeconds +
        ServerTimeClock.instance.elapsedSinceSync.inSeconds;
  }

  /// チュートリアルの倍速設定を時計へ反映します。
  void _advanceTutorialClock(int speed) {
    if (speed <= 0) return;
    // 実時間との差分を補正し、停止・倍速でも表示とメーターの進行を一致させます。
    _elapsedTimeOffsetSeconds += speed - 1;
    _updateElapsedTimeFromStart();
  }

  /// APIのISO日時をサーバー時刻として解釈します。
  DateTime? _parseServerDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// 最後に同期したサーバー時刻を返します。
  DateTime _serverNow() => ServerTimeClock.instance.now;

  /// 「世話が行き届いた日」7日で本編段階を進めます。
  void _advanceMainStageIfNeeded() {
    if (stageIndex.value == stages.length - 1) {
      if (position == '判定前') return;
      _endGame(
        endingStep: 0,
        message: '育成完了。${position}として図鑑に登録されました。',
        clearPosition: position,
      );
      return;
    }

    final requiredDays = currentStage.days;
    if (_hasServerStageCondition) {
      if (!_serverStageConditionReady()) return;
    } else if (requiredDays == null || daysInStage.value < requiredDays) {
      return;
    }

    if (stageIndex.value < stages.length - 1) {
      if (_pendingStageIndex != null) return;
      _pendingStageIndex =
          _stageIndexFromCode(_serverNextStageCode) ?? stageIndex.value + 1;
      daysInStage.value = 0;
      logs.insert(0, '成長条件を満たしました。サーバー確認後に次の段階へ進みます。');
      _queuePendingStageSync();
      return;
    }
  }

  bool get _hasServerStageCondition =>
      _serverRequiredWorkValue != null || _serverRequiredElapsedHours != null;

  bool _serverStageConditionReady() {
    final workReady = _serverRequiredWorkValue == null ||
        meters['仕事']! >= _serverRequiredWorkValue!;
    final elapsedHours = _currentServerElapsedSeconds ~/ 3600;
    final elapsedReady = _serverRequiredElapsedHours == null ||
        elapsedHours >= _serverRequiredElapsedHours!;
    return workReady && elapsedReady;
  }

  /// 段階上昇を既存の同期キューへ積みます。
  void _queuePendingStageSync() {
    if (_pendingStageIndex == null || _pendingStageSyncQueued) return;
    _pendingStageSyncQueued = true;
    unawaited(Future<void>.microtask(() {
      if (_pendingStageIndex != null && _queuedActions.isEmpty) {
        _syncServer();
      }
    }));
  }

  /// 練習系アクションかを判定します。
  bool _isTraining(TrainingActionType type) {
    return type == TrainingActionType.squat ||
        type == TrainingActionType.tackle ||
        type == TrainingActionType.passAndRun;
  }

  /// 現在の段階に対応する進化演出を表示対象として記録します。
  void _showEvolutionForCurrentStage() {
    evolutionStage.value = stageIndex.value;
  }

  /// 本編の「世話が行き届いた」判定を返します。
  bool get _isCared =>
      ['食事', '清潔', '体調', '仕事'].every((name) => meters[name]! >= 20);

  /// 体調が尽きた場合のゲームオーバーを判定します。
  void _checkGameOver() {
    if (ended.value) return;
    final zeroLimit = <String, int>{'食事': 48, '体調': 48, '清潔': 72};
    final zeroTarget = _findExceeded(_zeroHours, zeroLimit);
    if (zeroTarget == null && _lowConditionTraining < 15) return;
    _endGame(
      endingStep: 2,
      message: zeroTarget != null
          ? '${zeroTarget.key}が0のまま${zeroTarget.value}時間経過しました。'
          : '体調20未満での練習が15回になりました。',
    );
    logs.insert(0, 'ゲームオーバー：${endingMessage.value}');
  }

  /// 終了状態をサーバーへ保存し、定期復元による新規サイクル開始を防ぎます。
  void _endGame({
    required int endingStep,
    required String message,
    String? clearPosition,
  }) {
    if (ended.value) return;
    ended.value = true;
    this.endingStep.value = endingStep;
    endingMessage.value = message;
    this.clearPosition.value = clearPosition;
    endingSyncError.value = '';
    isEndingSyncPending.value = true;
    // 行動実行中に終了した場合は、その行動の同期要求を先にキューへ積みます。
    unawaited(Future<void>.microtask(_confirmEndingSync));
  }

  /// 保存に失敗した終了状態を再送します。
  void retryEndingSync() {
    if (!ended.value || isEndingSyncPending.value || _isDisposed) return;
    endingSyncError.value = '';
    isEndingSyncPending.value = true;
    unawaited(_confirmEndingSync());
  }

  /// 終了状態がサーバーで育成中でなくなったことを確認します。
  Future<void> _confirmEndingSync() async {
    final expectedSessionVersion = _ownedSessionVersion;
    final expectedPlayerId = _serverPlayerId;
    final expectedCycleNo = _serverCycleNo;
    final expectedStartedAt = _serverGameStartedAt;
    try {
      if (canRetryPendingSync) {
        await retryPendingSync();
      } else if (_syncRunning) {
        await _syncChain;
        if (!_ownsSession(expectedSessionVersion)) return;
        // 先行同期がplayingのままなら、演出中に決まった終了状態を送ります。
        // 既に完了している場合は重複送信しません。
        final current = await _serverProvider.fetchCurrent(
          expectedSessionVersion: expectedSessionVersion,
        );
        if (!_ownsSession(expectedSessionVersion)) return;
        if (current != null &&
            current['id'] == _serverPlayerId &&
            current['cycle_no'] == _serverCycleNo &&
            _sameGameInstance(
              _gameStartedAtFrom(current['started_at']),
              _serverGameStartedAt,
            ) &&
            current['status'] == 'playing') {
          await _queueSync();
        }
      } else {
        await _queueSync();
      }
      if (!_ownsSession(expectedSessionVersion)) return;
      final current = await _serverProvider.fetchCurrent(
        expectedSessionVersion: expectedSessionVersion,
      );
      if (!_ownsSession(expectedSessionVersion)) return;
      if (current != null) {
        final confirmedEnd = current['id'] == expectedPlayerId &&
            current['cycle_no'] == expectedCycleNo &&
            _sameGameInstance(
              _gameStartedAtFrom(current['started_at']),
              expectedStartedAt,
            ) &&
            const ['positive_end', 'negative_end'].contains(current['status']);
        if (confirmedEnd) {
          _hasUnsyncedLocalState = false;
          _restoreEndedState(current);
          endingSyncError.value = '';
          await _saveLocalGameState();
          return;
        }
        throw StateError(_hasUnknownSyncOutcome
            ? '終了時の通信結果が不明です。同じ操作IDで再確認してください。'
            : '終了状態がサーバーへ反映されていません。');
      }
    } catch (_) {
      if (_ownsSession(expectedSessionVersion)) {
        endingSyncError.value = _hasUnknownSyncOutcome
            ? '終了時の操作が反映されたか確認できません。同じ操作IDで再確認してください。'
            : '終了状態を保存できません。通信状態を確認して再試行してください。';
      }
    } finally {
      if (_ownsSession(expectedSessionVersion))
        isEndingSyncPending.value = false;
    }
  }

  /// 指定した継続時間条件に到達したメーターを返します。
  MapEntry<String, int>? _findExceeded(
    Map<String, int> counters,
    Map<String, int> limits,
  ) {
    for (final entry in limits.entries) {
      if (counters[entry.key]! >= entry.value) {
        return entry;
      }
    }
    return null;
  }

  /// 行動種別の表示名を返します。
  String _labelFor(TrainingActionType type) {
    return actions.firstWhere((action) => action.type == type).label;
  }
}
