/// 接続環境だけを選択します。Release/Debugの実行モードは変更しません。
class AppEnvironment {
  static const name = String.fromEnvironment('APP_ENV');
  static const isOtaTest = name == 'ota-test';
  static const usesProductionServices =
      bool.fromEnvironment('dart.vm.product') && !isOtaTest;

  static const authApiBaseUrl = usesProductionServices
      ? 'https://app.blue-sharks.jp/api/mobile/v1/'
      : 'https://memodevelop.com/bluesharks_web/index.php/api/mobile/v1/';
  static const wordpressApiBaseUrl = usesProductionServices
      ? 'https://blue-sharks.jp/wp-json/wp/v2/'
      : 'https://blue-sharks.donati.jp/wp-json/wp/v2/';
  static const webBaseUrl = usesProductionServices
      ? 'https://app.blue-sharks.jp/api/'
      : 'https://dev-blueshark.tmdsite.my.id/api';
  static const notificationTopic =
      usesProductionServices ? 'news_prod' : 'news_dev';
  static const remoteConfigEnvironment =
      usesProductionServices ? 'production' : 'debug';
  static const ticketsUrl = usesProductionServices
      ? 'https://blue-sharks.jp/tickets/'
      : 'https://blue-sharks.donati.jp/tickets/';
  static const fanClubUrl = usesProductionServices
      ? 'https://blue-sharks.jp/fanclub/'
      : 'https://blue-sharks.donati.jp/fanclub/';
  static const partnerUrl = usesProductionServices
      ? 'https://blue-sharks.jp/partner/'
      : 'https://blue-sharks.donati.jp/partner/';
  static const teamUrl = usesProductionServices
      ? 'https://blue-sharks.jp/team/'
      : 'https://blue-sharks.donati.jp/team/';
  static const wordpressAdminUrl = usesProductionServices
      ? 'https://blue-sharks.jp/wp-admin/'
      : 'https://blue-sharks.donati.jp/wp-admin/';

  /// mainの通信・SDK初期化より前に検証します。assertには依存しません。
  static void validate() {
    if (name.isNotEmpty && !isOtaTest) {
      throw StateError('Unsupported APP_ENV. Omit it or use ota-test.');
    }
    if (isOtaTest &&
        (const bool.fromEnvironment('USE_LOCAL_AUTH_API') ||
            const String.fromEnvironment('LOCAL_AUTH_API_HOST').isNotEmpty)) {
      throw StateError('ota-test cannot be combined with local API overrides.');
    }
  }
}
