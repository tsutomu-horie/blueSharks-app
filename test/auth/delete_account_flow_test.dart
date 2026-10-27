import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/delete_account_confirmation/controllers/delete_account_confirmation.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/mypage/controllers/mypage.controller.dart';

class _DeleteFlowAuthProvider extends AuthProvider {
  int deleteCallCount = 0;
  int logoutCallCount = 0;
  String? tokenAtDelete;

  @override
  Future<Response> deleteProfile(String token, Function onError) async {
    deleteCallCount++;
    tokenAtDelete = token;
    return const Response<dynamic>(statusCode: 200);
  }

  @override
  Future<Response> logoutAccount(String token) async {
    logoutCallCount++;
    return const Response<dynamic>(body: {'data': []}, statusCode: 200);
  }
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

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'accessToken': fakeToken});
  });

  tearDown(() async {
    Get.reset();
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
      'account deletion returns to the caller, clears the session, and skips logout',
      (tester) async {
    final provider = _DeleteFlowAuthProvider();
    final pageController = MypageController(apiProvider: provider)
      ..isLogin.value = true;
    final mainController = _TestMainController();
    Get.put<MainController>(mainController);
    final deletionController =
        DeleteAccountConfirmationController(apiProvider: provider);
    final routeResult = Completer<bool?>();

    await tester.pumpWidget(GetMaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('start-delete'),
            onPressed: () async {
              final result = await Get.to<bool>(() => Scaffold(
                    body: Builder(
                      builder: (deleteContext) => TextButton(
                        key: const Key('show-delete-sheet'),
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: deleteContext,
                            builder: (_) => const SizedBox(height: 24),
                          );
                        },
                        child: const Text('show sheet'),
                      ),
                    ),
                  ));
              pageController.handleAccountDeletionResult(result);
              routeResult.complete(result);
            },
            child: const Text('delete account'),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('start-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('show-delete-sheet')));
    await tester.pumpAndSettle();

    await deletionController.onDeleteAccount();
    await tester.pumpAndSettle();

    expect(await routeResult.future, isTrue);
    expect(provider.deleteCallCount, 1);
    expect(provider.tokenAtDelete, fakeToken);
    expect(provider.logoutCallCount, 0);
    expect(await AuthToken().getAccessToken(), isNull);
    expect(pageController.isLogin.value, isFalse);
    expect(pageController.profileData.value, isNull);
    expect(mainController.refreshCount, 1);
  });
}
