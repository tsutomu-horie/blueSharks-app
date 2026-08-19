import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';

import '../mini_games/models/mini_game_result.dart';
import '../models/training_game_models.dart';

/// 育成ゲームの進行状態と行動結果を管理します。
class TrainingGameController extends GetxController with WidgetsBindingObserver {
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
  final trainingCount = 0.obs;
  final tutorialSpeed = 1.obs;
  final isServerStateReady = false.obs;
  int _lastWorkDay = 0;
  int _lowConditionTraining = 0;
  bool _dayCared = false;
  final _zeroHours = <String, int>{'食事': 0, '清潔': 0, '体調': 0, '仕事': 0};
  final _overHours = <String, int>{'食事': 0, '清潔': 0, '体調': 0, '仕事': 0};
  final _tutorialZeroSeconds = <String, int>{'食事': 0, '清潔': 0, '体調': 0};
  Timer? _tutorialTimer;
  bool _isAppInBackground = false;
  Future<void> _syncChain = Future<void>.value();
  Future<void> _restoreChain = Future<void>.value();
  TrainingActionType? _queuedAction;
  bool _syncRequested = false;
  bool _syncRunning = false;
  bool _isDisposed = false;
  final TrainingGameProvider _serverProvider = TrainingGameProvider();
  int? _serverPlayerId;
  int _serverLockVersion = 0;

  /// 現在の段階定義を返します。
  TrainingStageDefinition get currentStage => stages[stageIndex.value];

