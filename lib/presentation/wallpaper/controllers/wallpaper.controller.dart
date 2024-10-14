import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';

class WallpaperController extends GetxController {
  void onNext() async {
    Get.off(() => const WallpaperSetPlayerScreen());
  }
}
