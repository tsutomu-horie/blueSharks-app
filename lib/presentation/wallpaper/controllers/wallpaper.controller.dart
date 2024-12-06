import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';

class WallpaperController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    AnalyticsService.logPageView(Routes.WALLPAPER);

  }
  void onNext() async {
    Get.off(() => const WallpaperSetPlayerScreen(null, ""));
  }
}
