import 'package:get/get.dart';

import '../../../../presentation/ForgotPasswordHome/controllers/forgot_password_home.controller.dart';

class ForgotPasswordHomeControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordHomeController>(
      () => ForgotPasswordHomeController(),
    );
  }
}
