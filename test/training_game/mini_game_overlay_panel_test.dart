import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_chrome.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_frame.dart';

void main() {
  for (final (screenWidth, expectedWidth) in [
    (320.0, 296.0),
    (375.0, 351.0),
    (800.0, 440.0),
  ]) {
    testWidgets('ウィンドウ幅は内容によらず画面内の共通幅になる $screenWidth', (tester) async {
      tester.view.physicalSize = Size(screenWidth, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final label in ['0', '99999', '一時停止中']) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MiniGameOverlayPanel(
              dark: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(label),
                ElevatedButton(onPressed: () {}, child: const Text('再開')),
              ]),
            ),
          ),
        ));

        final frame = find.byType(MiniGameSelectionFrame);
        expect(tester.getSize(frame).width, expectedWidth);
        expect(tester.getCenter(frame).dx, screenWidth / 2);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('小さい画面の文字拡大時も下端の操作までスクロールできる', (tester) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var resumed = false;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: MiniGameOverlayPanel(
            dark: true,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('一時停止中'),
              const SizedBox(height: 400),
              ElevatedButton(
                  onPressed: () => resumed = true, child: const Text('再開')),
            ]),
          ),
        ),
      ),
    ));
    await tester.scrollUntilVisible(find.text('再開'), 100);
    await tester.tap(find.text('再開'));
    expect(resumed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
