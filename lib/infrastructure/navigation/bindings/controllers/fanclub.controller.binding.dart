import 'package:get/get.dart';

import '../../../../presentation/fanclub/controllers/fanclub.controller.dart';

class FanclubControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FanclubController>(
      () => FanclubController(),
    );
  }
}
