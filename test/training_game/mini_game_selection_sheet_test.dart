import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_sheet.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';

class _NavigationLog extends NavigatorObserver {
  final List<Route<dynamic>> popped = [];
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
  }
}

void main() {
  Future<void> host(WidgetTester tester,
      {double scale = 1,
      _NavigationLog? navigation,
      ValueChanged<TrainingActionType?>? onResult}) async {
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [if (navigation != null) navigation],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              final result = await showMiniGameSelectionSheet(context);
              onResult?.call(result);
            },
            child: const Text('練習 / MG'),
          );
        }),
      ),
    ));
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('練習 / MG'));
    await tester.pumpAndSettle();
  }

  testWidgets('A案の2素材・短い操作説明を表示し、下部注釈と旧数値を表示しない', (tester) async {
    await host(tester);
    await open(tester);
    expect(find.text('タックル'), findsOneWidget);
    expect(find.text('パス＆ラン'), findsOneWidget);
    expect(find.text('フェイントを見抜いて\n相手の動く方向をタップ'), findsOneWidget);
    expect(find.text('仲間をねらってフリック\nパスをつないで走ろう'), findsOneWidget);
    expect(find.textContaining('秒'), findsNothing);
    expect(find.textContaining('全3セット'), findsNothing);
    expect(find.textContaining('少しお休み'), findsNothing);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.length, 2);
    expect((images[0].image as AssetImage).assetName,
        'assets/images/training_game/minigames/tackle_attack_normal.png');
    expect((images[1].image as AssetImage).assetName,
        'assets/images/training_game/selection/pass_run_ball.png');
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 812),
    const Size(320, 568),
    const Size(568, 320),
    const Size(834, 1194),
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('狭い画面・横画面・文字拡大で末尾カードまで選択できる $size ×$scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        TrainingActionType? result;
        await host(tester, scale: scale, onResult: (value) => result = value);
        await open(tester);
        expect(tester.takeException(), isNull);
        final pass =
            find.byKey(const ValueKey('mini-game-selection-passAndRun'));
        await tester.ensureVisible(pass);
        await tester.pumpAndSettle();
        await tester.tap(pass);
        await tester.pumpAndSettle();
        expect(result, TrainingActionType.passAndRun);
        expect(find.text('練習 / MG'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final type in [
    TrainingActionType.tackle,
    TrainingActionType.passAndRun
  ]) {
    testWidgets('カード連打でも選択結果は1回だけ返りHOMEを閉じない ${type.name}', (tester) async {
      final navigation = _NavigationLog();
      final results = <TrainingActionType?>[];
      await host(tester, navigation: navigation, onResult: results.add);
      await open(tester);
      final card = find.byKey(ValueKey('mini-game-selection-${type.name}'));
      final onTap = tester.widget<InkWell>(card).onTap!;
      onTap();
      onTap();
      await tester.pumpAndSettle();
      expect(results, [type]);
      expect(navigation.popped.length, 1);
      expect(find.text('練習 / MG'), findsOneWidget);
      await open(tester);
      expect(find.byType(MiniGameSelectionSheet), findsOneWidget);
    });
  }

  for (final method in ['back', 'barrier', 'drag']) {
    testWidgets('戻る・外側タップ・下スワイプは選択せず閉じ、再表示できる $method', (tester) async {
      final results = <TrainingActionType?>[];
      await host(tester, onResult: results.add);
      await open(tester);
      switch (method) {
        case 'back':
          await tester.binding.handlePopRoute();
        case 'barrier':
          await tester.tapAt(const Offset(400, 20));
        case 'drag':
          await tester.drag(
              find.byType(MiniGameSelectionSheet), const Offset(0, 500));
      }
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(find.byType(MiniGameSelectionSheet), findsNothing);
      await open(tester);
      expect(find.byType(MiniGameSelectionSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('入口を同じフレームで連打してもシートを重ねない', (tester) async {
    final navigation = _NavigationLog();
    await host(tester, navigation: navigation);
    final onPressed =
        tester.widget<TextButton>(find.byType(TextButton)).onPressed!;
    onPressed();
    onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(MiniGameSelectionSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('練習 / MG'), findsOneWidget);
    expect(navigation.popped.length, 1);
  });
}
