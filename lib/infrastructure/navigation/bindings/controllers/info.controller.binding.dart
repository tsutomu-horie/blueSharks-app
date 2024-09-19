import 'package:get/get.dart';

import '../../../../presentation/info/controllers/info.controller.dart';

class InfoControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfoController>(
      () => InfoController(),
    );
  }
}
