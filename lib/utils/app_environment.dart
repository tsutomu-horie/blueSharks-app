/// 接続環境だけを選択します。Release/Debugの実行モードは変更しません。
class AppEnvironment {
  // 未指定時もビルド方式から推測せず、テスト環境を使います。
  static const _configuredName =
      String.fromEnvironment('APP_ENV', defaultValue: 'test');
  // 既存のOTA設定から移行できるよう、旧名だけ互換対応します。
  static const name = _configuredName == 'ota-test' ? 'test' : _configuredName;
  static const usesProductionServices = name == 'production';
  static const usesLocalServices = name == 'local';
  static const badgeLabel = usesProductionServices ? '' : 'DEBUG';

  /// 検証版の育成UI。Flutterのビルド方式やサーバーの操作権限とは独立。
  /// 通常版ではDebugビルドでも表示しません。API側の権限判定は維持します。
  static const showsTrainingDebugUi = name == 'test' || name == 'local';
  static const localAuthApiHost = String.fromEnvironment('LOCAL_AUTH_API_HOST');

  // localでは会員APIのみPCへ接続し、他のサービスはテスト環境を使います。
  static const authApiBaseUrl = usesLocalServices
      ? 'http://$localAuthApiHost:8000/api/mobile/v1/'
      : usesProductionServices
          ? 'https://app.blue-sharks.jp/api/mobile/v1/'
          : 'https://memodevelop.com/bluesharks_web/index.php/api/mobile/v1/';
  // Website content is shared by production and test app environments.
  static const websiteBaseUrl = 'https://blue-sharks.donati.jp';
  static const wordpressApiBaseUrl = '$websiteBaseUrl/wp-json/wp/v2/';
  static const webBaseUrl = usesProductionServices
      ? 'https://app.blue-sharks.jp/api/'
      : 'https://dev-blueshark.tmdsite.my.id/api';
  static const notificationTopic =
      usesProductionServices ? 'news_prod' : 'news_dev';
  static const remoteConfigEnvironment =
      usesProductionServices ? 'production' : 'debug';
  static const ticketsUrl = '$websiteBaseUrl/tickets/';
  static const fanClubUrl = '$websiteBaseUrl/fanclub/';
  static const partnerUrl = '$websiteBaseUrl/partner/';
  static const teamUrl = '$websiteBaseUrl/team/';
  // Keep the management destination independent from public site/feed URLs.
  static const wordpressAdminUrl = 'https://blue-sharks.jp/wp-admin/';

  /// mainの通信・SDK初期化より前に検証します。assertには依存しません。
  static void validate() {
    if (!const ['local', 'test', 'production'].contains(name)) {
      throw StateError('Use APP_ENV=local, test, or production.');
    }
    if (const bool.fromEnvironment('USE_LOCAL_AUTH_API')) {
      throw StateError('Use APP_ENV=local instead of USE_LOCAL_AUTH_API.');
    }
    if (usesLocalServices) {
      // スキーム・ポート・パスは指定せず、到達可能なIPv4/ホスト名を渡します。
      final hostname = RegExp(
        r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
        r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$',
      );
      final isNumeric = RegExp(r'^[0-9.]+$').hasMatch(localAuthApiHost);
      final octets = localAuthApiHost.split('.');
      final validIpv4 = octets.length == 4 &&
          octets.every((part) {
            final number = int.tryParse(part);
            return number != null && number >= 0 && number <= 255;
          });
      if (localAuthApiHost.length > 253 ||
          !hostname.hasMatch(localAuthApiHost) ||
          (isNumeric && !validIpv4)) {
        throw StateError('local requires a valid LOCAL_AUTH_API_HOST.');
      }
    } else if (localAuthApiHost.isNotEmpty) {
      throw StateError('LOCAL_AUTH_API_HOST is available only for local.');
    }
  }
}
