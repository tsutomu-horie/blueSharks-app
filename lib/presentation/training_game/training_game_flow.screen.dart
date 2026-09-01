import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/training_game.controller.dart';
import 'controllers/training_game_new_game.controller.dart';

/// ワイヤーフレーム①「アプリ内 ゲーム起動」を表示します。
class TrainingGameLaunchScreen extends StatefulWidget {
  /// 起動画面を作成します。
  const TrainingGameLaunchScreen({super.key});

  @override
  State<TrainingGameLaunchScreen> createState() =>
      _TrainingGameLaunchScreenState();
}

class _TrainingGameLaunchScreenState extends State<TrainingGameLaunchScreen> {
  late final Future<String?> _accessTokenFuture;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _accessTokenFuture = AuthToken().getAccessToken();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLaunching,
      child: Scaffold(
        appBar: AppBar(title: const Text('アプリ ｜ ゲーム')),
        body: FutureBuilder<String?>(
          future: _accessTokenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
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
                        authenticated
                            ? 'ゲームを開始できます。'
                            : 'ゲームを起動するには会員認証が必要です。',
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: authenticated && !_isLaunching
                              ? _openGame
                              : null,
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
      final current = await TrainingGameProvider().fetchCurrent();
      await loadingDelay;
      if (!mounted) return;
      if (current == null) {
        Get.toNamed(Routes.TRAINING_GAME_NEW);
      } else {
        // 取得済み状態を引き渡し、育成画面での同一API再取得を省略します。
        Get.toNamed(Routes.TRAINING_GAME, arguments: current);
      }
    } catch (_) {
      await loadingDelay;
      if (!mounted) return;
      // サーバー未接続時は新規開始画面へ進めます。
      Get.toNamed(Routes.TRAINING_GAME_NEW);
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }
}

/// ワイヤーフレーム②「卵獲得・ニューゲーム」を表示します。
class TrainingGameNewGameScreen extends GetView<TrainingGameNewGameController> {
  /// ニューゲーム画面を作成します。
  const TrainingGameNewGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ニューゲーム')),
      body: Obx(
        () => Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              const Spacer(),
              Text('🥚', style: TextStyle(fontSize: 96.sp)),
              SizedBox(height: 16.h),
              const Text('新しい卵を手に入れました。'),
              if (controller.errorMessage.value.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(controller.errorMessage.value, textAlign: TextAlign.center),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: controller.isStarting.value ? null : _startGame,
                  child: controller.isStarting.value
                      ? const CircularProgressIndicator()
                      : const Text('はじめる'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 開始APIの成功後にだけ育成画面へ遷移します。
  void _startGame() {
    final arguments = Get.arguments;
    final forceRestart = arguments is Map && arguments['debugRestart'] == true;
    controller.startNewGame(forceRestart: forceRestart).then((startedState) {
      if (startedState == null) return;
      // 開始APIのレスポンスを引き渡し、画面表示時の再取得を省略します。
      // 新サイクルであることを明示し、旧ローカル状態の復元を禁止します。
      final newCycleState = Map<String, dynamic>.from(startedState)
        ..['_new_cycle'] = true;
      Get.offNamed(Routes.TRAINING_GAME, arguments: newCycleState);
    });
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
