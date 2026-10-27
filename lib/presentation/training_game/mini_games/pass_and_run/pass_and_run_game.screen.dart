import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

import '../models/mini_game_result.dart';
import '../mini_game_result_transition.dart';
import 'pass_and_run_character_visual.dart';
import 'pass_and_run_direction_guide.dart';
import '../../models/training_game_clock.dart';
import '../../models/mini_game_settings.dart';
import 'pass_and_run_logic.dart';
import 'pass_and_run_sparse_flick.dart';
import 'pass_and_run_motion.dart';
import 'pass_and_run_return_sprint.dart';
import 'pass_and_run_pace_assist.dart';

enum _PassGamePhase { waiting, playing, result }

/// 仲間の方向へフリックして成功回数を競うパス＆ランです。
class PassAndRunGameScreen extends StatefulWidget {
  /// パス＆ラン画面を作成します。
  const PassAndRunGameScreen({
    super.key,
    this.now,
    this.motionSeed,
    this.soundService,
    this.settings = const PassRunSettings(),
  });

  final PassRunSettings settings;

  @visibleForTesting
  final int? motionSeed;

  /// 受球・失敗・結果音の接続をプラグインなしで検証する差し替え点です。
  @visibleForTesting
  final TrainingGameSoundService? soundService;

  /// 入力・ticker・停止復帰を同じ瞬間で検証するための時計注入点です。
  /// 通常画面は育成ゲームの共通サーバー時計を使います。
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<PassAndRunGameScreen> createState() => _PassAndRunGameScreenState();
}

