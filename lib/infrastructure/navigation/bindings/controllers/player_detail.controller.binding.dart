import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_detail/controllers/player_detail.controller.dart';

class PlayerDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerDetailController>(
      () => PlayerDetailController(),
    );
  }
}
