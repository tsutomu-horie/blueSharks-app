import 'package:get/get.dart';

import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';

/// 育成ゲーム画面のControllerを遅延登録します。
class TrainingGameControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainingGameController>(() => TrainingGameController());
  }
}
