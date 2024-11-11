import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';

class NotificationListController extends GetxController {
  final AuthProvider apiProvider = AuthProvider();
  final RxList<NotificationItem> notificationList = RxList<NotificationItem>([]);

  @override
  void onInit() {
    super.onInit();
    getNotification();
  }

  void getNotification() async {
    final response = await apiProvider.getNotificationList();

    notificationList.value = response;
  }

  String formatDate(String dateString) {
    DateTime parsedDate = DateTime.parse(dateString);
    DateTime currentDate = DateTime.now();
    Duration difference = currentDate.difference(parsedDate);

    if (difference.inDays >= 1) {
      // If the date difference is more than or equal to 1 day, return the date in 'MMM d, yyyy' format
      return DateFormat('MMM d, yyyy').format(parsedDate);
    } else if (difference.inHours >= 1) {
      // If the difference is more than or equal to 1 hour, return in hours
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      // If the difference is more than or equal to 1 minute, return in minutes
      return '${difference.inMinutes} minutes ago';
    } else {
      // If the difference is less than a minute, return "Just now"
      return 'Just now';
    }
  }
}
