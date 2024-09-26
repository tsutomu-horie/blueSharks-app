import 'package:get/get.dart';

import '../../../../presentation/gameInfo/controllers/game_info.controller.dart';

class GameInfoControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameInfoController>(
      () => GameInfoController(),
    );
  }
}
