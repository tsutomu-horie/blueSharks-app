import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  RxString version = "".obs;

  @override
  void onInit() async {
    super.onInit();
    getAppVersion();

    await Future.delayed(const Duration(seconds: 3));
    Get.offAndToNamed('/wallpaper');
  }

  void getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version.value = packageInfo.version;
  }
}
