import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/firebase_options.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/awesome_notifications_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class FcmHelper {
  // prevent making instance
  FcmHelper._();

  // FCM Messaging
  static late FirebaseMessaging messaging;

  /// this function will initialize firebase and fcm instance
  static Future<void> initFcm() async {
    try {
      // initialize fcm and firebase core
      // if (Platform.isAndroid) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      // } else {
        AwesomeNotifications().initialize("resource://drawable/notif", [
          NotificationChannel(
              channelGroupKey: 'general_channel_group',
              channelKey: 'general_channel',
              channelName: 'General Notifications',
              channelDescription: 'Notification channel for general notifications',
          )
        ],
        );
      // }
        await AwesomeNotificationsHelper.init();
      await Future.delayed(Duration(seconds: 1));
      // initialize firebase
      messaging = FirebaseMessaging.instance;

      // notification settings handler
      await _setupFcmNotificationSettings();

      // generate token if it not already generated and store it on shared pref
      await _generateFcmToken();

      // background and foreground handlers
      FirebaseMessaging.onMessage.listen(_fcmForegroundHandler);
      FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    } catch (error) {
      // if you are connected to firebase and still get error
      // check the todo up in the function else ignore the error
      // or stop fcm service from main.dart class
      print("FCM Helper error ${error}");
    }
  }

  ///handle fcm notification settings (sound,badge..etc)
  static Future<void> _setupFcmNotificationSettings() async {
    //show notification with sound and badge
    messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true,
    );

    //NotificationSettings settings
    if (Platform.isIOS) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true
      );

      print('User granted permission: ${settings.authorizationStatus}');
    }

  }

  /// generate and save fcm token if its not already generated (generate only for 1 time)
  static Future<void> _generateFcmToken() async {
    try {
      var token = await messaging.getToken();
      print("token get ${token}");
      if(token != null){
        MySharedPref.setFcmToken(token);
        _sendFcmTokenToServer();
      }else {
        // retry generating token
        await Future.delayed(const Duration(seconds: 5));
        _generateFcmToken();
      }
    } catch (error) {
      print("error generate fcm $error");
    }
  }

  /// this method will be triggered when the app generate fcm
  /// token successfully
  static _sendFcmTokenToServer() async {
    var token = MySharedPref.getFcmToken();

    final auth = AuthProvider();
    print("find toke 2 $token");

    if (token != null) {
      final authToken = await auth.updateNotificationToken(token);
      print("find toke $authToken");

      if (authToken == null) {
        messaging.unsubscribeFromTopic("news");

        messaging.subscribeToTopic("news").then((_) {
          print('Subscribed to topic');
        });
      }

    }
  }

  ///handle fcm notification when app is closed/terminated
  /// if you are wondering about this annotation read the following
  /// https://stackoverflow.com/a/67083337
  @pragma('vm:entry-point')
  static Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
    print('Handling FCM Notification in Background: ${message.notification?.title}');

    // AwesomeNotificationsHelper.showNotification(
    //   id: 1,
    //   title: message.notification?.title ?? 'Tittle',
    //   body: message.notification?.body ?? 'Body',
    //   payload: message.data.cast(), // pass payload to the notification card so you can use it (when user click on notification)
    // );
  }

  //handle fcm notification when app is open
  static Future<void> _fcmForegroundHandler(RemoteMessage message) async {
    print('Handling FCM Notification in Foreground: ${message.notification?.title}');

    if (Platform.isAndroid) {
      AwesomeNotificationsHelper.showNotification(
        id: 1,
        title: message.notification?.title ?? 'Tittle',
        body: message.notification?.body ?? 'Body',
        payload: message.data
            .cast(), // pass payload to the notification card so you can use it (when user click on notification)
      );
    }
  }
}

