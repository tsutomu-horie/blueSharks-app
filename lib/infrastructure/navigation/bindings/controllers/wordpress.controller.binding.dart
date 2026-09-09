import 'package:get/get.dart';

import 'package:koto_blue_sharks/presentation/wordpress/controllers/wordpress.controller.dart';

class WordPressControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WordPressController>(() => WordPressController());
  }
}