class _PassAndRunGameScreenState extends State<PassAndRunGameScreen>
    with WidgetsBindingObserver {
  late final PassRunSettings _settings;
  Duration get _roundDuration =>
      Duration(milliseconds: _settings.roundDurationMs);
  Duration get _missPenalty => Duration(milliseconds: _settings.missPenaltyMs);
  Duration get _passArrivalDuration =>
      Duration(milliseconds: _settings.ballHalfFieldTravelMs);
  // Keep the validated collision-radius blend independent of ball speed.
  static const _collisionBlendDuration = Duration(milliseconds: 220);
  static const _catchSettleDuration = Duration(milliseconds: 80);
  static const _displayScale = .75;
  Duration get _turnDuration =>
      Duration(milliseconds: _settings.laneSwapDurationMs);

  void _playSound(TrainingGameSoundEffect effect) {
    unawaited(
      (widget.soundService ?? TrainingGameSoundService.instance).play(effect),
    );
  }

  // 80msの捕球接続に短い余裕を加える最短待機。描画frame数は保証しない。
  static const _passReturnDelay = Duration(milliseconds: 96);

  _PassGamePhase _phase = _PassGamePhase.waiting;
  bool _resultReturned = false;
  final _roundScores = <int>[0, 0];
  final _fieldTick = ValueNotifier<int>(0);
  late final Ticker _fieldTicker;
  late PassRunMotion _motion;
  PassRunReturnSprint? _mateSprint;
  PassRunPaceAssist? _playerAssist;
  double? _blockedSince;
  double? _lastPaceDecisionAt;
  double? _playerTurnStartFraction;
  double _playerAssistDistanceBase = 0;
  double _outboundPlayerDistanceDelta = 0;
  double? _mateTurnStartFraction;
  double _mateSprintDistanceBase = 0;
  double _outboundMateDistanceDelta = 0;
  Timer? _clockTimer;
  DateTime? _roundStartedAt;
  DateTime? _penaltyUntil;
  DateTime? _passStartedAt;
  Duration _collisionCheckedElapsed = Duration.zero;
  DateTime? _passArrivalAt;
  DateTime? _passReadyAt;
  Offset? _passStartOffset;
  Offset? _passTargetOffset;
  late Duration _passTravelDuration;
  late Duration _passReturnDuration;
  DateTime? _returnStartedAt;
  Duration? _pausedReturnElapsed;
  bool _isForwardPass = false;
  Offset? _passReturnStartOffset;
  Offset? _passReturnTargetOffset;
  Offset? _catchBallDisplacement;
  PassRunBallGeometry? _catchBallGeometry;
  PassRunBallGeometry? _releaseBallGeometry;
  double? _releaseCollisionRadius;
  PassRunBallGeometry? _returnReleaseGeometry;
  final _sparseFlick = PassRunSparseFlick();
  final _fieldInputKey = GlobalKey();
  Offset? _dragStart;
  Offset? _dragCurrent;
  Size _fieldSize = Size.zero;
  int _roundIndex = 0;
  late int _remainingMilliseconds;
  bool _lastPassSucceeded = false;
  bool _precacheStarted = false;
  bool _assetsReady = false;
  bool _assetLoadFailed = false;
  bool _preparingImages = false;
  final _pinnedImages =
      <({ImageStream stream, ImageStreamListener listener})>[];
  bool _passInFlight = false;
  bool _passScoreConfirmed = false;
  bool _isBallLost = false;
  int? _pendingPassRoundIndex;
  bool _isPaused = false;
  Duration? _pausedRoundRemaining;
  Duration? _pausedPenaltyRemaining;
  Duration? _pausedPassRemaining;
  Duration? _pausedPassElapsed;

  String _secondsLabel(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return seconds == seconds.roundToDouble()
        ? seconds.toInt().toString()
        : seconds.toString();
  }

  DateTime _now() => widget.now?.call() ?? TrainingGameClock.now();

  bool get _isOutbound => _roundIndex == 0;
  bool get _isPenalized => _isPaused
      ? (_pausedPenaltyRemaining ?? Duration.zero) > Duration.zero
      : _penaltyUntil != null && _now().isBefore(_penaltyUntil!);

  /// ラウンド終了時刻を過ぎていない場合だけ、新しいパスを受け付けます。
  bool get _canPass {
    final roundStartedAt = _roundStartedAt;
    if (roundStartedAt == null ||
        _now().isBefore(roundStartedAt) ||
        !_now().isBefore(roundStartedAt.add(_roundDuration))) {
      return false;
    }
    return _phase == _PassGamePhase.playing &&
        !_isPaused &&
        !_isPenalized &&
        !_passInFlight &&
        (_passReadyAt == null || !_now().isBefore(_passReadyAt!));
  }

  int get _totalScore => _roundScores.fold(0, (sum, score) => sum + score);

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _remainingMilliseconds = _roundDuration.inMilliseconds;
    _passTravelDuration = _passArrivalDuration;
    _passReturnDuration = _passArrivalDuration;
    _motion = _createMotion();
    WidgetsBinding.instance.addObserver(this);
    _fieldTicker = Ticker((_) {
      if (!mounted) return;
      // 描画フレームごとに確認し、移動中の仲間との衝突を取りこぼさないようにします。
      final now = _now();
      final movementChanged = _updateMovementAssistance();
      if (_updatePassCycle(now) || movementChanged) setState(() {});
      _fieldTick.value++;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheStarted) {
      _precacheStarted = true;
      unawaited(_prepareImages());
    }
  }

  Future<void> _prepareImages() async {
    if (_preparingImages) return;
    _preparingImages = true;
    var failed = false;
    final configuration = createLocalImageConfiguration(context);
    // Pin each state immediately and wait for its decoded image, so cache
    // eviction cannot race the transition from preparation into play.
    await Future.wait(
      PassAndRunCharacterVisual.assets.map((path) {
        final ready = Completer<void>();
        final stream = AssetImage(path).resolve(configuration);
        final listener = ImageStreamListener(
          (image, synchronousCall) {
            image.dispose();
            if (!ready.isCompleted) ready.complete();
          },
          onError: (Object error, StackTrace? stack) {
            failed = true;
            if (!ready.isCompleted) ready.complete();
          },
        );
        _pinnedImages.add((stream: stream, listener: listener));
        stream.addListener(listener);
        return ready.future;
      }),
    );
    if (!mounted) return;
    if (failed) {
      for (final image in _pinnedImages) {
        image.stream.removeListener(image.listener);
      }
      _pinnedImages.clear();
    }
    setState(() {
      _preparingImages = false;
      _assetsReady = !failed;
      _assetLoadFailed = failed;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final image in _pinnedImages) {
      image.stream.removeListener(image.listener);
    }
    _clockTimer?.cancel();
    _fieldTicker.dispose();
    _fieldTick.dispose();
    super.dispose();
  }

  /// OS割り込み中はタイマーを止め、復帰時に残り時間から再開します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseGame();
    }
  }

  /// 往路を開始し、制限時間と並走位置の更新を始めます。
  void _startGame() {
    if (!_assetsReady) return;
    // Retryでも同じ移動パターンを再生しないよう、実プレイごとにseedを変えます。
    _motion = _createMotion();
    _motion.updateFieldGeometry(_fieldSize);
    _roundIndex = 0;
    _roundScores
      ..clear()
      ..addAll([0, 0]);
    _startRound();
  }

  PassRunMotion _createMotion() => PassRunMotion(
        seed: widget.motionSeed ?? math.Random().nextInt(1 << 31),
        roundSeconds: _roundDuration.inMicroseconds / 1000000,
        speedScale: _settings.runSpeedScale,
      );

  /// 現在の片道ラウンドを開始します。
  void _startRound({Duration carryPenalty = Duration.zero}) {
    _clockTimer?.cancel();
    _mateSprint = null;
    _playerAssist = null;
    _blockedSince = null;
    _lastPaceDecisionAt = null;
    _playerAssistDistanceBase = 0;
    _mateSprintDistanceBase = 0;
    if (_isOutbound) {
      _mateTurnStartFraction = null;
      _outboundMateDistanceDelta = 0;
      _playerTurnStartFraction = null;
      _outboundPlayerDistanceDelta = 0;
    }
    _roundStartedAt = _isOutbound ? _now() : _now().add(_turnDuration);
    _penaltyUntil = carryPenalty > Duration.zero
        ? _roundStartedAt!.add(carryPenalty)
        : null;
    _passReadyAt = null;
    _passStartedAt = null;
    _collisionCheckedElapsed = Duration.zero;
    _passArrivalAt = null;
    _passStartOffset = null;
    _passTargetOffset = null;
    _passReturnDuration = _passArrivalDuration;
    _returnStartedAt = null;
    _catchBallDisplacement = null;
    _catchBallGeometry = null;
    _releaseBallGeometry = null;
    _returnReleaseGeometry = null;
    _isForwardPass = false;
    _passReturnStartOffset = null;
    _passReturnTargetOffset = null;
    _passInFlight = false;
    _passScoreConfirmed = false;
    _isBallLost = false;
    _pendingPassRoundIndex = null;
    _remainingMilliseconds = _roundDuration.inMilliseconds;
    setState(() {
      _phase = _PassGamePhase.playing;
      _isPaused = false;
      _lastPassSucceeded = false;
    });
    _startRoundTimers();
  }

  /// 現在の残り時間から計測と位置入替を開始します。
  void _startRoundTimers() {
    _fieldTicker
      ..stop()
      ..start();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _roundStartedAt == null) return;
      final now = _now();
      final previousRemainingDeciseconds = _remainingMilliseconds ~/ 100;
      final elapsed = now.difference(_roundStartedAt!);
      final remaining = _roundDuration - elapsed;
      if (remaining <= Duration.zero) {
        _finishRound();
        return;
      }
      _remainingMilliseconds = remaining.inMilliseconds.clamp(
        0,
        _roundDuration.inMilliseconds,
      );
      if (previousRemainingDeciseconds != _remainingMilliseconds ~/ 100) {
        setState(() {});
      }
    });
  }

  /// 往路から復路、または復路から結果画面へ進みます。
  void _finishRound() {
    _updatePassCycle(_now());
    _clockTimer?.cancel();
    _fieldTicker.stop();
    _passInFlight = false;
    _passScoreConfirmed = false;
    _isBallLost = false;
    _pendingPassRoundIndex = null;
    _passStartedAt = null;
    _collisionCheckedElapsed = Duration.zero;
    _passArrivalAt = null;
    _passReadyAt = null;
    _passStartOffset = null;
    _passTargetOffset = null;
    _passReturnStartOffset = null;
    _passReturnTargetOffset = null;
    _returnStartedAt = null;
    _catchBallDisplacement = null;
    _catchBallGeometry = null;
    _releaseBallGeometry = null;
    _returnReleaseGeometry = null;
    _isForwardPass = false;
    _dragStart = null;
    _dragCurrent = null;
    if (_roundIndex == 0) {
      final endSeconds = _roundDuration.inMilliseconds / 1000;
      _mateTurnStartFraction =
          (_mateOffsetAt(endSeconds).dy / _fieldSize.height -
                  _motion.geometry.minimum) /
              (_motion.geometry.movementRadius * 2);
      _playerTurnStartFraction =
          (_playerOffsetAt(endSeconds).dy / _fieldSize.height -
                  _motion.geometry.minimum) /
              (_motion.geometry.movementRadius * 2);
      final playerAssist = _playerAssist;
      if (playerAssist != null) {
        _outboundPlayerDistanceDelta = _distanceCorrection(
          playerAssist,
          _playerAssistDistanceBase,
          PassRunRunner.player,
          endSeconds,
        );
      }
      final sprint = _mateSprint;
      if (sprint != null) {
        _outboundMateDistanceDelta = _mateSprintDistanceBase +
            _motion.runningForwardRate * (endSeconds - sprint.start) +
            _motion.geometry.movementRadius *
                2 *
                sprint.distanceSinceStart(endSeconds) -
            (_motion.distanceAt(endSeconds, PassRunRunner.companion) -
                _motion.distanceAt(sprint.start, PassRunRunner.companion));
      }
      // 確定仕様に従い、往路終了時のペナルティ残時間を復路へ持ち越します。
      final carryPenalty =
          _isPenalized ? _penaltyUntil!.difference(_now()) : Duration.zero;
      _roundIndex = 1;
      _startRound(carryPenalty: carryPenalty);
      return;
    }
    setState(() {
      _remainingMilliseconds = 0;
      _phase = _PassGamePhase.result;
    });
    _playSound(TrainingGameSoundEffect.resultDisplayed);
  }

  /// フリック開始位置を記録します。
  void _handlePanStart(DragStartDetails details) {
    if (!_canPass) return;
    setState(() {
      // 指を置いた位置を丸の始点として表示し、フリックの起点を明確にします。
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  /// フリックの最終位置を保持します。
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    setState(() {
      // ドラッグ中の指先まで矢印を伸ばし、入力方向を確認できるようにします。
      _dragCurrent = details.localPosition;
    });
  }

  /// 指を離した時点でフリックを受け取り、ボールの移動を開始します。
  void _handlePanEnd(DragEndDetails details) {
    final start = _dragStart;
    final current = _dragCurrent;
    _dragStart = null;
    _dragCurrent = null;
    if (!_canPass ||
        _sparseFlick.blocked ||
        start == null ||
        current == null ||
        _fieldSize.isEmpty) {
      // フリックが成立しない場合も、表示中の操作ガイドは即時に消します。
      setState(() {});
      return;
    }
    final velocity = details.velocity.pixelsPerSecond;
    final flick = _sparseFlick.resolve(PassFlick(
      deltaX: current.dx - start.dx,
      deltaY: current.dy - start.dy,
      velocityX: velocity.dx,
      velocityY: velocity.dy,
    ));
    // 短い指のブレはミス扱いにせず、そのまま入力を待ちます。
    if (!PassAndRunRules.isFlick(flick)) {
      // 短いドラッグは発射せず、操作ガイドだけを消して次の入力を待ちます。
      setState(() {});
      return;
    }
    final direction = PassAndRunRules.userPassDirection(
      flick,
      outbound: _isOutbound,
    );
    // 補正後の投球方向を判定し、実際の球筋も同じ方向へ揃えます。
    if (PassAndRunRules.isForwardDirection(
      deltaX: direction.deltaX,
      deltaY: direction.deltaY,
      outbound: _isOutbound,
    )) {
      _playSound(TrainingGameSoundEffect.passFailed);
      setState(() {
        _isForwardPass = true;
        _lastPassSucceeded = false;
        _isBallLost = false;
        _penaltyUntil = _now().add(_missPenalty);
      });
      return;
    }
    _isForwardPass = false;
    _isBallLost = false;
    _returnStartedAt = null;
    _catchBallDisplacement = null;
    _catchBallGeometry = null;
    _releaseBallGeometry = null;
    _returnReleaseGeometry = null;
    // 発射位置を固定し、フリック方向へボールを飛ばします。
    final player = _playerOffset;
    final playerBall = _playerBallOffsetAt(player);
    final releaseGeometry = _geometryAt(
      PassRunCharacter.normal,
      _motionSeconds,
    );
    // 成否は発射時には決めず、移動中にボールと仲間が衝突した時点で確定します。
    final now = _now();
    _playerAssist?.release(_motionSeconds);
    _passInFlight = true;
    _passScoreConfirmed = false;
    _isBallLost = false;
    _pendingPassRoundIndex = _roundIndex;
    _passStartedAt = now;
    _collisionCheckedElapsed = Duration.zero;
    _passStartOffset = playerBall;
    _releaseBallGeometry = releaseGeometry;
    _releaseCollisionRadius = _collisionRadiusAt(
      PassRunCharacter.normal,
      _motionSeconds,
    );
    _passTargetOffset = _flickExitOffset(
      start: start,
      current: start + Offset(direction.deltaX, direction.deltaY),
    );
    _passReturnStartOffset = null;
    _passReturnTargetOffset = null;
    // 基準速度を保つため、フリック先までの距離に応じて移動時間を延長します。
    final actualDistance = (_passTargetOffset! - _passStartOffset!).distance;
    final standardPassDistance = _fieldSize.width * .5;
    _passTravelDuration = standardPassDistance == 0
        ? _passArrivalDuration
        : Duration(
            microseconds: (_passArrivalDuration.inMicroseconds *
                    actualDistance /
                    standardPassDistance)
                .round(),
          );
    _passArrivalAt = now.add(_passTravelDuration);
    _passReadyAt = _passArrivalAt;
    setState(() => _lastPassSucceeded = false);
  }

  /// 失敗時にボールが画面外へ抜ける位置を、フリック方向から求めます。
  Offset _flickExitOffset({required Offset start, required Offset current}) {
    final direction = current - start;
    if (direction.distance == 0) return _playerBallOffset;
    final origin = _playerBallOffset;
    final normalizedDirection = direction / direction.distance;
    const ballRadius = PassAndRunRules.ballCollisionRadius;
    // ボール半径ぶんだけ画面外に出す距離を求め、表示から消えた時点でミスを確定します。
    final horizontalDistance = normalizedDirection.dx > 0
        ? (_fieldSize.width + ballRadius - origin.dx) / normalizedDirection.dx
        : normalizedDirection.dx < 0
            ? (-ballRadius - origin.dx) / normalizedDirection.dx
            : double.infinity;
    final verticalDistance = normalizedDirection.dy > 0
        ? (_fieldSize.height + ballRadius - origin.dy) / normalizedDirection.dy
        : normalizedDirection.dy < 0
            ? (-ballRadius - origin.dy) / normalizedDirection.dy
            : double.infinity;
    final exitDistance = math.min(horizontalDistance, verticalDistance);
    return origin + normalizedDirection * exitDistance;
  }

  /// 2人が異なる速度で上下し、追いつき・追い越しが起きる現在位置を返します。
  double get _motionSeconds {
    final startedAt = _roundStartedAt;
    if (startedAt == null) return 0;
    if (_isPaused && _pausedRoundRemaining != null) {
      return math.max(
        0,
        (_roundDuration - _pausedRoundRemaining!).inMilliseconds / 1000,
      );
    }
    return math.max(0, _now().difference(startedAt).inMilliseconds / 1000);
  }

  // The inbound clock starts after the turn. Both actors and the held ball
  // share this geometry, so the transition never separates them or costs play time.
  double get _turnProgress {
    if (_isOutbound || _roundStartedAt == null) return 1;
    final remaining = _isPaused && _pausedRoundRemaining != null
        ? _pausedRoundRemaining! - _roundDuration
        : _roundStartedAt!.difference(_now());
    return (1 - remaining.inMicroseconds / _turnDuration.inMicroseconds)
        .clamp(0, 1)
        .toDouble();
  }

  PassRunRunner _runner(PassRunCharacter kind) =>
      kind == PassRunCharacter.normal
          ? PassRunRunner.player
          : PassRunRunner.companion;

  ({PassRunFacing from, PassRunFacing to, double progress}) _facingAt(
    PassRunCharacter kind,
    double seconds,
  ) {
    if (!_isOutbound && _turnProgress < 1) {
      final elapsed =
          (_turnProgress * _turnDuration.inMicroseconds).round() / 1000000;
      if (elapsed < PassRunMotion.facingSettleSeconds) {
        return (
          from: PassRunFacing.back,
          to: PassRunFacing.front,
          progress: (elapsed / PassRunMotion.facingSettleSeconds).clamp(0, 1),
        );
      }
    }
    return PassRunMotion.facingAt(
      seconds,
      _runner(kind),
      outbound: _isOutbound,
    );
  }

  PassRunFacing _spriteFacing(PassRunCharacter kind) {
    final transition = _facingAt(kind, _motionSeconds);
    return transition.progress == 0 ? transition.from : transition.to;
  }

  bool _directionChanging(PassRunCharacter kind) {
    final facing = _facingAt(kind, _motionSeconds);
    return facing.from != facing.to && facing.progress < 1;
  }

  Offset _actorOffsetAt(double seconds, {required bool player}) {
    final runner = player ? PassRunRunner.player : PassRunRunner.companion;
    if (_turnProgress < 1) {
      return _motion.turnOffset(
        _turnProgress,
        runner,
        field: _fieldSize,
        actorSize: _characterSize,
        playerStartY: _playerTurnStartFraction == null
            ? null
            : _motion.geometry.minimum +
                _motion.geometry.movementRadius * 2 * _playerTurnStartFraction!,
        mateStartY: _mateTurnStartFraction == null
            ? null
            : _motion.geometry.minimum +
                _motion.geometry.movementRadius * 2 * _mateTurnStartFraction!,
      );
    }
    final PassRunAssistedMovement? assisted =
        player ? _playerAssist : _mateSprint;
    final y = assisted != null
        ? _motion.geometry.minimum +
            _motion.geometry.movementRadius * 2 * assisted.positionAt(seconds)
        : _motion.yAt(seconds, runner, outbound: _isOutbound);
    final lane = player == _isOutbound ? .25 : .75;
    return Offset(_fieldSize.width * lane, _fieldSize.height * y);
  }

  Offset _playerOffsetAt(double seconds) =>
      _actorOffsetAt(seconds, player: true);

  Offset _mateOffsetAt(double seconds) =>
      _actorOffsetAt(seconds, player: false);

  Offset get _playerOffset => _playerOffsetAt(_motionSeconds);

  Offset get _mateOffset => _mateOffsetAt(_motionSeconds);

  double get _characterSize =>
      _displayScale *
      math.min(
        PassAndRunCharacterVisual.canvasSize,
        math.min(_fieldSize.height * .4, _fieldSize.width * .5),
      );

  double get _floorOffset =>
      _motion.runningForwardRate *
      _fieldSize.height *
      (_isOutbound ? _motionSeconds : _motion.roundSeconds - _motionSeconds);

  // 脚は各本人の走行距離に追従。衝突半径は従来の240ms時計を維持します。
  int _frameAt(double seconds, PassRunCharacter kind) {
    final runner = _runner(kind);
    final outboundDistance = (kind == PassRunCharacter.companion
            ? _outboundMateDistanceDelta
            : _outboundPlayerDistanceDelta) +
        _motion.distanceAt(_roundDuration.inMicroseconds / 1000000, runner);
    var distance = _isOutbound
        ? _motion.distanceAt(seconds, runner)
        : outboundDistance +
            _motion.runningForwardRate *
                (_turnProgress * _turnDuration.inMicroseconds / 1000000) +
            _motion.distanceAt(seconds, runner, outbound: false);
    final PassRunAssistedMovement? sprint =
        kind == PassRunCharacter.companion ? _mateSprint : _playerAssist;
    if (sprint != null && seconds >= sprint.start) {
      distance += _distanceCorrection(
        sprint,
        kind == PassRunCharacter.companion
            ? _mateSprintDistanceBase
            : _playerAssistDistanceBase,
        runner,
        seconds,
      );
    }
    return (distance * 45).floor() % 2;
  }

  PassRunBallGeometry _geometryAt(PassRunCharacter kind, double seconds) {
    final facing = _facingAt(kind, seconds);
    PassRunBallGeometry geometry(PassRunFacing direction) =>
        PassAndRunCharacterVisual.heldBallGeometry(
          character: kind,
          frame: _frameAt(seconds, kind),
          facing: direction,
          size: _characterSize,
        );
    return PassRunBallGeometry.lerp(
      geometry(facing.from),
      geometry(facing.to),
      facing.progress,
    );
  }

  Offset _heldBallOffsetAt(
    Offset actor,
    double seconds,
    PassRunCharacter kind,
  ) =>
      actor + _geometryAt(kind, seconds).offset;

  Offset _playerBallOffsetAt(Offset actor, {double? seconds}) =>
      _heldBallOffsetAt(
        actor,
        seconds ?? _motionSeconds,
        PassRunCharacter.normal,
      );

  Offset get _playerBallOffset => _playerBallOffsetAt(_playerOffset);
  Offset get _mateBallOffset => _heldBallOffsetAt(
        _mateOffset,
        _motionSeconds,
        PassRunCharacter.companion,
      );

  bool get _mateHolding =>
      _passInFlight && _passScoreConfirmed && _returnStartedAt == null;
  bool get _playerHolding =>
      _phase != _PassGamePhase.result &&
      !_passInFlight &&
      (!_isBallLost || !_isPenalized);
  double get _catchProgress =>
      ((_passElapsed - _passTravelDuration).inMicroseconds /
              _catchSettleDuration.inMicroseconds)
          .clamp(0, 1)
          .toDouble();
  bool get _catchSettling => _mateHolding && _catchProgress < 1;
  bool get _mateHoldingVisual =>
      _mateHolding &&
      !_catchSettling &&
      !_directionChanging(PassRunCharacter.companion);
  bool get _playerHoldingVisual =>
      _playerHolding && !_directionChanging(PassRunCharacter.normal);
  bool get _showFlightBall =>
      (_passInFlight && (!_mateHolding || _catchSettling)) ||
      (_playerHolding && !_playerHoldingVisual) ||
      (_mateHolding && !_mateHoldingVisual);
  bool get _showFlightTrail => _passInFlight && !_mateHolding;

  bool get _ballBehindActor {
    if (_playerHolding) {
      return _spriteFacing(PassRunCharacter.normal) == PassRunFacing.back;
    }
    if (_mateHolding) {
      return _spriteFacing(PassRunCharacter.companion) == PassRunFacing.back;
    }
    // Switch draw order only once the full ball clears a rear-facing actor's
    // canvas. This avoids revealing an overlapping ball at an arbitrary time.
    final ballBounds = Rect.fromCenter(
      center: _ballOffset,
      width: _ballGeometry.extent,
      height: _ballGeometry.extent,
    );
    bool overlapsRear(PassRunCharacter kind, Offset actor) =>
        _spriteFacing(kind) == PassRunFacing.back &&
        ballBounds.overlaps(
          Rect.fromCenter(
            center: actor,
            width: _characterSize,
            height: _characterSize,
          ),
        );
    return overlapsRear(PassRunCharacter.normal, _playerOffset) ||
        overlapsRear(PassRunCharacter.companion, _mateOffset);
  }

  PassRunBallGeometry get _ballGeometry {
    final normal = _geometryAt(PassRunCharacter.normal, _motionSeconds);
    final companion = _geometryAt(PassRunCharacter.companion, _motionSeconds);
    if (_mateHolding) {
      return PassRunBallGeometry.lerp(
        _catchBallGeometry ?? companion,
        companion,
        _catchProgress,
      );
    }
    if (_returnStartedAt != null) {
      return PassRunBallGeometry.lerp(
        _returnReleaseGeometry ?? companion,
        normal,
        _returnElapsed.inMicroseconds / _passReturnDuration.inMicroseconds,
      );
    }
    if (!_passInFlight) return normal;
    return PassRunBallGeometry.lerp(
      _releaseBallGeometry ?? normal,
      companion,
      _passElapsed.inMicroseconds / _passArrivalDuration.inMicroseconds,
    );
  }

  // Keep the validated pre-art-update collision envelope. Re-measuring the
  // new art must not silently enlarge/shrink the successful receiving window.
  double _collisionRadiusAt(PassRunCharacter kind, double seconds) {
    final even = (seconds * 1000 ~/ 240).isEven;
    final diameter = kind == PassRunCharacter.normal
        ? (even ? 27.549925049569 : 27.600348580376)
        : (even ? 30.956565121244 : 31.061003284964);
    return diameter /
        2 *
        (_characterSize / PassAndRunCharacterVisual.canvasSize);
  }

  /// 前回検査から期限内の終点まで、球と仲間の相対移動をsweepする。
  /// pause中の壁時計を使わず、投球経過時間で保持する。
  Offset? _sweptCatch(DateTime now, DateTime deadline) {
    final started = _passStartedAt;
    if (started == null ||
        _passStartOffset == null ||
        _passTargetOffset == null) {
      return null;
    }
    final endUs = math.min(
      _passTravelDuration.inMicroseconds,
      math.min(
        now.difference(started).inMicroseconds,
        deadline.difference(started).inMicroseconds,
      ),
    );
    var fromUs = _collisionCheckedElapsed.inMicroseconds;
    if (endUs < fromUs) return null;
    final startSeconds =
        started.difference(_roundStartedAt!).inMicroseconds / 1000000;
    Offset ballAt(int us) => Offset.lerp(
          _passStartOffset,
          _passTargetOffset,
          (us / _passTravelDuration.inMicroseconds).clamp(0, 1),
        )!;
    double radiusAt(int us) {
      final seconds = startSeconds + us / 1000000;
      final from = _releaseCollisionRadius ??
          _collisionRadiusAt(PassRunCharacter.normal, startSeconds);
      final to = _collisionRadiusAt(PassRunCharacter.companion, seconds);
      final blend = (us / _collisionBlendDuration.inMicroseconds).clamp(0, 1);
      return from +
          (to - from) * blend +
          PassAndRunRules.mateCollisionRadius *
              (_characterSize / PassAndRunCharacterVisual.canvasSize);
    }

    // 半径が変わる240ms境界と220ms blend終端だけで区切る。
    // 描画時間を固定刻みに細分化するループではない。
    do {
      final seconds = startSeconds + fromUs / 1000000;
      final nextRadiusUs =
          (((seconds * 1000000 / 240000).floor() + 1) * 240000 -
              (startSeconds * 1000000).round());
      var toUs = math.min(endUs, math.max(fromUs + 1, nextRadiusUs));
      if (fromUs < _collisionBlendDuration.inMicroseconds) {
        toUs = math.min(toUs, _collisionBlendDuration.inMicroseconds);
      }
      final startDelta =
          ballAt(fromUs) - _mateOffsetAt(startSeconds + fromUs / 1000000);
      final endDelta =
          ballAt(toUs) - _mateOffsetAt(startSeconds + toUs / 1000000);
      // 境界直前の半径で区間を解き、境界後の値は次区間で扱う。
      final hit = PassAndRunRules.sweptCollision(
        startX: startDelta.dx,
        startY: startDelta.dy,
        endX: endDelta.dx,
        endY: endDelta.dy,
        startRadius: radiusAt(fromUs),
        endRadius: radiusAt(toUs > fromUs ? toUs - 1 : toUs),
      );
      if (hit != null) {
        _collisionCheckedElapsed = Duration(microseconds: endUs);
        return ballAt(fromUs + ((toUs - fromUs) * hit).round());
      }
      // 半径が不連続に増える境界が検査終端でも、境界後の円を検査する。
      if (PassAndRunRules.hasCollided(
        ballDeltaX: endDelta.dx,
        ballDeltaY: endDelta.dy,
        ballRadius: radiusAt(toUs),
        mateRadius: 0,
      )) {
        _collisionCheckedElapsed = Duration(microseconds: endUs);
        return ballAt(toUs);
      }
      fromUs = toUs;
    } while (fromUs < endUs);
    _collisionCheckedElapsed = Duration(microseconds: endUs);
    return null;
  }

  /// 一時停止を考慮した現在のパス経過時間を返します。
  Duration get _passElapsed {
    if (_isPaused && _pausedPassElapsed != null) return _pausedPassElapsed!;
    final startedAt = _passStartedAt;
    if (startedAt == null) return Duration.zero;
    return _now().difference(startedAt);
  }

  Duration get _returnElapsed {
    if (_isPaused && _pausedReturnElapsed != null) return _pausedReturnElapsed!;
    return _returnStartedAt == null
        ? Duration.zero
        : _now().difference(_returnStartedAt!);
  }

  /// 独立球は飛翔中だけ表示。仲間保持中は画像内の球が移動に追従します。
  Offset get _ballOffset {
    if (!_passInFlight) return _playerBallOffset;
    if (_mateHolding) {
      return _mateBallOffset +
          (_catchBallDisplacement ?? Offset.zero) * (1 - _catchProgress);
    }
    final returning = _returnStartedAt != null;
    final start = returning ? _passReturnStartOffset : _passStartOffset;
    final target = returning ? _passReturnTargetOffset : _passTargetOffset;
    if (start == null || target == null) return _playerBallOffset;
    final elapsed = returning ? _returnElapsed : _passElapsed;
    final duration = returning ? _passReturnDuration : _passTravelDuration;
    final progress = elapsed.inMicroseconds / duration.inMicroseconds;
    return Offset.lerp(start, target, progress.clamp(0, 1).toDouble())!;
  }

  Offset get _ballTrailStart => _returnStartedAt == null
      ? _passStartOffset ?? _playerOffset
      : _passReturnStartOffset ?? _mateOffset;

  void _clearPassCycle() {
    _passInFlight = false;
    _passScoreConfirmed = false;
    _pendingPassRoundIndex = null;
    _passStartedAt = null;
    _collisionCheckedElapsed = Duration.zero;
    _passArrivalAt = null;
    _passReadyAt = null;
    _passStartOffset = null;
    _passTargetOffset = null;
    _passReturnStartOffset = null;
    _passReturnTargetOffset = null;
    _returnStartedAt = null;
    _catchBallDisplacement = null;
    _catchBallGeometry = null;
    _releaseBallGeometry = null;
    _returnReleaseGeometry = null;
  }

  double _distanceCorrection(
    PassRunAssistedMovement movement,
    double previous,
    PassRunRunner runner,
    double seconds,
  ) =>
      previous +
      _motion.runningForwardRate * (seconds - movement.start) +
      _motion.geometry.movementRadius *
          2 *
          movement.distanceSinceStart(seconds) -
      (_motion.distanceAt(seconds, runner, outbound: _isOutbound) -
          _motion.distanceAt(movement.start, runner, outbound: _isOutbound));

  /// 返球後だけ、仲間を鮫太郎の後方へ滑らかに寄せて次のパスを作ります。
  /// 2秒後は元の独立した走行軌道へ戻り、設定された可動域を保ちます。
  double _mateRecoveryTarget(double seconds) {
    final span = _motion.geometry.movementRadius * 2;
    final assisted = _playerAssist;
    final playerFraction = assisted?.positionAt(seconds) ??
        (_motion.yAt(seconds, PassRunRunner.player, outbound: _isOutbound) -
                _motion.geometry.minimum) /
            span;
    final behind =
        PassRunReturnSprint.recoveryBehindFraction * (_isOutbound ? 1 : -1);
    return (playerFraction + behind).clamp(.025, .975).toDouble();
  }

  /// Help only a prolonged blocked relationship, never align both runners.
  bool _updateMovementAssistance() {
    if (_phase != _PassGamePhase.playing || _isPaused || _turnProgress < 1) {
      return false;
    }
    final t = _motionSeconds;
    final mateCarrier = _passScoreConfirmed && _returnStartedAt == null;
    final playerCarrier = !_passInFlight && !_isPenalized;
    if (!mateCarrier && !playerCarrier) {
      _blockedSince = null;
      _playerAssist?.release(t);
      return false;
    }
    final direction = mateCarrier
        ? _returnPlan(_mateBallOffset).target - _mateBallOffset
        : _mateOffset - _playerOffset;
    final blocked = PassAndRunRules.isForwardDirection(
      deltaX: direction.dx,
      deltaY: direction.dy,
      outbound: _isOutbound,
    );
    if (!blocked) {
      _blockedSince = null;
      _playerAssist?.release(t);
      return false;
    }
    _blockedSince ??= t;
    if (t - _blockedSince! < (mateCarrier ? .25 : .65) ||
        (_lastPaceDecisionAt != null && t - _lastPaceDecisionAt! < .35)) {
      return false;
    }
    final previous = _playerAssist;
    final up = _isOutbound;
    double base(double at) =>
        (_motion.yAt(at, PassRunRunner.player, outbound: up) -
            _motion.geometry.minimum) /
        (_motion.geometry.movementRadius * 2);
    double velocity(double at) =>
        (_motion.worldVelocityYAt(at, PassRunRunner.player, outbound: up) +
            (up ? 1 : -1) * _motion.runningForwardRate) /
        (_motion.geometry.movementRadius * 2);
    if (previous != null) {
      _playerAssistDistanceBase = _distanceCorrection(
        previous,
        _playerAssistDistanceBase,
        PassRunRunner.player,
        t,
      );
    }

    final forecastSeconds =
        _motion.roundSeconds + PassRunMotion.maxForecastSeconds;
    final phaseRoom = math.max(
      0.0,
      PassRunMotion.trajectoryProfileHorizonSeconds / _settings.runSpeedScale -
          forecastSeconds,
    );
    // Reserve 25% for a smooth rate transition's small overshoot. Preserve
    // the existing random profile instead of regenerating it with a new horizon.
    final maximumRate = math.min(
      1.12,
      1 + phaseRoom / (forecastSeconds * 1.25),
    );
    final mateMovement = _mateSprint;
    double mateAt(double at) =>
        mateMovement?.positionAt(at) ??
        (_motion.yAt(at, PassRunRunner.companion, outbound: up) -
                _motion.geometry.minimum) /
            (_motion.geometry.movementRadius * 2);
    PassRunPaceAssist? selected;
    var bestCost = double.infinity;
    // Choose only a pace, never a position or a new route. Reevaluate slowly
    // because the independent random path may turn while an assist is active.
    for (final rate in [1.0, maximumRate, .88]) {
      final candidate = PassRunPaceAssist(
        start: t,
        normalPosition: base,
        normalVelocity: velocity,
        targetRate: rate,
        attackUp: up,
        previous: previous,
      );
      var firstLegal = 3.05, deficit = 0.0;
      for (var tick = 1; tick <= 60; tick++) {
        final ahead = tick * .05;
        final difference = (mateCarrier
                ? candidate.positionAt(t + ahead) - mateAt(t + ahead)
                : mateAt(t + ahead) - candidate.positionAt(t + ahead)) *
            (up ? 1 : -1);
        if (difference >= .01 && firstLegal > 3) firstLegal = ahead;
        deficit += math.max(0, -difference) * (1 - ahead / 4);
      }
      final cost = firstLegal * 100 + deficit;
      if (cost < bestCost) {
        bestCost = cost;
        selected = candidate;
      }
    }
    _playerAssist = selected!;
    _lastPaceDecisionAt = t;
    return true;
  }

  /// 慣性なし・一定球速と、現在の移動モデルによる将来の受球点です。
  /// 距離は場内に有界、開始時は距離>0、上限では球移動距離が必ず勝ちます。
  /// 投球後は直線等速で、この確定点へ飛ばします。
  ({Offset target, Duration duration}) _returnPlan(Offset origin) {
    final speed = _fieldSize.width *
        .5 /
        (_passArrivalDuration.inMicroseconds / Duration.microsecondsPerSecond);
    final seconds = _motionSeconds;
    var low = 0.0;
    var high = (_fieldSize.width + _fieldSize.height + 224) / speed;
    for (var i = 0; i < 32; i++) {
      final mid = (low + high) / 2;
      final future = seconds + mid;
      final target = _playerBallOffsetAt(
        _playerOffsetAt(future),
        seconds: future,
      );
      if ((target - origin).distance > speed * mid) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final future = seconds + high;
    return (
      target: _playerBallOffsetAt(_playerOffsetAt(future), seconds: future),
      duration: Duration(microseconds: math.max(1, (high * 1000000).round())),
    );
  }

  bool _updatePassCycle(DateTime now) {
    if (!_passInFlight || _isPaused || _pendingPassRoundIndex != _roundIndex) {
      return false;
    }
    var changed = false;
    final deadline = _roundStartedAt?.add(_roundDuration);
    final caught = !_passScoreConfirmed && deadline != null
        ? _sweptCatch(now, deadline)
        : null;
    if (caught != null) {
      // 捕球後80msは承認済み非保持画と独立球で保持位置まで連続接続。
      // 最後に球中心・寸法・傾きが一致した瞬間だけ保持画へ切り替えます。
      final caughtBall = caught;
      final caughtGeometry = _ballGeometry;
      _catchBallDisplacement = caughtBall - _mateBallOffset;
      _catchBallGeometry = caughtGeometry;
      _roundScores[_roundIndex]++;
      _passScoreConfirmed = true;
      _lastPassSucceeded = true;
      _playSound(TrainingGameSoundEffect.passReceived);
      _passTravelDuration = _passElapsed;
      _passArrivalAt = now;
      final seconds = _motionSeconds;
      final previousSprint = _mateSprint;
      final outbound = _isOutbound;
      // Store sprint coordinates in the usable-area fraction, so rotation
      // changes the field mapping rather than invalidating cached bounds.
      double basePosition(double t) =>
          (_motion.yAt(t, PassRunRunner.companion, outbound: outbound) -
              _motion.geometry.minimum) /
          (_motion.geometry.movementRadius * 2);
      double baseVelocity(double t) =>
          (_motion.worldVelocityYAt(
                t,
                PassRunRunner.companion,
                outbound: outbound,
              ) +
              (outbound ? 1 : -1) * _motion.runningForwardRate) /
          (_motion.geometry.movementRadius * 2);
      if (previousSprint != null) {
        _mateSprintDistanceBase +=
            _motion.runningForwardRate * (seconds - previousSprint.start) +
                _motion.geometry.movementRadius *
                    2 *
                    previousSprint.distanceSinceStart(seconds) -
                (_motion.distanceAt(
                      seconds,
                      PassRunRunner.companion,
                      outbound: outbound,
                    ) -
                    _motion.distanceAt(
                      previousSprint.start,
                      PassRunRunner.companion,
                      outbound: outbound,
                    ));
      }
      _mateSprint = PassRunReturnSprint(
        start: seconds,
        position: previousSprint?.positionAt(seconds) ?? basePosition(seconds),
        velocity: previousSprint?.velocityAt(seconds) ?? baseVelocity(seconds),
        acceleration: previousSprint?.accelerationAt(seconds) ??
            (baseVelocity(seconds + .001) - baseVelocity(seconds)) / .001,
        minimum: 0,
        maximum: 1,
        attackUp: outbound,
        normalPosition: basePosition,
        normalVelocity: baseVelocity,
        end: _roundDuration.inMilliseconds / 1000 + 6,
        normalSpeed: .18 *
            _settings.runSpeedScale /
            (_motion.geometry.movementRadius * 2),
      );
      _passReadyAt = null;
      changed = true;
    }
    if (!_passScoreConfirmed &&
        _passArrivalAt != null &&
        !now.isBefore(_passArrivalAt!)) {
      _playSound(TrainingGameSoundEffect.passFailed);
      _isBallLost = true;
      _penaltyUntil = now.add(_missPenalty);
      _clearPassCycle();
      return true;
    }
    if (_mateHolding &&
        _passArrivalAt != null &&
        !now.isBefore(_passArrivalAt!.add(_passReturnDelay))) {
      final origin = _mateBallOffset;
      var plan = _returnPlan(origin);
      var direction = plan.target - origin;
      // Freeze the receiver's coast BEFORE fixing the flight endpoint.
      // An assisted forecast must never change after the ball has launched.
      if (!PassAndRunRules.isForwardDirection(
        deltaX: direction.dx,
        deltaY: direction.dy,
        outbound: _isOutbound,
      )) {
        _playerAssist?.release(_motionSeconds);
        plan = _returnPlan(origin);
        direction = plan.target - origin;
      }
      if (!PassAndRunRules.isForwardDirection(
        deltaX: direction.dx,
        deltaY: direction.dy,
        outbound: _isOutbound,
      )) {
        _passReturnStartOffset = origin;
        _returnReleaseGeometry = _geometryAt(
          PassRunCharacter.companion,
          _motionSeconds,
        );
        _passReturnTargetOffset = plan.target;
        _passReturnDuration = plan.duration;
        _mateSprint?.release(
          _motionSeconds,
          recoveryTarget: _mateRecoveryTarget,
        );
        _returnStartedAt = now;
        _passReadyAt = now.add(plan.duration);
        changed = true;
      }
    }
    if (_returnStartedAt != null &&
        _passReadyAt != null &&
        !now.isBefore(_passReadyAt!)) {
      _clearPassCycle();
      changed = true;
    }
    return changed;
  }

  /// ミニゲーム結果を育成画面へ返します。
  void _completeGame() {
    if (_resultReturned || ModalRoute.of(context)?.isCurrent != true) return;
    _resultReturned = true;
    Navigator.of(context).pop(
      MiniGameResult.passAndRun(
        outboundScore: _roundScores[0],
        inboundScore: _roundScores[1],
      ),
    );
  }

  /// 手動操作またはOS割り込みで、残り時間を保持したまま停止します。
  void _pauseGame() {
    if (_phase != _PassGamePhase.playing || _isPaused) return;
    final now = _now();
    if (!now.isBefore(_roundStartedAt!.add(_roundDuration))) {
      _finishRound();
      if (_phase != _PassGamePhase.playing) return;
    }
    // 次のticker前に返球期限を越えても、完了状態を保存して停止します。
    _updatePassCycle(now);
    _pausedRoundRemaining =
        _roundStartedAt!.add(_roundDuration).difference(now);
    _remainingMilliseconds = _pausedRoundRemaining!.inMilliseconds.clamp(
      0,
      _roundDuration.inMilliseconds,
    );
    _pausedReturnElapsed =
        _returnStartedAt == null ? null : now.difference(_returnStartedAt!);
    _pausedPenaltyRemaining =
        _penaltyUntil != null && now.isBefore(_penaltyUntil!)
            ? _penaltyUntil!.difference(now)
            : null;
    _pausedPassRemaining = _passReadyAt != null && now.isBefore(_passReadyAt!)
        ? _passReadyAt!.difference(now)
        : null;
    _pausedPassElapsed =
        _passStartedAt == null ? null : now.difference(_passStartedAt!);
    _clockTimer?.cancel();
    _fieldTicker.stop();
    setState(() => _isPaused = true);
  }

  /// 一時停止前の残り時間と入力待ちを復元します。
  void _resumeGame() {
    final remaining = _pausedRoundRemaining;
    if (_phase != _PassGamePhase.playing || !_isPaused || remaining == null) {
      return;
    }
    final now = _now();
    _roundStartedAt = now.subtract(_roundDuration - remaining);
    _penaltyUntil = _pausedPenaltyRemaining == null
        ? null
        : now.add(_pausedPenaltyRemaining!);
    _passReadyAt =
        _pausedPassRemaining == null ? null : now.add(_pausedPassRemaining!);
    if (_passInFlight && _pausedPassElapsed != null) {
      _passStartedAt = now.subtract(_pausedPassElapsed!);
      _passArrivalAt = _passStartedAt!.add(_passTravelDuration);
      if (_returnStartedAt != null && _pausedReturnElapsed != null) {
        _returnStartedAt = now.subtract(_pausedReturnElapsed!);
      }
    }
    setState(() => _isPaused = false);
    _startRoundTimers();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          final box =
              _fieldInputKey.currentContext?.findRenderObject() as RenderBox?;
          final bounds =
              box == null ? null : box.localToGlobal(Offset.zero) & box.size;
          _sparseFlick.down(event, fieldBounds: bounds, ready: _canPass);
        },
        onPointerMove: _sparseFlick.move,
        onPointerUp: _sparseFlick.up,
        onPointerCancel: _sparseFlick.cancel,
        child: _buildGame(context),
      );

  Widget _buildGame(BuildContext context) {
    final remainingSeconds = (_remainingMilliseconds / 1000).clamp(
      0,
      _motion.roundSeconds,
    );
    return Scaffold(
      backgroundColor: const Color(0xffe9f4e5),
      appBar: AppBar(
        title: const Text('② パス＆ラン'),
        backgroundColor: const Color(0xff153d5b),
        foregroundColor: Colors.white,
        actions: [
          if (_phase == _PassGamePhase.playing)
            IconButton(
              onPressed: _isPaused ? _resumeGame : _pauseGame,
              tooltip: _isPaused ? '再開' : '一時停止',
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isOutbound ? '往路' : '復路',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '残り ${remainingSeconds.toStringAsFixed(1)}s　PASS $_totalScore',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _fieldTick,
                  builder: (context, _, child) => _buildField(),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusPanel(),
            ],
          ),
        ),
      ),
    );
  }

  /// 2本の縦レーンと並走する2人を表示します。
  Widget _buildField() {
    return LayoutBuilder(
      key: _fieldInputKey,
      builder: (context, constraints) {
        _fieldSize = constraints.biggest;
        _motion.updateFieldGeometry(_fieldSize);
        final player = _playerOffset;
        final mate = _mateOffset;
        final ball = _ballOffset;
        final actorSize = _characterSize;
        final labelScale = math.min(
          1.0,
          math.max(0.0, _fieldSize.height * .22 - actorSize / 2 - 2) / 16,
        );
        final ballGeometry = _ballGeometry;
        return GestureDetector(
          key: const Key('pass-field'),
          behavior: HitTestBehavior.opaque,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onPanCancel: () {
            _sparseFlick.block();
            setState(() {
              _dragStart = null;
              _dragCurrent = null;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color(0xff79ba63)),
                ),
                Positioned(
                  left: constraints.maxWidth * .25 - 2,
                  top: 16,
                  bottom: 16,
                  child: _LaneLine(offset: _floorOffset),
                ),
                Positioned(
                  left: constraints.maxWidth * .75 - 2,
                  top: 16,
                  bottom: 16,
                  child: _LaneLine(offset: _floorOffset),
                ),
                if (_phase == _PassGamePhase.playing &&
                    !_isPaused &&
                    _playerHolding)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const Key('pass-direction-guide'),
                        painter: PassRunDirectionGuidePainter(
                          center: player,
                          attackUp: _isOutbound,
                          seconds: _motionSeconds,
                        ),
                      ),
                    ),
                  ),
                if (_dragStart != null && _dragCurrent != null)
                  CustomPaint(
                    key: const Key('pass-flick-guide'),
                    size: constraints.biggest,
                    painter: _FlickGuidePainter(
                      start: _dragStart!,
                      end: _dragCurrent!,
                    ),
                  ),
                if (_showFlightTrail)
                  CustomPaint(
                    key: const Key('pass-ball-trail'),
                    size: constraints.biggest,
                    painter: _BallTrailPainter(
                      start: _ballTrailStart,
                      current: ball,
                    ),
                  ),
                if (_showFlightBall && _ballBehindActor)
                  Positioned(
                    key: const Key('pass-ball'),
                    left: ball.dx - ballGeometry.extent / 2,
                    top: ball.dy - ballGeometry.extent / 2,
                    child: PassAndRunBallVisual(geometry: ballGeometry),
                  ),
                Positioned(
                  left: player.dx - actorSize / 2,
                  top: player.dy - actorSize / 2,
                  child: PassAndRunCharacterVisual(
                    key: const Key('pass-player'),
                    character: PassRunCharacter.normal,
                    holding: _playerHoldingVisual,
                    frame: _frameAt(_motionSeconds, PassRunCharacter.normal),
                    facing: _spriteFacing(PassRunCharacter.normal),
                    size: actorSize,
                    visualScale: math.min(
                      PassAndRunCharacterVisual.candidateVisualScale,
                      (actorSize / 2 + 2) / (actorSize * 51 / 112),
                    ),
                    ballKey: const Key('pass-ball'),
                  ),
                ),
                Positioned(
                  left: player.dx - actorSize / 2,
                  top: player.dy - actorSize / 2 - 16 * labelScale - 2,
                  width: actorSize,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * labelScale,
                          vertical: 2 * labelScale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff153d5b),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '鮫太郎',
                          key: Key('pass-player-label'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10 * labelScale,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: mate.dx - actorSize / 2,
                  top: mate.dy - actorSize / 2,
                  child: PassAndRunCharacterVisual(
                    key: const Key('pass-mate'),
                    character: PassRunCharacter.companion,
                    holding: _mateHoldingVisual,
                    frame: _frameAt(_motionSeconds, PassRunCharacter.companion),
                    facing: _spriteFacing(PassRunCharacter.companion),
                    size: actorSize,
                    visualScale: math.min(
                      PassAndRunCharacterVisual.candidateVisualScale,
                      (actorSize / 2 + 2) / (actorSize * 51 / 112),
                    ),
                    ballKey: const Key('pass-ball'),
                  ),
                ),
                if (_showFlightBall && !_ballBehindActor)
                  Positioned(
                    key: const Key('pass-ball'),
                    left: ball.dx - ballGeometry.extent / 2,
                    top: ball.dy - ballGeometry.extent / 2,
                    child: PassAndRunBallVisual(geometry: ballGeometry),
                  ),
                if (_phase == _PassGamePhase.waiting) _buildStartOverlay(),
                MiniGameResultTransition(
                  visible: _phase == _PassGamePhase.result,
                  child: _buildResultOverlay(),
                ),
                if (_isPaused) _buildPauseOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ルールとスタートボタンをゲーム画面へ重ねます。
  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: .86),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'パス＆ラン',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${_secondsLabel(_roundDuration)}秒 × 往復2セット\n攻撃方向へは投げず、真横・後方の仲間を狙おう',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _assetsReady
                  ? _startGame
                  : _assetLoadFailed
                      ? _prepareImages
                      : null,
              child: Text(
                _assetsReady
                    ? 'スタート'
                    : _assetLoadFailed
                        ? '再読込'
                        : '準備中…',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 往復の成功回数とメイン画面へ戻る操作を表示します。
  Widget _buildResultOverlay() {
    return ColoredBox(
      color: const Color(0xff153d5b).withValues(alpha: .93),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('パス成功', style: TextStyle(color: Colors.white70)),
          Text(
            '$_totalScore',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 82,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            '回',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '往路 ${_roundScores[0]} ＋ 復路 ${_roundScores[1]}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _completeGame,
            child: const Text('メインへ戻る'),
          ),
        ],
      ),
    );
  }

  /// 一時停止中の入力を遮断し、再開操作を表示します。
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

  /// 入力可能状態、返球待ち、ミスペナルティを表示します。
  Widget _buildStatusPanel() {
    final message = _phase == _PassGamePhase.waiting
        ? '${_secondsLabel(_roundDuration)}秒 × 往復2セット（合計${_secondsLabel(_roundDuration * 2)}秒）'
        : _phase == _PassGamePhase.result
            ? 'プレイ完了'
            : _isPenalized
                ? '${_isForwardPass ? '前方パス' : 'MISS'}　${_secondsLabel(_missPenalty)}秒間パス不可'
                : _passInFlight && !_passScoreConfirmed
                    ? 'ボール移動中…'
                    : _mateHolding
                        ? '仲間からの返球待ち…'
                        : _passInFlight
                            ? '仲間から返球中…'
                            : !_canPass
                                ? '次のパスを準備中…'
                                : _lastPassSucceeded
                                    ? 'PASS!　次の仲間位置を狙おう'
                                    : '仲間の現在位置へ素早くフリック';
    return Container(
      width: double.infinity,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _isPenalized ? const Color(0xffffdddd) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 縦方向の移動レーンを破線で描画します。
class _LaneLine extends StatelessWidget {
  const _LaneLine({required this.offset});
  final double offset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4,
      child: CustomPaint(painter: _DashedLinePainter(offset)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.offset);
  final double offset;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3;
    for (var y = offset % 20 - 20; y < size.height; y += 20) {
      canvas.drawLine(Offset(2, y), Offset(2, y + 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      offset != oldDelegate.offset;
}

/// フリックの開始位置と現在の入力方向を、操作中だけ重ねて表示します。
class _FlickGuidePainter extends CustomPainter {
  const _FlickGuidePainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xff1f76d2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final originPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final originBorderPaint = Paint()
      ..color = const Color(0xff1f76d2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 指を置いた位置を丸で残し、どこからフリックしているかを示します。
    canvas.drawCircle(start, 12, originPaint);
    canvas.drawCircle(start, 12, originBorderPaint);
    final direction = end - start;
    if (direction.distance < 1) return;

    canvas.drawLine(start, end, guidePaint);
    final normalized = direction / direction.distance;
    final perpendicular = Offset(-normalized.dy, normalized.dx);
    final arrowBase = end - normalized * 18;
    canvas.drawLine(end, arrowBase + perpendicular * 9, guidePaint);
    canvas.drawLine(end, arrowBase - perpendicular * 9, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _FlickGuidePainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}

/// ボール移動中の残像と発光ラインを描画します。
class _BallTrailPainter extends CustomPainter {
  const _BallTrailPainter({required this.start, required this.current});

  final Offset start;
  final Offset current;

  @override
  void paint(Canvas canvas, Size size) {
    if ((current - start).distance < 1) return;
    final bounds = Rect.fromPoints(start, current).inflate(8);
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xaafff0a8)],
      ).createShader(bounds)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, current, linePaint);

    // ボールに近いほど濃くなる残像を重ね、速度感を表現します。
    for (var index = 1; index <= 4; index++) {
      final factor = 1 - index * .13;
      final point = Offset.lerp(start, current, factor)!;
      final trailPaint = Paint()
        ..color = const Color(0xfffff0a8).withValues(alpha: .42 - index * .07);
      canvas.drawOval(
        Rect.fromCenter(
          center: point,
          width: 18 - index * 2,
          height: 10 - index.toDouble(),
        ),
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BallTrailPainter oldDelegate) {
    return start != oldDelegate.start || current != oldDelegate.current;
  }
}
