import 'package:get/get.dart';

import '../../../../presentation/LocalFullScreen/controllers/local_full_screen.controller.dart';

class LocalFullScreenControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocalFullScreenController>(
      () => LocalFullScreenController(),
    );
  }
}
