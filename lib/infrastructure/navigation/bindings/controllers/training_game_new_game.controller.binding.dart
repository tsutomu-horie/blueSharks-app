import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game_new_game.controller.dart';

/// 卵獲得画面のControllerを遅延登録します。
class TrainingGameNewGameControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainingGameNewGameController>(() => TrainingGameNewGameController());
  }
}
