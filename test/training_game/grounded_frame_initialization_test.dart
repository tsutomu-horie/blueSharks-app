import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_clean_warp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('初回画像読込失敗を保持せず次の準備で再試行する', (tester) async {
    final frame = SametarohAssets.completionFrameFor(TrainingActionType.clean,
        bodyKey: 'sh');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var attempts = 0;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (utf8.decode(message!.buffer.asUint8List()) == frame.asset) attempts++;
      return null;
    });
    try {
      await tester.runAsync(() async {
        await expectLater(
            SametarohCleanWarp.prepare(frame), throwsA(isA<FlutterError>()));
        await expectLater(
            SametarohCleanWarp.prepare(frame), throwsA(isA<FlutterError>()));
      });
      expect(attempts, 2);
    } finally {
      messenger.setMockMessageHandler('flutter/assets', null);
    }
    await tester.runAsync(() => SametarohCleanWarp.prepare(frame));
  });

  testWidgets('準備済み完了人物は最初のbuildから表示し読み上げを保持する', (tester) async {
    final frame = SametarohAssets.completionFrameFor(TrainingActionType.squat,
        bodyKey: 'wtb');
    final prepared =
        await tester.runAsync(() => SametarohCleanWarp.prepare(frame));
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
              child: SametarohFrameImage(
                  frame: frame,
                  width: frame.canvasSize.width,
                  height: frame.canvasSize.height,
                  semanticLabel: '筋トレ完了'))));
      expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => identical(image.image, prepared)),
          isTrue);
      expect(find.bySemanticsLabel('筋トレ完了'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
