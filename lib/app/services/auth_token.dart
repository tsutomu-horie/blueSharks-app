import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef AuthSessionChangeListener = FutureOr<void> Function(int sessionVersion);

class AuthToken {
  static int _sessionVersion = 0;
  static final _sessionChangeListeners = <AuthSessionChangeListener>{};

  final _storage = const FlutterSecureStorage();

  /// Ephemeral session generation. It is never written to secure or local storage.
  static int get sessionVersion => _sessionVersion;

  static void addSessionChangeListener(AuthSessionChangeListener listener) {
    _sessionChangeListeners.add(listener);
  }

  static void removeSessionChangeListener(AuthSessionChangeListener listener) {
    _sessionChangeListeners.remove(listener);
  }

  static Future<void> _advanceSessionVersion() async {
    final version = ++_sessionVersion;
    for (final listener in List<AuthSessionChangeListener>.of(
      _sessionChangeListeners,
    )) {
      await listener(version);
    }
  }

  @visibleForTesting
  static Future<void> notifySessionChangedForTesting() =>
      _advanceSessionVersion();

  Future<void> saveAccessToken(String token) async {
    await _advanceSessionVersion();
    await _storage.write(key: 'accessToken', value: token.replaceAll('"', ''));
  }

  Future<String?> getAccessToken() async {
    const _storage = FlutterSecureStorage();
    try {
      final accessToken = await _storage.read(key: 'accessToken');
      return accessToken;
    } on PlatformException catch (e) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      print("get error secure storage ${e}");
      await _storage.deleteAll();
      await _advanceSessionVersion();
    }
    return null;
  }

  Future<void> deleteToken() async {
    try {
      await _advanceSessionVersion();
    } finally {
      await _storage.delete(key: 'accessToken');
    }
  }
}

class AuthSessionChangedException implements Exception {
  const AuthSessionChangedException();
}
