import 'package:shared_preferences/shared_preferences.dart';

class MySharedPref {
  // prevent making instance
  MySharedPref._();

  // get storage
  static late SharedPreferences _sharedPreferences;

  // STORING KEYS
  static const String _fcmTokenKey = 'fcm_token';
  static const String _currentWallpaper = 'wallpaperPreferences';
  static const String _currentWallpaperName = 'wallpaperName';
  static const String _notificationKey = 'notification';
  static const String _isFirstOpen = 'isFirstOpen';
  static const String _saveGameGuideArticles = 'saveGameGuideArticles';
  static const String _gameGuideArticlesCache = 'gameGuideArticlesCache';
  static const String _gameGuideArticlesCachedAt = 'gameGuideArticlesCachedAt';

  /// init get storage services
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static setStorage(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
  }

  /// save generated fcm token
  static Future<void> setFcmToken(String token) =>
      _sharedPreferences.setString(_fcmTokenKey, token);

  /// get authorization token
  static String? getFcmToken() => _sharedPreferences.getString(_fcmTokenKey);

  /// save generated fcm token
  static Future<void> setWallpaper(String wallpaperLink) =>
      _sharedPreferences.setString(_currentWallpaper, wallpaperLink);

  /// get authorization token
  static String? getWallpaper() =>
      _sharedPreferences.getString(_currentWallpaper);

  /// save generated fcm token
  static Future<void> setWallpaperName(String wallapaperName) =>
      _sharedPreferences.setString(_currentWallpaperName, wallapaperName);

  /// get authorization token
  static String? getWallpaperName() =>
      _sharedPreferences.getString(_currentWallpaperName);

  /// save generated fcm token
  static Future<void> setNotification(String status) =>
      _sharedPreferences.setString(_notificationKey, status);

  /// get authorization token
  static String? getNotification() =>
      _sharedPreferences.getString(_notificationKey);

  /// save generated fcm token
  static Future<void> setFirstOpen(String status) =>
      _sharedPreferences.setString(_isFirstOpen, status);

  /// get authorization token
  static String? getFirstOpen() => _sharedPreferences.getString(_isFirstOpen);

  static Future<void> setSaveGameGuideArticles(bool enabled) =>
      _sharedPreferences.setBool(_saveGameGuideArticles, enabled);

  static bool getSaveGameGuideArticles() =>
      _sharedPreferences.getBool(_saveGameGuideArticles) ?? false;

  static Future<void> setGameGuideArticlesCache(String value) =>
      _sharedPreferences.setString(_gameGuideArticlesCache, value);

  static String? getGameGuideArticlesCache() =>
      _sharedPreferences.getString(_gameGuideArticlesCache);

  static Future<void> setGameGuideArticlesCachedAt(DateTime value) =>
      _sharedPreferences.setString(
        _gameGuideArticlesCachedAt,
        value.toIso8601String(),
      );

  static DateTime? getGameGuideArticlesCachedAt() {
    final value = _sharedPreferences.getString(_gameGuideArticlesCachedAt);
    return value == null ? null : DateTime.tryParse(value);
  }

  static Future<void> clearGameGuideArticlesCache() async {
    await _sharedPreferences.remove(_gameGuideArticlesCache);
    await _sharedPreferences.remove(_gameGuideArticlesCachedAt);
  }

  /// clear all data from shared pref
  // static Future<void> clear() async => await _sharedPreferences.clear();

  static Future<void> clear() async {
    await _sharedPreferences.remove(_currentWallpaper);
    await _sharedPreferences.remove(_currentWallpaperName);
    await _sharedPreferences.remove(_notificationKey);
    await _sharedPreferences.remove(_saveGameGuideArticles);
    await clearGameGuideArticlesCache();
  }
}
