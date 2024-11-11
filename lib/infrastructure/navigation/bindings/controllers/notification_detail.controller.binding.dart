import 'package:get/get.dart';

import '../../../../presentation/NotificationDetail/controllers/notification_detail.controller.dart';

class NotificationDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationDetailController>(
      () => NotificationDetailController(),
    );
  }
}
