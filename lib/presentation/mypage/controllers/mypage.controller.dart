import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';

class MypageController extends GetxController {
  void logout() async {
    final auth = AuthToken();
    await auth.deleteToken();

    Get.offAll(() => const SplashScreen());
  }
}
