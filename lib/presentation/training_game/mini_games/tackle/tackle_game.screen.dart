import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/mini_game_result.dart';
import 'tackle_game_logic.dart';

enum _TacklePhase {
  waiting,
  approach,
  input,
  resolution,
  attemptResult,
  gameResult,
}

/// 3セットの反応速度を計測するタックルミニゲームです。
class TackleGameScreen extends StatefulWidget {
  /// タックルミニゲーム画面を作成します。
  const TackleGameScreen({super.key});

  @override
  State<TackleGameScreen> createState() => _TackleGameScreenState();
}

class _TackleGameScreenState extends State<TackleGameScreen>
    with WidgetsBindingObserver {
  final _random = Random();
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

  int get _setNumber => (_attempts.length + 1).clamp(1, TackleRules.setCount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _timers) {
      timer.cancel();
    }
    _reactionWatch.stop();
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
    _cancelTimers();
    _phaseStartedAt = DateTime.now();
    setState(() {
      _latestAttempt = null;
      _attemptSucceeded = null;
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
    _timers.add(Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _phase != _TacklePhase.approach || _isPaused) return;
      setState(() {
        _opponentDuration = const Duration(milliseconds: 650);
        _opponentCurve = Curves.easeOut;
        _opponentAlignment = const Alignment(-.18, 0);
      });
    }));
    _timers.add(Timer(const Duration(milliseconds: 1350), _startFeint));
  }

  /// ランダムな踏み込みと、その反対方向への切り返しを開始します。
  void _startFeint() {
    if (!mounted || _phase != _TacklePhase.approach || _isPaused) return;
    final feintDirection =
        _random.nextBool() ? TackleDirection.up : TackleDirection.down;
    _actualDirection = feintDirection == TackleDirection.up
        ? TackleDirection.down
        : TackleDirection.up;
    _phaseStartedAt = DateTime.now();
    _reactionWatch
      ..reset()
      ..start();
    setState(() {
      _phase = _TacklePhase.input;
      _opponentDuration = const Duration(milliseconds: 110);
      _opponentCurve = Curves.easeInOut;
      _opponentAlignment = Alignment(
        -.18,
        feintDirection == TackleDirection.up ? -.48 : .48,
      );
    });
    // 踏み込みを短く見せた後、仕様どおり反対方向へ切り返します。
    _timers.add(Timer(const Duration(milliseconds: 110), () {
      if (!mounted || _phase != _TacklePhase.input || _isPaused) return;
      setState(() {
        _opponentAlignment = Alignment(
          -.36,
          _actualDirection == TackleDirection.up ? -.58 : .58,
        );
      });
    }));
    _timers.add(Timer(TackleRules.inputLimit, () => _finishAttempt(null)));
  }

  /// 上下いずれかのタップを現在セットの結果へ変換します。
  void _handleDirection(TackleDirection direction) {
    if (_isPaused) return;
    if (_phase == _TacklePhase.approach) {
      // 判定開始前のタップは、お手つきとしてこのセットをMISSにします。
      _finishAttempt(
        const TackleAttempt(isCorrect: false),
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
            direction == _actualDirection && reaction <= TackleRules.inputLimit,
        reaction: reaction,
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
        (_phase != _TacklePhase.input && _phase != _TacklePhase.approach)) {
      return;
    }
    _cancelTimers();
    _reactionWatch.stop();
    final result = attempt ?? const TackleAttempt(isCorrect: false);
    final success = result.isCorrect;
    setState(() {
      _attempts.add(result);
      _latestAttempt = result;
      _attemptSucceeded = success;
      _phase = _TacklePhase.resolution;
      // 成否にかかわらず、ユーザーがタップした上／下方向へ鮫太朗を移動します。
      if (tappedDirection != null) {
        _playerDuration = const Duration(milliseconds: 160);
        _playerAlignment = Alignment(
          -.82,
          tappedDirection == TackleDirection.up ? -.36 : .36,
        );
      }
      // 成功時は鮫太朗の手前で止め、失敗時は左端の画面外まで抜けさせます。
      _opponentDuration = success
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 520);
      _opponentCurve = success ? Curves.easeOut : Curves.easeIn;
      _opponentAlignment = Alignment(
        success ? -.58 : -1.35,
        _actualDirection == TackleDirection.up ? -.58 : .58,
      );
    });
    // 決着演出を確認してから、ユーザーが次セットへ進める判定画面を表示します。
    _timers.add(Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _phase != _TacklePhase.resolution) return;
      setState(() => _phase = _TacklePhase.attemptResult);
    }));
  }

  /// 次セット、または3セット後の総合結果へ進みます。
  void _advanceAfterAttempt() {
    if (_attempts.length >= TackleRules.setCount) {
      setState(() => _phase = _TacklePhase.gameResult);
      return;
    }
    _startAttempt();
  }

  /// ミニゲーム結果を育成画面へ返します。
  void _completeGame() {
    final average = TackleRules.averageReaction(_attempts);
    final successCount = _attempts.where((attempt) => attempt.isCorrect).length;
    Navigator.of(context).pop(
      MiniGameResult.tackle(
        rank: TackleRules.overallRank(_attempts),
        averageSeconds: average == null
            ? null
            : average.inMicroseconds / Duration.microsecondsPerSecond,
        successCount: successCount,
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
        (_phase != _TacklePhase.approach && _phase != _TacklePhase.input)) {
      return;
    }
    final elapsed = _phaseStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_phaseStartedAt!);
    final limit = _phase == _TacklePhase.approach
        ? const Duration(milliseconds: 1350)
        : TackleRules.inputLimit;
    _pausedDelay = elapsed >= limit ? Duration.zero : limit - elapsed;
    _restartInputOnResume = _phase == _TacklePhase.input;
    _cancelTimers();
    if (_phase == _TacklePhase.input) _reactionWatch.stop();
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
        ? const Duration(milliseconds: 1350)
        : TackleRules.inputLimit;
    _phaseStartedAt = DateTime.now().subtract(limit - delay);
    setState(() {
      _isPaused = false;
      _opponentDuration = delay;
      _opponentCurve = Curves.easeOut;
      _opponentAlignment = const Alignment(-.18, 0);
    });
    if (_phase == _TacklePhase.approach) {
      _timers.add(Timer(delay, _startFeint));
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
          if (_phase == _TacklePhase.approach || _phase == _TacklePhase.input)
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
          'SET $_setNumber / ${TackleRules.setCount}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Text('判定猶予 0.5秒'),
      ],
    );
  }

  /// 接近する相手と上下の入力領域を表示します。
  Widget _buildField() {
    return ClipRRect(
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
            duration: _playerDuration,
            curve: Curves.easeOut,
            alignment: _playerAlignment,
            child: Text('🦈', style: TextStyle(fontSize: 72)),
          ),
          AnimatedAlign(
            duration: _opponentDuration,
            curve: _opponentCurve,
            alignment: _opponentAlignment,
            child: const Text('🏃', style: TextStyle(fontSize: 58)),
          ),
          if (_phase == _TacklePhase.resolution) _buildResolutionOverlay(),
          if (_phase == _TacklePhase.waiting)
            _buildOverlay(
              title: 'タックル練習',
              detail: '全3セット',
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
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
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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

  /// 3セットの総合ランクと記録を表示します。
  Widget _buildResultOverlay() {
    final rank = TackleRules.overallRank(_attempts);
    final successCount = _attempts.where((attempt) => attempt.isCorrect).length;
    final average = TackleRules.averageReaction(_attempts);
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
              '平均反応 $averageLabel　成功 $successCount/${TackleRules.setCount}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _completeGame, child: const Text('メインへ戻る')),
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
                    ? '今だ！ 踏み込みと反対をタップ'
                    : '全3セットの反応速度を計測します',
          ),
        ),
      );
    }
    final reaction = _latestAttempt!.reaction;
    final reactionLabel = reaction == null
        ? '時間切れ'
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Text('>> タップして次へ <<'),
            ],
          ),
        ),
      ),
    );
  }
}
