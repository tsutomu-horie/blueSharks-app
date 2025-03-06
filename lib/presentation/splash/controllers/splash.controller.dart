import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/awesome_notifications_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    debugPrint("Bundle ID: $bundleID");

    AnalyticsService.logPageView(Routes.SPLASH);

    final isOpen = MySharedPref.getFirstOpen();
    isFirstOpen.value = "${MySharedPref.getFirstOpen()}";

    // Perform a version check
    await versionCheck(
      onResume: () async {
        debugPrint("Version check passed, resuming...");

        await Future.delayed(const Duration(seconds: 1));

        if (isOpen != null && isOpen != "") {
          Get.offAll(() => const MainScreen());
        } else {
          Get.offAndToNamed('/wallpaper');
        }
      },
    );

    // await NotificationService.initializeNotification(); // Add this line
    // print("Shownifo");
    // NotificationService.showSimpleNotification(
    //   title: 'Simple Notification',
    //   body: 'This is a simple notification',
    // );
  }

  Future<void> versionCheck({
    required VoidCallback onResume,
  }) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Configure and fetch the latest Remote Config values
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 600),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();

      // Fetch app version from Remote Config
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appVersion = packageInfo.version;
      String platform = Platform.isAndroid ? "android" : "ios";
      String firebaseVersionKey = "${platform}_${Constants.isRelease ? "production" : "debug"}_version";
      String isMajorKey = "${platform}_${Constants.isRelease ? "production" : "debug"}_is_major";

      debugPrint("jakdsa ${firebaseVersionKey} ${isMajorKey}");

      String remoteVersion = remoteConfig.getString(firebaseVersionKey);

      bool isMajor = remoteConfig.getBool(isMajorKey);
      debugPrint("data remote ${firebaseVersionKey} \n ${isMajorKey}  \n ${remoteVersion} ${isMajor}");

      // Compare versions
      final int comparison = compareVersions(remoteVersion, appVersion);
      if (comparison > 0) {
        // If a new version is available
        showUpdateDialog(
          isMajor: isMajor,
          onUpdate: () {
            // Navigate to the app store link
            final url = Platform.isAndroid
                ? "https://play.google.com/store/apps/details?id=${packageInfo.packageName}"
                : "https://apps.apple.com/us/app/id6741193664";
            launchUrl(Uri.parse(url));
          },
          onIgnore: () {
            if (!isMajor) {
              // Resume the app only if it's a minor update
              onResume();
            }
          },
        );
      } else {
        onResume(); // No updates required
      }
    } catch (e) {
      debugPrint("Error checking version: $e");
      onResume(); // Fallback if an error occurs
    }
  }

  void showUpdateDialog({
    required bool isMajor,
    required VoidCallback onUpdate,
    required VoidCallback onIgnore,
  }) {
    Get.defaultDialog(
      title: "Update Required",
      titleStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: BrandColor.main, // Optional: Change title color
      ),
      middleText: isMajor
          ? "A major update is required to continue using the app."
          : "A new version of the app is available. Do you want to update?",
      middleTextStyle: TextStyle(
        fontSize: 14.sp,
        color: TextColor.secondary, // Optional: Change message text color
      ),
      textConfirm: "Update",
      textCancel: isMajor ? "Exit" : "Skip",
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white,
      buttonColor: BrandColor.main, // Set the default button background color
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColor.main,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onUpdate,
        child: Text(
          "Update",
          style: TextStyle(color: Colors.white),
        ),
      ),
      cancel: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: BrandColor.main, width: 1)),
        ),
        onPressed: () {
          if (isMajor) {
            // Close the app for major updates
            SystemNavigator.pop();
          } else {
            onIgnore();
          }
        },
        child: Text(
          isMajor ? "Exit" : "Skip",
          style: TextStyle(color: BrandColor.main),
        ),
      ),
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
    );
  }


  int compareVersions(String version1, String version2) {
    final v1 = version1.split('.').map(int.parse).toList();
    final v2 = version2.split('.').map(int.parse).toList();

    // Pad the shorter version array with zeros
    while (v1.length < v2.length) {
      v1.add(0);
    }
    while (v2.length < v1.length) {
      v2.add(0);
    }

    debugPrint("Padded versions: $v1 $v2");

    for (int i = 0; i < v1.length; i++) {
      if (v1[i] > v2[i]) return 1; // v1 is greater
      if (v1[i] < v2[i]) return -1; // v2 is greater
    }

    return 0; // Versions are equal
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
        debugPrint("notif allowed");
      } else {
        debugPrint("notif rejected");
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

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        // -1 is random id
        channelKey: "chat_channel",
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

    debugPrint("send notif suksesss");
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
