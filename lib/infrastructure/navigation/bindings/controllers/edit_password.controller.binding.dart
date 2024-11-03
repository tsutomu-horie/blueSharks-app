import 'package:get/get.dart';

import '../../../../presentation/EditPassword/controllers/edit_password.controller.dart';

class EditPasswordControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditPasswordController>(
      () => EditPasswordController(),
    );
  }
}
