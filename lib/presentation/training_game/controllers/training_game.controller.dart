import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
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
  int _lastWorkDay = 0;
  int _lowConditionTraining = 0;
  bool _dayCared = false;
  final _zeroHours = <String, int>{'食事': 0, '清潔': 0, '体調': 0, '仕事': 0};
  final _overHours = <String, int>{'食事': 0, '清潔': 0, '体調': 0, '仕事': 0};
  final _cooldownUntil = <TrainingActionType, DateTime>{};
  final _tutorialZeroSeconds = <String, int>{'食事': 0, '清潔': 0, '体調': 0};
  Timer? _tutorialTimer;
  Timer? _mainTimer;
  DateTime? _mainStartedAt;
  DateTime? _mainProgressAt;
  int _elapsedTimeOffsetSeconds = 0;
  final _mainClockTick = 0.obs;
  bool _isAppInBackground = false;
  Future<void> _syncChain = Future<void>.value();
  Future<void> _restoreChain = Future<void>.value();
  TrainingActionType? _queuedAction;
  bool _syncRequested = false;
  bool _syncRunning = false;
  bool _hasUnsyncedLocalState = false;
  int _localStateRevision = 0;
  bool _isDisposed = false;
  final TrainingGameProvider _serverProvider = TrainingGameProvider();
  int? _serverPlayerId;
  int _serverLockVersion = 0;

  /// 現在の段階定義を返します。
  TrainingStageDefinition get currentStage => stages[stageIndex.value];

  /// 当日の仕事が未実施で、仕事のお世話を開始できるかを返します。
  bool get canWorkToday => _lastWorkDay != day.value;

  /// 指定行動のクールタイムが終了しているかを返します。
  bool canPerform(TrainingActionType type) {
    cooldownTick.value;
    if (!isCooldownEnabled(type)) return true;
    final until = _cooldownUntil[type];
    return until == null || !DateTime.now().isBefore(until);
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
    final remaining = until.difference(DateTime.now());
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
    final elapsedSeconds = _mainStartedAt == null
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
    if (ended.value) return '🦈';
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
          stageIndex.value < 2 &&
          !ended.value) {
        _advanceTutorialClock(timeSpeed.value);
        tickTutorial(timeSpeed.value);
      }
    });
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      cooldownTick.value++;
      if (isServerStateReady.value && !_isAppInBackground) {
        _mainClockTick.value++;
        if (stageIndex.value >= 2) {
          _advanceMainClock(timeSpeed.value);
        } else {
          _updateElapsedTimeFromStart();
        }
        _advanceMainProgressToNow();
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
    _queueSync(force: true);
    super.onClose();
  }

  /// 育成完了後の演出フローを次へ進めます。
  void advanceEndingStep() {
    if (ended.value) endingStep.value++;
  }

  /// 段階上昇時の進化演出を完了し、育成画面へ戻します。
  void advanceEvolution() {
    evolutionStage.value = null;
    if (stageIndex.value >= 2) {
      _mainProgressAt = DateTime.now();
      _updateElapsedTimeFromStart();
      _mainClockTick.value++;
    }
  }

  /// 育成画面を離れる前にローカルのリアルタイム進行を停止します。
  void pauseLocalProgress() {
    _isAppInBackground = true;
  }

  /// アプリがバックグラウンドへ移る前に育成状態を保存します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isAppInBackground = true;
      _queueSync();
    }
    if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      // オフライン中の精算はサーバー状態の再取得へ一元化し、端末側の二重減衰を防ぎます。
      unawaited(_restoreServerState());
    }
  }

  /// サーバーに保存された育成状態を復元し、なければ新規作成します。
  Future<void> _restoreServerState() async {
    // 復帰イベントが短時間に複数回発生しても、取得処理を直列化します。
    _restoreChain = _restoreChain.then((_) async {
      if (_isDisposed) return;
      // 復帰直前のローカル操作を先に保存してからサーバー状態を読み込みます。
      await _syncChain;
      final data = await _serverProvider.fetchCurrent();
      if (_isDisposed) return;
      if (data == null) {
        await _startServerState();
      } else {
        _initializeServerState(data);
      }
      isServerStateReady.value = true;
    }).catchError((_) {
      // オフライン時は既存のローカル進行を維持します。
      if (!_isDisposed) isServerStateReady.value = true;
    });
    await _restoreChain;
  }

  /// 初期状態をサーバーへ保存します。
  Future<void> _startServerState() async {
    final data = await _serverProvider.start(
      stageCode: _stageCode,
      parameters: _serverParameters,
    );
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    _applyServerState(data);
    _refreshUnlockedPositionsInBackground();
  }

  /// 取得済みのサーバー状態を初期表示へ反映します。
  void _initializeServerState(Map<String, dynamic> data) {
    _serverPlayerId = (data['id'] as num?)?.toInt();
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? 0;
    _applyServerState(data);
    isServerStateReady.value = true;
    _refreshUnlockedPositionsInBackground();
  }

  /// APIレスポンスの状態を画面状態へ反映します。
  void _applyServerState(Map<String, dynamic> data) {
    final startedAt = _parseServerDateTime(data['started_at']) ??
        MySharedPref.getTrainingGameStartedAt();
    if (startedAt != null) {
      _mainStartedAt = startedAt;
      // サーバー状態を再取得しても、同じ育成サイクルのデバッグ加算を復元します。
      _elapsedTimeOffsetSeconds =
          MySharedPref.getTrainingGameDebugElapsedSeconds();
      unawaited(MySharedPref.setTrainingGameStartedAt(startedAt));
      _updateElapsedTimeFromStart();
    }
    final stage = data['stage_code'] as String?;
    final stageMap = {'egg': 0, 'child': 1, 'training': 2, 'growth': 3};
    if (stage != null && stageMap.containsKey(stage))
      stageIndex.value = stageMap[stage]!;
    if (stageIndex.value >= 2 && _mainProgressAt == null) {
      _mainProgressAt = DateTime.now();
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
        if (displayName != null) meters[displayName] = value;
        if (tendencyName != null) trends[tendencyName] = value;
      }
    }
    _restoreLocalGameState(data);
    _restoreEndedState(data);
  }

  /// サーバーに未保存の途中進行を、同じ育成サイクルに限って復元します。
  void _restoreLocalGameState(Map<String, dynamic> serverData) {
    final encodedState = MySharedPref.getTrainingGameLocalState();
    if (encodedState == null || _serverPlayerId == null) return;
    final decodedState = jsonDecode(encodedState);
    if (decodedState is! Map) return;
    final localState = Map<String, dynamic>.from(decodedState);
    if (localState['player_id'] != _serverPlayerId) return;

    _hasUnsyncedLocalState = localState['has_unsynced_state'] == true;
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

    elapsedHours.value = _localInt(localState, 'elapsed_hours', elapsedHours.value);
    totalElapsedSeconds.value =
        _localInt(localState, 'total_elapsed_seconds', totalElapsedSeconds.value);
    mainElapsedSeconds.value =
        _localInt(localState, 'main_elapsed_seconds', mainElapsedSeconds.value);
    day.value = _localInt(localState, 'day', day.value);
    secondsInStage.value =
        _localInt(localState, 'seconds_in_stage', secondsInStage.value);
    daysInStage.value =
        _localInt(localState, 'days_in_stage', daysInStage.value);
    actionsToday.value =
        _localInt(localState, 'actions_today', actionsToday.value);
    trainingCount.value =
        _localInt(localState, 'training_count', trainingCount.value);
    _lastWorkDay = _localInt(localState, 'last_work_day', _lastWorkDay);
    _lowConditionTraining =
        _localInt(localState, 'low_condition_training', _lowConditionTraining);
    _dayCared = localState['day_cared'] == true;
    _restoreCooldowns(localState['cooldowns']);
    _restoreCounters(localState['zero_hours'], _zeroHours);
    _restoreCounters(localState['over_hours'], _overHours);
    _restoreCounters(localState['tutorial_zero_seconds'], _tutorialZeroSeconds);
    ended.value = localState['ended'] == true;
    endingStep.value = _localInt(localState, 'ending_step', endingStep.value);
    endingMessage.value = localState['ending_message'] as String? ?? endingMessage.value;
    clearPosition.value = localState['clear_position'] as String?;
  }

  /// サーバーが返す終了状態をローカル表示へ反映します。
  void _restoreEndedState(Map<String, dynamic> data) {
    final status = data['status'] as String?;
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
      if (until != null && DateTime.now().isBefore(until)) {
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
      ][stageIndex.value.clamp(0, 3).toInt()];

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
  void _syncServer({TrainingActionType? action}) {
    _queueSync(action: action);
  }

  /// 同期を順番に実行し、同時更新競合を防ぎます。
  void _queueSync({TrainingActionType? action, bool force = false}) {
    if (_isDisposed && !force) return;
    // 連続操作中は最新状態と最後の行動だけを保持し、古い同期を捨てます。
    _queuedAction = action ?? _queuedAction;
    _syncRequested = true;
    _hasUnsyncedLocalState = true;
    _localStateRevision++;
    if (_syncRunning) return;
    _syncRunning = true;
    _syncChain = _drainSyncQueue().catchError((_) {
      // 同期失敗時も画面上のローカル状態を保持します。
    });
    TrainingGameProvider.registerPendingSync(_syncChain);
    unawaited(_syncChain);
  }

  /// 保留中の同期要求を1回の通信へ集約します。
  Future<void> _drainSyncQueue() async {
    try {
      while (_syncRequested) {
        _syncRequested = false;
        final action = _queuedAction;
        _queuedAction = null;
        await syncNow(action: action);
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
  Future<void> syncNow({TrainingActionType? action}) async {
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
    final data = await _serverProvider.sync(
      stageCode: _stageCode,
      parameters: _serverParameters,
      lockVersion: _serverLockVersion,
      positionCode: _positionCode,
      branchCode: _branchCode,
      actionCode: action == null ? null : _actionCode(action),
      status: isPositiveEnd
          ? 'positive_end'
          : ended.value
              ? 'negative_end'
              : 'playing',
    );
    _serverLockVersion =
        (data['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
    // 後続行動がなければサーバー優先へ戻し、ある場合は未送信状態を保持します。
    _hasUnsyncedLocalState = syncingRevision != _localStateRevision;
    await _saveLocalGameState();
    // 図鑑はポジティブ終了時だけ再取得し、通常同期の余分な通信を省きます。
    if (isPositiveEnd && !_isDisposed) await refreshUnlockedPositions();
  }

  /// 同じ育成サイクルだけを対象に、途中進行のローカル復元情報を保存します。
  Future<void> _saveLocalGameState() {
    final playerId = _serverPlayerId;
    if (playerId == null) return Future<void>.value();
    return MySharedPref.setTrainingGameLocalState(jsonEncode({
      'player_id': playerId,
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
      'last_work_day': _lastWorkDay,
      'low_condition_training': _lowConditionTraining,
      'day_cared': _dayCared,
      'zero_hours': _zeroHours,
      'over_hours': _overHours,
      'tutorial_zero_seconds': _tutorialZeroSeconds,
      'cooldowns': {
        for (final entry in _cooldownUntil.entries)
          if (DateTime.now().isBefore(entry.value))
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
    if (type == TrainingActionType.work && _lastWorkDay == day.value) {
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
    final wasCleanNoop =
        type == TrainingActionType.clean && meters['清潔']! >= 100;
    final miniGameMultiplier = miniGameResult?.effectMultiplier ?? 1.0;
    final workBeforeAction = meters['仕事']!;

    switch (type) {
      case TrainingActionType.meal:
        _changeMeter('食事', 35);
        _changeMeter('清潔', -3);
        break;
      case TrainingActionType.clean:
        // 清潔度100以上では掃除を空振り扱いにし、行動回数だけ消費します。
        if (!wasCleanNoop) {
          _changeMeter('清潔', 40);
          _addTrend('TECH', 2, '体調');
        }
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
        _lastWorkDay = day.value;
        break;
    }
    if (_isTraining(type) && wasOverfed) {
      _changeTrend('BULK', 1);
      _changeTrend('RUN', -.5);
    }
    logs.insert(
      0,
      wasCleanNoop
          ? '掃除をしましたが、部屋は汚れていないため効果はありません。'
          : miniGameResult == null
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
    _syncServer(action: type);
  }

  /// 指定時間を進め、自然減衰と段階移行を処理します。
  void advanceTime(int hours) {
    advanceTimeMinutes(hours * 60);
  }

  /// 指定した分数を進め、自然減衰と段階移行を処理します。
  void advanceTimeMinutes(int minutes) {
    if (minutes <= 0 || ended.value || evolutionStage.value != null) return;
    // デバッグ加算分も表示用の経過時間へ反映し、内部進行と時計を一致させます。
    _elapsedTimeOffsetSeconds += minutes * 60;
    unawaited(MySharedPref.setTrainingGameDebugElapsedSeconds(
        _elapsedTimeOffsetSeconds));
    final progressAt = _mainProgressAt ??= DateTime.now();
    _mainProgressAt = progressAt.subtract(Duration(minutes: minutes));
    _mainClockTick.value++;
    _advanceMainProgressToNow();
    logs.insert(0, '${minutes}分経過。メーターが自然に減少しました。');
    if (!_isDisposed) _syncServer();
  }

  /// デバッグ操作として育成期の初期状態にします。
  void debugStartAtTraining() {
    stageIndex.value = 2;
    meters.assignAll({'食事': 20, '清潔': 20, '体調': 20, '仕事': 20});
    trends.assignAll({'FW': 0, 'CMD': 0, 'RUN': 0, 'BULK': 0, 'TECH': 0});
    elapsedHours.value = 0;
    totalElapsedSeconds.value = 0;
    mainElapsedSeconds.value = 0;
    day.value = 1;
    secondsInStage.value = 0;
    daysInStage.value = 0;
    actionsToday.value = 0;
    trainingCount.value = 0;
    timeSpeed.value = 1;
    _dayCared = false;
    _lowConditionTraining = 0;
    _zeroHours.updateAll((key, value) => 0);
    _overHours.updateAll((key, value) => 0);
    _tutorialZeroSeconds.updateAll((key, value) => 0);
    _cooldownUntil.clear();
    ended.value = false;
    endingMessage.value = '';
    clearPosition.value = null;
    endingStep.value = 0;
    evolutionStage.value = null;
    // デバッグ開始を仮想サイクルの開始時刻とし、実運用のstarted_atと同じ経路で計測します。
    _mainStartedAt = DateTime.now();
    _mainProgressAt = DateTime.now();
    _elapsedTimeOffsetSeconds = 0;
    unawaited(MySharedPref.clearTrainingGameDebugElapsedSeconds());
    unawaited(MySharedPref.setTrainingGameStartedAt(_mainStartedAt!));
    _updateElapsedTimeFromStart();
    // デバッグ開始直後から本編のリアルタイム時計を再描画します。
    _mainClockTick.value++;
    _syncServer();
  }

  /// メーターを範囲内に収めて更新します。
  void _changeMeter(String name, double amount) {
    meters[name] = (meters[name]! + amount).clamp(0, 150).toDouble();
  }

  /// 行動完了時点からクールタイムを開始します。
  void _startCooldown(TrainingActionType type) {
    if (!isCooldownEnabled(type)) return;
    _cooldownUntil[type] = DateTime.now().add(careCooldown);
  }

  /// 傾向値を0未満にならないよう更新します。
  void _changeTrend(String name, double amount) {
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
    if (meters['体調']! > 100) return;
    final sourceValue = meters[source]! + sourceOffset;
    var coefficient = sourceValue >= 80
        ? 1.4
        : sourceValue >= 50
            ? 1.0
            : sourceValue >= 20
                ? .6
                : .2;
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
    if (seconds <= 0 || evolutionStage.value != null) return;
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
        ended.value = true;
        // チュートリアル失敗時は進化演出を挟まず、引退画面へ直接進みます。
        endingStep.value = 2;
        endingMessage.value = 'チュートリアル失敗。卵からやりなおしてください。';
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
    final ready = stageIndex.value == 0
        ? secondsInStage.value >= 180 &&
            meters['清潔']! >= 60 &&
            meters['体調']! >= 60
        : trainingCount.value >= 15 &&
            ['食事', '清潔', '体調'].every((name) => meters[name]! >= 60);
    if (!ready) return;
    stageIndex.value++;
    _showEvolutionForCurrentStage();
    secondsInStage.value = 0;
    trainingCount.value = 0;
    actionsToday.value = 0;
    logs.insert(0, '成長しました。段階「${currentStage.name}」へ進みます。');
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
    _overHours.updateAll((name, hours) => meters[name]! > 100 ? hours + 1 : 0);
    _dayCared = _dayCared ||
        ['食事', '清潔', '体調', '仕事'].every((name) => meters[name]! >= 20);
    // 育成期は実時間4時間をゲーム内の1日として扱います。
    if (elapsedHours.value % mainDayHours == 0) {
      day.value++;
      if (_dayCared) daysInStage.value++;
      _dayCared = false;
      actionsToday.value = 0;
      _lastWorkDay = 0;
      _advanceMainStageIfNeeded();
    }
    _checkGameOver();
  }

  /// 本編開始後に実時間で経過した時間を反映します。
  void _advanceMainProgressToNow() {
    if (stageIndex.value < 2 || ended.value || evolutionStage.value != null)
      return;
    final progressAt = _mainProgressAt ??= DateTime.now();
    final elapsedSeconds = DateTime.now().difference(progressAt).inSeconds;
    if (elapsedSeconds < 0) {
      // 端末時計が巻き戻された場合、過去の基準時刻を待たず現在から進行を再開します。
      _mainProgressAt = DateTime.now();
      _updateElapsedTimeFromStart();
      return;
    }
    // 卵段階と同じく、鮫になった後も毎秒の実時間を画面状態へ反映します。
    _updateElapsedTimeFromStart();
    final elapsedHours = elapsedSeconds ~/ Duration.secondsPerHour;
    if (elapsedHours <= 0) return;
    for (var index = 0; index < elapsedHours; index++) {
      _tickMainHour();
      if (ended.value || evolutionStage.value != null) break;
    }
    _mainProgressAt = progressAt.add(Duration(hours: elapsedHours));
    _updateElapsedTimeFromStart();
    _syncServer();
  }

  /// サーバーの育成開始日時を基準に、画面へ表示する経過秒数を更新します。
  void _updateElapsedTimeFromStart() {
    final startedAt = _mainStartedAt;
    if (startedAt == null) return;
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    final currentElapsedSeconds =
        (elapsedSeconds < 0 ? 0 : elapsedSeconds) + _elapsedTimeOffsetSeconds;
    // 端末時計の巻き戻しで表示中の経過時間が減少しないよう維持します。
    if (currentElapsedSeconds >= mainElapsedSeconds.value) {
      mainElapsedSeconds.value = currentElapsedSeconds;
    }
  }

  /// チュートリアルの倍速設定を時計へ反映します。
  void _advanceTutorialClock(int speed) {
    // 実時間との差分を補正し、停止・倍速でも表示とメーターの進行を一致させます。
    _elapsedTimeOffsetSeconds += speed - 1;
    _updateElapsedTimeFromStart();
  }

  /// 育成期・成長期の倍速設定を時計と本編進行へ反映します。
  void _advanceMainClock(int speed) {
    _elapsedTimeOffsetSeconds += speed - 1;
    final progressAt = _mainProgressAt;
    if (progressAt != null) {
      // 基準時刻をずらし、次の本編更新でも同じ倍率の経過時間を扱います。
      _mainProgressAt = progressAt.subtract(Duration(seconds: speed - 1));
    }
    _updateElapsedTimeFromStart();
  }

  /// APIのISO日時を端末のローカル時刻へ変換します。
  DateTime? _parseServerDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  /// 「世話が行き届いた日」7日で本編段階を進めます。
  void _advanceMainStageIfNeeded() {
    final requiredDays = currentStage.days;
    if (requiredDays == null || daysInStage.value < requiredDays) return;
    if (stageIndex.value < stages.length - 1) {
      stageIndex.value++;
      _showEvolutionForCurrentStage();
      daysInStage.value = 0;
      logs.insert(0, '成長しました。段階「${currentStage.name}」へ進みます。');
      return;
    }
    if (position == '判定前') {
      // 傾向未成立のまま図鑑登録せず、次の世話・練習で再判定できる状態を維持します。
      daysInStage.value = requiredDays - 1;
      logs.insert(0, 'ポジション判定には練習による傾向値の獲得が必要です。');
      return;
    }
    ended.value = true;
    clearPosition.value = position;
    endingStep.value = 0;
    endingMessage.value = '育成完了。${position}として図鑑に登録されました。';
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
    final overLimit = <String, int>{'食事': 72, '仕事': 72};
    final zeroTarget = _findExceeded(_zeroHours, zeroLimit);
    final overTarget = _findExceeded(_overHours, overLimit);
    if (zeroTarget == null && overTarget == null && _lowConditionTraining < 15)
      return;
    ended.value = true;
    endingStep.value = 2;
    endingMessage.value = zeroTarget != null
        ? '${zeroTarget.key}が0のまま${zeroTarget.value}時間経過しました。'
        : overTarget != null
            ? '${overTarget.key}が過剰のまま${overTarget.value}時間経過しました。'
            : '体調20未満での練習が15回になりました。';
    logs.insert(0, 'ゲームオーバー：体調が0になりました。');
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
