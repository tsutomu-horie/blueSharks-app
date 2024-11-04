import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';

class NotificationListController extends GetxController {
  final AuthProvider apiProvider = AuthProvider();
  final RxList<Notification> notificationList = RxList<Notification>([]);

  @override
  void onInit() {
    super.onInit();
    getNotification();
  }

  void getNotification() async {
    final response = await apiProvider.getNotificationList();

    notificationList.value = response;
  }
}
