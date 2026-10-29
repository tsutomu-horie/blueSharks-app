import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class AuthSessionManager {
  AuthSessionManager._();

  static const replacedCode = 'SESSION_REPLACED';
  static const replacedMessageType = 'session_replaced';
  static bool _handlingReplacement = false;
  static bool _noticePendingOrVisible = false;

  static bool isSessionReplacedResponse(Response<dynamic> response) {
    final body = response.body;
    return response.statusCode == 401 &&
        body is Map &&
        body['code'] == replacedCode;
  }

  static Future<bool> handleResponse(
    Response<dynamic> response, {
    required String requestToken,
  }) async {
    if (!isSessionReplacedResponse(response)) return false;
    if (_handlingReplacement) return true;

    final snapshot = await AuthToken().readSessionSnapshot();
    if (snapshot.token != requestToken) return true;

    _handlingReplacement = true;
    try {
      final cleared = await AuthToken().deleteTokenIfMatches(
        requestToken,
        snapshot.sessionVersion,
      );
      if (!cleared) return false;

      await _showLoginNotice();
      return true;
    } finally {
      _handlingReplacement = false;
    }
  }

  static Future<void> _showLoginNotice() async {
    if (_noticePendingOrVisible) return;
    if (Get.key.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showLoginNotice());
      });
      return;
    }

    _noticePendingOrVisible = true;
    try {
      if (Get.currentRoute != Routes.LOGIN) {
        await Get.offAllNamed(Routes.LOGIN);
      }
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('別の端末でログインされました'),
          content: const Text(
            'データ保全のため、この端末からログアウトしました。再度利用するにはログインしてください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<void>(),
              child: const Text('ログイン画面へ'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      _noticePendingOrVisible = false;
    }
  }
}
