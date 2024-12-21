import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class AwesomeNotificationsHelper {
  // prevent making instance
  AwesomeNotificationsHelper._();

  // Notification lib
  static AwesomeNotifications awesomeNotifications = AwesomeNotifications();

  /// initialize local notifications service, create channels and groups
  /// setup notifications button actions handlers
  static init() async {
    print("setup listten2 2");
    // initialize local notifications
    await _initNotification();

    listenToActionButtons();

    // request permission to show notifications
    awesomeNotifications.requestPermissionToSendNotifications();

    // list when user click on notifications
  }

  /// when user click on notification or click on button on the notification
  static listenToActionButtons() {
    print("setup listten");
    // Only after at least the action method is set, the notification events are delivered
    awesomeNotifications.setListeners(
        onActionReceivedMethod:         NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:    NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  NotificationController.onDismissActionReceivedMethod
    );
  }


  ///init notifications channels
  static _initNotification() async {
    await awesomeNotifications.initialize(
        'resource://mipmap/notif_icon',
        [
          // NotificationChannel(
          //   channelGroupKey: NotificationChannels.generalChannelGroupKey,
          //   channelKey: NotificationChannels.generalChannelKey,
          //   channelName: NotificationChannels.generalChannelName,
          //   groupKey: NotificationChannels.generalGroupKey,
          //   channelDescription: NotificationChannels.generalChannelDescription,
          //   defaultColor: Colors.green,
          //   ledColor: Colors.white,
          //   channelShowBadge: true,
          //   playSound: true,
          //   importance: NotificationImportance.Max,
          // ),
          NotificationChannel(
              channelGroupKey: NotificationChannels.chatChannelGroupKey,
              channelKey: NotificationChannels.chatChannelKey,
              channelName: NotificationChannels.chatChannelName,
              groupKey: NotificationChannels.chatGroupKey,
              channelDescription: NotificationChannels.chatChannelDescription,
              defaultColor: Colors.green,
              ledColor: Colors.white,
              channelShowBadge: true,
              playSound: true,
              importance: NotificationImportance.Max)
        ],

        channelGroups: [
          // NotificationChannelGroup(
          //   channelGroupKey: NotificationChannels.generalChannelGroupKey,
          //   channelGroupName: NotificationChannels.generalChannelGroupName,
          // ),
          NotificationChannelGroup(
            channelGroupKey: NotificationChannels.chatChannelGroupKey,
            channelGroupName: NotificationChannels.chatChannelGroupName,
          )
        ]);
  }


  //display notification for user with sound
  static showNotification(
      {required String title,
        required String body,
        required int id,
        String? channelKey,
        String? groupKey,
        NotificationLayout? notificationLayout,
        String? summary,
        List<NotificationActionButton>? actionButtons,
        Map<String, String>? payload,
        String? largeIcon}) async {
    awesomeNotifications.isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        awesomeNotifications.requestPermissionToSendNotifications();
      } else {
        print("show large ${largeIcon}");
        // u can show notification
        awesomeNotifications.createNotification(
          content: NotificationContent(
            id: id,
            title: title,
            body: body,
            groupKey: NotificationChannels.chatGroupKey,
            channelKey: NotificationChannels.chatChannelKey,
            showWhen: true, // Hide/show the time elapsed since notification was displayed
            payload: payload, // data of the notification (it will be used when user clicks on notification)
            notificationLayout: notificationLayout ?? NotificationLayout.Default, // notification shape (message,media player..etc) For ex => NotificationLayout.Messaging
            autoDismissible: true, // dismiss notification when user clicks on it
            summary: summary, // for ex: New message (it will be shown on status bar before notificaiton shows up)
            largeIcon: largeIcon, // image of sender for ex (when someone send you message his image will be shown)
          ),
          actionButtons: actionButtons,
        );
      }
    });
  }
}


class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print("onNotif created");
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
    print("onNotif onNotificationDisplayedMethod");

  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
    print("onNotif onDismissActionReceivedMethod");

  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print("=== Notification Clicked ===");
    print("Action Type: ${receivedAction.actionType}");
    print("Payload: ${receivedAction.payload}");

    if (receivedAction.actionType == ActionType.Default) {
      final String? notificationId = receivedAction.payload?['id'];
      print("Notification ID: $notificationId");

      // Store the notification ID for later use
      if (notificationId != null) {
        await Get.toNamed(Routes.NOTIFICATION_LIST, arguments: {
          'notification_id': notificationId,
          'from_notification': true
        });
      } else {
        await Get.toNamed(Routes.NOTIFICATION_LIST);
      }
    }
  }
}


class NotificationChannels {
  // chat channel (for messages only)
  static String get chatChannelKey => "chat_channel";
  static String get chatChannelName => "Bluesharks Notification";
  static String get chatGroupKey => "Bluesharks Notification Group";
  static String get chatChannelGroupKey => "chat_channel_group";
  static String get chatChannelGroupName => "Bluesharks channels";
  static String get chatChannelDescription => "This cannel will shown update about bluesharks news";

  // general channel (for all other notifications)
  // static String get generalChannelKey => "general_channel";
  // static String get generalGroupKey => "general group key";
  // static String get generalChannelGroupKey => "general_channel_group";
  // static String get generalChannelGroupName => "general notifications channel";
  // static String get generalChannelName => "general notifications channels";
  // static String get generalChannelDescription => "Notification channel for general notifications";
}
