import 'package:flutter/material.dart';
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
  static String? getFcmToken() =>
      _sharedPreferences.getString(_fcmTokenKey);

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

  /// clear all data from shared pref
  static Future<void> clear() async => await _sharedPreferences.clear();

}