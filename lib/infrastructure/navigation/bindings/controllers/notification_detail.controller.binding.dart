import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/notification/notification_detail/controllers/notification_detail.controller.dart';

class NotificationDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationDetailController>(
      () => NotificationDetailController(),
    );
  }
}
