import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/fcm_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class LoginController extends GetxController {
  LoginController({AuthProvider? apiProvider})
      : apiProvider = apiProvider ?? AuthProvider();

  final AuthProvider apiProvider;
  final loginErrorMessage = RxnString();
  bool _disposed = false;

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  final emailTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();

  final isLoadingLogin = false.obs;

  var isPasswordHidden = true.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.LOGIN);
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login(BuildContext context, String selectedPlayer,
      String selectedPlayerName, bool isFromHome) async {
    if (_disposed || isLoadingLogin.value) return;
    isLoadingLogin.value = true;
    loginErrorMessage.value = null;
    try {
      final response = await apiProvider.login(
        emailTextFieldController.text,
        passwordTextFieldController.text,
        () {}, // Present one error below, after the request has settled.
      );
      if (response.access_token.trim().isEmpty) {
        throw const LoginFailure(LoginFailureKind.invalidResponse);
      }
      if (_disposed || !context.mounted) return;
      await completeLogin(
          response, selectedPlayer, selectedPlayerName, isFromHome);
    } on LoginFailure catch (error) {
      loginErrorMessage.value = switch (error.kind) {
        LoginFailureKind.rejected => 'ログインできませんでした。入力内容を確認し、時間をおいて再度お試しください。',
        LoginFailureKind.network => '通信できませんでした。接続を確認して再度お試しください。',
        LoginFailureKind.server => '現在ログインできません。時間をおいて再度お試しください。',
        LoginFailureKind.invalidResponse => 'ログイン情報を確認できませんでした。再度お試しください。',
      };
    } catch (_) {
      loginErrorMessage.value = 'ログインを完了できませんでした。再度お試しください。';
    } finally {
      isLoadingLogin.value = false;
    }
  }

  @protected
  Future<void> completeLogin(Auth response, String selectedPlayer,
      String selectedPlayerName, bool isFromHome) async {
    final session = await persistLogin(response);
    if (_disposed || session != AuthToken.sessionVersion) return;
    MySharedPref.setWallpaper(selectedPlayer);
    MySharedPref.setWallpaperName(selectedPlayerName);
    MySharedPref.setFirstOpen('alreadyOpen');
    // Notification availability never decides whether authentication succeeded.
    unawaited(Future<void>.sync(syncNotifications).catchError((Object _) {
      debugPrint('[fcm-sync] deferred');
    }));
    navigateAfterLogin(isFromHome);
  }

  @protected
  Future<int> persistLogin(Auth response) async {
    return AuthToken().saveAccessTokenForSession(response.access_token);
  }

  @protected
  Future<void> syncNotifications() => FcmHelper.syncForCurrentSession();

  @protected
  void navigateAfterLogin(bool isFromHome) {
    if (!isFromHome) {
      Get.offAll(() => const MainScreen());
    } else {
      Get.back(result: true);
    }
  }
}
