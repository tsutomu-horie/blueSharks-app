import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_result_transition.dart';

void main() {
  testWidgets(
      'prelude precedes the result, then reveals it without replay on rebuild',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ResultHost()));
    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();
    expect(find.text('結果発表'), findsOneWidget);
    expect(find.text('総合結果 0'), findsNothing);
    expect(find.byKey(const Key('confirm-result')), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('結果発表'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('結果発表'), findsNothing);
    expect(find.text('総合結果 0'), findsOneWidget);
    final opacity = tester
        .widget<Opacity>(
            find.byKey(const Key('mini-game-result-reveal-content')))
        .opacity;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));
    await tester.tap(find.byKey(const Key('confirm-result')),
        warnIfMissed: false);
    expect(tester.state<_ResultHostState>(find.byType(_ResultHost)).confirmed,
        isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester
            .widget<Opacity>(
                find.byKey(const Key('mini-game-result-reveal-content')))
            .opacity,
        1);
    await tester.tap(find.byKey(const Key('rebuild-result')));
    await tester.pump();
    expect(find.text('総合結果 1'), findsOneWidget);
    expect(find.text('結果発表'), findsNothing);
    await tester.tap(find.byKey(const Key('confirm-result')));
    expect(tester.state<_ResultHostState>(find.byType(_ResultHost)).confirmed,
        isTrue);
  });

  testWidgets('disposing during the prelude cancels its animation cleanly',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ResultHost()));
    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the result immediately without a prelude',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: _ResultHost(disableAnimations: true)));
    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();
    expect(find.text('総合結果 0'), findsOneWidget);
    expect(find.text('結果発表'), findsNothing);
    await tester.tap(find.byKey(const Key('confirm-result')));
    expect(tester.state<_ResultHostState>(find.byType(_ResultHost)).confirmed,
        isTrue);
  });
}

class _ResultHost extends StatefulWidget {
  const _ResultHost({this.disableAnimations = false});

  final bool disableAnimations;

  @override
  State<_ResultHost> createState() => _ResultHostState();
}

class _ResultHostState extends State<_ResultHost> {
  bool _visible = false;
  bool confirmed = false;
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: widget.disableAnimations,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: TextButton(
                key: const Key('show-result'),
                onPressed: () => setState(() => _visible = true),
                child: const Text('結果を表示'),
              ),
            ),
            MiniGameResultTransition(
              visible: _visible,
              child: ColoredBox(
                color: Colors.blue,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('総合結果 $_revision'),
                      TextButton(
                        key: const Key('confirm-result'),
                        onPressed: () => setState(() => confirmed = true),
                        child: const Text('確定'),
                      ),
                      TextButton(
                        key: const Key('rebuild-result'),
                        onPressed: () => setState(() => _revision++),
                        child: const Text('再描画'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
