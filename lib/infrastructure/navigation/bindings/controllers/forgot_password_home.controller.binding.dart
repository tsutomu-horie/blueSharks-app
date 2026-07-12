import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/register/forgot_password_home/controllers/forgot_password_home.controller.dart';

class ForgotPasswordHomeControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordHomeController>(
      () => ForgotPasswordHomeController(),
    );
  }
}
