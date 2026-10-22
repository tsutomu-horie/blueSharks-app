import 'dart:convert';

import 'app_environment.dart';

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
  // Keep saved articles separate when the website source changes.
  static const String _gameGuideArticlesCache =
      'gameGuideArticlesCache:${AppEnvironment.websiteBaseUrl}:match-filters-v1';
  static const String _gameGuideArticlesCachedAt =
      'gameGuideArticlesCachedAt:${AppEnvironment.websiteBaseUrl}:match-filters-v1';
  static const String _trainingGameStartedAt = 'trainingGameStartedAt';
  static const String _trainingGameDebugElapsedSeconds =
      'trainingGameDebugElapsedSeconds';
  static const String _trainingGameLocalState = 'trainingGameLocalState';
  static const String _trainingGamePendingActions =
      'trainingGamePendingActions';
  static const String _trainingGamePendingActionsArchive =
      'trainingGamePendingActionsArchive';
  static const String _trainingGamePendingActionsRecovery =
      'trainingGamePendingActionsRecovery';

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

  /// 現在の育成サイクル開始日時を保存します。
  static Future<void> setTrainingGameStartedAt(DateTime value) =>
      _sharedPreferences.setString(
        _trainingGameStartedAt,
        value.toIso8601String(),
      );

  /// 保存済みの育成サイクル開始日時を取得します。
  static DateTime? getTrainingGameStartedAt() {
    final value = _sharedPreferences.getString(_trainingGameStartedAt);
    return value == null ? null : DateTime.tryParse(value);
  }

  /// 保存済みの育成サイクル開始日時を削除します。
  static Future<void> clearTrainingGameStartedAt() =>
      _sharedPreferences.remove(_trainingGameStartedAt);

  /// デバッグで加算した育成経過秒数を保存します。
  static Future<void> setTrainingGameDebugElapsedSeconds(int value) =>
      _sharedPreferences.setInt(_trainingGameDebugElapsedSeconds, value);

  /// 保存済みのデバッグ加算秒数を取得します。
  static int getTrainingGameDebugElapsedSeconds() =>
      _sharedPreferences.getInt(_trainingGameDebugElapsedSeconds) ?? 0;

  /// デバッグ加算秒数を新しい育成サイクル開始前に削除します。
  static Future<void> clearTrainingGameDebugElapsedSeconds() =>
      _sharedPreferences.remove(_trainingGameDebugElapsedSeconds);

  /// サーバーに保持しない育成途中の進行状態を保存します。
  static Future<void> setTrainingGameLocalState(String value) =>
      _sharedPreferences.setString(_trainingGameLocalState, value);

  /// 保存済みの育成途中の進行状態を取得します。
  static String? getTrainingGameLocalState() =>
      _sharedPreferences.getString(_trainingGameLocalState);

  /// 新規育成サイクル開始時に以前の進行状態を削除します。
  static Future<void> clearTrainingGameLocalState() =>
      _sharedPreferences.remove(_trainingGameLocalState);

  /// 未確定アクションの冪等キーと内容をプロセス再起動後も保持します。
  static Future<bool> setTrainingGamePendingActions(String value) =>
      _sharedPreferences.setString(_trainingGamePendingActions, value);

  /// 保留中アクションの永続キューを取得します。
  static String? getTrainingGamePendingActions() =>
      _sharedPreferences.getString(_trainingGamePendingActions);

  /// 全アプリデータ削除時にのみ、保留アクションキューを削除します。
  static Future<bool> clearTrainingGamePendingActions() =>
      _sharedPreferences.remove(_trainingGamePendingActions);

  /// 破損したjournalを再送せずに退避し、未確定操作の調査用に原文を保全します。
  static Future<bool> archiveTrainingGamePendingActions(String value) async {
    final rawArchive =
        _sharedPreferences.getString(_trainingGamePendingActionsArchive);
    final archived = <String>[];
    if (rawArchive != null) {
      final decoded = jsonDecode(rawArchive);
      if (decoded is! List || decoded.any((entry) => entry is! String)) {
        return false;
      }
      archived.addAll(decoded.cast<String>());
    }
    if (!archived.contains(value)) archived.add(value);
    return _sharedPreferences.setString(
      _trainingGamePendingActionsArchive,
      jsonEncode(archived),
    );
  }

  /// 退避済みのjournal原文を返します。
  static String? getTrainingGamePendingActionsArchive() =>
      _sharedPreferences.getString(_trainingGamePendingActionsArchive);

  /// 破損journalの処理結果を確認するまで、対象ゲームの停止状態を再起動後も保持します。
  static Future<bool> setTrainingGamePendingActionsRecovery(String value) =>
      _sharedPreferences.setString(_trainingGamePendingActionsRecovery, value);

  static String? getTrainingGamePendingActionsRecovery() =>
      _sharedPreferences.getString(_trainingGamePendingActionsRecovery);

  static Future<bool> clearTrainingGamePendingActionsRecovery() =>
      _sharedPreferences.remove(_trainingGamePendingActionsRecovery);

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
    await _sharedPreferences.remove(_trainingGameStartedAt);
    await _sharedPreferences.remove(_trainingGameDebugElapsedSeconds);
    await _sharedPreferences.remove(_trainingGameLocalState);
    await _sharedPreferences.remove(_trainingGamePendingActions);
    await _sharedPreferences.remove(_trainingGamePendingActionsArchive);
    await _sharedPreferences.remove(_trainingGamePendingActionsRecovery);
    await clearGameGuideArticlesCache();
  }
}
