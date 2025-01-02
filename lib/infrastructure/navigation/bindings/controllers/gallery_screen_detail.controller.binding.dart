import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/gallery/gallery_detail/controllers/gallery_detail.controller.dart';

class GalleryScreenDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryDetailController>(
      () => GalleryDetailController(),
    );
  }
}
