import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/register/register_email_from_home/controllers/register_email_from_home.controller.dart';

class RegisterEmailFromHomeControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterEmailFromHomeController>(
      () => RegisterEmailFromHomeController(),
    );
  }
}
