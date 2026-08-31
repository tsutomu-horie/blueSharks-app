import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

import '../mini_games/models/mini_game_result.dart';
import '../models/training_game_models.dart';
import '../models/training_game_position_classifier.dart';

/// 育成ゲームの進行状態と行動結果を管理します。
class TrainingGameController extends GetxController
    with WidgetsBindingObserver {
  /// 回数上限を設けず、連打だけを抑制するための暫定クールタイムです。
  /// 仕様では秒数が調整項目のため、正式値確定時にここだけ変更します。
  static const careCooldown = Duration(seconds: 60);

  /// 育成期におけるゲーム内1日の経過時間です。
  static const mainDayHours = 4;

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

  final meters = <String, double>{
    // 段階1のチュートリアル用初期値を、サーバー応答前にも表示します。
    '食事': 100,
    '清潔': 50,
    '体調': 50,
    '仕事': 0,
  }.obs;
  final trends = <String, double>{
    'FW': 0,
    'CMD': 0,
    'RUN': 0,
    'BULK': 0,
    'TECH': 0,
  }.obs;
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
  final _cooldownUntil = <TrainingActionType, DateTime>{};
  final _tutorialZeroSeconds = <String, int>{'食事': 0, '清潔': 0, '体調': 0};
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
  final _queuedActions = <({TrainingActionType type, MiniGameResult? result})>[];
  bool _syncRequested = false;
  bool _syncRunning = false;
  Future<void>? _debugTimeSync;
  bool _syncBlockedUntilServerRestore = false;
  bool _hasUnsyncedLocalState = false;
  bool _skipFinalSync = false;
  int _localStateRevision = 0;
  bool _isDisposed = false;
  final TrainingGameProvider _serverProvider = TrainingGameProvider();
  int? _serverPlayerId;
  int? _serverCycleNo;
  int _serverLockVersion = 0;

  /// 現在の段階定義を返します。
  TrainingStageDefinition get currentStage => stages[stageIndex.value];

  /// サーバー時刻で当日の仕事が未実施かを返します。
  bool get canWorkToday =>
      _isWorkAvailable && !_isWorkSyncPending && _pendingStageIndex == null;

  /// 仕事の可否照会または専用画面への遷移中かを返します。
  bool get isWorkPreparationPending => _isWorkPreparationPending;

  /// 仕事画面を開く直前に、サーバー時刻による実施可否を取得します。
  Future<bool> prepareWork() async {
    final debugTimeSync = _debugTimeSync;
    if (debugTimeSync != null) await debugTimeSync;
    if (_isWorkPreparationPending || _isWorkSyncPending || _isDisposed) {
      return false;
    }
    _isWorkPreparationPending = true;
    var prepared = false;
    workAvailabilityError.value = '';
    try {
      final data = await _serverProvider.fetchCurrent();
      if (data == null || _isDisposed) return false;
      // 可否と同じ応答に含まれるlock_version・パラメータも更新し、
      // 他端末操作後に古い状態で仕事を送信しないようにします。
      if (!_initializeServerState(data)) return false;
      prepared = canWorkToday;
      return prepared;
    } catch (_) {
      if (!_isDisposed) {
        workAvailabilityError.value = '仕事の実施可否を確認できませんでした。通信状態を確認してください。';
        logs.insert(0, '仕事の実施可否を確認できませんでした。通信状態を確認してください。');
      }
      return false;
    } finally {
      if (!prepared) _isWorkPreparationPending = false;
    }
  }

  /// 仕事の専用画面を閉じた後、次の仕事開始を可能にします。
  void finishWorkPreparation() => _isWorkPreparationPending = false;

  /// 指定行動のクールタイムが終了しているかを返します。
  bool canPerform(TrainingActionType type) {
    cooldownTick.value;
    if (_pendingStageIndex != null) return false;
    if (!isCooldownEnabled(type)) return true;
    final until = _cooldownUntil[type];
    return until == null || !_serverNow().isBefore(until);
  }

  /// 指定行動のクールタイム設定を返します。
  bool isCooldownEnabled(TrainingActionType type) =>
      cooldownEnabled[type] ?? false;

  /// デバッグメニューから指定行動のクールタイムを切り替えます。
  void setCooldownEnabled(TrainingActionType type, bool enabled) {
    cooldownEnabled[type] = enabled;
    if (!enabled) _cooldownUntil.remove(type);
    cooldownTick.value++;
  }

  /// 指定行動の残りクールタイムを返します。
  Duration cooldownRemaining(TrainingActionType type) {
    cooldownTick.value;
    final until = _cooldownUntil[type];
    if (until == null) return Duration.zero;
    final remaining = until.difference(_serverNow());
    return remaining.isNegative ? Duration.zero : remaining;
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
    final main = {
      'FW': trends['FW']!,
      'CMD': trends['CMD']!,
      'RUN': trends['RUN']!
    };
    if (main.values.every((value) => value == 0) && trends['BULK'] == 0)
      return null;
    final top = main.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {'FW': 'A フォワード型', 'CMD': 'B 司令塔型', 'RUN': 'C バックス型'}[top.first.key];
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
    return TrainingGamePositionClassifier.classify(trends);
  }

  /// 初期表示用のログを準備します。
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    logs.add('段階1「卵」からスタート。お世話をして時間を進めましょう。');
    final initialState = Get.arguments;
    if (initialState is Map) {
      // 遷移元で取得済みの状態を利用し、初期表示時の重複通信を避けます。
      _initializeServerState(Map<String, dynamic>.from(initialState));
    } else {
      unawaited(_restoreServerState());
    }
    _tutorialTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      cooldownTick.value++;
      if (isServerStateReady.value &&
          !_isAppInBackground &&
          evolutionStage.value == null &&
          _pendingStageIndex == null &&
          stageIndex.value < 2 &&
          !ended.value) {
        _advanceTutorialClock(timeSpeed.value);
        tickTutorial(timeSpeed.value);
      }
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
        // パラメータ減衰はサーバー精算だけで確定し、端末時計には依存しません。
        if (_mainClockTick.value % 60 == 0) unawaited(_restoreServerState());
      }
    });
  }

  /// Controller破棄時にチュートリアルのリアルタイム進行を停止します。
  @override
  void onClose() {
    // 破棄後にタイマーやライフサイクル通知から状態を更新しないよう先に停止します。
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _tutorialTimer?.cancel();
    _mainTimer?.cancel();
    // 画面終了直前の最新状態だけを、既存の同期処理の後ろへ追加します。
    if (!_skipFinalSync) _queueSync(force: true);
    super.onClose();
  }

  /// デバッグ用に、サーバー・端末の育成データを初期パラメータ付きで初期化します。
  Future<Map<String, dynamic>?> resetDebugGame() {
    if (_isDisposed) return Future<Map<String, dynamic>?>.value();
    // 先行する同期を完了させてから削除し、古い状態の再保存を防ぎます。
    return TrainingGameProvider.waitForPendingSync()
        .then((_) => _serverProvider.resetDebugState())
        .then<Map<String, dynamic>?>((initialState) async {
      _skipFinalSync = true;
      await MySharedPref.clearTrainingGameStartedAt();
      await MySharedPref.clearTrainingGameDebugElapsedSeconds();
      await MySharedPref.clearTrainingGameLocalState();
      // 画面遷移を挟まず、APIが返した初期状態を現在のControllerへ反映します。
      _resetLocalProgressForNewCycle();
      _initializeServerState(initialState);
      _skipFinalSync = false;
      return initialState;
    }, onError: (_, __) {
      // 初期化失敗時は現在のゲームを維持し、誤って画面遷移しないようにします。
      return null;
    });
  }

  /// 初期化前サイクルのローカル進行状態を破棄します。
  void _resetLocalProgressForNewCycle() {
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
    _lowConditionTraining = 0;
    _dayCared = false;
    _zeroHours.updateAll((key, value) => 0);
    _tutorialZeroSeconds.updateAll((key, value) => 0);
    _cooldownUntil.clear();
    _pendingStageIndex = null;
    _pendingStageSyncQueued = false;
    ended.value = false;
    endingStep.value = 0;
    endingMessage.value = '';
    isEndingSyncPending.value = false;
    endingSyncError.value = '';
    clearPosition.value = null;
    evolutionStage.value = null;
    _elapsedTimeOffsetSeconds = 0;
    _activeMainProgressBaseSeconds = null;
    _processedActiveMainHours = 0;
    _waitingForServerRestore = false;
    _restoreLocalCountersOnNextServerState = true;
  }

  /// 育成完了後の演出フローを次へ進めます。
  void advanceEndingStep() {
    if (ended.value) endingStep.value++;
  }

  /// 段階上昇時の進化演出を完了し、育成画面へ戻します。
  void advanceEvolution() {
    evolutionStage.value = null;
    _resetActiveMainProgressBaseline();
    _updateElapsedTimeFromStart();
    _mainClockTick.value++;
  }

  /// 育成画面を離れる前にローカルのリアルタイム進行を停止します。
  void pauseLocalProgress() {
    _isAppInBackground = true;
    _waitingForServerRestore = true;
    _activeMainProgressBaseSeconds = null;
    _restoreLocalCountersOnNextServerState = true;
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
    if (state == AppLifecycleState.resumed &&
        !ended.value &&
        evolutionStage.value == null) {
      _isAppInBackground = false;
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
    serverErrorMessage.value = '';
    // 復帰イベントが短時間に複数回発生しても、取得処理を直列化します。
    _restoreChain = _restoreChain.then((_) async {
      if (_isDisposed) return;
      // 復帰直前のローカル操作を先に保存してからサーバー状態を読み込みます。
      await _syncChain;
      final data = await _serverProvider.fetchCurrent();
      if (_isDisposed) return;
      if (data != null) {
        if (!_initializeServerState(data)) return;
      } else if (!ended.value) {
        isServerStateReady.value = false;
        serverErrorMessage.value =
            '育成データが見つかりません。ゲーム開始画面からやり直してください。';
        return;
      }
      isServerStateReady.value = true;
    }).catchError((_) {
      // 仕様どおり、通信不可時はローカル状態だけでプレイを継続しません。
      if (!_isDisposed) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
      }
    });
    await _restoreChain;
  }

  /// 通信エラー画面からサーバー状態の取得を再試行します。
  void retryRestoreServerState() {
    if (_isDisposed) return;
    unawaited(_restoreServerState());
  }

  /// 初期状態をサーバーへ保存します。
  Future<void> _startServerState() async {
    final data = await _serverProvider.start(
      stageCode: _stageCode,
      parameters: _serverParameters,
    );
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverCycleNo = (data['cycle_no'] as num?)?.toInt();
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    _applyServerState(data);
    _refreshUnlockedPositionsInBackground();
  }

  /// 取得済みのサーバー状態を初期表示へ反映します。
  bool _initializeServerState(Map<String, dynamic> data) {
    final serverCycleNo = (data['cycle_no'] as num?)?.toInt();
    final isNewCycle =
        serverCycleNo != null &&
        _serverCycleNo != null &&
        serverCycleNo != _serverCycleNo;
    final hasStaleLocalCycle = _hasStaleLocalCycle(serverCycleNo);
    if (isNewCycle || hasStaleLocalCycle) {
      _resetLocalProgressForNewCycle();
      unawaited(MySharedPref.clearTrainingGameDebugElapsedSeconds());
      unawaited(MySharedPref.clearTrainingGameLocalState());
    }
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverCycleNo = serverCycleNo ?? _serverCycleNo;
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    if (!_applyServerState(
      data,
      restoreLocalState: !isNewCycle && !hasStaleLocalCycle,
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
    final stage = data['stage_code'] as String?;
    final serverStageIndex = _stageIndexFromCode(stage);
    if (_pendingStageIndex != null &&
        serverStageIndex != null &&
        serverStageIndex < _pendingStageIndex!) {
      return false;
    }
    _restoreServerClock(data, restoreDebugElapsed: restoreDebugElapsed);
    _restoreWorkAvailability(data);
    if (serverStageIndex != null) {
      final previousStage = stageIndex.value;
      stageIndex.value = serverStageIndex;
      if (_pendingStageIndex == serverStageIndex) {
        _pendingStageIndex = null;
        _pendingStageSyncQueued = false;
        if (serverStageIndex > previousStage) _showEvolutionForCurrentStage();
      }
    }
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
          trends[tendencyName] = value.clamp(0, 999).toDouble();
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
      _hasUnsyncedLocalState = false;
    }
    _restoreLocalCountersOnNextServerState = false;
    final serverActionsToday = (data['actions_today'] as num?)?.toInt();
    if (serverActionsToday != null) {
      actionsToday.value = serverActionsToday;
    }
    // ローカル保存値より、サーバーが現在時刻で判定した値を優先します。
    _restoreServerCooldowns(data['cooldowns']);
    _restoreEndedState(data);
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
    final serverHasBulk =
        serverParameters is Map && serverParameters.containsKey('tendency_bulk');
    final serverHasTech =
        serverParameters is Map && serverParameters.containsKey('tendency_tech');
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
      clearPosition.value = _positionNameFromCode(data['position_code']) ?? position;
      endingMessage.value = '育成完了。${clearPosition.value}として図鑑に登録されました。';
      return;
    }
    if (status == 'negative_end') {
      ended.value = true;
      endingStep.value = 2;
      endingMessage.value = '育成は終了しました。卵からやりなおしてください。';
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
    for (final entry in rawCooldowns.entries) {
      final type = _actionTypeFromCode(entry.key.toString());
      final value = entry.value;
      if (type == null || value is! String) continue;
      final until = DateTime.tryParse(value);
      if (until != null && _serverNow().isBefore(until)) {
        _cooldownUntil[type] = until;
      }
    }
  }

  /// サーバーが現在時刻で判定したクールタイムを復元します。
  void _restoreServerCooldowns(Object? rawCooldowns) {
    if (rawCooldowns is! Map) return;
    _cooldownUntil.clear();
    for (final entry in rawCooldowns.entries) {
      final type = _actionTypeFromCode(entry.key.toString());
      final value = entry.value;
      if (type == null || value is! String) continue;
      final until = DateTime.tryParse(value);
      if (until != null && _serverNow().isBefore(until)) {
        _cooldownUntil[type] = until;
      }
    }
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
    if (_isDisposed) return;
    final positions = await _serverProvider.fetchUnlockedPositions();
    if (_isDisposed) return;
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
        'growth'
      ][(_pendingStageIndex ?? stageIndex.value).clamp(0, 3).toInt()];

  /// サーバー段階コードを画面段階番号へ変換します。
  int? _stageIndexFromCode(Object? stageCode) => const {
        'egg': 0,
        'child': 1,
        'training': 2,
        'growth': 3,
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
    bool force = false,
  }) {
    if ((_isDisposed && !force) || _syncBlockedUntilServerRestore) {
      return Future<void>.value();
    }
    // 連続操作中も各アクションを順番に保持し、効果を失わないようにします。
    if (action != null) _queuedActions.add((type: action, result: miniGameResult));
    _syncRequested = true;
    _hasUnsyncedLocalState = true;
    _localStateRevision++;
    if (_syncRunning) return _syncChain;
    _syncRunning = true;
    _syncChain = _drainSyncQueue().catchError((_) {
      // 同期失敗時も画面上のローカル状態を保持します。
    });
    TrainingGameProvider.registerPendingSync(_syncChain);
    unawaited(_syncChain);
    return _syncChain;
  }

  /// 保留中の同期要求を1回の通信へ集約します。
  Future<void> _drainSyncQueue() async {
    try {
      while (_syncRequested || _queuedActions.isNotEmpty) {
        _syncRequested = false;
        final pending = _queuedActions.isEmpty ? null : _queuedActions.removeAt(0);
        await syncNow(action: pending?.type, miniGameResult: pending?.result);
      }
    } finally {
      _syncRunning = false;
    }
  }

  /// 画面離脱時の同期をキューへ追加します。
  void syncInBackground() {
    _queueSync();
  }

  /// 画面終了前に最新状態の同期完了を待ちます。
  Future<void> syncNow({TrainingActionType? action, MiniGameResult? miniGameResult}) async {
    // 仕事はサーバー受理前に楽観更新するため、その結果が確定するまで
    // 退室など別経路の同期で増分を送信しないようにします。
    if (_syncBlockedUntilServerRestore ||
        (_isWorkSyncPending && action != TrainingActionType.work)) {
      return;
    }
    if (_serverPlayerId == null) {
      await _startServerState();
      return;
    }
    // 後続の行動と区別できるよう、この通信が受け取る状態世代を記録します。
    final syncingRevision = _localStateRevision;
    // APIに未保存の進行カウンターも、通信失敗時に失わないよう先に保持します。
    _hasUnsyncedLocalState = true;
    await _saveLocalGameState();
    final isPositiveEnd = clearPosition.value != null;
    try {
      final data = await _serverProvider.sync(
        stageCode: _stageCode,
        parameters: _serverParameters,
        lockVersion: _serverLockVersion,
        positionCode: _positionCode,
        branchCode: _branchCode,
        actionCode: action == null ? null : _actionCode(action),
        actionScore: miniGameResult?.score,
        actionEffectMultiplier: miniGameResult?.effectMultiplier,
        status: isPositiveEnd
            ? 'positive_end'
            : ended.value
                ? 'negative_end'
                : 'playing',
      );
      _serverLockVersion =
          (data['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
      _restoreWorkAvailability(data);
      if (syncingRevision == _localStateRevision) {
        _hasUnsyncedLocalState = false;
        _applyServerState(data);
      }
      // 後続行動がなければサーバー優先へ戻し、ある場合は未送信状態を保持します。
      _hasUnsyncedLocalState = syncingRevision != _localStateRevision;
      await _saveLocalGameState();
      // 図鑑はポジティブ終了時だけ再取得し、通常同期の余分な通信を省きます。
      if (isPositiveEnd && !_isDisposed) await refreshUnlockedPositions();
    } catch (_) {
      if (action == TrainingActionType.work) {
        // サーバーに拒否された楽観更新を捨てます。後続アクションで、
        // 拒否済み仕事のメーター増分を保存してしまうことを防ぎます。
        _isWorkAvailable = false;
        _hasUnsyncedLocalState = false;
        // _initializeServerState内のローカル復元で、同期直前の楽観更新を
        // 再適用しないよう、対象スナップショットを先に破棄します。
        await MySharedPref.clearTrainingGameLocalState();
        try {
          final serverData = await _serverProvider.fetchCurrent();
          if (serverData != null && !_isDisposed) {
            _initializeServerState(serverData);
          }
        } catch (_) {
          // サーバー状態を取得できるまで画面操作を停止します。拒否済み仕事の
          // 楽観更新を残したまま、別アクションで同期することを防ぎます。
          if (!_isDisposed) {
            _syncBlockedUntilServerRestore = true;
            isServerStateReady.value = false;
            serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
          }
        }
        await _saveLocalGameState();
      } else if (!_isDisposed) {
        await _restoreAuthoritativeStateAfterSyncFailure();
      }
      rethrow;
    } finally {
      if (action == TrainingActionType.work) _isWorkSyncPending = false;
    }
  }

  /// 同期に失敗した場合は端末側の先行変更を破棄し、サーバー状態へ戻します。
  Future<void> _restoreAuthoritativeStateAfterSyncFailure() async {
    _pendingStageIndex = null;
    _pendingStageSyncQueued = false;
    await MySharedPref.clearTrainingGameLocalState();
    try {
      final data = await _serverProvider.fetchCurrent();
      if (!_isDisposed && data != null) _initializeServerState(data);
    } catch (_) {
      if (!_isDisposed) {
        isServerStateReady.value = false;
        serverErrorMessage.value = '通信状態を確認して、もう一度お試しください。';
      }
    }
  }

  /// 同じ育成サイクルだけを対象に、途中進行のローカル復元情報を保存します。
  Future<void> _saveLocalGameState() {
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
        for (final entry in _cooldownUntil.entries)
          if (_serverNow().isBefore(entry.value))
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
  String _actionCode(TrainingActionType type) => const {
        TrainingActionType.meal: 'meal',
        TrainingActionType.clean: 'clean',
        TrainingActionType.rest: 'rest',
        TrainingActionType.squat: 'training',
        TrainingActionType.work: 'work',
        TrainingActionType.tackle: 'tackle',
        TrainingActionType.passAndRun: 'pass_run',
      }[type]!;

  /// 保存済みコードを行動種別へ戻します。
  TrainingActionType? _actionTypeFromCode(String code) => const {
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
    if (type != TrainingActionType.tackle &&
        type != TrainingActionType.passAndRun) return;
    final expectedType = type == TrainingActionType.tackle
        ? MiniGameType.tackle
        : MiniGameType.passAndRun;
    if (result.type != expectedType) return;
    perform(type, miniGameResult: result);
  }

  /// 指定した行動を実行し、メーターと傾向値を更新します。
  void perform(TrainingActionType type, {MiniGameResult? miniGameResult}) {
    if (ended.value || evolutionStage.value != null) return;
    if (_pendingStageIndex != null) {
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
    if (type == TrainingActionType.work && !canWorkToday) {
      logs.insert(0, '仕事は1日1回までです。');
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
        _changeMeter('清潔', 40);
        _addTrend('TECH', 2, '体調');
        break;
      case TrainingActionType.rest:
        _changeMeter('体調', 40);
        _changeMeter('食事', -5);
        break;
      case TrainingActionType.squat:
        _changeMeter('食事', -12);
        _changeMeter('清潔', -8);
        _changeMeter('体調', -6);
        _addTrend('FW', 3, '食事', sourceOffset: 12, training: true);
        _addTrend('BULK', 2, '食事', sourceOffset: 12, training: true);
        break;
      case TrainingActionType.tackle:
        _changeMeter('清潔', -12);
        _changeMeter('体調', -12);
        _changeMeter('食事', -8);
        _changeMeter('仕事', 10 * miniGameMultiplier);
        _addTrend('FW', 5 * miniGameMultiplier, '体調',
            sourceOffset: 12, training: true);
        _addTrend('BULK', 1 * miniGameMultiplier, '体調',
            sourceOffset: 12, training: true);
        break;
      case TrainingActionType.passAndRun:
        _changeMeter('清潔', -10);
        _changeMeter('体調', -10);
        _changeMeter('食事', -10);
        _changeMeter('仕事', 10 * miniGameMultiplier);
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
        break;
      case TrainingActionType.work:
        _changeMeter('食事', -10);
        _changeMeter('体調', -10);
        _changeMeter('仕事', 30);
        _addTrend('TECH', 6, '体調', sourceOffset: 10);
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

  /// 指定時間を進め、自然減衰と段階移行を処理します。
  void advanceTime(int hours) {
    advanceTimeMinutes(hours * 60);
  }

  /// 指定した分数を進め、自然減衰と段階移行を処理します。
  void advanceTimeMinutes(int minutes) {
    if (minutes <= 0 ||
        ended.value ||
        evolutionStage.value != null ||
        _pendingStageIndex != null) {
      return;
    }
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
    if (day.value > previousDay) {
      final previousSync = _debugTimeSync ?? Future<void>.value();
      final sync = previousSync.then((_) => _syncDebugTimeAndResetDailyActions());
      _debugTimeSync = sync;
      unawaited(sync.whenComplete(() {
        if (identical(_debugTimeSync, sync)) _debugTimeSync = null;
      }));
    } else {
      _syncServer();
    }
  }

  /// デバッグでゲーム内日付を進めた場合だけ、日次アクション制限も解除します。
  Future<void> _syncDebugTimeAndResetDailyActions() async {
    try {
      await TrainingGameProvider.waitForPendingSync();
      await syncNow();
      final data = await _serverProvider.resetDebugDailyActionUsage();
      if (!_isDisposed) _initializeServerState(data);
    } catch (_) {
      if (!_isDisposed) {
        logs.insert(0, 'デバッグ用の日次アクション制限をリセットできませんでした。');
      }
    }
  }

  /// デバッグ操作として育成期の初期状態にします。
  Future<void> debugStartAtTraining() async {
    if (_pendingStageIndex != null) return;
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
      );
      if (_isDisposed) return;
      _resetLocalProgressForNewCycle();
      _initializeServerState(data);
    } catch (_) {
      if (!_isDisposed) logs.insert(0, '育成期のデバッグ開始に失敗しました。');
    }
  }

  /// メーターを範囲内に収めて更新します。
  void _changeMeter(String name, double amount) {
    // 可視パラメータは仕様どおり整数相当の0〜100で保持します。
    meters[name] = (meters[name]! + amount).clamp(0, 150).toDouble();
  }

  /// 行動完了時点からクールタイムを開始します。
  void _startCooldown(TrainingActionType type) {
    if (!isCooldownEnabled(type)) return;
    _cooldownUntil[type] = _serverNow().add(careCooldown);
  }

  /// 傾向値を0未満にならないよう更新します。
  void _changeTrend(String name, double amount) {
    // 育成傾向も仕様上の上限100を超えないようにします。
    trends[name] = (trends[name]! + amount).clamp(0, 999).toDouble();
  }

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
        !['食事', '清潔', '体調'].every((name) => meters[name]! >= 50)) {
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
    final ready = stageIndex.value == 0
        ? secondsInStage.value >= 180 &&
            meters['清潔']! >= 60 &&
            meters['体調']! >= 60
        : trainingCount.value >= 15 &&
            ['食事', '清潔', '体調'].every((name) => meters[name]! >= 60);
    if (!ready) return;
    _pendingStageIndex = stageIndex.value + 1;
    secondsInStage.value = 0;
    trainingCount.value = 0;
    actionsToday.value = 0;
    logs.insert(0, '成長しました。段階「${currentStage.name}」へ進みます。');
    _queuePendingStageSync();
    // タイマー起点の段階上昇でも同期を開始します。行動同期が先に積まれた場合は重複させません。
    unawaited(Future<void>.microtask(() {
      if (!_syncRunning && _queuedActions.isEmpty && _pendingStageIndex != null) {
        _syncServer();
      }
    }));
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
    // 育成期は実時間4時間をゲーム内の1日として扱います。
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
    if (stageIndex.value < 2 ||
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

  /// 本編1時間分の日次判定だけを進めます。自然減衰はサーバーが確定します。
  void _tickActiveMainHour() {
    elapsedHours.value++;
    if (elapsedHours.value % mainDayHours != 0) return;

    day.value++;
    if (_dayCared) daysInStage.value++;
    _dayCared = false;
    actionsToday.value = 0;
    _advanceMainStageIfNeeded();
  }

  /// デバッグで手動加算した時間を、実時間処理済みとして扱います。
  void _markActiveMainProgressAsProcessed() {
    final base = _activeMainProgressBaseSeconds;
    if (base == null) return;
    final elapsedSeconds = _currentServerElapsedSeconds - base;
    _processedActiveMainHours =
        elapsedSeconds < 0 ? 0 : elapsedSeconds ~/ 3600;
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
    mainElapsedSeconds.value =
        _serverElapsedSeconds +
        _elapsedTimeOffsetSeconds +
        ServerTimeClock.instance.elapsedSinceSync.inSeconds;
  }

  /// チュートリアルの倍速設定を時計へ反映します。
  void _advanceTutorialClock(int speed) {
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
    final requiredDays = currentStage.days;
    if (requiredDays == null || daysInStage.value < requiredDays) return;
    if (stageIndex.value < stages.length - 1) {
      if (_pendingStageIndex != null) return;
      _pendingStageIndex = stageIndex.value + 1;
      daysInStage.value = 0;
      logs.insert(0, '成長条件を満たしました。サーバー確認後に次の段階へ進みます。');
      _queuePendingStageSync();
      return;
    }
    if (position == '判定前') {
      // 傾向未成立のまま図鑑登録せず、次の世話・練習で再判定できる状態を維持します。
      daysInStage.value = requiredDays - 1;
      logs.insert(0, 'ポジション判定には練習による傾向値の獲得が必要です。');
      return;
    }
    _endGame(
      endingStep: 0,
      message: '育成完了。${position}として図鑑に登録されました。',
      clearPosition: position,
    );
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
    logs.insert(0, 'ゲームオーバー：体調が0になりました。');
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
    try {
      await _queueSync();
      if (_isDisposed) return;
      final current = await _serverProvider.fetchCurrent();
      if (current != null) {
        throw StateError('終了状態がサーバーへ反映されていません。');
      }
    } catch (_) {
      if (!_isDisposed) {
        endingSyncError.value =
            '終了状態を保存できません。通信状態を確認して再試行してください。';
      }
    } finally {
      if (!_isDisposed) isEndingSyncPending.value = false;
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
