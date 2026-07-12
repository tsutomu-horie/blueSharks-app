import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/stadium/controllers/stadium.controller.dart';

class StadiumImageFullScreenControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StadiumController>(
      () => StadiumController(),
    );
  }
}
