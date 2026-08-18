import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';

/// 卵獲得画面から新しい育成サイクルを開始します。
class TrainingGameNewGameController extends GetxController {
  /// API開始処理の実行状態です。
  final isStarting = false.obs;

  /// API開始処理のエラーメッセージです。
  final errorMessage = ''.obs;

  final TrainingGameProvider _provider = TrainingGameProvider();

  /// 卵獲得画面の初期値で新しい育成サイクルを作成します。
  Future<Map<String, dynamic>?> startNewGame() {
    if (isStarting.value) return Future<Map<String, dynamic>?>.value();
    isStarting.value = true;
    errorMessage.value = '';

    return _provider
        .start(
          stageCode: 'egg',
          parameters: const {
            'hunger': 100,
            'cleanliness': 50,
            'condition': 50,
            'work': 0,
            'tendency_fw': 0,
            'tendency_command': 0,
            'tendency_backs': 0,
          },
        )
        .then<Map<String, dynamic>?>((data) {
          if (!isClosed) isStarting.value = false;
          return data;
        })
        .catchError((_) {
          // 開始に失敗した場合は卵獲得画面を維持し、再実行できるようにします。
          if (!isClosed) {
            isStarting.value = false;
            errorMessage.value = '育成の開始に失敗しました。通信状態を確認して再度お試しください。';
          }
          return null;
        });
  }
}
