import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/presentation/login/controllers/login.controller.dart';

// All transport is replaced here. Successful completion never touches storage,
// Firebase, notifications, navigation, or a real account.
class MockProvider extends AuthProvider {
  MockProvider(this.reply);
  final Future<Response<dynamic>> Function() reply;
  int calls = 0;
  @override
  Future<Response<dynamic>> requestLogin(Map<String, dynamic> body) {
    calls++;
    return reply();
  }
}

class TestController extends LoginController {
  TestController(AuthProvider provider) : super(apiProvider: provider);
  int completed = 0;
  @override
  Future<void> completeLogin(
      Auth response, String player, String name, bool fromHome) async {
    completed++;
  }
}

class CompletionController extends LoginController {
  CompletionController(AuthProvider provider) : super(apiProvider: provider);
  int saved = 0;
  int navigated = 0;
  int notificationStarts = 0;
  Future<void> Function()? notificationWork;
  Future<int> Function()? persistenceWork;
  @override
  Future<int> persistLogin(Auth response) {
    saved++;
    return persistenceWork?.call() ?? Future.value(AuthToken.sessionVersion);
  }

  @override
  Future<void> syncNotifications() {
    notificationStarts++;
    return notificationWork?.call() ?? Future.value();
  }

  @override
  void navigateAfterLogin(bool fromHome) {
    navigated++;
  }
}

Map<String, dynamic> validData({String token = 'mock-session'}) => {
      'data': {
        'id': 1,
        'name': 'mock',
        'email': 'mock@example.invalid',
        'access_token': token
      },
    };

