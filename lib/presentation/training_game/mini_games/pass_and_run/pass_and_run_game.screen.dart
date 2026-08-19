import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mini_game_result.dart';
import 'pass_and_run_logic.dart';

enum _PassGamePhase {
  waiting,
  playing,
  result,
}

/// 仲間の方向へフリックして成功回数を競うパス＆ランです。
class PassAndRunGameScreen extends StatefulWidget {
  /// パス＆ラン画面を作成します。
  const PassAndRunGameScreen({super.key});

  @override
  State<PassAndRunGameScreen> createState() => _PassAndRunGameScreenState();
}

class _PassAndRunGameScreenState extends State<PassAndRunGameScreen>
    with WidgetsBindingObserver {
  static const _passArrivalDuration = Duration(milliseconds: 220);
  static const _passCycleDuration = Duration(milliseconds: 400);

  _PassGamePhase _phase = _PassGamePhase.waiting;
  final _roundScores = <int>[0, 0];
  Timer? _clockTimer;
  DateTime? _roundStartedAt;
  DateTime? _penaltyUntil;
  DateTime? _passStartedAt;
  DateTime? _passArrivalAt;
  DateTime? _passReadyAt;
  Offset? _passStartOffset;
  Offset? _passTargetOffset;
  Offset? _dragStart;
  Offset? _dragCurrent;
  Size _fieldSize = Size.zero;
  int _roundIndex = 0;
  int _remainingMilliseconds = PassAndRunRules.roundDuration.inMilliseconds;
  bool _lastPassSucceeded = false;
  bool _passInFlight = false;
  bool _passScoreConfirmed = false;
  bool _isFailedPass = false;
  bool _isBallLost = false;
  int? _pendingPassRoundIndex;
  bool _isPaused = false;
  Duration? _pausedRoundRemaining;
  Duration? _pausedPenaltyRemaining;
  Duration? _pausedPassRemaining;
  Duration? _pausedPassElapsed;

  bool get _isOutbound => _roundIndex == 0;
  bool get _isPenalized =>
      _penaltyUntil != null && DateTime.now().isBefore(_penaltyUntil!);
  bool get _canPass =>
      _phase == _PassGamePhase.playing &&
      !_isPaused &&
      !_isPenalized &&
      !_passInFlight &&
      (_passReadyAt == null || !DateTime.now().isBefore(_passReadyAt!));
  int get _totalScore => _roundScores.fold(0, (sum, score) => sum + score);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
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
    _roundIndex = 0;
    _roundScores
      ..clear()
      ..addAll([0, 0]);
    _startRound();
  }

  /// 現在の片道15秒を開始します。
  void _startRound({Duration carryPenalty = Duration.zero}) {
    _clockTimer?.cancel();
    _roundStartedAt = DateTime.now();
    _penaltyUntil =
        carryPenalty > Duration.zero ? DateTime.now().add(carryPenalty) : null;
    _passReadyAt = null;
    _passStartedAt = null;
    _passArrivalAt = null;
    _passStartOffset = null;
    _passTargetOffset = null;
    _passInFlight = false;
    _passScoreConfirmed = false;
    _isFailedPass = false;
    _isBallLost = false;
    _pendingPassRoundIndex = null;
    _remainingMilliseconds = PassAndRunRules.roundDuration.inMilliseconds;
    setState(() {
      _phase = _PassGamePhase.playing;
      _isPaused = false;
      _lastPassSucceeded = false;
    });
    _startRoundTimers();
  }

  /// 現在の残り時間から計測と位置入替を開始します。
  void _startRoundTimers() {
    _clockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _roundStartedAt == null) return;
      final now = DateTime.now();
      _updatePassCycle(now);
      final elapsed = now.difference(_roundStartedAt!);
      final remaining = PassAndRunRules.roundDuration - elapsed;
      if (remaining <= Duration.zero) {
        _finishRound();
        return;
      }
      setState(() => _remainingMilliseconds = remaining.inMilliseconds);
    });
  }

  /// 往路から復路、または復路から結果画面へ進みます。
  void _finishRound() {
    _updatePassCycle(DateTime.now());
    _clockTimer?.cancel();
    _passInFlight = false;
    _passScoreConfirmed = false;
    _isFailedPass = false;
    _isBallLost = false;
    _pendingPassRoundIndex = null;
    _passStartedAt = null;
    _passArrivalAt = null;
    _passReadyAt = null;
    _passStartOffset = null;
    _passTargetOffset = null;
    _dragStart = null;
    _dragCurrent = null;
    if (_roundIndex == 0) {
      // 確定仕様に従い、往路終了時のペナルティ残時間を復路へ持ち越します。
      final carryPenalty = _isPenalized
          ? _penaltyUntil!.difference(DateTime.now())
          : Duration.zero;
      _roundIndex = 1;
      _startRound(carryPenalty: carryPenalty);
      return;
    }
    setState(() {
      _remainingMilliseconds = 0;
      _phase = _PassGamePhase.result;
    });
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

  /// 指を離した時点で距離・速度・仲間方向との角度差を判定します。
  void _handlePanEnd(DragEndDetails details) {
    final start = _dragStart;
    final current = _dragCurrent;
    _dragStart = null;
    _dragCurrent = null;
    if (!_canPass || start == null || current == null || _fieldSize.isEmpty) {
      // フリックが成立しない場合も、表示中の操作ガイドは即時に消します。
      setState(() {});
      return;
    }
    final velocity = details.velocity.pixelsPerSecond;
    final flick = PassFlick(
      deltaX: current.dx - start.dx,
      deltaY: current.dy - start.dy,
      velocityX: velocity.dx,
      velocityY: velocity.dy,
    );
    // 短い指のブレはミス扱いにせず、そのまま入力を待ちます。
    if (!PassAndRunRules.isFlick(flick)) {
      // 短いドラッグは発射せず、操作ガイドだけを消して次の入力を待ちます。
      setState(() {});
      return;
    }
    final player = _playerOffset;
    final mate = _mateOffset;
    final succeeded = PassAndRunRules.isAccurate(
      flick: flick,
      targetDeltaX: mate.dx - player.dx,
      targetDeltaY: mate.dy - player.dy,
    );
    // 成否にかかわらず、フリックとして成立した入力はボールを発射します。
    // 失敗時はフリック先まで飛ばし、得点を加算せずペナルティだけを適用します。
    final now = DateTime.now();
    _passInFlight = true;
    _passScoreConfirmed = false;
    _isFailedPass = !succeeded;
    _isBallLost = false;
    _pendingPassRoundIndex = _roundIndex;
    _passStartedAt = now;
    _passArrivalAt = now.add(_passArrivalDuration);
    _passReadyAt = now.add(_passCycleDuration);
    _passStartOffset = _playerBallOffset;
    _passTargetOffset = succeeded
        ? _mateCatchOffset
        : _flickExitOffset(start: start, current: current);
    if (!succeeded) {
      _penaltyUntil = DateTime.now().add(PassAndRunRules.missPenalty);
    }
    setState(() => _lastPassSucceeded = succeeded);
  }

  /// 失敗時にボールが画面外へ抜ける位置を、フリック方向から求めます。
  Offset _flickExitOffset({required Offset start, required Offset current}) {
    final direction = current - start;
    if (direction.distance == 0) return _playerBallOffset;
    // ClipRRectで切り取られる位置まで飛ばし、失敗パスの返球を発生させません。
    final exitDistance = math.max(_fieldSize.width, _fieldSize.height) * 2;
    return _playerBallOffset + direction / direction.distance * exitDistance;
  }

  /// 2人が異なる速度で上下し、追いつき・追い越しが起きる現在位置を返します。
  double get _motionSeconds {
    final startedAt = _roundStartedAt;
    if (startedAt == null) return 0;
    if (_isPaused && _pausedRoundRemaining != null) {
      return (PassAndRunRules.roundDuration - _pausedRoundRemaining!)
              .inMilliseconds /
          1000;
    }
    return DateTime.now().difference(startedAt).inMilliseconds / 1000;
  }

  Offset get _playerOffset {
    final y = .5 + .28 * math.sin(_motionSeconds * math.pi * 2 / 2.6);
    return Offset(
      _fieldSize.width * (_isOutbound ? .25 : .75),
      _fieldSize.height * y,
    );
  }

  Offset get _mateOffset {
    final y = .5 +
        .28 * math.sin(_motionSeconds * math.pi * 2 / 2.05 + math.pi * .65);
    return Offset(
      _fieldSize.width * (_isOutbound ? .75 : .25),
      _fieldSize.height * y,
    );
  }

  /// 鮫太朗が保持しているときのボール表示位置です。
  Offset get _playerBallOffset =>
      _playerOffset +
      Offset(
        _isOutbound ? 24 : -24,
        4,
      );

  /// 仲間が受け取るときのボール表示位置です。
  Offset get _mateCatchOffset =>
      _mateOffset +
      Offset(
        _isOutbound ? -20 : 20,
        4,
      );

  /// 一時停止を考慮した現在のパス経過時間を返します。
  Duration get _passElapsed {
    if (_isPaused && _pausedPassElapsed != null) return _pausedPassElapsed!;
    final startedAt = _passStartedAt;
    if (startedAt == null) return Duration.zero;
    return DateTime.now().difference(startedAt);
  }

  /// 成功時は往路と返球、失敗時は画面外へ抜ける現在のボール位置を返します。
  Offset get _ballOffset {
    final start = _passStartOffset;
    final target = _passTargetOffset;
    if (!_passInFlight || start == null || target == null) {
      return _playerBallOffset;
    }
    final elapsed = _passElapsed;
    if (elapsed <= _passArrivalDuration) {
      final progress =
          elapsed.inMicroseconds / _passArrivalDuration.inMicroseconds;
      return Offset.lerp(start, target, progress.clamp(0, 1).toDouble())!;
    }
    if (_isFailedPass) return target;
    final returnDuration = _passCycleDuration - _passArrivalDuration;
    final returnElapsed = elapsed - _passArrivalDuration;
    final progress =
        returnElapsed.inMicroseconds / returnDuration.inMicroseconds;
    return Offset.lerp(
      target,
      _playerBallOffset,
      progress.clamp(0, 1).toDouble(),
    )!;
  }

  /// 軌跡残像の始点を、パス往路・返球に応じて返します。
  Offset get _ballTrailStart {
    if (_isFailedPass || _passElapsed <= _passArrivalDuration) {
      return _passStartOffset ?? _playerOffset;
    }
    return _passTargetOffset ?? _mateOffset;
  }

  /// ボール到達時の得点確定と、返球完了後の次入力解放を更新します。
  void _updatePassCycle(DateTime now) {
    if (!_passInFlight || _isPaused || _pendingPassRoundIndex != _roundIndex) {
      return;
    }
    // ラウンド終了後のタイマー更新で、遅れて到達したボールを得点化しないようにします。
    final roundDeadline = _roundStartedAt?.add(PassAndRunRules.roundDuration);
    if (!_isFailedPass &&
        !_passScoreConfirmed &&
        _passArrivalAt != null &&
        roundDeadline != null &&
        !_passArrivalAt!.isAfter(roundDeadline) &&
        !now.isBefore(_passArrivalAt!)) {
      _roundScores[_roundIndex]++;
      _passScoreConfirmed = true;
    }
    if (_isFailedPass &&
        _passArrivalAt != null &&
        !now.isBefore(_passArrivalAt!)) {
      // 画面外へ抜けた失敗ボールを、ペナルティ中は再表示しません。
      _isBallLost = true;
    }
    if (_passReadyAt != null && !now.isBefore(_passReadyAt!)) {
      _passInFlight = false;
      _passScoreConfirmed = false;
      _pendingPassRoundIndex = null;
      _passStartedAt = null;
      _passArrivalAt = null;
      _passReadyAt = null;
      _passStartOffset = null;
      _passTargetOffset = null;
      _isFailedPass = false;
    }
  }

  /// ミニゲーム結果を育成画面へ返します。
  void _completeGame() {
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
    final now = DateTime.now();
    _pausedRoundRemaining = Duration(milliseconds: _remainingMilliseconds);
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
    setState(() => _isPaused = true);
  }

  /// 一時停止前の残り時間と入力待ちを復元します。
  void _resumeGame() {
    final remaining = _pausedRoundRemaining;
    if (_phase != _PassGamePhase.playing || !_isPaused || remaining == null) {
      return;
    }
    final now = DateTime.now();
    _roundStartedAt = now.subtract(PassAndRunRules.roundDuration - remaining);
    _penaltyUntil = _pausedPenaltyRemaining == null
        ? null
        : now.add(_pausedPenaltyRemaining!);
    _passReadyAt =
        _pausedPassRemaining == null ? null : now.add(_pausedPassRemaining!);
    if (_passInFlight && _pausedPassElapsed != null) {
      _passStartedAt = now.subtract(_pausedPassElapsed!);
      _passArrivalAt = _passStartedAt!.add(_passArrivalDuration);
    }
    setState(() => _isPaused = false);
    _startRoundTimers();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (_remainingMilliseconds / 1000).clamp(0, 15);
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
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '残り ${remainingSeconds.toStringAsFixed(1)}s　PASS $_totalScore',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildField()),
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
      builder: (context, constraints) {
        _fieldSize = constraints.biggest;
        final player = _playerOffset;
        final mate = _mateOffset;
        final ball = _ballOffset;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                    child: Container(color: const Color(0xff79ba63))),
                Positioned(
                  left: constraints.maxWidth * .25 - 2,
                  top: 16,
                  bottom: 16,
                  child: const _LaneLine(),
                ),
                Positioned(
                  left: constraints.maxWidth * .75 - 2,
                  top: 16,
                  bottom: 16,
                  child: const _LaneLine(),
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
                if (_passInFlight)
                  CustomPaint(
                    key: const Key('pass-ball-trail'),
                    size: constraints.biggest,
                    painter: _BallTrailPainter(
                      start: _ballTrailStart,
                      current: ball,
                    ),
                  ),
                Positioned(
                  left: player.dx - 28,
                  top: player.dy - 28,
                  child: const Text('🦈', style: TextStyle(fontSize: 52)),
                ),
                Positioned(
                  left: mate.dx - 24,
                  top: mate.dy - 24,
                  child: const Text('🏃', style: TextStyle(fontSize: 46)),
                ),
                if (_phase != _PassGamePhase.result &&
                    (!_isBallLost || !_isPenalized))
                  Positioned(
                    key: const Key('pass-ball'),
                    left: ball.dx - 15,
                    top: ball.dy - 10,
                    child: const _MockRugbyBall(),
                  ),
                if (_phase == _PassGamePhase.waiting) _buildStartOverlay(),
                if (_phase == _PassGamePhase.result) _buildResultOverlay(),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '15秒 × 往復2セット',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _startGame, child: const Text('スタート')),
          ],
        ),
      ),
    );
  }

  /// 往復の成功回数とメイン画面へ戻る操作を表示します。
  Widget _buildResultOverlay() {
    return Positioned.fill(
      child: ColoredBox(
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
            const Text('回',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              '往路 ${_roundScores[0]} ＋ 復路 ${_roundScores[1]}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _completeGame, child: const Text('メインへ戻る')),
          ],
        ),
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
        ? '15秒 × 往復2セット（合計30秒）'
        : _phase == _PassGamePhase.result
            ? 'プレイ完了'
            : _isPenalized
                ? 'MISS　2秒間パス不可'
                : _passInFlight && !_passScoreConfirmed
                    ? 'ボール移動中…'
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
  const _LaneLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3;
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(2, y), Offset(2, y + 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// フリックの開始位置と現在の入力方向を、操作中だけ重ねて表示します。
class _FlickGuidePainter extends CustomPainter {
  const _FlickGuidePainter({
    required this.start,
    required this.end,
  });

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
  const _BallTrailPainter({
    required this.start,
    required this.current,
  });

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
        ..color = const Color(0xfffff0a8).withValues(
          alpha: .42 - index * .07,
        );
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

/// 正式素材へ差し替えるまで使用するデフォルメラグビーボールです。
class _MockRugbyBall extends StatelessWidget {
  const _MockRugbyBall();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.35,
      child: const SizedBox(
        width: 30,
        height: 20,
        child: CustomPaint(painter: _MockRugbyBallPainter()),
      ),
    );
  }
}

class _MockRugbyBallPainter extends CustomPainter {
  const _MockRugbyBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ballRect = Offset.zero & size;
    canvas.drawOval(
      ballRect,
      Paint()..color = const Color(0xff9a552d),
    );
    canvas.drawOval(
      ballRect.deflate(1),
      Paint()
        ..color = const Color(0xff5f301c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final seamPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .3, size.height * .5),
      Offset(size.width * .7, size.height * .5),
      seamPaint,
    );
    for (var index = 0; index < 4; index++) {
      final x = size.width * (.4 + index * .07);
      canvas.drawLine(
        Offset(x, size.height * .38),
        Offset(x, size.height * .62),
        seamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MockRugbyBallPainter oldDelegate) => false;
}
