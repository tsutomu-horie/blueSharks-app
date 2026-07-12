import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/info/detail_info/controllers/detail_info.controller.dart';

class InfoDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfoDetailController>(
      () => InfoDetailController(),
    );
  }
}