void main() {
  final cases = <String, Future<Response<dynamic>> Function()>{
    for (final status in [401, 403, 422])
      'rejected $status': () async => Response(statusCode: status),
    for (final field in ['email', 'username', 'password'])
      'rejected 422 json $field': () async => Response(statusCode: 422, body: {
            'message': 'mock-validation-message',
            'errors': {
              field: ['mock-server-detail']
            },
          }),
    'server': () async => const Response(statusCode: 503),
    'server rate 429': () async => const Response(statusCode: 429, body: {
          'message': 'mock-server-detail',
        }),
    'network status': () async => const Response(),
    'socket': () async => throw const SocketException('mock'),
    'timeout': () async => throw TimeoutException('mock'),
    'invalid json': () async => throw const FormatException('mock'),
    'html': () async => const Response(statusCode: 200, body: '<html>'),
    'missing data': () async => const Response(statusCode: 200, body: {}),
    'wrong fields': () async =>
        const Response(statusCode: 200, body: {'data': {}}),
    'empty token': () async =>
        Response(statusCode: 200, body: validData(token: '  ')),
  };
  for (final entry in cases.entries) {
    testWidgets('${entry.key} shows error and stops loading', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        child: MaterialApp(home: Builder(builder: (value) {
          context = value;
          return const SizedBox();
        })),
      ));
      final controller = TestController(MockProvider(entry.value));
      await controller.login(context, '', '', false);
      await tester.pump();
      expect(controller.isLoadingLogin.value, isFalse);
      expect(controller.loginErrorMessage.value, isNotEmpty);
      expect(controller.completed, 0);
      expect(find.byType(Dialog), findsOneWidget);
      if (entry.key.startsWith('rejected')) {
        expect(
          find.text(
              'メールアドレスまたはIDが確認できませんでした。ご登録情報を再度ご確認ください'),
          findsOneWidget,
        );
        expect(
          find.text(
              'ファンクラブ会員情報の更新には最大12時間かかります。ご登録情報が正しい場合には、しばらくしてから再度会員連携を行ってください。'),
          findsOneWidget,
        );
      }
      final expected = entry.key.startsWith('rejected')
          ? 'ログインできません'
          : ['network status', 'socket', 'timeout'].contains(entry.key)
              ? '通信'
              : entry.key.startsWith('server')
                  ? '現在'
                  : 'ログイン情報';
      expect(controller.loginErrorMessage.value, startsWith(expected));
    });
  }
  testWidgets('pending request times out and late response cannot log in',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      child: MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })),
    ));
    final pending = Completer<Response<dynamic>>();
    final controller = TestController(MockProvider(() => pending.future));
    final operation = controller.login(context, '', '', false);
    await tester.pump(const Duration(seconds: 21));
    await operation;
    expect(controller.isLoadingLogin.value, isFalse);
    expect(controller.loginErrorMessage.value, startsWith('通信'));
    pending.complete(Response(statusCode: 200, body: validData()));
    await tester.pump();
    expect(controller.completed, 0);
  });
  testWidgets(
      'normal login completes once; duplicate tap is ignored; retry clears error',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final pending = Completer<Response<dynamic>>();
    final provider = MockProvider(() => pending.future);
    final controller = TestController(provider);
    controller.loginErrorMessage.value = 'previous failure';
    final first = controller.login(context, '', '', false);
    expect(controller.isLoadingLogin.value, isTrue);
    expect(controller.loginErrorMessage.value, isNull);
    await controller.login(context, '', '', false);
    expect(provider.calls, 1);
    pending.complete(Response(statusCode: 200, body: validData()));
    await first;
    expect(controller.isLoadingLogin.value, isFalse);
    expect(controller.loginErrorMessage.value, isNull);
    expect(controller.completed, 1);
  });
  testWidgets('retry success then old timed-out success completes only once',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      child: MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })),
    ));
    final old = Completer<Response<dynamic>>();
    var attempts = 0;
    final provider = MockProvider(() => ++attempts == 1
        ? old.future
        : Future.value(Response(statusCode: 200, body: validData())));
    final controller = TestController(provider);
    final first = controller.login(context, '', '', false);
    await tester.pump(const Duration(seconds: 21));
    await first;
    await controller.login(context, '', '', false);
    expect(provider.calls, 2);
    expect(controller.completed, 1);
    expect(controller.loginErrorMessage.value, isNull);
    old.complete(Response(statusCode: 200, body: validData()));
    await tester.pump();
    expect(controller.completed, 1);
    expect(controller.loginErrorMessage.value, isNull);
    expect(controller.isLoadingLogin.value, isFalse);
  });
  testWidgets('unexpected exception has safe generic feedback', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      child: MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })),
    ));
    final controller = TestController(
        MockProvider(() async => throw StateError('private-canary')));
    final captured = <String>[];
    await runZoned(() => controller.login(context, '', '', false),
        zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
      captured.add(line);
    }));
    await tester.pump();
    expect(captured.join(), isNot(contains('private-canary')));
    expect(find.byType(Dialog), findsOneWidget);
    expect(controller.isLoadingLogin.value, isFalse);
    expect(controller.loginErrorMessage.value, 'ログインを完了できませんでした。再度お試しください。');
  });
  for (final notificationFails in [false, true]) {
    testWidgets(
        'notification pending/failure never blocks authenticated completion: $notificationFails',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      MySharedPref.setStorage(await SharedPreferences.getInstance());
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })));
      final pending = Completer<void>();
      final controller = CompletionController(MockProvider(
          () async => Response(statusCode: 200, body: validData())))
        ..notificationWork = () => notificationFails
            ? Future.error(StateError('private-canary'))
            : pending.future;
      await controller.login(context, '', '', false);
      expect(controller.saved, 1);
      expect(controller.navigated, 1);
      expect(controller.notificationStarts, 1);
      expect(controller.isLoadingLogin.value, isFalse);
      expect(controller.loginErrorMessage.value, isNull);
      if (!notificationFails) pending.complete();
      await tester.pump();
      expect(controller.navigated, 1);
      expect(controller.loginErrorMessage.value, isNull);
    });
  }
  testWidgets('disposed login ignores late authentication success',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final response = Completer<Response<dynamic>>();
    final controller =
        CompletionController(MockProvider(() => response.future));
    final login = controller.login(context, '', '', false);
    controller.onClose();
    response.complete(Response(statusCode: 200, body: validData()));
    await login;
    expect(controller.saved, 0);
    expect(controller.notificationStarts, 0);
    expect(controller.navigated, 0);
  });
  for (final dispose in [false, true]) {
    testWidgets(
        'session switch or disposal during persistence suppresses stale completion: $dispose',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })));
      final savedSession = AuthToken.sessionVersion;
      final persistence = Completer<int>();
      final controller = CompletionController(MockProvider(
          () async => Response(statusCode: 200, body: validData())))
        ..persistenceWork = () => persistence.future;
      final login = controller.login(context, '', '', false);
      await tester.pump();
      expect(controller.saved, 1);
      if (dispose) {
        controller.onClose();
      } else {
        await AuthToken.notifySessionChangedForTesting();
      }
      persistence.complete(savedSession);
      await login;
      expect(controller.notificationStarts, 0);
      expect(controller.navigated, 0);
      expect(controller.isLoadingLogin.value, isFalse);
    });
  }
}
