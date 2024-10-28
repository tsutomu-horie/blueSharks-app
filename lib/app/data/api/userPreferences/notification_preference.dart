import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPreference {
  final _storage = const FlutterSecureStorage();

  Future<void> saveNotificationSetting(String notificationSetting) async {
    await _storage.write(key: 'notificationSetting', value: notificationSetting.replaceAll('"', ''));
  }

  Future<String?> getNotificationSetting() async {
    String? wallpaper = await _storage.read(key: 'notificationSetting');

    if (wallpaper != null){
      return wallpaper;
    }

    return null;
  }

  Future<void> deleteNotificationSetting() async {
    return await _storage.delete(key: 'notificationSetting');
  }
}
