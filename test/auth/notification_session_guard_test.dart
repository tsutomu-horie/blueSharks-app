import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';

class CaptureNotificationProvider extends AuthProvider {
  int requests = 0;
  @override
  Future<Response<T>> post<T>(String? url, dynamic body,
      {String? contentType,
      Map<String, String>? headers,
      Map<String, dynamic>? query,
      dynamic decoder,
      dynamic uploadProgress}) async {
    requests++;
    return Response<T>(statusCode: 200);
  }
}

// Use the real event loop for serialized MethodChannel storage operations.
Future<void> _drain([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  test('session switch during mocked storage read prevents HTTP send',
      () async {
    final read = Completer<String?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (_) => read.future);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null));
    final provider = CaptureNotificationProvider();
    final pending = provider.updateNotificationTokenWhileCurrent('mock-device',
        isActive: () => true, expectedSessionVersion: AuthToken.sessionVersion);
    await _drain();
    await AuthToken.notifySessionChangedForTesting();
    read.complete('mock-auth');
    expect(await pending, isNull);
    expect(provider.requests, 0);
  });
  test('current session sends once through mocked HTTP transport', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (_) async => 'mock-auth');
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null));
    final provider = CaptureNotificationProvider();
    final result = await provider.updateNotificationTokenWhileCurrent(
        'mock-device',
        isActive: () => true,
        expectedSessionVersion: AuthToken.sessionVersion);
    expect(result?.statusCode, 200);
    expect(provider.requests, 1);
  });
}
