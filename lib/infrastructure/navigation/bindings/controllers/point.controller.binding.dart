import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';

class PointControllerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PointController>()) {
      Get.put(PointController(), permanent: true);
    }
  }
}
