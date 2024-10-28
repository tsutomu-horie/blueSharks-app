import 'package:get/get.dart';

import '../../../../presentation/RegisterEmailFromHome/controllers/register_email_from_home.controller.dart';

class RegisterEmailFromHomeControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterEmailFromHomeController>(
      () => RegisterEmailFromHomeController(),
    );
  }
}
