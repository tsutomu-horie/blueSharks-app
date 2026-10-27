import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/training_game.controller.dart';
import 'controllers/training_game_new_game.controller.dart';
import 'training_hatching_scene.dart';

/// ワイヤーフレーム①「アプリ内 ゲーム起動」を表示します。
class TrainingGameLaunchScreen extends StatefulWidget {
  /// 起動画面を作成します。
  const TrainingGameLaunchScreen(
      {super.key, this.autoStart = false, this.provider});

  final bool autoStart;
  final TrainingGameProvider? provider;

  @override
  State<TrainingGameLaunchScreen> createState() =>
      _TrainingGameLaunchScreenState();
}

class _TrainingGameLaunchScreenState extends State<TrainingGameLaunchScreen> {
  late final Future<String?> _accessTokenFuture;
  bool _isLaunching = false;
  bool _autoStartPending = false;
  bool _didReplaceLaunch = false;
  late final int _session;

  @override
  void initState() {
    super.initState();
    _session = AuthToken.sessionVersion;
    _autoStartPending = widget.autoStart;
    _accessTokenFuture = AuthToken().getAccessToken();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final token = await _accessTokenFuture;
        if (!mounted) return;
        if (token?.isNotEmpty == true && _session == AuthToken.sessionVersion) {
          await _openGame();
        } else {
          setState(() => _autoStartPending = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLaunching,
      child: Scaffold(
        appBar:
            AppBar(title: Text(_autoStartPending ? 'ゲームを起動中…' : 'アプリ ｜ ゲーム')),
        body: FutureBuilder<String?>(
          future: _accessTokenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_autoStartPending) {
              return const Center(child: CircularProgressIndicator());
            }
            final authenticated = snapshot.data?.isNotEmpty == true;
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FlowPlaceholder(height: 180.h, label: 'ゲームバナー'),
                      SizedBox(height: 20.h),
                      Text(
                        '鮫太朗育成ゲーム',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        authenticated ? 'ゲームを開始できます。' : 'ゲームを起動するには会員認証が必要です。',
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed:
                              authenticated && !_isLaunching ? _openGame : null,
                          child: _isLaunching
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    const Text('起動中…'),
                                  ],
                                )
                              : const Text('ゲームを起動'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLaunching) _buildLaunchingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 起動中は画面操作を抑止し、待機中であることを表示します。
  Widget _buildLaunchingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: ColoredBox(
          color: Colors.black26,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 22.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 14.h),
                    Text(
                      'ゲームを起動中…',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 育成中の卵がある場合は②を省略し、③へ直接遷移します。
  Future<void> _openGame() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    final loadingDelay = Future<void>.delayed(
      TrainingGameController.randomTransitionLoadingDuration(),
    );
    try {
      await TrainingGameProvider.waitForPendingSync();
      final current = await (widget.provider ?? TrainingGameProvider())
          .fetchCurrent(expectedSessionVersion: _session);
      await loadingDelay;
      if (!mounted || _session != AuthToken.sessionVersion) return;
      if (current == null) {
        _navigateToGame(Routes.TRAINING_GAME_NEW);
      } else {
        // 取得済み状態を引き渡し、育成画面での同一API再取得を省略します。
        _navigateToGame(Routes.TRAINING_GAME, arguments: current);
      }
    } catch (_) {
      await loadingDelay;
      if (!mounted || _session != AuthToken.sessionVersion) return;
      // サーバー未接続時は新規開始画面へ進めます。
      _navigateToGame(Routes.TRAINING_GAME_NEW);
    } finally {
      if (mounted && !_didReplaceLaunch) {
        setState(() {
          _isLaunching = false;
          _autoStartPending = false;
        });
      }
    }
  }

  void _navigateToGame(String route, {Object? arguments}) {
    if (widget.autoStart) {
      _didReplaceLaunch = true;
      Get.offNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route, arguments: arguments);
    }
  }
}

/// 新しい出会いと孵化演出を表示し、保存成功後に幼体の育成へ進みます。
class TrainingGameNewGameScreen extends StatefulWidget {
  const TrainingGameNewGameScreen(
      {super.key, this.soundFactory = createTrainingHatchingSound});

  final TrainingGameSoundService Function() soundFactory;

  @override
  State<TrainingGameNewGameScreen> createState() =>
      _TrainingGameNewGameScreenState();
}

class _TrainingGameNewGameScreenState extends State<TrainingGameNewGameScreen>
    with WidgetsBindingObserver {
  late final TrainingGameNewGameController _controller;
  late final bool _forceRestart;
  late final int _session;
  bool _busy = false;
  bool _hatching = false;
  bool _hatched = false;
  bool _foreground = true;
  bool _didNavigate = false;
  Map<String, dynamic>? _startedState;
  int _sceneGeneration = 0;
  bool _sceneLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TrainingGameNewGameController>();
    final arguments = Get.arguments;
    _forceRestart = arguments is Map && arguments['debugRestart'] == true;
    _session = AuthToken.sessionVersion;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _openStartedGame();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('新しい出会い')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/training_game/scenes/home_outdoor_day.png',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xf2effaff),
                    Color(0xe6f5fcff),
                    Color(0xf2ffffff),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .85),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  '鮫太朗とのものがたり',
                                  style: TextStyle(
                                    color: Color(0xff26769a),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TrainingHatchingScene(
                                key: ValueKey(_sceneGeneration),
                                isPlaying: _hatching,
                                soundFactory: widget.soundFactory,
                                onCompleted: _onHatched,
                                onLoadFailed: _onSceneLoadFailed,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Obx(() => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_controller.errorMessage.value.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(_controller.errorMessage.value,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Color(0xffa12b2b))),
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff126694),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(0xff6b9db7),
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _busy ? null : _startGame,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_controller.isStarting.value) ...[
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Text(_controller.isStarting.value
                                            ? '育成を準備しています…'
                                            : _busy
                                                ? '卵がかえっています…'
                                                : _hatched
                                                    ? 'もう一度接続する'
                                                    : 'はじめる',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    if (_busy) return;
    _controller.errorMessage.value = '';
    setState(() {
      _busy = true;
      _hatching = true;
      if (_sceneLoadFailed) {
        _sceneGeneration++;
        _sceneLoadFailed = false;
      }
    });
    if (_hatched) _submitStart();
  }

  void _onHatched() {
    if (!mounted || _hatched) return;
    _hatched = true;
    _submitStart();
  }

  void _onSceneLoadFailed() {
    if (!mounted) return;
    _controller.errorMessage.value = '素材を読み込めませんでした。もう一度お試しください。';
    setState(() {
      _busy = false;
      _hatching = false;
      _sceneLoadFailed = true;
    });
  }

  Future<void> _submitStart() async {
    if (!mounted) return;
    if (_session != AuthToken.sessionVersion) {
      _controller.errorMessage.value =
          'ログイン状態が変わりました。画面を閉じて、もう一度お試しください。';
      setState(() => _busy = false);
      return;
    }
    final state = await _controller.startNewGame(forceRestart: _forceRestart);
    if (!mounted) return;
    if (_session != AuthToken.sessionVersion) {
      _controller.errorMessage.value =
          'ログイン状態が変わりました。画面を閉じて、もう一度お試しください。';
      setState(() => _busy = false);
      return;
    }
    if (state == null) {
      setState(() => _busy = false);
      return;
    }
    _startedState = state;
    _openStartedGame();
  }

  void _openStartedGame() {
    if (!mounted || !_foreground || _didNavigate || _startedState == null) return;
    if (_session != AuthToken.sessionVersion) {
      _controller.errorMessage.value =
          'ログイン状態が変わりました。画面を閉じて、もう一度お試しください。';
      setState(() {
        _busy = false;
        _startedState = null;
      });
      return;
    }
    _didNavigate = true;
    // 通常再開の冪等応答には_new_cycleを付けず、保存済み進行を維持します。
    Get.offNamed(Routes.TRAINING_GAME, arguments: _startedState);
  }
}

/// 素材が未提供のワイヤーフレーム領域を表示します。
class _FlowPlaceholder extends StatelessWidget {
  /// プレースホルダーを作成します。
  const _FlowPlaceholder({required this.height, required this.label});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xffe2e5e8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xffc4c9ce)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xff5b6672))),
    );
  }
}
