import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';
import 'package:koto_blue_sharks/presentation/register/registration_notification_sync.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class CaptureProvider extends AuthProvider {
  int posts = 0;
  int failPosts = 0;
  String? bearer;
  Completer<Response<dynamic>>? holdPost;
  @override
  Future<Response<T>> post<T>(String? url, dynamic body,
      {String? contentType,
      Map<String, String>? headers,
      Map<String, dynamic>? query,
      dynamic decoder,
      dynamic uploadProgress}) async {
    posts++;
    bearer = headers?['Authorization'];
    if (posts <= failPosts) return Response<T>(statusCode: 503);
    if (holdPost != null) return await holdPost!.future as Response<T>;
    return Response<T>(statusCode: 200);
  }
}

// Use the real event loop for serialized MethodChannel storage operations.
Future<void> _drain([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    await AuthToken.notifySessionChangedForTesting();
    SharedPreferences.setMockInitialValues({'fcm_token': 'mock-old-device'});
    await MySharedPref.init();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
      'registration recovers from a settled HTTP failure using the real sender',
      () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'mock-auth');
    final provider = CaptureProvider()..failPosts = 1;
    final worker = NotificationTokenSync(
      currentSession: () => AuthToken.sessionVersion,
      retryDelay: Duration.zero,
      readToken: () async => 'mock-recovery-device',
      sendToken: (token, session, active) async =>
          await provider.updateNotificationTokenWhileCurrent(token,
              expectedSessionVersion: session, isActive: active) !=
          null,
    );
    expect(await worker.sync(), NotificationSyncOutcome.synced);
    expect(provider.posts, 2);
    worker.dispose();
  });

  test('registration legacy send lease expires during storage read', () async {
    final storageRead = Completer<String?>();
    messenger.setMockMethodCallHandler(channel, (_) => storageRead.future);
    final provider = CaptureProvider();
    final operation = provider.updateNotificationToken('mock-device-deadline');
    await _drain(const Duration(seconds: 6));
    expect(await operation, isNull);
    storageRead.complete('mock-auth');
    await _drain();
    expect(provider.posts, 0);
  });

  for (final dispose in [false, true]) {
    test(
        'same-session storage delay cannot post after worker timeout/dispose: $dispose',
        () async {
      final storageRead = Completer<String?>();
      messenger.setMockMethodCallHandler(channel, (_) => storageRead.future);
      final provider = CaptureProvider();
      final worker = NotificationTokenSync(
        currentSession: () => AuthToken.sessionVersion,
        stepTimeout: const Duration(seconds: 1),
        readToken: () async => 'mock-device-worker',
        sendToken: (token, session, active) async =>
            await provider.updateNotificationTokenWhileCurrent(token,
                expectedSessionVersion: session, isActive: active) !=
            null,
      );
      final operation = worker.sync();
      await _drain();
      if (dispose) {
        worker.dispose();
      } else {
        await _drain(const Duration(seconds: 2));
      }
      expect(
          await operation,
          dispose
              ? NotificationSyncOutcome.cancelled
              : NotificationSyncOutcome.deferred);
      storageRead.complete('mock-auth');
      await _drain();
      expect(provider.posts, 0);
      worker.dispose();
    });
  }

  test(
      'worker refreshes saved token; No14 legacy sender shares dedup across providers',
      () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'mock-auth');
    final workerProvider = CaptureProvider()
      ..holdPost = Completer<Response<dynamic>>();
    final registrationProvider = CaptureProvider();
    final worker = NotificationTokenSync(
      currentSession: () => AuthToken.sessionVersion,
      readToken: () async => 'mock-new-device',
      cacheToken: MySharedPref.setFcmToken,
      sendToken: (token, session, active) async =>
          await workerProvider.updateNotificationTokenWhileCurrent(token,
              expectedSessionVersion: session, isActive: active) !=
          null,
    );
    final sync = worker.sync();
    await _drain();
    expect(MySharedPref.getFcmToken(), 'mock-new-device');
    final registration = syncSavedFcmTokenAfterRegistration(
      isFromHome: true,
      readSavedFcmToken: MySharedPref.getFcmToken,
      updateNotificationToken: registrationProvider.updateNotificationToken,
    );
    await _drain();
    expect(workerProvider.posts, 1);
    expect(registrationProvider.posts, 0);
    workerProvider.holdPost!.complete(const Response(statusCode: 200));
    expect(await sync, NotificationSyncOutcome.synced);
    expect(await registration, RegistrationNotificationTokenSyncStatus.synced);
    expect(
        await registrationProvider.updateNotificationToken('mock-new-device'),
        isNotNull);
    expect(registrationProvider.posts, 0);
    worker.dispose();
  });

  test('logout session switch blocks pending No14 legacy storage read',
      () async {
    final storageRead = Completer<String?>();
    messenger.setMockMethodCallHandler(channel, (_) => storageRead.future);
    final provider = CaptureProvider();
    final operation = provider.updateNotificationToken('mock-logout-device');
    await _drain();
    await AuthToken.notifySessionChangedForTesting();
    storageRead.complete('mock-auth');
    expect(await operation, isNull);
    expect(provider.posts, 0);
  });

  test('No13 queued saves return their own committed session versions',
      () async {
    final releaseFirstWrite = Completer<void>();
    var writes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'write' && ++writes == 1) {
        await releaseFirstWrite.future;
      }
      return null;
    });
    final before = AuthToken.sessionVersion;
    final first = AuthToken().saveAccessTokenForSession('mock-first-auth');
    await _drain();
    final second = AuthToken().saveAccessTokenForSession('mock-second-auth');
    await _drain();
    releaseFirstWrite.complete();
    expect(await first, before + 1);
    expect(await second, before + 2);
    expect(AuthToken.sessionVersion, before + 2);
  });
  for (final expire in [false, true]) {
    test(
        'notification snapshot waits for new-session token write; lease expiry=$expire',
        () async {
      final writeStarted = Completer<void>();
      final releaseWrite = Completer<void>();
      var stored = 'mock-old-account-auth';
      var reads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') {
          writeStarted.complete();
          await releaseWrite.future;
          stored = (call.arguments as Map)['value'] as String;
        }
        if (call.method == 'read') {
          reads++;
          return stored;
        }
        return null;
      });
      final save =
          AuthToken().saveAccessTokenForSession('mock-new-account-auth');
      await _drain();
      expect(writeStarted.isCompleted, isTrue);
      final provider = CaptureProvider();
      final registration =
          provider.updateNotificationToken('mock-pending-write-device');
      await _drain();
      // The session has advanced, but its token is still old in the fake store.
      // A queue-external getAccessToken would read and send that old credential.
      expect(reads, 0);
      expect(provider.posts, 0);
      if (expire) {
        await _drain(const Duration(seconds: 6));
        expect(await registration, isNull);
      }
      releaseWrite.complete();
      final savedSession = await save;
      await _drain();
      expect(savedSession, AuthToken.sessionVersion);
      if (expire) {
        expect(provider.posts, 0);
      } else {
        expect((await registration)?.statusCode, 200);
        expect(provider.posts, 1);
        expect(provider.bearer, 'Bearer mock-new-account-auth');
      }
      expect(reads, 1);
    });
  }

  test('queued newer save invalidates the notification snapshot session',
      () async {
    final releaseFirst = Completer<void>();
    var writes = 0;
    var stored = 'mock-old-auth';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'write') {
        if (++writes == 1) await releaseFirst.future;
        stored = (call.arguments as Map)['value'] as String;
      }
      return call.method == 'read' ? stored : null;
    });
    final first = AuthToken().saveAccessTokenForSession('mock-first-auth');
    await _drain();
    final expected = AuthToken.sessionVersion;
    final second = AuthToken().saveAccessTokenForSession('mock-second-auth');
    final provider = CaptureProvider();
    final registration = provider.updateNotificationTokenWhileCurrent(
        'mock-stale-snapshot-device',
        expectedSessionVersion: expected,
        isActive: () => true);
    releaseFirst.complete();
    await first;
    await second;
    expect(await registration, isNull);
    expect(provider.posts, 0);
  });
}
