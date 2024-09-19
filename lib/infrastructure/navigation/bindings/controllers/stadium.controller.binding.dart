import 'package:get/get.dart';

import '../../../../presentation/stadium/controllers/stadium.controller.dart';

class StadiumControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StadiumController>(
      () => StadiumController(),
    );
  }
}
