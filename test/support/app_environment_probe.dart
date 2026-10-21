// Run with Dart VM defines to verify real Debug/Release environment selections without
// launching Flutter, Firebase, network requests, or an iOS build.
import 'dart:io' show stdout;

import 'package:koto_blue_sharks/utils/app_environment.dart';

void main() {
  const expectInvalid = bool.fromEnvironment('EXPECT_INVALID');
  var rejected = false;
  try {
    AppEnvironment.validate();
  } on StateError {
    rejected = true;
  }
  check('invalid configuration', rejected, expectInvalid);
  if (expectInvalid) {
    stdout.writeln('PASS: invalid configuration rejected');
    return;
  }

  check('build mode', const bool.fromEnvironment('dart.vm.product'),
      const bool.fromEnvironment('EXPECT_PRODUCT'));
  const production = bool.fromEnvironment('EXPECT_PRODUCTION_SERVICES');
  check(
    'production selection',
    AppEnvironment.usesProductionServices,
    production,
  );
  check(
    'local selection',
    AppEnvironment.usesLocalServices,
    const bool.fromEnvironment('EXPECT_LOCAL'),
  );
  check('training debug UI', AppEnvironment.showsTrainingDebugUi, !production);
  check('badge', AppEnvironment.badgeLabel, production ? '' : 'DEBUG');
  final actual = <String, String>{
    'auth': AppEnvironment.authApiBaseUrl,
    'wordpress': AppEnvironment.wordpressApiBaseUrl,
    'web': AppEnvironment.webBaseUrl,
    'topic': AppEnvironment.notificationTopic,
    'remoteConfig': AppEnvironment.remoteConfigEnvironment,
    'tickets': AppEnvironment.ticketsUrl,
    'fanClub': AppEnvironment.fanClubUrl,
    'partner': AppEnvironment.partnerUrl,
    'team': AppEnvironment.teamUrl,
    'wordpressAdmin': AppEnvironment.wordpressAdminUrl,
  };
  final expected = production
      ? <String, String>{
          'auth': 'https://app.blue-sharks.jp/api/mobile/v1/',
          'wordpress': 'https://blue-sharks.donati.jp/wp-json/wp/v2/',
          'web': 'https://app.blue-sharks.jp/api/',
          'topic': 'news_prod',
          'remoteConfig': 'production',
          'tickets': 'https://blue-sharks.donati.jp/tickets/',
          'fanClub': 'https://blue-sharks.donati.jp/fanclub/',
          'partner': 'https://blue-sharks.donati.jp/partner/',
          'team': 'https://blue-sharks.donati.jp/team/',
          'wordpressAdmin': 'https://blue-sharks.donati.jp/wp-admin/',
        }
      : <String, String>{
          'auth': AppEnvironment.usesLocalServices
              ? 'http://${const String.fromEnvironment('LOCAL_AUTH_API_HOST')}:8000/api/mobile/v1/'
              : 'https://memodevelop.com/bluesharks_web/index.php/api/mobile/v1/',
          'wordpress': 'https://blue-sharks.donati.jp/wp-json/wp/v2/',
          'web': 'https://dev-blueshark.tmdsite.my.id/api',
          'topic': 'news_dev',
          'remoteConfig': 'debug',
          'tickets': 'https://blue-sharks.donati.jp/tickets/',
          'fanClub': 'https://blue-sharks.donati.jp/fanclub/',
          'partner': 'https://blue-sharks.donati.jp/partner/',
          'team': 'https://blue-sharks.donati.jp/team/',
          'wordpressAdmin': 'https://blue-sharks.donati.jp/wp-admin/',
        };
  for (final entry in expected.entries) {
    check(entry.key, actual[entry.key], entry.value);
  }
  stdout.writeln('PASS: 10 connection settings and environment selection');
}

void check(String label, Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('$label: expected $expected, got $actual');
  }
}
