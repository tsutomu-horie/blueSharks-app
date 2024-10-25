import 'package:get/get.dart';

import '../../../../presentation/gallery/controllers/gallery.controller.dart';

class GalleryControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryController>(
      () => GalleryController(),
    );
  }
}
