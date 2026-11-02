import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_session_manager.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

void main() {
  testWidgets('replaced session shows notice and opens login on demand',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({'accessToken': 'old-token'});
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: Text('game')),
      getPages: [GetPage(name: Routes.LOGIN, page: () => const Scaffold(body: Text('login')))],
    ));
    final handled = AuthSessionManager.handleResponse(
      const Response(statusCode: 401, body: {'code': 'SESSION_REPLACED'}),
      requestToken: 'old-token',
    );
    await tester.pumpAndSettle();
    expect(await handled, isTrue);
    expect(await AuthToken().getAccessToken(), isNull);
    expect(find.textContaining('別端末でのログインを検知しました'), findsOneWidget);
    expect(find.text('login'), findsNothing);
    await tester.tap(find.text('ログイン画面へ'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
