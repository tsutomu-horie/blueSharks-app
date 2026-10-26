import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/delete_account_confirmation/controllers/delete_account_confirmation.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/mypage/controllers/mypage.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/mypage/mypage.screen.dart';

class _RecordingAuthProvider extends AuthProvider {
  _RecordingAuthProvider(
    this.response, {
    this.beforeRequest,
    this.responseCompleter,
    this.afterResponseReceived,
  });

  final Response<dynamic> response;
  final Future<void> Function()? beforeRequest;
  final Completer<Response<dynamic>>? responseCompleter;
  final Future<void> Function()? afterResponseReceived;
  int postCount = 0;
  String? requestedUrl;
  dynamic requestedBody;
  Map<String, String>? requestedHeaders;

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    postCount++;
    requestedUrl = url;
    requestedBody = body;
    requestedHeaders = headers;
    await beforeRequest?.call();
    final result =
        responseCompleter == null ? response : await responseCompleter!.future;
    await afterResponseReceived?.call();
    return result as Response<T>;
  }
}

class _ControllerAuthProvider extends AuthProvider {
  _ControllerAuthProvider(this.onLogout);

  final Future<Response<dynamic>> Function() onLogout;
  int callCount = 0;
  String? tokenAtRequest;

  @override
  Future<Response> logoutAccount(String token) async {
    callCount++;
    tokenAtRequest = token;
    return onLogout();
  }
}

class _DeleteFlowAuthProvider extends AuthProvider {
  int deleteCallCount = 0;
  int logoutCallCount = 0;
  String? tokenAtDelete;
  final Future<void> Function(String token)? beforeDeleteRequest;
  final Future<void> Function(String token)? beforeDeleteResponse;
  final Future<void> Function(String token)? afterDeleteResponse;

  _DeleteFlowAuthProvider({
    this.beforeDeleteRequest,
    this.beforeDeleteResponse,
    this.afterDeleteResponse,
  });

  @override
  Future<Response> deleteProfile(String token, Function onError) async {
    deleteCallCount++;
    tokenAtDelete = token;
    await beforeDeleteRequest?.call(token);
    await beforeDeleteResponse?.call(token);
    const response = Response<dynamic>(statusCode: 200);
    await afterDeleteResponse?.call(token);
    return response;
  }

  @override
  Future<Response> logoutAccount(String token) async {
    logoutCallCount++;
    return const Response<dynamic>(body: {'data': []}, statusCode: 200);
  }
}

class _SequenceAuthProvider extends AuthProvider {
  _SequenceAuthProvider(this.outcomes);

  final List<Future<Response<dynamic>> Function()> outcomes;
  int callCount = 0;

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    final response = await outcomes[callCount++]();
    return response as Response<T>;
  }
}

class _TestMypageController extends MypageController {
  _TestMypageController({required super.apiProvider});

  @override
  void onInit() {} // ignore: must_call_super
}

class _TestMainController extends MainController {
  int refreshCount = 0;

  @override
  void onInit() {} // ignore: must_call_super

  @override
  void refreshUnreadMessageCount() {
    refreshCount++;
  }
}

