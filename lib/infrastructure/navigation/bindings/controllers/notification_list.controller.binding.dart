import 'package:get/get.dart';

import '../../../../presentation/NotificationList/controllers/notification_list.controller.dart';

class NotificationListControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationListController>(
      () => NotificationListController(),
    );
  }
}
