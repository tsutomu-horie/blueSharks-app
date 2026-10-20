import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

void main() {
  test('auth API URL follows the selected connection environment', () {
    AppEnvironment.validate();
    if (Constants.useLocalAuthApi) {
      const host = String.fromEnvironment('LOCAL_AUTH_API_HOST');
      final effectiveHost = host.isNotEmpty
          ? host
          : defaultTargetPlatform == TargetPlatform.android
              ? '10.0.2.2'
              : '127.0.0.1';
      expect(
        Constants.baseUrlAuthApi,
        'http://$effectiveHost:8000/api/mobile/v1/',
      );
      return;
    }
    expect(Constants.baseUrlAuthApi, AppEnvironment.authApiBaseUrl);
  });

  test('all connection settings use the same environment', () {
    expect(Constants.baseUrl, AppEnvironment.wordpressApiBaseUrl);
    expect(Constants.baseUrlWeb, AppEnvironment.webBaseUrl);
    expect(Constants.topic, AppEnvironment.notificationTopic);
    expect(
      Constants.remoteConfigEnvironment,
      AppEnvironment.remoteConfigEnvironment,
    );
    expect(Constants.ticketsUrl, AppEnvironment.ticketsUrl);
    expect(Constants.fanClubUrl, AppEnvironment.fanClubUrl);
    expect(Constants.partnerUrl, AppEnvironment.partnerUrl);
    expect(Constants.teamUrl, AppEnvironment.teamUrl);
    expect(Constants.wordpressAdminUrl, AppEnvironment.wordpressAdminUrl);
  });

  test(
    'connection selection does not change the build mode or shared links',
    () {
      expect(Constants.isRelease, kReleaseMode);
      expect(
        Constants.useLocalAuthApi,
        !kReleaseMode && const bool.fromEnvironment('USE_LOCAL_AUTH_API'),
      );
      expect(Constants.shopUrl, 'https://bluesharks.base.shop/');
      expect(
        Constants.instagramUrl,
        'https://www.instagram.com/shimz.bluesharks/',
      );
      expect(Constants.xUrl, 'https://x.com/Bluesharks_2020');
    },
  );
}
