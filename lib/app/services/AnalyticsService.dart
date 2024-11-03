import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:koto_blue_sharks/firebase_options.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> init() async {
    if (kDebugMode) {
      print("init");
    }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  }

  static void logPageView(String pageName) async {
    if (kDebugMode) {
      print("log page ${pageName}");
    }
    return _analytics.logEvent(
      name: 'page_view',
      parameters: {'page': pageName},
    );
  }
}

final AnalyticsService analyticsService = AnalyticsService();
