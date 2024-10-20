import 'package:get/get.dart';

import '../../../../presentation/register/register_email/controllers/register_email.controller.dart';

class RegisterEmailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterEmailController>(
      () => RegisterEmailController(),
    );
  }
}
