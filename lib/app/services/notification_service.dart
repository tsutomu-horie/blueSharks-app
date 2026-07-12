import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPreference {
  final _storage = const FlutterSecureStorage();

  Future<void> saveNotificationSetting(String notificationSetting) async {
    await _storage.write(key: 'notificationSetting', value: notificationSetting.replaceAll('"', ''));
  }

  Future<String?> getNotificationSetting() async {
    const _storage = FlutterSecureStorage();
    try {
      final accessToken = await _storage.read(key: 'notificationSetting');
      return accessToken;
    } on PlatformException catch (e) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await _storage.deleteAll();
    }

    // String? wallpaper = await _storage.read(key: 'notificationSetting');
    //
    // if (wallpaper != null){
    //   return wallpaper;
    // }
    //
    // return null;
  }

  Future<void> deleteNotificationSetting() async {
    return await _storage.delete(key: 'notificationSetting');
  }
}
