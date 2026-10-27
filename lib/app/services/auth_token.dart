import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef AuthSessionChangeListener = FutureOr<void> Function(int sessionVersion);
typedef AuthTokenSnapshot = ({String? token, int sessionVersion});

class AuthToken {
  static int _sessionVersion = 0;
  static final _sessionChangeListeners = <AuthSessionChangeListener>{};
  static Future<void> _mutationQueue = Future<void>.value();

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

  Future<T> _serializeMutation<T>(Future<T> Function() action) async {
    final previous = _mutationQueue;
    final release = Completer<void>();
    _mutationQueue = release.future;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }

  @visibleForTesting
  static Future<void> notifySessionChangedForTesting() =>
      _advanceSessionVersion();

  Future<void> saveAccessToken(String token) async {
    await _serializeMutation(() async {
      await _advanceSessionVersion();
      await _storage.write(
        key: 'accessToken',
        value: token.replaceAll('"', ''),
      );
    });
  }

  Future<String?> getAccessToken() async {
    return _readAccessToken();
  }

  Future<AuthTokenSnapshot> readSessionSnapshot() =>
      _serializeMutation(() async {
        final token = await _readAccessToken();
        return (token: token, sessionVersion: _sessionVersion);
      });

  Future<String?> _readAccessToken() async {
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
    await _serializeMutation(() async {
      try {
        await _advanceSessionVersion();
      } finally {
        await _storage.delete(key: 'accessToken');
      }
    });
  }

  Future<bool> deleteTokenIfMatches(
    String expectedToken,
    int expectedSessionVersion,
  ) =>
      _serializeMutation(() async {
        if (_sessionVersion != expectedSessionVersion) return false;

        final currentToken = await _readAccessToken();
        if (currentToken != expectedToken ||
            _sessionVersion != expectedSessionVersion) {
          return false;
        }

        try {
          await _advanceSessionVersion();
        } finally {
          await _storage.delete(key: 'accessToken');
        }
        return true;
      });
}

class AuthSessionChangedException implements Exception {
  const AuthSessionChangedException();
}
