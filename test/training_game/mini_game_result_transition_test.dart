import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_result_transition.dart';

void main() {
  testWidgets(
      'result fades and moves in over 200ms without replaying on rebuild',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ResultHost()));

    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();
    expect(find.text('総合結果 0'), findsOneWidget);
    expect(_currentFade(tester).opacity.value, 0);
    expect(_currentSlide(tester).position.value.dy, closeTo(.02, .0001));

    await tester.pump(const Duration(milliseconds: 100));
    expect(_currentFade(tester).opacity.value, greaterThan(0));
    expect(_currentFade(tester).opacity.value, lessThan(1));
    expect(_currentSlide(tester).position.value.dy, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 100));
    expect(_currentFade(tester).opacity.value, 1);
    expect(_currentSlide(tester).position.value.dy, 0);

    await tester.tap(find.byKey(const Key('rebuild-result')));
    await tester.pump();
    expect(find.text('総合結果 1'), findsOneWidget);
    expect(_currentFade(tester).opacity.value, 1);
  });

  testWidgets('result action is available before the entrance finishes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ResultHost()));

    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-result')));

    expect(tester.state<_ResultHostState>(find.byType(_ResultHost)).confirmed,
        isTrue);
    expect(_currentFade(tester).opacity.value, lessThan(1));
  });

  testWidgets('reduced motion shows the result immediately without movement',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: _ResultHost(disableAnimations: true),
    ));

    await tester.tap(find.byKey(const Key('show-result')));
    await tester.pump();

    expect(find.text('総合結果 0'), findsOneWidget);
    expect(_resultTransitions<FadeTransition>(tester), findsNothing);
    expect(_resultTransitions<SlideTransition>(tester), findsNothing);
  });
}

FadeTransition _currentFade(WidgetTester tester) => tester
    .widgetList<FadeTransition>(_resultTransitions<FadeTransition>(tester))
    .last;

SlideTransition _currentSlide(WidgetTester tester) => tester
    .widgetList<SlideTransition>(_resultTransitions<SlideTransition>(tester))
    .last;

Finder _resultTransitions<T extends Widget>(WidgetTester tester) =>
    find.descendant(
      of: find.byKey(const Key('mini-game-result-transition-switcher')),
      matching: find.byType(T),
    );

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
