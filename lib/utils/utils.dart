import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/error_dialog_view.dart';

class Utils {
  static void showError(BuildContext context, String title, String? message) {
    errorDialogView(context, title, message);
    print("error with ${title} , ${message}");
  }

  static void logScreenView(String screenName, FirebaseAnalytics analytics) {

    analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
      },
    );
  }
}