void main() {
  const fakeToken = 'synthetic-test-token';
  const failureMessage = 'ログアウトできませんでした。通信状況を確認して、もう一度お試しください。';

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'accessToken': fakeToken});
  });

  tearDown(() async {
    Get.reset();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthProvider.logoutAccount', () {
    test('posts logout with the current bearer token and returns the response',
        () async {
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
      );

      final response = await provider.logoutAccount(fakeToken);

      expect(provider.requestedUrl, 'logout');
      expect(provider.requestedBody, isNull);
      expect(provider.requestedHeaders?['Authorization'], 'Bearer $fakeToken');
      expect(response.statusCode, 200);
      expect(response.body, {'data': []});
    });

    test('throws when the server response is unsuccessful', () async {
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(
            statusCode: 500, statusText: 'synthetic failure'),
      );

      await expectLater(
        provider.logoutAccount(fakeToken),
        throwsA(isA<Exception>()),
      );
    });

    test('returns 401 as an already-invalid token outcome', () async {
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(statusCode: 401),
      );

      final response = await provider.logoutAccount(fakeToken);

      expect(response.statusCode, 401);
    });
  });

  group('MypageController.logout', () {
    test('clears local state only after the server logout succeeds', () async {
      final provider = _ControllerAuthProvider(() async =>
          const Response<dynamic>(body: {'data': []}, statusCode: 200));
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await controller.logout();

      expect(provider.callCount, 1);
      expect(provider.tokenAtRequest, fakeToken);
      expect(await AuthToken().getAccessToken(), isNull);
      expect(controller.isLogin.value, isFalse);
      expect(controller.isLogoutInProgress.value, isFalse);
      expect(mainController.refreshCount, 1);
    });

    test(
        'keeps the starting token on the request if storage changes before send',
        () async {
      const replacementToken = 'synthetic-replacement-token';
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
        beforeRequest: () => AuthToken().saveAccessToken(replacementToken),
      );
      final profile = UserData(
        accountId: 'synthetic-account',
        createdAt: '2026-01-01',
        email: 'synthetic@example.test',
        id: 1,
        isVerified: true,
      );
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true
        ..profileData.value = profile;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await controller.logout();

      expect(provider.requestedHeaders?['Authorization'], 'Bearer $fakeToken');
      expect(await AuthToken().getAccessToken(), replacementToken);
      expect(controller.isLogin.value, isTrue);
      expect(controller.profileData.value, same(profile));
      expect(mainController.refreshCount, 0);
    });

    test('preserves a replacement session while logout is awaiting response',
        () async {
      const replacementToken = 'synthetic-replacement-token';
      final response = Completer<Response<dynamic>>();
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
        responseCompleter: response,
      );
      final profile = UserData(
        accountId: 'synthetic-account',
        createdAt: '2026-01-01',
        email: 'synthetic@example.test',
        id: 1,
        isVerified: true,
      );
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true
        ..profileData.value = profile;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      final logout = controller.logout();
      await Future<void>.delayed(Duration.zero);
      expect(provider.postCount, 1);
      expect(provider.requestedHeaders?['Authorization'], 'Bearer $fakeToken');

      await AuthToken().saveAccessToken(replacementToken);
      response.complete(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
      );
      await logout;

      expect(await AuthToken().getAccessToken(), replacementToken);
      expect(controller.isLogin.value, isTrue);
      expect(controller.profileData.value, same(profile));
      expect(mainController.refreshCount, 0);
    });

    test('preserves a replacement session after logout response arrives',
        () async {
      const replacementToken = 'synthetic-replacement-token';
      final provider = _RecordingAuthProvider(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
        afterResponseReceived: () =>
            AuthToken().saveAccessToken(replacementToken),
      );
      final profile = UserData(
        accountId: 'synthetic-account',
        createdAt: '2026-01-01',
        email: 'synthetic@example.test',
        id: 1,
        isVerified: true,
      );
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true
        ..profileData.value = profile;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await controller.logout();

      expect(provider.requestedHeaders?['Authorization'], 'Bearer $fakeToken');
      expect(await AuthToken().getAccessToken(), replacementToken);
      expect(controller.isLogin.value, isTrue);
      expect(controller.profileData.value, same(profile));
      expect(mainController.refreshCount, 0);
    });

    test('keeps local state on failure and allows a successful retry',
        () async {
      var attempts = 0;
      final provider = _ControllerAuthProvider(() async {
        attempts++;
        if (attempts == 1) throw StateError('synthetic failure');
        return const Response<dynamic>(body: {'data': []}, statusCode: 200);
      });
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await expectLater(controller.logout(), throwsA(isA<StateError>()));

      expect(provider.callCount, 1);
      expect(await AuthToken().getAccessToken(), fakeToken);
      expect(controller.isLogin.value, isTrue);
      expect(controller.isLogoutInProgress.value, isFalse);

      await controller.logout();

      expect(provider.callCount, 2);
      expect(await AuthToken().getAccessToken(), isNull);
      expect(controller.isLogin.value, isFalse);
      expect(mainController.refreshCount, 1);
    });

    test('clears stale local state when retry after a lost response gets 401',
        () async {
      final provider = _SequenceAuthProvider([
        () async => throw TimeoutException('synthetic lost response'),
        () async => const Response<dynamic>(statusCode: 401),
      ]);
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await expectLater(
        controller.logout(),
        throwsA(isA<TimeoutException>()),
      );
      expect(await AuthToken().getAccessToken(), fakeToken);
      expect(controller.isLogin.value, isTrue);

      await controller.logout();

      expect(provider.callCount, 2);
      expect(await AuthToken().getAccessToken(), isNull);
      expect(controller.isLogin.value, isFalse);
      expect(controller.isLogoutInProgress.value, isFalse);
      expect(mainController.refreshCount, 1);
    });

    for (final statusCode in [403, 500]) {
      test('keeps local state when server returns $statusCode', () async {
        final provider = _RecordingAuthProvider(
          Response<dynamic>(statusCode: statusCode),
        );
        final controller = _TestMypageController(apiProvider: provider)
          ..isLogin.value = true;
        final mainController = _TestMainController();
        Get.put<MainController>(mainController);

        await expectLater(controller.logout(), throwsA(isA<Exception>()));

        expect(await AuthToken().getAccessToken(), fakeToken);
        expect(controller.isLogin.value, isTrue);
        expect(controller.isLogoutInProgress.value, isFalse);
        expect(mainController.refreshCount, 0);
      });
    }

    test('clears local state without a request when no token exists', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final provider = _ControllerAuthProvider(() async =>
          const Response<dynamic>(body: {'data': []}, statusCode: 200));
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      await controller.logout();

      expect(provider.callCount, 0);
      expect(controller.isLogin.value, isFalse);
      expect(controller.isLogoutInProgress.value, isFalse);
      expect(mainController.refreshCount, 1);
    });

    test('ignores a second request while the first logout is pending',
        () async {
      final response = Completer<Response<dynamic>>();
      final provider = _ControllerAuthProvider(() => response.future);
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      final firstLogout = controller.logout();
      await Future<void>.delayed(Duration.zero);
      final secondLogout = controller.logout();

      expect(provider.callCount, 1);
      expect(identical(secondLogout, firstLogout), isTrue);
      expect(controller.isLogoutInProgress.value, isTrue);
      expect(await AuthToken().getAccessToken(), fakeToken);

      response.complete(
        const Response<dynamic>(body: {'data': []}, statusCode: 200),
      );
      await Future.wait([firstLogout, secondLogout]);

      expect(provider.callCount, 1);
      expect(await AuthToken().getAccessToken(), isNull);
      expect(controller.isLogin.value, isFalse);
      expect(controller.isLogoutInProgress.value, isFalse);
      expect(mainController.refreshCount, 1);
    });

    test(
        'account deletion completion clears local state without another logout',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final provider = _ControllerAuthProvider(() async =>
          const Response<dynamic>(body: {'data': []}, statusCode: 200));
      final controller = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);

      controller.onAccountDeleted();

      expect(provider.callCount, 0);
      expect(controller.isLogin.value, isFalse);
      expect(await AuthToken().getAccessToken(), isNull);
      expect(mainController.refreshCount, 1);
    });

    test('account deletion preserves a replacement session', () async {
      const replacementToken = 'synthetic-replacement-token';
      final provider = _DeleteFlowAuthProvider(
        beforeDeleteResponse: (_) =>
            AuthToken().saveAccessToken(replacementToken),
      );
      final profile = UserData(
        accountId: 'synthetic-account',
        createdAt: '2026-01-01',
        email: 'synthetic@example.test',
        id: 1,
        isVerified: true,
      );
      final pageController = _TestMypageController(apiProvider: provider)
        ..isLogin.value = true
        ..profileData.value = profile;
      final mainController = _TestMainController();
      Get.put<MainController>(mainController);
      final deletionController =
          DeleteAccountConfirmationController(apiProvider: provider);

      final deletedCurrentSession =
          await deletionController.deleteCurrentAccount();
      pageController.handleAccountDeletionResult(deletedCurrentSession);

      expect(deletedCurrentSession, isFalse);
      expect(provider.deleteCallCount, 1);
      expect(provider.tokenAtDelete, fakeToken);
      expect(provider.logoutCallCount, 0);
      expect(await AuthToken().getAccessToken(), replacementToken);
      expect(pageController.isLogin.value, isTrue);
      expect(pageController.profileData.value, same(profile));
      expect(mainController.refreshCount, 0);
    });

    for (final phase in [
      'before the delete request',
      'while awaiting the delete response',
      'after the delete response is ready',
    ]) {
      test('account deletion keeps a session replacement $phase', () async {
        const replacementToken = 'synthetic-replacement-token';
        Future<void> replaceSession(String _) =>
            AuthToken().saveAccessToken(replacementToken);
        final provider = _DeleteFlowAuthProvider(
          beforeDeleteRequest:
              phase == 'before the delete request' ? replaceSession : null,
          beforeDeleteResponse: phase == 'while awaiting the delete response'
              ? replaceSession
              : null,
          afterDeleteResponse: phase == 'after the delete response is ready'
              ? replaceSession
              : null,
        );
        final pageController = _TestMypageController(apiProvider: provider)
          ..isLogin.value = true;
        final mainController = _TestMainController();
        Get.put<MainController>(mainController);
        final deletionController =
            DeleteAccountConfirmationController(apiProvider: provider);

        final deletedCurrentSession =
            await deletionController.deleteCurrentAccount();
        pageController.handleAccountDeletionResult(deletedCurrentSession);

        expect(deletedCurrentSession, isFalse);
        expect(provider.deleteCallCount, 1);
        expect(provider.tokenAtDelete, fakeToken);
        expect(provider.logoutCallCount, 0);
        expect(await AuthToken().getAccessToken(), replacementToken);
        expect(pageController.isLogin.value, isTrue);
        expect(mainController.refreshCount, 0);
      });
    }
  });

  testWidgets(
      'keeps the confirmation open with a retry message after failure and disables rapid taps',
      (tester) async {
    final failure = Completer<void>();
    var attempts = 0;

    Future<void> fakeLogout() {
      attempts++;
      if (attempts == 1) return failure.future;
      return Future<void>.value();
    }

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-logout'),
              onPressed: () => const MypageScreen()
                  .showLogoutConfirmation(context, fakeLogout),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('open-logout')));
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('logout-confirm'));
    await tester.tap(confirm);
    await tester.pump();

    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

    await tester.tap(confirm);
    await tester.pump();
    expect(attempts, 1);

    failure.completeError(StateError('synthetic failure'));
    await tester.pump();
    await tester.pump();

    expect(find.text(failureMessage), findsOneWidget);
    expect(confirm, findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(confirm, findsNothing);
    expect(find.text(failureMessage), findsNothing);
  });

  testWidgets('pending confirmation survives barrier close, reopen, and retry',
      (tester) async {
    final pendingLogout = Completer<void>();
    Future<void>? sharedLogout;
    var attempts = 0;

    Future<void> fakeLogout() {
      final activeLogout = sharedLogout;
      if (activeLogout != null) return activeLogout;

      attempts++;
      final operation =
          attempts == 1 ? pendingLogout.future : Future<void>.value();
      late final Future<void> shared;
      shared = operation.whenComplete(() {
        if (identical(sharedLogout, shared)) sharedLogout = null;
      });
      sharedLogout = shared;
      return shared;
    }

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-logout'),
              onPressed: () => const MypageScreen()
                  .showLogoutConfirmation(context, fakeLogout),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    Future<void> openAndStartLogout() async {
      await tester.tap(find.byKey(const Key('open-logout')));
      await tester.pumpAndSettle().timeout(const Duration(seconds: 3));
      final confirmButton = tester
          .widget<ElevatedButton>(find.byKey(const Key('logout-confirm')));
      confirmButton.onPressed!.call();
      await tester.pump();
      await tester.pump();
    }

    await openAndStartLogout();
    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('logout-confirm')), findsNothing);

    await openAndStartLogout();
    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('logout-sheet-content')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logout-confirm')), findsNothing);

    await openAndStartLogout();
    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);

    pendingLogout.completeError(StateError('synthetic failure'));
    await tester.pump();
    await tester.pump();
    expect(find.text(failureMessage), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('logout-confirm')), findsNothing);

    await openAndStartLogout();
    expect(attempts, 2);
    await tester.pumpAndSettle().timeout(const Duration(seconds: 3));
    expect(find.byKey(const Key('logout-confirm')), findsNothing);
  });

  testWidgets(
      'system back closes a pending sheet without losing the shared logout result',
      (tester) async {
    final pendingLogout = Completer<void>();
    Future<void>? sharedLogout;
    var attempts = 0;

    Future<void> fakeLogout() {
      final activeLogout = sharedLogout;
      if (activeLogout != null) return activeLogout;

      attempts++;
      final operation =
          attempts == 1 ? pendingLogout.future : Future<void>.value();
      late final Future<void> shared;
      shared = operation.whenComplete(() {
        if (identical(sharedLogout, shared)) sharedLogout = null;
      });
      sharedLogout = shared;
      return shared;
    }

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-logout'),
              onPressed: () => const MypageScreen()
                  .showLogoutConfirmation(context, fakeLogout),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    Future<void> startLogout() async {
      await tester.tap(find.byKey(const Key('open-logout')));
      await tester.pumpAndSettle();
      tester
          .widget<ElevatedButton>(find.byKey(const Key('logout-confirm')))
          .onPressed!
          .call();
      await tester.pump();
      await tester.pump();
    }

    await startLogout();
    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('logout-confirm')), findsNothing);

    await startLogout();
    expect(attempts, 1);
    expect(find.byKey(const Key('logout-progress')), findsOneWidget);

    pendingLogout.completeError(StateError('synthetic failure'));
    await tester.pump();
    await tester.pump();
    expect(find.text(failureMessage), findsOneWidget);

    final confirm = tester.widget<ElevatedButton>(
      find.byKey(const Key('logout-confirm')),
    );
    confirm.onPressed!.call();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const Key('logout-confirm')), findsNothing);
  });
}
