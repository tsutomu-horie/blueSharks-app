import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_attempt_feedback.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_pitch_background.dart';
import 'tackle_test_driver.dart';

void main() {
  testWidgets('参考図の実線・4本の5m/15m破線・10m破線・短いマークを省略しない', (tester) async {
    const size = Size(343, 574);
    final recorder = ui.PictureRecorder();
    TacklePitchPainter().paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(
        () => picture.toImage(size.width.toInt(), size.height.toInt()));
    final bytes = await tester
        .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    bool white(double x, double y) {
      final px =
          (size.width * .075 + (366 - y) / 342 * size.width * .85).round();
      final py =
          (size.height * .07 + (x - 24) / 552 * size.height * .86).round();
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final at = ((py + dy) * 343 + px + dx) * 4;
          if (bytes!.getUint8(at) > 200 && bytes.getUint8(at + 2) > 150) {
            return true;
          }
        }
      }
      return false;
    }

    for (final sample in <String, Offset>{
      '外周': const Offset(24, 195),
      'トライ': const Offset(102, 180),
      '22m': const Offset(190, 180),
      '中央線': const Offset(300, 180),
      '5m左': const Offset(141, 48),
      '15m左': const Offset(141, 97),
      '15m右': const Offset(141, 293),
      '5m右': const Offset(141, 342),
      '10m上': const Offset(260, 33),
      '10m下': const Offset(340, 33),
      '短いマーク上': const Offset(123, 160),
      '短いマーク下': const Offset(476, 229),
      'センターマーク': const Offset(294, 195),
      '上ゴール': const Offset(70, 172),
      '下ゴール': const Offset(530, 219),
    }.entries) {
      expect(white(sample.value.dx, sample.value.dy), isTrue,
          reason: sample.key);
    }
    expect(white(220, 180), isFalse, reason: '何もない芝に線を追加しない');
    expect(white(70, 97), isFalse, reason: '縦破線をインゴールへ延ばさない');
    image!.dispose();
    picture.dispose();
  });

  testWidgets('中央拡大は縦画面のまま左右をゴール方向にし、外周を映さない', (tester) async {
    const size = Size(343, 574);
    final recorder = ui.PictureRecorder();
    TacklePitchPainter(zoom: 14, quarterTurns: 1).paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(343, 574));
    final bytes = await tester
        .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    bool white(int x, int y) {
      final at = (y * 343 + x) * 4;
      return bytes!.getUint8(at) > 200 && bytes.getUint8(at + 2) > 150;
    }

    expect(white(171, 80), isTrue);
    expect(white(171, 500), isTrue);
    expect(white(80, 287), isFalse, reason: '中央線は水平ではなく縦に走る');
    expect(white(20, 20), isFalse, reason: 'コート外周は拡大表示の外にある');
    image!.dispose();
    picture.dispose();
  });

  testWidgets('プレー範囲から縦のコートラインを外し、横破線はUIとして描く', (tester) async {
    const size = Size(343, 574);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    TacklePitchPainter(zoom: 14, quarterTurns: 1, longitudinalOffsetMeters: 5)
        .paint(canvas, size);
    final background = recorder.endRecording();
    final image = await tester.runAsync(() => background.toImage(343, 574));
    final bytes = await tester
        .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    var white = 0;
    for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
      if (bytes.getUint8(i) > 200 && bytes.getUint8(i + 2) > 150) white++;
    }
    expect(white, 0, reason: '中央線と10m線の間を表示し、コートの縦線は映さない');
    final leftTone = bytes.getUint8((80 * 343 + 10) * 4);
    final rightTone = bytes.getUint8((80 * 343 + 332) * 4);
    final middleTone = bytes.getUint8((80 * 343 + 171) * 4);
    expect((leftTone - rightTone).abs(), lessThanOrEqualTo(1),
        reason: '左右の明暗を均等にする');
    expect(middleTone, greaterThan(leftTone), reason: '中央を少し明るくする');
    image!.dispose();
    background.dispose();
    final uiRecorder = ui.PictureRecorder();
    final uiCanvas = Canvas(uiRecorder);
    uiCanvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xff83bd42));
    const TackleInputDividerPainter().paint(uiCanvas, size);
    final picture = uiRecorder.endRecording();
    final guide = await tester.runAsync(() => picture.toImage(343, 574));
    final data = await tester
        .runAsync(() => guide!.toByteData(format: ui.ImageByteFormat.rawRgba));
    expect(data!.getUint8((287 * 343 + 20) * 4), greaterThan(200),
        reason: '横の破線が中央に描画される');
    expect(data.getUint8((80 * 343 + 171) * 4), 131, reason: '縦方向の区切りは足さない');
    guide!.dispose();
    picture.dispose();
  });

  Widget feedback(String rank, {bool reduced = false, Key? key}) => MaterialApp(
      home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
              body: Center(
                  child: SizedBox(
                      key: const Key('field'),
                      width: 343,
                      height: 574,
                      child: TackleAttemptFeedback(
                          key: key,
                          rank: rank,
                          succeeded: rank != 'MISS',
                          contactPoint: const Offset(90, 420),
                          impactDelay: Duration(
                              milliseconds: rank == 'MISS' ? 80 : 310)))))));

  testWidgets('全ランクが中央に出て、成功+1表示を出さない', (tester) async {
    for (final rank in ['OK', 'GOOD', 'GREAT', 'PERFECT', 'MISS']) {
      await tester.pumpWidget(feedback(rank, key: ValueKey(rank)));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.getCenter(find.text(rank)),
          tester.getCenter(find.byKey(const Key('field'))));
      expect(find.text('成功 +1'), findsNothing);
      final paint = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is TackleImpactPainter);
      if (rank == 'MISS') {
        expect(paint, isEmpty);
      } else {
        expect((paint.single.painter! as TackleImpactPainter).strength,
            {'OK': 0, 'GOOD': 1, 'GREAT': 2, 'PERFECT': 3}[rank]);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('接触前は波紋を出さず、一度表示して消える', (tester) async {
    await tester.pumpWidget(feedback('GREAT'));
    Finder impacts() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is TackleImpactPainter);
    await tester.pump(const Duration(milliseconds: 300));
    expect(impacts(), findsNothing);
    await tester.pump(const Duration(milliseconds: 30));
    expect(impacts(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(impacts(), findsNothing);
    expect(
        tester
            .widget<Opacity>(find
                .ancestor(
                    of: find.text('GREAT'), matching: find.byType(Opacity))
                .first)
            .opacity,
        0);
  });

  testWidgets('中断後に短い波紋を遅れて再生しない', (tester) async {
    await tester.pumpWidget(feedback('PERFECT'));
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is TackleImpactPainter),
        findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('動きを減らす設定では波紋・拡縮を使わず中央に判定を表示する', (tester) async {
    await tester.pumpWidget(feedback('PERFECT', reduced: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is TackleImpactPainter),
        findsNothing);
    final transform = tester.widget<Transform>(find
        .ancestor(of: find.text('PERFECT'), matching: find.byType(Transform))
        .first);
    expect(transform.transform.entry(0, 0), 1);
  });

  testWidgets('案内文字なしで読み上げ入力と次セット操作を行える', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(MaterialApp(home: tackleTestScreen()));
      expect(find.text('上をタップ ▲'), findsNothing);
      expect(find.text('下をタップ ▼'), findsNothing);
      await tester.tap(find.text('スタート'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1350));
      void activate(String key) {
        final node = tester.getSemantics(find.byKey(ValueKey(key)));
        tester.binding.performSemanticsAction(ui.SemanticsActionEvent(
            type: ui.SemanticsAction.tap,
            nodeId: node.id,
            viewId: tester.view.viewId));
      }

      activate('tackle-tap-up');
      await tester.pump();
      expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 650));
      activate('tackle-tap-down');
      activate('tackle-tap-down');
      await tester.pump();
      expect(find.text('SET 2 / 3'), findsOneWidget);
      expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byKey(const Key('tackle-input-cue')), findsOneWidget);
      expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });
}
