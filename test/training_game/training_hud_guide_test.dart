import 'package:koto_blue_sharks/presentation/training_game/training_hud_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingHudGuide', () {
    test('uses the confirmed copy for every guide state', () {
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.food),
        '食事の状態を表します。時間の経過や行動で減るため、ごはんで補いましょう。',
      );
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.work),
        '仕事への取り組みを表します。仕事は1日1回行えます。実行後は食事と体調にも気を配りましょう。',
      );
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.work, unlocked: false),
        'もう少し育つと、仕事ができるようになります。',
      );
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.cleanliness),
        '清潔さを表します。時間の経過や行動で低下するため、定期的に掃除をしましょう。',
      );
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.condition),
        '体の調子を表します。疲れがたまったときは、休養をとって回復させましょう。',
      );
      expect(
        TrainingHudGuide.messageFor(TrainingHudGuideItem.miniGame),
        'タップしてミニゲームを選びます。プレイすると仕事の値が上がりますが、食事・清潔・体調を消費するため、お世話も必要です。',
      );
      expect(
        TrainingHudGuide.messageFor(
          TrainingHudGuideItem.miniGame,
          unlocked: false,
        ),
        'もう少し育つと、ミニゲームで遊べるようになります。',
      );
    });

    testWidgets('shows the selected guide in a dismissible dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => TrainingHudGuide.show(
                  context,
                  TrainingHudGuideItem.work,
                  unlocked: false,
                ),
                child: const Text('ガイドを開く'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ガイドを開く'));
      await tester.pumpAndSettle();

      expect(find.text('仕事'), findsOneWidget);
      expect(
        find.text('もう少し育つと、仕事ができるようになります。'),
        findsOneWidget,
      );

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('training-hud-guide-dialog')),
        findsNothing,
      );
    });
  });

  group('TrainingHudGuidePressTarget', () {
    testWidgets('keeps short taps and consumes a completed long press', (
      tester,
    ) async {
      var taps = 0;
      var guides = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrainingHudGuidePressTarget(
                semanticsLabel: '練習/MG',
                holdDuration: const Duration(milliseconds: 700),
                onTap: () => taps++,
                onLongPressGuide: () => guides++,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('練習/MG')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TrainingHudGuidePressTarget));
      await tester.pump();
      expect(taps, 1);
      expect(guides, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('練習/MG')),
      );
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 699));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final ring = tester.getRect(find.byType(CircularProgressIndicator));
      final button = tester.getRect(find.byType(TrainingHudGuidePressTarget));
      expect(ring.center, button.center);
      expect(ring.width, greaterThanOrEqualTo(76));

      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value!,
        greaterThan(0),
      );

      await tester.pump(const Duration(milliseconds: 1));
      expect(guides, 1);
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await gesture.up();
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('cancels the progress cue when the pointer moves away', (
      tester,
    ) async {
      var taps = 0;
      var guides = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrainingHudGuidePressTarget(
                semanticsLabel: '練習/MG',
                holdDuration: const Duration(milliseconds: 700),
                onTap: () => taps++,
                onLongPressGuide: () => guides++,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('練習/MG')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.text('練習/MG'));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await gesture.moveTo(center + const Offset(100, 0));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pump();

      expect(taps, 0);
      expect(guides, 0);
    });

    testWidgets('clears the progress cue on early release or pointer cancel', (
      tester,
    ) async {
      var taps = 0;
      var guides = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrainingHudGuidePressTarget(
                semanticsLabel: '練習/MG',
                holdDuration: const Duration(milliseconds: 700),
                onLongPressGuide: () => guides++,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('練習/MG')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.text('練習/MG'));
      final releasedEarly = await tester.startGesture(center);
      await tester.pump(Duration.zero);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await releasedEarly.up();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 700));
      expect(guides, 0);

      final canceled = await tester.startGesture(center);
      await tester.pump(Duration.zero);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await canceled.cancel();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      expect(taps, 1);
      expect(guides, 0);
    });

    testWidgets('shows a guide on hold even when short tap is unavailable', (
      tester,
    ) async {
      var guides = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrainingHudGuidePressTarget(
                semanticsLabel: '練習/MG',
                holdDuration: const Duration(milliseconds: 100),
                onLongPressGuide: () => guides++,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('練習/MG')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TrainingHudGuidePressTarget));
      await tester.pump();
      expect(guides, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('練習/MG')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(guides, 1);
      await gesture.up();
      await tester.pump();
      expect(guides, 1);
    });
  });
}
