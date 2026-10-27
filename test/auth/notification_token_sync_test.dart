import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';

void main() {
  testWidgets('permanent null stops after three reads without sending',
      (tester) async {
    var reads = 0;
    var sends = 0;
    final worker = NotificationTokenSync(
      currentSession: () => 1,
      readToken: () async {
        reads++;
        return null;
      },
      sendToken: (_, __, ___) async {
        sends++;
        return true;
      },
    );
    final done = worker.sync();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(await done, NotificationSyncOutcome.deferred);
    await tester.pump(const Duration(minutes: 1));
    expect(reads, 3);
    expect(sends, 0);
    worker.dispose();
  });

  testWidgets(
      'token arrives on bounded retry, concurrent calls share one worker',
      (tester) async {
    var reads = 0;
    var sends = 0;
    final sentSessions = <int>[];
    final worker = NotificationTokenSync(
      currentSession: () => 7,
      readToken: () async => ++reads == 1 ? null : 'mock-device',
      sendToken: (_, session, ___) async {
        sentSessions.add(session);
        sends++;
        return true;
      },
    );
    final first = worker.sync();
    final same = worker.sync();
    expect(identical(first, same), isTrue);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(await first, NotificationSyncOutcome.synced);
    expect(await worker.sync(), NotificationSyncOutcome.synced);
    expect(sends, 1);
    expect(sentSessions, [7]);
    worker.dispose();
  });

  testWidgets('pending read times out once and late token has no send',
      (tester) async {
    final lateToken = Completer<String?>();
    var reads = 0;
    var sends = 0;
    final worker = NotificationTokenSync(
      currentSession: () => 1,
      readToken: () {
        reads++;
        return lateToken.future;
      },
      sendToken: (_, __, ___) async {
        sends++;
        return true;
      },
    );
    final done = worker.sync();
    await tester.pump(const Duration(seconds: 6));
    expect(await done, NotificationSyncOutcome.deferred);
    lateToken.complete('mock-late-device');
    await tester.pump(const Duration(minutes: 1));
    expect(reads, 1);
    expect(sends, 0);
    worker.dispose();
  });

  testWidgets('session change cancels old pending read before registration',
      (tester) async {
    var session = 1;
    var reads = 0;
    final old = Completer<String?>();
    final sentSessions = <int>[];
    final worker = NotificationTokenSync(
      currentSession: () => session,
      readToken: () =>
          ++reads == 1 ? old.future : Future.value('mock-new-device'),
      sendToken: (_, expected, ___) async {
        sentSessions.add(expected);
        return true;
      },
    );
    final first = worker.sync();
    session = 2;
    worker.cancel();
    expect(await first, NotificationSyncOutcome.cancelled);
    expect(await worker.sync(), NotificationSyncOutcome.synced);
    old.complete('mock-old-device');
    await tester.pump();
    expect(sentSessions, [2]);
    worker.dispose();
  });

  testWidgets(
      'session guard also rejects stale read without explicit cancellation',
      (tester) async {
    var session = 1;
    final pending = Completer<String?>();
    var sends = 0;
    final worker = NotificationTokenSync(
      currentSession: () => session,
      readToken: () => pending.future,
      sendToken: (_, __, ___) async {
        sends++;
        return true;
      },
    );
    final done = worker.sync();
    session++;
    pending.complete('mock-device');
    expect(await done, NotificationSyncOutcome.cancelled);
    expect(sends, 0);
    worker.dispose();
  });

  testWidgets('dispose stops pending read and future sync without sending',
      (tester) async {
    final pending = Completer<String?>();
    var sends = 0;
    final worker = NotificationTokenSync(
      currentSession: () => 1,
      readToken: () => pending.future,
      sendToken: (_, __, ___) async {
        sends++;
        return true;
      },
    );
    final done = worker.sync();
    worker.dispose();
    expect(await done, NotificationSyncOutcome.cancelled);
    pending.complete('mock-device');
    await tester.pump();
    expect(await worker.sync(), NotificationSyncOutcome.cancelled);
    expect(sends, 0);
  });

  testWidgets('send timeout never launches duplicate send on another sync',
      (tester) async {
    var sends = 0;
    final pending = Completer<bool>();
    final worker = NotificationTokenSync(
      currentSession: () => 1,
      readToken: () async => 'mock-device',
      sendToken: (_, __, ___) {
        sends++;
        return pending.future;
      },
    );
    final done = worker.sync();
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(await done, NotificationSyncOutcome.deferred);
    expect(await worker.sync(), NotificationSyncOutcome.deferred);
    pending.complete(true);
    await tester.pump();
    expect(sends, 1);
    worker.dispose();
  });

  testWidgets('failure is bounded and does not expose exception content',
      (tester) async {
    var sends = 0;
    final worker = NotificationTokenSync(
      currentSession: () => 1,
      readToken: () async => 'mock-device',
      sendToken: (_, __, ___) async {
        sends++;
        throw StateError('private-canary');
      },
    );
    final printed = <String>[];
    final result = await runZoned(worker.sync,
        zoneSpecification: ZoneSpecification(
            print: (_, __, ___, value) => printed.add(value)));
    expect(result, NotificationSyncOutcome.deferred);
    expect(await worker.sync(), NotificationSyncOutcome.deferred);
    expect(sends, 1);
    expect(printed, isEmpty);
    worker.dispose();
  });
}
