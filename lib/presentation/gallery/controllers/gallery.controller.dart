import 'package:get/get.dart';

class GalleryController extends GetxController {
  var selectedIndex = 0.obs;

  void onSwitch(int index) {
    selectedIndex.value = index;
  }
}
