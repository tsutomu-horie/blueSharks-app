import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_controls.dart';

void main() {
  Widget host(double value, {int version = 0, double delta = 0}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 130,
            height: 50,
            child: TrainingHomeMeter(
              name: '食事',
              value: value,
              feedbackVersion: version,
              delta: delta,
            ),
          ),
        ),
      );

  testWidgets('お世話の実増分を表示し数値とゲージが到達して表示が消える', (tester) async {
    await tester.pumpWidget(host(80));
    await tester.pumpWidget(host(100, version: 1, delta: 20));
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    final gauge = tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox).first);
    expect(gauge.widthFactor, greaterThan(.8));
    expect(gauge.widthFactor, lessThan(1));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('100'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('+20'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('初期表示と同期更新では回復演出を出さない', (tester) async {
    await tester.pumpWidget(host(80, version: 1, delta: 20));
    expect(find.text('+20'), findsNothing);
    await tester.pumpWidget(host(90, version: 1, delta: 20));
    expect(find.text('90'), findsOneWidget);
    expect(find.text('+20'), findsNothing);
  });

  testWidgets('演出中の自然減衰で増分表示が消えず最新値に到達する', (tester) async {
    await tester.pumpWidget(host(50));
    await tester.pumpWidget(host(85, version: 1, delta: 35));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(host(84.9, version: 1, delta: 35));
    expect(find.text('+35'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+35'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('+35'), findsNothing);
  });

  testWidgets('消費量も符号付きで表示し次の演出で置き換える', (tester) async {
    await tester.pumpWidget(host(80));
    await tester.pumpWidget(host(75, version: 1, delta: -5));
    expect(find.text('-5'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(host(110, version: 2, delta: 35));
    expect(find.text('-5'), findsNothing);
    expect(find.text('+35'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('110'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小数の変動量は表示される整数値どうしの差で表示する', (tester) async {
    await tester.pumpWidget(host(80.1));
    await tester.pumpWidget(host(80.7, version: 1, delta: .6));
    expect(find.text('+1'), findsOneWidget);
    expect(find.textContaining('.'), findsNothing);

    await tester.pumpWidget(host(80.4, version: 2, delta: -.3));
    expect(find.textContaining(RegExp(r'[+-]\d+\.\d')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
