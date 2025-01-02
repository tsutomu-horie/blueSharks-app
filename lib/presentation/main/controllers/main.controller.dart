import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';


class MainController extends GetxController {
  var selectedIndex = 0.obs;
  var selectedTopicId = Rx<int?>(null); // Track the selected topic ID
  var selectedPost = Rx<Post?>(null); // Track the selected topic ID
  final AuthProvider apiProvider = AuthProvider();

  var unreadMessage = 0.obs;

  @override
  void onInit() {
    super.onInit();

    print("saklfajs djsalk $unreadMessage");

    getUnreadNotificationCount();
    setupFirebaseMessaging();
  }

  void refreshUnreadMessageCount() {
    print("refreshUnreadMessageCount $unreadMessage");

    getUnreadNotificationCount(); // Call the method to refresh the count
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      getUnreadNotificationCount();
    });
  }

  void getUnreadNotificationCount() async {

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    print("get unread isLogin=${token != null}");
    if (token != null) {
      unreadMessage.value = await apiProvider.getUnreadNotification();
    } else {
      unreadMessage.value = 0;
    }
  }

  void navigateToNotification() async {
    await Get.to(() => const NotificationListScreen())?.then((_) {
      // Refresh the unread notification count after returning
      getUnreadNotificationCount();
    });
  }

  void launchFanClub(){
    launchExternalWeb(Constants.fanClubUrl);
  }

  void launchTicket(){
    launchExternalWeb(Constants.ticketsUrl);
  }

  void launchGood(){
    launchExternalWeb(Constants.shopUrl);
  }

  void launchExternalWeb(String url) async {
    final Uri webUrl = Uri.parse(url); // Replace with your profile URL
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    } else {
      throw 'Could not launch $webUrl';
    }
  }
}
