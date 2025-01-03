import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/awesome_notifications_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  RxString version = "".obs;
  RxString isFirstOpen = "".obs;

  final MemberProvider memberProvider = MemberProvider();
  final RxList<Category> allCategories = <Category>[].obs;
  final RxMap<int, List<Member>> categoryPlayers = <int, List<Member>>{}.obs;
  final RxBool isLoading = false.obs;

  Box<Category>? categoryBox;
  Box<Member>? playerBox;

  @override
  void onInit() async {
    super.onInit();
    getAppVersion();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String bundleID = packageInfo.packageName;
    print("Bundle ID: $bundleID");

    AnalyticsService.logPageView(Routes.SPLASH);

    final isOpen = MySharedPref.getFirstOpen();
    isFirstOpen.value = "${MySharedPref.getFirstOpen()}";

    await Future.delayed(const Duration(seconds: 2));

    if (isOpen != null && isOpen != "") {
      Get.offAll(() => const MainScreen());
    } else {
      Get.offAndToNamed('/wallpaper');
    }

    // await NotificationService.initializeNotification(); // Add this line
    // print("Shownifo");
    // NotificationService.showSimpleNotification(
    //   title: 'Simple Notification',
    //   body: 'This is a simple notification',
    // );
  }

  void getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version.value = packageInfo.version;
  }
}

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://mipmap/notif_icon',
      [
        NotificationChannel(
          channelKey: 'news_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Prompt the user to enable notifications
        AwesomeNotifications().requestPermissionToSendNotifications();
        print("notif allowed");

      } else {
        print("notif rejected");
      }
    });

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showNotification({
    required final String title,
    required final String body,
    final String? summary,
    final Map<String, String>? payload,
    final ActionType actionType = ActionType.Default,
    final NotificationLayout notificationLayout = NotificationLayout.Default,
    final NotificationCategory? category,
    final String? bigPicture,
    final List<NotificationActionButton>? actionButtons,
    final bool scheduled = false,
    final int? interval,
  }) async {
    assert(!scheduled || (scheduled && interval != null));


    print("show edsksd");
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, // -1 is random id
        channelKey:  "chat_channel",
        title: title,
        body: body,
        summary: summary,
        payload: payload,
        actionType: actionType,
        notificationLayout: notificationLayout,
        category: category,
        bigPicture: bigPicture,
      ),
      actionButtons: actionButtons,
      schedule: scheduled
          ? NotificationInterval(
        interval: interval,
        repeats: false,
      )
          : null,
    );
  }

  // Show simple notification
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    
    await showNotification(
      title: title,
      body: body,
    );

    print("send notif suksesss");
  }

  // Show notification with image
  static Future<void> showBigPictureNotification({
    required String title,
    required String body,
    required String imageUrl,
  }) async {
    await showNotification(
      title: title,
      body: body,
      bigPicture: imageUrl,
      notificationLayout: NotificationLayout.BigPicture,
    );
  }

  // Show notification with buttons
  static Future<void> showNotificationWithButtons({
    required String title,
    required String body,
  }) async {
    await showNotification(
      title: title,
      body: body,
      actionButtons: [
        NotificationActionButton(
          key: 'ACCEPT',
          label: 'Accept',
        ),
        NotificationActionButton(
          key: 'REJECT',
          label: 'Reject',
          isDangerousOption: true,
        ),
      ],
    );
  }

  // Show scheduled notification
  static Future<void> showScheduledNotification({
    required String title,
    required String body,
    required int seconds,
  }) async {
    await showNotification(
      title: title,
      body: body,
      scheduled: true,
      interval: seconds,
    );
  }
}