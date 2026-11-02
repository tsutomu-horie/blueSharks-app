import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_theme.dart';

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
      // Navigation futures complete when the destination is removed, so do not
      // wait for that future while processing an API response.
      unawaited(Get.offAll<void>(() => const SessionReplacedScreen()));
    } finally {
      _noticePendingOrVisible = false;
    }
  }
}

class SessionReplacedScreen extends StatelessWidget {
  const SessionReplacedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TrainingGameTheme(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '別端末でのログインを検知しました。\nデータ保全のため自動ログアウトしました。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.LOGIN),
                    child: const Text('ログイン画面へ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
