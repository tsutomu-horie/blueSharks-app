import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/notification/notification_list/controllers/notification_list.controller.dart';

class NotificationListControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationListController>(
      () => NotificationListController(),
    );
  }
}
