import 'package:get/get.dart';

import '../../../../presentation/wallpaper_set_player/controllers/wallpaper_set_player.controller.dart';

class WallpaperSetPlayerControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WallpaperSetPlayerController>(
      () => WallpaperSetPlayerController(),
    );
  }
}
