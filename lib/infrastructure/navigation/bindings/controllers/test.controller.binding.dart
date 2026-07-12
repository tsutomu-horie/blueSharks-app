import 'package:get/get.dart';

import '../../../../presentation/test/controllers/test.controller.dart';

class TestControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TestController>(
      () => TestController(),
    );
  }
}
