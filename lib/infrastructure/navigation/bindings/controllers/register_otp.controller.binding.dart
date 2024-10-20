import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/register/register_otp/controllers/register_otp.controller.dart';

class RegisterOtpControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterOtpController>(
      () => RegisterOtpController(),
    );
  }
}
