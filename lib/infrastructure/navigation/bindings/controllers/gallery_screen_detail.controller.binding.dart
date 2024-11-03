import 'package:get/get.dart';

import '../../../../presentation/GalleryScreenDetail/controllers/gallery_screen_detail.controller.dart';

class GalleryScreenDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryScreenDetailController>(
      () => GalleryScreenDetailController(),
    );
  }
}
