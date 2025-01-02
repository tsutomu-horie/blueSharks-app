import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/profile/edit_password/controllers/edit_password.controller.dart';

class EditPasswordControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditPasswordController>(
      () => EditPasswordController(),
    );
  }
}
