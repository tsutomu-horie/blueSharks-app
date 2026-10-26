import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/register/registration_notification_sync.dart';

void main() {
  group('registration notification token sync', () {
    test('home flow syncs the saved token exactly once', () async {
      final events = <String>[];
      final status = await syncSavedFcmTokenAfterRegistration(
        isFromHome: true,
        readSavedFcmToken: () {
          events.add('read-saved-token');
          return 'mock-fcm-token';
        },
        updateNotificationToken: (token) async {
          events.add('sync-token');
          expect(token, 'mock-fcm-token');
          return Object();
        },
      );

      expect(status, RegistrationNotificationTokenSyncStatus.synced);
      expect(events, ['read-saved-token', 'sync-token']);
    });

    test('normal registration leaves sync to confirmation flow', () async {
      var syncCalled = false;
      var continuationCalled = false;
      final incompleteStatuses = <RegistrationNotificationTokenSyncStatus>[];

      await continueAfterBestEffortNotificationSync(
        isFromHome: false,
        sync: () async {
          syncCalled = true;
          return RegistrationNotificationTokenSyncStatus.synced;
        },
        onSyncIncomplete: incompleteStatuses.add,
        continueFlow: () async {
          continuationCalled = true;
        },
      );

      expect(syncCalled, isFalse);
      expect(continuationCalled, isTrue);
      expect(incompleteStatuses, isEmpty);
    });

    test('missing saved token is reported and does not call updater', () async {
      var updateCalled = false;
      final status = await syncSavedFcmTokenAfterRegistration(
        isFromHome: true,
        readSavedFcmToken: () => null,
        updateNotificationToken: (_) async {
          updateCalled = true;
          return Object();
        },
      );

      expect(
        status,
        RegistrationNotificationTokenSyncStatus.missingSavedToken,
      );
      expect(updateCalled, isFalse);
    });

    test('missing saved token does not block the existing navigation',
        () async {
      var continuationCalled = false;
      final incompleteStatuses = <RegistrationNotificationTokenSyncStatus>[];

      await continueAfterBestEffortNotificationSync(
        isFromHome: true,
        sync: () => syncSavedFcmTokenAfterRegistration(
          isFromHome: true,
          readSavedFcmToken: () => null,
          updateNotificationToken: (_) async => Object(),
        ),
        onSyncIncomplete: incompleteStatuses.add,
        continueFlow: () async {
          continuationCalled = true;
        },
      );

      expect(continuationCalled, isTrue);
      expect(
        incompleteStatuses,
        [RegistrationNotificationTokenSyncStatus.missingSavedToken],
      );
    });

    test('null provider result is not reported as synced', () async {
      final status = await syncSavedFcmTokenAfterRegistration(
        isFromHome: true,
        readSavedFcmToken: () => 'mock-fcm-token',
        updateNotificationToken: (_) async => null,
      );

      expect(
        status,
        RegistrationNotificationTokenSyncStatus.missingAuthToken,
      );
    });

    test('provider failure is reported and does not block navigation',
        () async {
      var continuationCalled = false;
      final incompleteStatuses = <RegistrationNotificationTokenSyncStatus>[];

      await continueAfterBestEffortNotificationSync(
        isFromHome: true,
        sync: () => syncSavedFcmTokenAfterRegistration(
          isFromHome: true,
          readSavedFcmToken: () => 'mock-fcm-token',
          updateNotificationToken: (_) async =>
              throw StateError('mock failure'),
        ),
        onSyncIncomplete: incompleteStatuses.add,
        continueFlow: () async {
          continuationCalled = true;
        },
      );

      expect(continuationCalled, isTrue);
      expect(
        incompleteStatuses,
        [RegistrationNotificationTokenSyncStatus.failed],
      );
    });

    test('unexpected sync failure also continues navigation', () async {
      var continuationCalled = false;
      final incompleteStatuses = <RegistrationNotificationTokenSyncStatus>[];

      await continueAfterBestEffortNotificationSync(
        isFromHome: true,
        sync: () async => throw StateError('mock unexpected failure'),
        onSyncIncomplete: incompleteStatuses.add,
        continueFlow: () async {
          continuationCalled = true;
        },
      );

      expect(continuationCalled, isTrue);
      expect(
        incompleteStatuses,
        [RegistrationNotificationTokenSyncStatus.failed],
      );
    });

    test('concurrent taps start the success action only once', () async {
      final guard = OneShotAsyncAction();
      final finishFirstAction = Completer<void>();
      var actionCalls = 0;

      final firstTap = guard.run(() {
        actionCalls++;
        return finishFirstAction.future;
      });
      final secondTap = guard.run(() async {
        actionCalls++;
      });

      expect(actionCalls, 1);
      finishFirstAction.complete();
      await Future.wait([firstTap, secondTap]);
      expect(actionCalls, 1);
    });

    test('sync failure followed by another tap does not repeat sync or route',
        () async {
      final guard = OneShotAsyncAction();
      var syncCalls = 0;
      var navigationCalls = 0;
      final incompleteStatuses = <RegistrationNotificationTokenSyncStatus>[];

      Future<void> onSuccessTap() => guard.run(() async {
            await continueAfterBestEffortNotificationSync(
              isFromHome: true,
              sync: () => syncSavedFcmTokenAfterRegistration(
                isFromHome: true,
                readSavedFcmToken: () => 'mock-fcm-token',
                updateNotificationToken: (_) async {
                  syncCalls++;
                  throw StateError('mock failure');
                },
              ),
              onSyncIncomplete: incompleteStatuses.add,
              continueFlow: () async {
                navigationCalls++;
              },
            );
          });

      await onSuccessTap();
      await onSuccessTap();

      expect(syncCalls, 1);
      expect(navigationCalls, 1);
      expect(
          incompleteStatuses, [RegistrationNotificationTokenSyncStatus.failed]);
    });
  });
}
