import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/reset_password/controllers/reset_password.controller.dart';
import 'package:koto_blue_sharks/presentation/reset_password/reset_password.screen.dart';


class ResetPasswordControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResetPasswordController>(
      () => ResetPasswordController(),
    );
  }
}
