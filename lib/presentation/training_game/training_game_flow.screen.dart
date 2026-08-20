import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/training_game_new_game.controller.dart';

/// ワイヤーフレーム①「アプリ内 ゲーム起動」を表示します。
class TrainingGameLaunchScreen extends StatelessWidget {
  /// 起動画面を作成します。
  const TrainingGameLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アプリ ｜ ゲーム')),
      body: FutureBuilder<String?>(
        future: AuthToken().getAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final authenticated = snapshot.data?.isNotEmpty == true;
          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FlowPlaceholder(height: 180.h, label: 'ゲームバナー'),
                SizedBox(height: 20.h),
                Text('鮫太朗育成ゲーム', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700)),
                SizedBox(height: 8.h),
                Text(authenticated ? 'ゲームを開始できます。' : 'ゲームを起動するには会員認証が必要です。'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: authenticated ? _openGame : null,
                    child: const Text('ゲームを起動'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 育成中の卵がある場合は②を省略し、③へ直接遷移します。
  void _openGame() {
    TrainingGameProvider.waitForPendingSync().then((_) {
      return TrainingGameProvider().fetchCurrent();
    }).then((current) {
      if (current == null) {
        Get.toNamed(Routes.TRAINING_GAME_NEW);
        return;
      }
      // 取得済み状態を引き渡し、育成画面での同一API再取得を省略します。
      Get.toNamed(Routes.TRAINING_GAME, arguments: current);
    }).catchError((_) {
      // サーバー未接続時は新規開始画面へ進めます。
      Get.toNamed(Routes.TRAINING_GAME_NEW);
    });
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
      Get.offNamed(Routes.TRAINING_GAME, arguments: startedState);
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
