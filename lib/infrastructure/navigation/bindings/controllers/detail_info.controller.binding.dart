import 'package:get/get.dart';

import '../../../../presentation/detailInfo/controllers/detail_info.controller.dart';

class DetailInfoControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailInfoController>(
      () => DetailInfoController(),
    );
  }
}
