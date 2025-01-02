import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/wallpaper/update_wallpaper/controllers/update_wallpaper.controller.dart';

class WallpaperSetPlayerControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdateWallpaperController>(
      () => UpdateWallpaperController(),
    );
  }
}
