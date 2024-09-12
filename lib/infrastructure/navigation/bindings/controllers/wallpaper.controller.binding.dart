import 'package:get/get.dart';

import '../../../../presentation/wallpaper/controllers/wallpaper.controller.dart';

class WallpaperControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WallpaperController>(
      () => WallpaperController(),
    );
  }
}
