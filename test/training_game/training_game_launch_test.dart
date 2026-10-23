import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_flow.screen.dart';

class _Provider extends TrainingGameProvider {
  int calls = 0;
  Map<String, dynamic>? current;
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    calls++;
    await gate?.future;
    return current;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'accessToken': 'test'});
  });
  tearDown(() => Get.reset());

  Future<void> host(WidgetTester tester, _Provider provider,
      {bool autoStart = true, Future<void>? pendingSync}) async {
    TrainingGameProvider.registerPendingSync(
        pendingSync ?? Future<void>.value());
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        home: Scaffold(
            body: TextButton(
          onPressed: () => Get.toNamed(Routes.TRAINING_GAME_LAUNCH),
          child: const Text('アプリホーム'),
        )),
        getPages: [
          GetPage(
              name: Routes.TRAINING_GAME_LAUNCH,
              page: () => TrainingGameLaunchScreen(
                  autoStart: autoStart, provider: provider)),
          GetPage(
              name: Routes.TRAINING_GAME_NEW,
              page: () => const Scaffold(body: Text('新規孵化'))),
          GetPage(
              name: Routes.TRAINING_GAME,
              page: () =>
                  Scaffold(body: Text('再開:${(Get.arguments as Map)['id']}'))),
        ],
      ),
    ));
    await tester.tap(find.text('アプリホーム'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final existing in [false, true]) {
    testWidgets('${existing ? '既存ゲーム' : '初回'}へ直接進み、戻るとアプリホーム', (tester) async {
      final provider = _Provider()..current = existing ? {'id': 42} : null;
      await host(tester, provider);
      await tester.pump(const Duration(seconds: 4));
      expect(provider.calls, 1);
      await tester.pumpAndSettle();
      expect(find.text(existing ? '再開:42' : '新規孵化'), findsOneWidget);
      expect(find.text('アプリ ｜ ゲーム'), findsNothing);
      expect(provider.calls, 1);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.text('アプリホーム'), findsOneWidget);
    });
  }

  testWidgets('起動待機中の戻ると連打で重複起動しない', (tester) async {
    final gate = Completer<void>();
    final provider = _Provider()..gate = gate;
    await host(tester, provider);
    await tester.tapAt(const Offset(180, 400));
    await tester.tapAt(const Offset(180, 400));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 4));
    expect(provider.calls, 1);
    expect(find.text('新規孵化'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('新規孵化'), findsOneWidget);
    expect(provider.calls, 1);
  });

  testWidgets('未完了の保存同期を待って一度だけ起動し、遷移中も中間画面を表示しない', (tester) async {
    final sync = Completer<void>();
    final provider = _Provider();
    await host(tester, provider, pendingSync: sync.future);
    await tester.pump(const Duration(seconds: 4));
    expect(provider.calls, 0);
    sync.complete();
    await tester.pump();
    expect(provider.calls, 1);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('アプリ ｜ ゲーム', skipOffstage: false), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('新規孵化'), findsOneWidget);
  });

  testWidgets('セッション変更後に遷移しない', (tester) async {
    final gate = Completer<void>();
    final provider = _Provider()..gate = gate;
    await host(tester, provider);
    await AuthToken.notifySessionChangedForTesting();
    gate.complete();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('新規孵化'), findsNothing);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('アプリホーム'), findsOneWidget);
  });

  testWidgets('未認証時はAPIを呼ばず認証案内を維持', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final provider = _Provider();
    await host(tester, provider);
    await tester.pumpAndSettle();
    expect(provider.calls, 0);
    expect(find.text('ゲームを起動するには会員認証が必要です。'), findsOneWidget);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('アプリホーム'), findsOneWidget);
  });

  testWidgets('通常入口は明示起動と中間画面への戻るを維持', (tester) async {
    final provider = _Provider();
    await host(tester, provider, autoStart: false);
    await tester.pumpAndSettle();
    expect(provider.calls, 0);
    await tester.tap(find.text('ゲームを起動'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('新規孵化'), findsOneWidget);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('アプリ ｜ ゲーム'), findsOneWidget);
  });
}
