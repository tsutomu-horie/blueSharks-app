import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

import '../models/mini_game_result.dart';
import '../../models/mini_game_settings.dart';
import 'tackle_player_visual.dart';
import 'tackle_opponent_visual.dart';
import 'tackle_contact_geometry.dart';
import 'tackle_running_trajectory.dart';
import 'tackle_trial_plan.dart';
import 'tackle_game_logic.dart';
import '../../models/training_game_clock.dart';

enum _TacklePhase {
  waiting,
  approach,
  feint,
  input,
  resolution,
  attemptResult,
  gameResult,
}

/// 設定されたセット数の反応速度を計測するタックルミニゲームです。
class TackleGameScreen extends StatefulWidget {
  /// タックルミニゲーム画面を作成します。
  const TackleGameScreen({
    super.key,
    this.random,
    this.soundService,
    this.settings = const TackleSettings(),
  });

  final TackleSettings settings;

  final Random? random;

  /// 結果音の接続をプラグインなしで検証する差し替え点です。
  @visibleForTesting
  final TrainingGameSoundService? soundService;

  @override
  State<TackleGameScreen> createState() => _TackleGameScreenState();
}

class _TackleGameScreenState extends State<TackleGameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  void _playSound(TrainingGameSoundEffect effect) {
    unawaited(
      (widget.soundService ?? TrainingGameSoundService.instance).play(effect),
    );
  }

  final _contactFieldKey = GlobalKey();
  final _contactPlayerKey = GlobalKey();
  final _contactOpponentKey = GlobalKey();
  late final AnimationController _runningClock;
  TackleRunningTrajectory? _runningRoute;
  double? _contactAt;
  double? _successAt;
  Alignment? _successPlayerFrom;
  Alignment? _successPlayerTo;
  Alignment get _paintPlayerAlignment {
    if (_successAt == null) return _playerAlignment;
    final t = ((_paintRunningMs - _successAt!) / (_contactAt! - _successAt!))
        .clamp(0.0, 1.0);
    return Alignment.lerp(
      _successPlayerFrom!,
      _successPlayerTo!,
      Curves.easeOut.transform(t),
    )!;
  }

  double? _failureAt;
  Alignment? _failureFrom;
  double get _realRunningMs => _runningClock.value * 10000;
  bool _inputClockStarted = false;
  double get _runningMs => _inputClockStarted
      ? TackleRunningTrajectory.visualMilliseconds(_realRunningMs)
      : TackleRunningTrajectory.preludeVisualMilliseconds(_realRunningMs);
  double get _paintRunningMs =>
      _contactAt == null ? _runningMs : min(_runningMs, _contactAt!);
  Alignment get _paintOpponent {
    final route = _runningRoute;
    if (route == null) return _opponentAlignment;
    if (_failureAt != null) {
      return Alignment.lerp(
        _failureFrom!,
        _opponentAlignment,
        Curves.easeIn.transform(
          ((_realRunningMs - _failureAt!) / 520).clamp(0, 1),
        ),
      )!;
    }
    return route.sample(_paintRunningMs);
  }

  late final TackleSettings _settings;
  late final Random _random;
  late TackleTrialPlan _trialPlan;
  final _attempts = <TackleAttempt>[];
  final _reactionWatch = Stopwatch();
  final _timers = <Timer>[];
  _TacklePhase _phase = _TacklePhase.waiting;
  Alignment _playerAlignment = const Alignment(-.82, 0);
  Duration _playerDuration = Duration.zero;
  Alignment _opponentAlignment = const Alignment(1.25, 0);
  Duration _opponentDuration = Duration.zero;
  Curve _opponentCurve = Curves.linear;
  TackleDirection _actualDirection = TackleDirection.up;
  TackleAttempt? _latestAttempt;
  bool? _attemptSucceeded;
  DateTime? _phaseStartedAt;
  Duration? _pausedDelay;
  bool _isPaused = false;
  bool _restartInputOnResume = false;
  // 判定演出が終わるまでは、入力イベントから次セットへ進めません。
  bool _canAdvanceAfterAttempt = false;
  // 判定結果の表示中は現在のセット番号を維持し、次セット開始時に更新します。
  int _displayedSetNumber = 1;

  int get _setNumber => _displayedSetNumber;

  bool get _opponentIsRunning =>
      !_isPaused &&
      (_phase == _TacklePhase.approach ||
          _phase == _TacklePhase.feint ||
          _phase == _TacklePhase.input ||
          _phase == _TacklePhase.resolution);

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _random = widget.random ?? Random();
    WidgetsBinding.instance.addObserver(this);
    _runningClock =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (!mounted) return;
            if ((_contactAt != null && _runningMs >= _contactAt!) ||
                (_failureAt != null && _realRunningMs >= _failureAt! + 520)) {
              _runningClock.stop();
            }
            setState(() {});
          });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _timers) {
      timer.cancel();
    }
    _reactionWatch.stop();
    _runningClock.dispose();
    super.dispose();
  }

  /// OS割り込み中は反応計測と接近待ちを一時停止します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseGame();
    }
  }

  /// ゲーム開始または次セットの接近演出を開始します。
  void _startAttempt() {
    _trialPlan = TackleTrialPlan.draw(_random);
    _actualDirection = _trialPlan.actualDirection;
    _inputClockStarted = false;
    _reactionWatch
      ..stop()
      ..reset();
    _runningClock.stop();
    _runningRoute = null;
    _contactAt = null;
    _successAt = null;
    _successPlayerFrom = null;
    _successPlayerTo = null;
    _failureAt = null;
    _failureFrom = null;
    _cancelTimers();
    _phaseStartedAt = TrainingGameClock.now();
    final nextSetNumber =
        (_attempts.length + 1).clamp(1, _settings.setCount).toInt();
    setState(() {
      _displayedSetNumber = nextSetNumber;
      _latestAttempt = null;
      _attemptSucceeded = null;
      _canAdvanceAfterAttempt = false;
      _phase = _TacklePhase.approach;
      _isPaused = false;
      _playerAlignment = const Alignment(-.82, 0);
      _playerDuration = Duration.zero;
      _opponentAlignment = const Alignment(1.25, 0);
      _opponentDuration = Duration.zero;
      _opponentCurve = Curves.linear;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != _TacklePhase.approach || _isPaused) return;
      setState(() {
        _opponentDuration = const Duration(milliseconds: 700);
        _opponentCurve = Curves.easeIn;
        _opponentAlignment = const Alignment(.45, 0);
      });
    });
    // 出現後に加速し、後半は減速してフェイント位置へ入ります。
    _timers.add(
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted || _phase != _TacklePhase.approach || _isPaused) return;
        setState(() {
          _opponentDuration = _trialPlan.secondApproachDuration;
          _opponentCurve = Curves.easeOut;
          _opponentAlignment = const Alignment(-.18, 0);
        });
      }),
    );
    _timers.add(Timer(_trialPlan.approachDuration, _startTrialRoute));
  }

  /// フェイントがある試行では、受付開始前に予備動作を見せます。
  void _startTrialRoute() {
    if (!mounted || _phase != _TacklePhase.approach || _isPaused) return;
    _runningRoute = TackleRunningTrajectory(
      start: _measuredOpponentAlignment() ?? _opponentAlignment,
      downward: _actualDirection == TackleDirection.down,
      hasFeint: _trialPlan.hasFeint,
    );
    _contactAt = null;
    _successAt = null;
    _successPlayerFrom = null;
    _successPlayerTo = null;
    _failureAt = null;
    _inputClockStarted = false;
    _reactionWatch
      ..stop()
      ..reset();
    if (!_trialPlan.hasFeint) {
      _startInput();
      return;
    }
    _phaseStartedAt = TrainingGameClock.now();
    setState(() {
      _phase = _TacklePhase.feint;
      _opponentDuration = TackleRunningTrajectory.feintDuration;
      _opponentCurve = Curves.easeInOut;
      _opponentAlignment = Alignment(
        -.18,
        _actualDirection == TackleDirection.up ? .48 : -.48,
      );
    });
    _runningClock.forward(from: 0);
    _timers.add(Timer(TackleRunningTrajectory.feintDuration, _startInput));
  }

  /// 本進路へ切り返すGOでのみ、反応計測と入力受付を開始します。
  void _startInput() {
    if (!mounted ||
        _isPaused ||
        (_phase != _TacklePhase.approach && _phase != _TacklePhase.feint)) {
      return;
    }
    _runningClock.stop();
    _inputClockStarted = true;
    _phaseStartedAt = TrainingGameClock.now();
    _reactionWatch
      ..reset()
      ..start();
    setState(() {
      _phase = _TacklePhase.input;
      _opponentDuration = Duration.zero;
      _opponentCurve = Curves.easeInOut;
      _opponentAlignment = Alignment(
        -.36,
        _actualDirection == TackleDirection.up ? -.58 : .58,
      );
    });
    _runningClock.forward(from: 0);
    _timers.add(Timer(_settings.inputLimit, () => _finishAttempt(null)));
  }

  /// 上下いずれかのタップを現在セットの結果へ変換します。
  void _handleDirection(TackleDirection direction) {
    if (_isPaused) return;
    if (_phase == _TacklePhase.approach || _phase == _TacklePhase.feint) {
      // 判定開始前のタップは、お手つきとしてこのセットをMISSにします。
      _finishAttempt(
        TackleAttempt(isCorrect: false, settings: _settings),
        tappedDirection: direction,
      );
      return;
    }
    if (_phase != _TacklePhase.input) return;
    _reactionWatch.stop();
    final reaction = _reactionWatch.elapsed;
    _finishAttempt(
      TackleAttempt(
        isCorrect:
            direction == _actualDirection && reaction <= _settings.inputLimit,
        reaction: reaction,
        settings: _settings,
      ),
      tappedDirection: direction,
    );
  }

  /// 1セットを確定し、成否に応じた決着演出を再生します。
  void _finishAttempt(
    TackleAttempt? attempt, {
    TackleDirection? tappedDirection,
  }) {
    if (!mounted ||
        (_phase != _TacklePhase.input &&
            _phase != _TacklePhase.approach &&
            _phase != _TacklePhase.feint)) {
      return;
    }
    _cancelTimers();
    _reactionWatch.stop();
    final result =
        attempt ?? TackleAttempt(isCorrect: false, settings: _settings);
    final success = result.isCorrect;
    final visualNow = _runningMs;
    final contactTime = TackleRunningTrajectory.contactTime(visualNow);
    final contact = success && tappedDirection != null && _runningRoute != null
        ? _measureInterceptTargets(tappedDirection, contactTime)
        : null;
    final failureFrom = _runningRoute == null ? null : _paintOpponent;
    final playerFrom =
        _measuredAlignment(_contactPlayerKey) ?? _playerAlignment;
    // 接近中のタップはお手付きなので、相手はプレイヤーの逆方向へ退場します。
    final isFalseStart =
        _phase == _TacklePhase.approach || _phase == _TacklePhase.feint;
    final opponentExitDirection = isFalseStart && tappedDirection != null
        ? _oppositeDirection(tappedDirection)
        : _actualDirection;
    setState(() {
      _attempts.add(result);
      _latestAttempt = result;
      _attemptSucceeded = success;
      _canAdvanceAfterAttempt = false;
      _phase = _TacklePhase.resolution;
      if (success && contact != null) {
        _contactAt = contactTime;
        _successAt = visualNow;
        _successPlayerFrom = playerFrom;
        _successPlayerTo = contact.playerAlignment;
      } else if (failureFrom != null) {
        _failureFrom = failureFrom;
        _failureAt = _realRunningMs;
      }
      // 成否にかかわらず、ユーザーがタップした上／下方向へ鮫太朗を移動します。
      if (tappedDirection != null) {
        _playerDuration = success && contact != null
            ? Duration(
                microseconds: ((contactTime - visualNow) *
                        1000 /
                        TackleRunningTrajectory.presentationRate)
                    .round(),
              )
            : const Duration(milliseconds: 160);
        _playerAlignment = contact?.playerAlignment ??
            Alignment(-.82, tappedDirection == TackleDirection.up ? -.36 : .36);
      }
      // 成功時は鮫太朗の手前で止め、失敗時は左端の画面外まで抜けさせます。
      _opponentDuration = success
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 520);
      _opponentCurve = success ? _opponentCurve : Curves.easeIn;
      _opponentAlignment = success && contact != null
          ? _opponentAlignment
          : Alignment(
              success ? -.58 : -1.35,
              opponentExitDirection == TackleDirection.up ? -.58 : .58,
            );
    });
    // 決着演出を確認してから、ユーザーが次セットへ進める判定画面を表示します。
    _timers.add(
      Timer(const Duration(milliseconds: 650), () {
        if (!mounted || _phase != _TacklePhase.resolution) return;
        setState(() {
          _phase = _TacklePhase.attemptResult;
          // 決着演出を見終えてから、初めて次セットへの操作を有効にします。
          _canAdvanceAfterAttempt = true;
        });
      }),
    );
  }

  Alignment? _measuredOpponentAlignment() =>
      _measuredAlignment(_contactOpponentKey);

  Alignment? _measuredAlignment(GlobalKey childKey) {
    final field = _contactFieldKey.currentContext?.findRenderObject();
    final opponent = childKey.currentContext?.findRenderObject();
    if (field is! RenderBox ||
        opponent is! RenderBox ||
        !field.hasSize ||
        !opponent.hasSize) {
      return null;
    }
    final c = field.globalToLocal(
      opponent.localToGlobal(opponent.size.center(Offset.zero)),
    );
    final available = Offset(
      field.size.width - opponent.size.width,
      field.size.height - opponent.size.height,
    );
    if (available.dx <= 0 || available.dy <= 0) return null;
    return Alignment(
      (2 * c.dx - field.size.width) / available.dx,
      (2 * c.dy - field.size.height) / available.dy,
    );
  }

  TackleContactTargets? _measureInterceptTargets(
    TackleDirection direction,
    double contactTime,
  ) {
    final field = _contactFieldKey.currentContext?.findRenderObject();
    final player = _contactPlayerKey.currentContext?.findRenderObject();
    final opponent = _contactOpponentKey.currentContext?.findRenderObject();
    if (field is! RenderBox ||
        player is! RenderBox ||
        opponent is! RenderBox ||
        !field.hasSize ||
        !player.hasSize ||
        !opponent.hasSize) {
      return null;
    }
    final reference = tackleContactTargets(
      field: field.size,
      player: player.size,
      opponent: opponent.size,
      downward: direction == TackleDirection.down,
    );
    if (reference == null) return null;
    return tackleInterceptTargets(
      field: field.size,
      player: player.size,
      opponent: opponent.size,
      reference: reference,
      future: _runningRoute!.sample(contactTime),
    );
  }

  /// 指定されたタップ方向と反対側の方向を返します。
  TackleDirection _oppositeDirection(TackleDirection direction) {
    return direction == TackleDirection.up
        ? TackleDirection.down
        : TackleDirection.up;
  }

  /// 次セット、または全セット後の総合結果へ進みます。
  void _advanceAfterAttempt() {
    if (_phase != _TacklePhase.attemptResult || !_canAdvanceAfterAttempt) {
      return;
    }
    // 同じタップや重複したコールバックで、2セット進まないようにします。
    _canAdvanceAfterAttempt = false;
    if (_attempts.length >= _settings.setCount) {
      setState(() => _phase = _TacklePhase.gameResult);
      _playSound(TrainingGameSoundEffect.resultDisplayed);
      return;
    }
    _startAttempt();
  }

  /// ミニゲーム結果を育成画面へ返します。
  void _completeGame() {
    final successCount = TackleRules.successCount(
      _attempts,
      settings: _settings,
    );
    Navigator.of(context).pop(
      MiniGameResult.tackle(
        settings: _settings,
        successCount: successCount,
        successfulReactionTotalUs: TackleRules.successfulReactionTotalUs(
          _attempts,
          settings: _settings,
        ),
      ),
    );
  }

  /// 現在セットに関係する遅延処理をすべて停止します。
  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// 接近中または入力受付中の残り時間を保持して停止します。
  void _pauseGame() {
    if (_isPaused ||
        (_phase != _TacklePhase.approach &&
            _phase != _TacklePhase.feint &&
            _phase != _TacklePhase.input)) {
      return;
    }
    final elapsed = _phaseStartedAt == null
        ? Duration.zero
        : TrainingGameClock.now().difference(_phaseStartedAt!);
    final limit = _phase == _TacklePhase.approach
        ? _trialPlan.approachDuration
        : _phase == _TacklePhase.feint
            ? TackleRunningTrajectory.feintDuration
            : _settings.inputLimit;
    _pausedDelay = elapsed >= limit ? Duration.zero : limit - elapsed;
    _restartInputOnResume =
        _phase == _TacklePhase.input || _phase == _TacklePhase.feint;
    _cancelTimers();
    if (_phase == _TacklePhase.input || _phase == _TacklePhase.feint) {
      _reactionWatch.stop();
      _runningClock.stop();
    }
    setState(() => _isPaused = true);
  }

  /// 一時停止前のフェーズと残り時間からゲームを再開します。
  void _resumeGame() {
    if (!_isPaused || _pausedDelay == null) return;
    if (_restartInputOnResume) {
      _restartInputOnResume = false;
      _startAttempt();
      return;
    }
    final delay = _pausedDelay!;
    final limit = _phase == _TacklePhase.approach
        ? _trialPlan.approachDuration
        : _phase == _TacklePhase.feint
            ? TackleRunningTrajectory.feintDuration
            : _settings.inputLimit;
    _phaseStartedAt = TrainingGameClock.now().subtract(limit - delay);
    setState(() {
      _isPaused = false;
      _opponentDuration = delay;
      _opponentCurve = Curves.easeOut;
      _opponentAlignment = const Alignment(-.18, 0);
    });
    if (_phase == _TacklePhase.approach) {
      _timers.add(Timer(delay, _startTrialRoute));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe8f3e8),
      appBar: AppBar(
        title: const Text('① タックル'),
        backgroundColor: const Color(0xff123d28),
        foregroundColor: Colors.white,
        actions: [
          if (_phase == _TacklePhase.approach ||
              _phase == _TacklePhase.feint ||
              _phase == _TacklePhase.input)
            IconButton(
              onPressed: _isPaused ? _resumeGame : _pauseGame,
              tooltip: _isPaused ? '再開' : '一時停止',
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // 判定表示後は、下部パネル以外を含む画面全体のタップで次セットへ進めます。
          onTap: _phase == _TacklePhase.attemptResult
              ? _advanceAfterAttempt
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                Expanded(child: _buildField()),
                const SizedBox(height: 12),
                _buildBottomPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// セット数と入力猶予を表示します。
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SET $_setNumber / ${_settings.setCount}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text('判定猶予 ${_settings.inputLimitMs / 1000}秒'),
      ],
    );
  }

  /// 接近する相手と上下の入力領域を表示します。
  Widget _buildField() {
    return ClipRRect(
      key: _contactFieldKey,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(child: Container(color: const Color(0xffb9df9c))),
                Container(height: 4, color: Colors.white70),
                Expanded(child: Container(color: const Color(0xff8fca70))),
              ],
            ),
          ),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleFieldTap(TackleDirection.up),
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('上をタップ ▲'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleFieldTap(TackleDirection.down),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('下をタップ ▼'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedAlign(
            duration: _successAt == null ? _playerDuration : Duration.zero,
            curve: Curves.easeOut,
            alignment: _paintPlayerAlignment,
            child: KeyedSubtree(
              key: _contactPlayerKey,
              child: TacklePlayerVisual(
                key: const Key('tackle-player'),
                visualScale: TacklePlayerVisual.candidateVisualScale,
                attacking: _attemptSucceeded == true || _playerAlignment.y != 0,
                downward: _attemptSucceeded == true
                    ? _actualDirection == TackleDirection.down
                    : _playerAlignment.y > 0,
              ),
            ),
          ),
          AnimatedAlign(
            duration: _runningRoute == null ? _opponentDuration : Duration.zero,
            curve: _runningRoute == null ? _opponentCurve : Curves.linear,
            alignment: _paintOpponent,
            child: KeyedSubtree(
              key: _contactOpponentKey,
              child: KeyedSubtree(
                key: _runningRoute == null
                    ? null
                    : Key(
                        !_inputClockStarted
                            ? 'tackle-running-feint'
                            : (_actualDirection == TackleDirection.up
                                ? 'tackle-running-up'
                                : 'tackle-running-down'),
                      ),
                child: TackleOpponentVisual(
                  key: const Key('tackle-opponent'),
                  running: _opponentIsRunning,
                ),
              ),
            ),
          ),
          if (_phase == _TacklePhase.resolution) _buildResolutionOverlay(),
          if (_phase == _TacklePhase.waiting)
            _buildOverlay(
              title: 'タックル練習',
              detail: '全${_settings.setCount}セット',
              buttonLabel: 'スタート',
              onPressed: _startAttempt,
            ),
          if (_phase == _TacklePhase.gameResult) _buildResultOverlay(),
          if (_isPaused) _buildPauseOverlay(),
        ],
      ),
    );
  }

  /// 入力中は上下判定、判定表示中は次セットへの進行としてフィールドタップを処理します。
  void _handleFieldTap(TackleDirection direction) {
    if (_phase == _TacklePhase.attemptResult) {
      _advanceAfterAttempt();
      return;
    }
    _handleDirection(direction);
  }

  /// タックル成立または相手の突破を、決着フェーズとしてフィールド上に表示します。
  Widget _buildResolutionOverlay() {
    final succeeded = _attemptSucceeded ?? false;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (succeeded
                      ? const Color(0xff14532d)
                      : const Color(0xff991b1b))
                  .withValues(alpha: .88),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                succeeded ? 'TACKLE!' : '突破された！',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// スタート待ちに使用する半透明オーバーレイを作成します。
  Widget _buildOverlay({
    required String title,
    required String detail,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: .82),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(detail, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  /// 全セットの総合ランクと記録を表示します。
  Widget _buildResultOverlay() {
    final rank = TackleRules.overallRank(_attempts, settings: _settings);
    final successCount = TackleRules.successCount(
      _attempts,
      settings: _settings,
    );
    final average = TackleRules.averageReaction(_attempts, settings: _settings);
    final averageLabel = average == null
        ? '―'
        : '${(average.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(2)}秒';
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xff123d28).withValues(alpha: .92),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('総合ランク', style: TextStyle(color: Colors.white70)),
            Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 88,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '判定平均 $averageLabel　成功 $successCount/${_settings.setCount}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _completeGame,
              child: const Text('メインへ戻る'),
            ),
          ],
        ),
      ),
    );
  }

  /// 一時停止中のタップを遮断し、再開操作を表示します。
  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: .68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle, color: Colors.white, size: 64),
            const SizedBox(height: 12),
            const Text(
              '一時停止中',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _resumeGame, child: const Text('再開')),
          ],
        ),
      ),
    );
  }

  /// 1セットの成否と、それまでの記録を表示します。
  Widget _buildBottomPanel() {
    if (_phase != _TacklePhase.attemptResult || _latestAttempt == null) {
      return SizedBox(
        height: 96,
        child: Center(
          child: Text(
            _phase == _TacklePhase.approach
                ? '相手の接近をよく見よう'
                : _phase == _TacklePhase.input
                    ? 'GO! 進む方向をタップ'
                    : _phase == _TacklePhase.feint
                        ? '相手の動きを見よう'
                        : '全${_settings.setCount}セットの反応速度を計測します',
            key: _phase == _TacklePhase.input
                ? const Key('tackle-input-cue')
                : null,
          ),
        ),
      );
    }
    final reaction = _latestAttempt!.reaction;
    final reactionLabel = reaction == null
        ? '突破された！'
        : '${(reaction.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(2)}秒';
    return SizedBox(
      height: 96,
      child: InkWell(
        onTap: _advanceAfterAttempt,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _latestAttempt!.isCorrect
                ? const Color(0xffdff5df)
                : const Color(0xffffe1e1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_latestAttempt!.rank}　$reactionLabel',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('>> タップして次へ <<'),
            ],
          ),
        ),
      ),
    );
  }
}
