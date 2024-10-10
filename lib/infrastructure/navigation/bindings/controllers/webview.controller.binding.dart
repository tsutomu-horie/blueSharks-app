import 'package:get/get.dart';

import '../../../../presentation/webview/controllers/webview.controller.dart';

class WebviewControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebviewController>(
      () => WebviewController(),
    );
  }
}
