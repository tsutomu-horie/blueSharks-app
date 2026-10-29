import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_theme.dart';

void main() {
  testWidgets('育成ゲームは既存ホームの日本語フォントを使い文字倍率を保つ', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          textScaler: TextScaler.linear(1.5),
        ),
        child: const MaterialApp(
          home: TrainingGameTheme(
            child: Scaffold(
              body: Text('育成ゲームの説明', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ),
    );

    final textContext = tester.element(find.text('育成ゲームの説明'));
    expect(
        Theme.of(textContext).textTheme.bodyMedium!.fontFamily, 'LINESeedJP');
    expect(DefaultTextStyle.of(textContext).style.fontFamily, 'LINESeedJP');
    expect(MediaQuery.textScalerOf(textContext).scale(14), 21);
    expect(tester.takeException(), isNull);
  });
}
