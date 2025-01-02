import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/gallery/gallery_list/controllers/gallery.controller.dart';

class GalleryControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryController>(
      () => GalleryController(),
    );
  }
}
