import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/controllers/register_member_fanclub.controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  testWidgets(
    'success callback saves auth first and one-shot syncs/routes once on home',
    (tester) async {
      final events = <String>[];
      final updateResponse = Completer<Response?>();
      final provider = _RecordingAuthProvider(
        events: events,
        update: (token) {
          expect(token, 'mock-fcm-token');
          return updateResponse.future;
        },
      );
      final dialogShown = Completer<void>();
      late Future<void> Function() successTap;
      var continuationCalls = 0;

      final controller = RegisterMemberFanclubController(
        apiProvider: provider,
        saveAccessToken: (token) async {
          expect(token, 'mock-access-token');
          events.add('save-auth');
        },
        syncNotifications: () async {
          events.add('read-fcm');
          final response =
              await provider.updateNotificationToken('mock-fcm-token');
          return response == null
              ? NotificationSyncOutcome.deferred
              : NotificationSyncOutcome.synced;
        },
        showSuccessDialog: (_, callback) {
          events.add('show-dialog');
          successTap = callback as Future<void> Function();
          dialogShown.complete();
        },
        continueAfterRegistration: (isFromHome) async {
          expect(isFromHome, isTrue);
          events.add('continue-home');
          continuationCalls++;
        },
      );

      final context = await _mountAndGetContext(tester);
      controller.onRegister(
        'mock-otp',
        'member@example.test',
        () {},
        () {},
        '',
        '',
        context,
        true,
      );
      await dialogShown.future;

      expect(events, ['register', 'save-auth', 'show-dialog']);
      final firstTap = successTap();
      final concurrentTap = successTap();
      await tester.pump();

      expect(provider.updateCalls, 1);
      expect(events, [
        'register',
        'save-auth',
        'show-dialog',
        'read-fcm',
        'update-fcm',
      ]);

      updateResponse.complete(const Response(statusCode: 200, body: {}));
      await Future.wait([firstTap, concurrentTap]);
      await successTap(); // A later re-press is still ignored.

      expect(provider.updateCalls, 1);
      expect(continuationCalls, 1);
      expect(events.last, 'continue-home');
    },
  );

  testWidgets(
    'sync failure then re-press keeps home continuation single-shot',
    (tester) async {
      final events = <String>[];
      final provider = _RecordingAuthProvider(
        events: events,
        update: (token) async {
          expect(token, 'mock-fcm-token');
          throw StateError('mock sync failure');
        },
      );
      final dialogShown = Completer<void>();
      late Future<void> Function() successTap;
      var continuationCalls = 0;

      final controller = RegisterMemberFanclubController(
        apiProvider: provider,
        saveAccessToken: (_) async => events.add('save-auth'),
        syncNotifications: () async {
          await provider.updateNotificationToken('mock-fcm-token');
          return NotificationSyncOutcome.synced;
        },
        showSuccessDialog: (_, callback) {
          successTap = callback as Future<void> Function();
          dialogShown.complete();
        },
        continueAfterRegistration: (isFromHome) async {
          expect(isFromHome, isTrue);
          continuationCalls++;
        },
      );

      final context = await _mountAndGetContext(tester);
      controller.onRegister(
        'mock-otp',
        'member@example.test',
        () {},
        () {},
        '',
        '',
        context,
        true,
      );
      await dialogShown.future;

      await successTap();
      await successTap();

      expect(provider.updateCalls, 1);
      expect(continuationCalls, 1);
    },
  );

  testWidgets(
    'normal registration does not add controller sync before confirmation',
    (tester) async {
      final events = <String>[];
      final provider = _RecordingAuthProvider(
        events: events,
        update: (_) async => const Response(statusCode: 200, body: {}),
      );
      final dialogShown = Completer<void>();
      late Future<void> Function() successTap;
      var continuationCalls = 0;

      final controller = RegisterMemberFanclubController(
        apiProvider: provider,
        saveAccessToken: (_) async => events.add('save-auth'),
        syncNotifications: () async {
          events.add('read-fcm');
          final response =
              await provider.updateNotificationToken('mock-fcm-token');
          return response == null
              ? NotificationSyncOutcome.deferred
              : NotificationSyncOutcome.synced;
        },
        showSuccessDialog: (_, callback) {
          successTap = callback as Future<void> Function();
          dialogShown.complete();
        },
        continueAfterRegistration: (isFromHome) async {
          expect(isFromHome, isFalse);
          continuationCalls++;
        },
      );

      final context = await _mountAndGetContext(tester);
      controller.onRegister(
        'mock-otp',
        'member@example.test',
        () {},
        () {},
        '',
        '',
        context,
        false,
      );
      await dialogShown.future;
      await successTap();

      expect(provider.updateCalls, 0);
      expect(events, ['register', 'save-auth']);
      expect(continuationCalls, 1);
    },
  );
}

Future<BuildContext> _mountAndGetContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (value) {
          context = value;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

class _RecordingAuthProvider extends AuthProvider {
  _RecordingAuthProvider({required this.events, required this.update});

  final List<String> events;
  final Future<Response?> Function(String token) update;
  var updateCalls = 0;

  @override
  void onInit() {}

  @override
  Future<Auth> register(
    String acountId,
    String email,
    String otpId,
    String password,
    Function(String) onError,
  ) async {
    events.add('register');
    return Auth(
      id: 1,
      name: 'Mock Member',
      email: email,
      access_token: 'mock-access-token',
    );
  }

  @override
  Future<Response?> updateNotificationToken(String fcm) {
    updateCalls++;
    events.add('update-fcm');
    return update(fcm);
  }
}
