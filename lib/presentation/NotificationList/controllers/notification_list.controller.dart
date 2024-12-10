import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/NotificationDetail/notification_detail.screen.dart';

class NotificationListController extends GetxController {
  final AuthProvider apiProvider = AuthProvider();
  final RxList<NotificationItem> notificationList = RxList<NotificationItem>([]);

  @override
  void onInit() {
    super.onInit();
    getNotification();

    AnalyticsService.logPageView(Routes.NOTIFICATION_LIST);

  }

  void getNotification() async {
    try {
      final response = await apiProvider.getNotificationList();
      notificationList.value = response;

      // Check if we came from a notification
      final arguments = Get.arguments;
      if (arguments != null && arguments['from_notification'] == true) {
        final String? notificationId = arguments['notification_id'];
        if (notificationId != null) {
          // Find the notification in the list
          final notification = notificationList.firstWhereOrNull(
                  (element) => element.id.toString() == notificationId
          );

          if (notification != null) {
            // Navigate to detail after a short delay to ensure list is loaded
            await Future.delayed(Duration(milliseconds: 100));
            Get.to(() => NotificationDetailScreen(notification));
          }
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
    }
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
