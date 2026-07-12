import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/controllers/player_list.controller.dart';


class PlayerListControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerListController>(
      () => PlayerListController(),
    );
  }
}