  /// 参照HTMLと同じ形式で現在時刻を表示します。
  String get clockLabel {
    if (stageIndex.value < 2) {
      final minutes = (secondsInStage.value ~/ 60).toString().padLeft(2, '0');
      final seconds = (secondsInStage.value % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    final hour = (elapsedHours.value % 24).toString().padLeft(2, '0');
    return '$hour:00';
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
    final main = {'FW': trends['FW']!, 'CMD': trends['CMD']!, 'RUN': trends['RUN']!};
    if (main.values.every((value) => value == 0) && trends['BULK'] == 0) return null;
    final top = main.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
    final main = {'FW': trends['FW']!, 'CMD': trends['CMD']!, 'RUN': trends['RUN']!};
    final ordered = main.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = main.values.reduce((a, b) => a + b);
    if (total == 0 && trends['BULK'] == 0) return '判定前';
    final top = ordered.first.key;
    final second = ordered[1].key;
    final purity = total == 0 ? 0 : ordered.first.value / total;
    final ratio = ordered.first.value == 0 ? 0 : ordered[1].value / ordered.first.value;
    final techBulk = trends['BULK'] == 0 ? 99 : trends['TECH']! / trends['BULK']!;
    final floor = main.values.reduce((a, b) => a < b ? a : b);
    if (purity < .5 && floor >= 30) return 'フルバック';
    if (top == 'FW' && second == 'RUN' && ratio >= .55) {
      return trends['TECH']! >= trends['BULK']! ? 'フランカー' : 'ナンバーエイト';
    }
    if (top == 'FW' && techBulk >= 1) return 'フッカー';
    if (top == 'FW' && techBulk >= .35) return 'ロック';
    if (top == 'FW') return 'プロップ';
    if (top == 'CMD') return ratio >= .4 ? 'スクラムハーフ' : 'スタンドオフ';
    return second == 'FW' && ratio >= .55 ? 'センター' : 'ウイング';
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
      if (isServerStateReady.value &&
          !_isAppInBackground &&
          evolutionStage.value == null &&
          stageIndex.value < 2 &&
          !ended.value) {
        tickTutorial(tutorialSpeed.value);
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
    final stage = data['stage_code'] as String?;
    final stageMap = {'egg': 0, 'child': 1, 'training': 2, 'growth': 3};
    if (stage != null && stageMap.containsKey(stage)) stageIndex.value = stageMap[stage]!;
    final parameters = data['parameters'];
    if (parameters is Map) {
      const displayMap = {'hunger': '食事', 'cleanliness': '清潔', 'condition': '体調', 'work': '仕事'};
      const tendencyMap = {'tendency_fw': 'FW', 'tendency_command': 'CMD', 'tendency_backs': 'RUN'};
      for (final entry in parameters.entries) {
        final value = (entry.value as num?)?.toDouble();
        if (value == null) continue;
        final displayName = displayMap[entry.key];
        final tendencyName = tendencyMap[entry.key];
        if (displayName != null) meters[displayName] = value;
        if (tendencyName != null) trends[tendencyName] = value;
      }
    }
  }

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
  String get _stageCode => ['egg', 'child', 'training', 'growth'][stageIndex.value.clamp(0, 3).toInt()];

  /// DB設計のパラメータコードへ変換します。
  Map<String, double> get _serverParameters => {
        'hunger': meters['食事']!,
        'cleanliness': meters['清潔']!,
        'condition': meters['体調']!,
        'work': meters['仕事']!,
        'tendency_fw': trends['FW']!,
        'tendency_command': trends['CMD']!,
        'tendency_backs': trends['RUN']!,
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
    _serverLockVersion = (data['lock_version'] as num?)?.toInt() ?? _serverLockVersion;
    // 図鑑はポジティブ終了時だけ再取得し、通常同期の余分な通信を省きます。
    if (isPositiveEnd && !_isDisposed) await refreshUnlockedPositions();
  }

  /// ポジション名をDBコードへ変換します。
  String? get _positionCode => const {
        'プロップ': 'prop', 'フッカー': 'hooker', 'ロック': 'lock', 'フランカー': 'flanker',
        'ナンバーエイト': 'number_eight', 'スクラムハーフ': 'scrum_half', 'スタンドオフ': 'stand_off',
        'センター': 'center', 'ウイング': 'wing', 'フルバック': 'fullback',
      }[position];

  /// 図鑑に登録済みかを返します。
  bool isPositionUnlocked(String positionName) {
    final code = const {
      'プロップ': 'prop', 'フッカー': 'hooker', 'ロック': 'lock', 'フランカー': 'flanker',
      'ナンバーエイト': 'number_eight', 'スクラムハーフ': 'scrum_half', 'スタンドオフ': 'stand_off',
      'センター': 'center', 'ウイング': 'wing', 'フルバック': 'fullback',
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
        TrainingActionType.meal: 'meal', TrainingActionType.clean: 'clean', TrainingActionType.rest: 'rest',
        TrainingActionType.squat: 'training', TrainingActionType.work: 'work', TrainingActionType.tackle: 'tackle',
        TrainingActionType.passAndRun: 'pass_run',
      }[type]!;

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
      _performTutorialAction(type);
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
        _addTrend('FW', 5 * miniGameMultiplier, '体調', sourceOffset: 12, training: true);
        _addTrend('BULK', 1 * miniGameMultiplier, '体調', sourceOffset: 12, training: true);
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
      miniGameResult == null
          ? '${_labelFor(type)}を実行しました。'
          : '${miniGameResult.summary}／育成結果へ反映しました。',
    );
    actionsToday.value++;
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
    if (ended.value || evolutionStage.value != null) return;
    for (var index = 0; index < hours; index++) {
      _tickMainHour();
      if (ended.value) return;
    }
    logs.insert(0, '${hours}時間経過。メーターが自然に減少しました。');
    _syncServer();
  }

  /// デバッグ操作としてチュートリアルを省略し、本編の初期状態にします。
  void debugSkipTutorial() {
    stageIndex.value = 2;
    meters.assignAll({'食事': 20, '清潔': 20, '体調': 20, '仕事': 20});
    trends.assignAll({'FW': 0, 'CMD': 0, 'RUN': 0, 'BULK': 0, 'TECH': 0});
    elapsedHours.value = 0;
    day.value = 1;
    secondsInStage.value = 0;
    daysInStage.value = 0;
    actionsToday.value = 0;
    trainingCount.value = 0;
    tutorialSpeed.value = 1;
    _dayCared = false;
    _lowConditionTraining = 0;
    _zeroHours.updateAll((key, value) => 0);
    _overHours.updateAll((key, value) => 0);
    _tutorialZeroSeconds.updateAll((key, value) => 0);
    ended.value = false;
    endingMessage.value = '';
    clearPosition.value = null;
    endingStep.value = 0;
    evolutionStage.value = null;
    _syncServer();
  }

  /// メーターを範囲内に収めて更新します。
  void _changeMeter(String name, double amount) {
    meters[name] = (meters[name]! + amount).clamp(0, 150).toDouble();
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
  void _performTutorialAction(TrainingActionType type) {
    if (stageIndex.value == 0 &&
        type != TrainingActionType.clean &&
        type != TrainingActionType.rest) return;
    if (stageIndex.value == 1 &&
        type == TrainingActionType.squat &&
        !['食事', '清潔', '体調'].every((name) => meters[name]! >= 50)) return;

    final activeMeters = stageIndex.value == 0
        ? ['清潔', '体調']
        : ['食事', '清潔', '体調'];
    final effects = <TrainingActionType, Map<String, double>>{
      TrainingActionType.meal: {'食事': 35, '清潔': -3},
      TrainingActionType.clean: {'清潔': 40},
      TrainingActionType.rest: {'体調': 40, '食事': -5},
      TrainingActionType.squat: {'食事': -12, '清潔': -8, '体調': -6},
    }[type];
    if (effects == null) return;

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
  }

  /// チュートリアルを参照HTMLと同じ秒単位で進めます。
  void tickTutorial(int seconds) {
    if (seconds <= 0 || evolutionStage.value != null) return;
    final decay = stageIndex.value == 0
        ? {'清潔': .7, '体調': .7}
        : {'食事': .2, '清潔': .2, '体調': .2};
    decay.forEach((name, amount) => _changeMeter(name, -amount * seconds));
    secondsInStage.value += seconds;
    for (final name in decay.keys) {
      _tutorialZeroSeconds[name] = meters[name]! <= 0
          ? _tutorialZeroSeconds[name]! + seconds
          : 0;
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
  void setTutorialSpeed(int speed) {
    tutorialSpeed.value = speed;
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
    _changeMeter('食事', meters['食事']! > 100 ? -8.4 : -4.2);
    _changeMeter('清潔', meters['清潔']! > 100 ? -2.8 : -1.4);
    _changeMeter('体調', meters['体調']! > 100 ? -4.2 : -2.1);
    _changeMeter('仕事', meters['仕事']! > 100 ? -8.4 : -4.2);
    _zeroHours.updateAll((name, hours) => meters[name]! <= 0 ? hours + 1 : 0);
    _overHours.updateAll((name, hours) => meters[name]! > 100 ? hours + 1 : 0);
    _dayCared = _dayCared ||
        ['食事', '清潔', '体調', '仕事']
            .every((name) => meters[name]! >= 20);
    if (elapsedHours.value % 24 == 0) {
      day.value++;
      if (_dayCared) daysInStage.value++;
      _dayCared = false;
      actionsToday.value = 0;
      _lastWorkDay = 0;
      _advanceMainStageIfNeeded();
    }
    _checkGameOver();
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
  bool get _isCared => ['食事', '清潔', '体調', '仕事']
      .every((name) => meters[name]! >= 20);

  /// 体調が尽きた場合のゲームオーバーを判定します。
  void _checkGameOver() {
    if (ended.value) return;
    final zeroLimit = <String, int>{'食事': 48, '体調': 48, '清潔': 72};
    final overLimit = <String, int>{'食事': 72, '仕事': 72};
    final zeroTarget = _findExceeded(_zeroHours, zeroLimit);
    final overTarget = _findExceeded(_overHours, overLimit);
    if (zeroTarget == null && overTarget == null && _lowConditionTraining < 15) return;
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
