import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/firebase_options.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/awesome_notifications_helper.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class FcmHelper {
  // prevent making instance
  FcmHelper._();

  // FCM Messaging
  static late FirebaseMessaging messaging;

  static Future<void>? _initialization;
  static bool _ready = false;
  static bool _sessionListenerAdded = false;
  static final _tokenSync = NotificationTokenSync(
    currentSession: () => AuthToken.sessionVersion,
    readToken: () => messaging.getToken(),
    cacheToken: MySharedPref.setFcmToken,
    sendToken: (token, session, isActive) async {
      final response = await AuthProvider().updateNotificationTokenWhileCurrent(
        token,
        expectedSessionVersion: session,
        isActive: isActive,
      );
      return response != null && !response.hasError;
    },
  );

  /// Startup and registration reuse the same initialization/listener set.
  static Future<void> initFcm() async {
    await (_initialization ??= _initialize());
    unawaited(syncForCurrentSession());
  }

  /// Registration must acquire a current token even when startup had none.
  static Future<NotificationSyncOutcome> syncAfterRegistration() async {
    await (_initialization ??= _initialize());
    return _ready ? _tokenSync.sync() : NotificationSyncOutcome.deferred;
  }

  static Future<void> _initialize() async {
    if (!_sessionListenerAdded) {
      AuthToken.addSessionChangeListener((_) => _tokenSync.cancel());
      _sessionListenerAdded = true;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));
      await AwesomeNotificationsHelper.init()
          .timeout(const Duration(seconds: 5));
      messaging = FirebaseMessaging.instance;
      await messaging
          .setForegroundNotificationPresentationOptions(
            alert: true,
            sound: true,
            badge: true,
          )
          .timeout(const Duration(seconds: 5));
      if (Platform.isIOS) {
        await messaging
            .requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            )
            .timeout(const Duration(seconds: 5));
      }
      await messaging
          .subscribeToTopic(Constants.topic)
          .timeout(const Duration(seconds: 5));
      FirebaseMessaging.onMessage.listen(_fcmForegroundHandler);
      FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
      _ready = true;
    } catch (_) {
      _initialization = null;
      debugPrint('[fcm-init] deferred');
    }
  }

  /// App/session-owned; route disposal after a successful login does not create
  /// another listener or cancel the valid session's background synchronization.
  static Future<void> syncForCurrentSession() async {
    final outcome =
        _ready ? await _tokenSync.sync() : NotificationSyncOutcome.deferred;
    debugPrint('[fcm-sync] ${outcome.name}');
  }

  ///handle fcm notification when app is closed/terminated
  /// if you are wondering about this annotation read the following
  /// https://stackoverflow.com/a/67083337
  @pragma('vm:entry-point')
  static Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
    debugPrint('[fcm] background-message');

    // AwesomeNotificationsHelper.showNotification(
    //   id: 1,
    //   title: message.notification?.title ?? 'Tittle',
    //   body: message.notification?.body ?? 'Body',
    //   payload: message.data.cast(), // pass payload to the notification card so you can use it (when user click on notification)
    // );
  }

  //handle fcm notification when app is open
  static Future<void> _fcmForegroundHandler(RemoteMessage message) async {
    if (Platform.isAndroid) {
      AwesomeNotificationsHelper.showNotification(
          id: 1,
          title: message.notification?.title ?? 'Tittle',
          body: message.notification?.body ?? 'Body',
          payload: message.data.cast(),
          largeIcon: Platform.isAndroid
              ? message.notification?.android?.imageUrl
              : message.notification?.apple?.imageUrl);
    }
  }
}
