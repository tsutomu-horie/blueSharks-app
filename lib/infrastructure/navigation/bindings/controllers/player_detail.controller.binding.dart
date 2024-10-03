import 'package:get/get.dart';

import '../../../../presentation/playerDetail/controllers/player_detail.controller.dart';

class PlayerDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerDetailController>(
      () => PlayerDetailController(),
    );
  }
}
