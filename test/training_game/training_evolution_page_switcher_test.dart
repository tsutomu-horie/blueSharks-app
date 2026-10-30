import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_page_switcher.dart';

void main() {
  Widget host(String page, {bool reduceMotion = false, VoidCallback? onTap}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: TrainingEvolutionPageSwitcher(
              pageKey: page,
              child: TextButton(onPressed: onTap, child: Text(page)),
            ),
          ),
        ),
      );
  const light = ValueKey('evolution-transition-light');

  testWidgets('進化への出入りは中央で画面を交換し光で覆う', (tester) async {
    await tester.pumpWidget(host('home'));
    await tester.pumpWidget(host('evolution-3'));
    expect(find.text('home'), findsOneWidget);
    expect(find.text('evolution-3'), findsNothing);
    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.widget<Opacity>(find.byKey(light)).opacity,
        closeTo(.3125, .001));
    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.widget<Opacity>(find.byKey(light)).opacity, 1);
    expect(find.text('evolution-3'), findsOneWidget);
    expect(find.text('home'), findsNothing);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(light), findsNothing);

    await tester.pumpWidget(host('home'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<Opacity>(find.byKey(light)).opacity, 1);
    expect(find.text('home'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(light), findsNothing);
  });

  testWidgets('光の途中は操作を止め、完了後は操作できる', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host('home'));
    await tester.pumpWidget(host('evolution-2', onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('evolution-2'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('evolution-2'));
    expect(taps, 1);
  });

  testWidgets('動きを減らす設定では即時切り替えし途中の設定変更にも従う', (tester) async {
    await tester.pumpWidget(host('home'));
    await tester.pumpWidget(host('evolution-2'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(host('evolution-2', reduceMotion: true));
    expect(find.text('evolution-2'), findsOneWidget);
    expect(find.byKey(light), findsNothing);
    await tester.pumpWidget(host('home', reduceMotion: true));
    expect(find.text('home'), findsOneWidget);
    expect(find.byKey(light), findsNothing);
  });

  testWidgets('後半の外部更新も最後の画面に到達する', (tester) async {
    await tester.pumpWidget(host('home'));
    await tester.pumpWidget(host('evolution-2'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(host('home'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('home'), findsOneWidget);
    expect(find.byKey(light), findsNothing);
  });

  testWidgets('進化以外の遷移は従来の300msフェード', (tester) async {
    await tester.pumpWidget(host('home'));
    await tester.pumpWidget(host('ending-0'));
    expect(find.byKey(light), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('home'), findsOneWidget);
    expect(find.text('ending-0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsNothing);
  });
}
