import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/notification/notification_detail/notification_detail.screen.dart';

class NotificationListController extends GetxController {
  final AuthProvider apiProvider = AuthProvider();
  final RxList<NotificationItem> notificationList = RxList<NotificationItem>([]);
  final isLogin = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() async {
    super.onInit();
    getNotification(true);

    AnalyticsService.logPageView(Routes.NOTIFICATION_LIST);

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    isLogin.value = token != null;
  }

  void getNotification(bool isOnInit) async {
    isLoading.value = true;
    try {
      final response = await apiProvider.getNotificationList();
      notificationList.value = response;

      print("isoon ${isOnInit}");
      if (isOnInit) {
        // Check if we came from a notification
        final arguments = Get.arguments;
        print("arguments is $arguments");
        if (arguments != null && arguments['from_notification'] == true) {
          final String? notificationId = arguments['notification_id'];
          if (notificationId != null) {
            // Find the notification in the list
            final notification = notificationList.firstWhereOrNull(
                    (element) => element.data.model_id.toString() == notificationId
            );


            if (notification != null) {
              // Navigate to detail after a short delay to ensure list is loaded
              await Future.delayed(Duration(milliseconds: 100));
              print("naviaget to notif");
              Get.to(() => NotificationDetailScreen(notification))?.then((_) {
                // Refresh the unread notification count after returning
                getNotification(false);
              });
            }
          }
        }
      }

      isLoading.value = false;

    } catch (e) {
      isLoading.value = false;
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(String dateString) {
    DateTime parsedDate = DateTime.parse(dateString);
    DateTime currentDate = DateTime.now();
    Duration difference = currentDate.difference(parsedDate);

    if (difference.inDays >= 1) {
      // If the date difference is more than or equal to 1 day, return the date in 'MMM d, yyyy' format
      return DateFormat('yyyy.MM.dd').format(parsedDate);
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
