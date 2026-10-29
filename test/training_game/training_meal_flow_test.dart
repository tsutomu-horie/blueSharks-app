import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

String _shownAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image).first).image as AssetImage)
        .assetName;

void main() {
  for (final body in <String?>[
    null,
    'pr',
    'sh',
    'wtb',
    'unknown',
    SametarohAssets.childBodyKey
  ]) {
    testWidgets('食事はstartなしで1↔2、完了後タップまでdoneを表示: $body', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await Navigator.of(context)
                            .push<bool>(MaterialPageRoute(
                          builder: (_) => TrainingGameCareActionScreen(
                            actionType: TrainingActionType.meal,
                            bodyKey: body,
                          ),
                        ));
                      },
                      child: const Text('open meal'),
                    ),
                  )),
        ),
      ));
      final frames =
          SametarohAssets.careFramesFor(TrainingActionType.meal, bodyKey: body);
      final done = SametarohAssets.completionFrameFor(TrainingActionType.meal,
          bodyKey: body);
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final frame in [...frames, done]) {
          await precacheImage(AssetImage(frame.asset), context);
        }
      });
      await tester.tap(find.text('open meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('食事内容を選ぶ'), findsNothing);
      expect(find.text('がっつり／高タンパク'), findsNothing);
      expect(find.text('軽め／バランス'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(_shownAsset(tester), frames[0].asset);
      expect(
          tester
              .widget<SametarohAnimatedImage>(
                  find.byType(SametarohAnimatedImage))
              .initialFrame,
          isNull);
      await tester.pump(const Duration(milliseconds: 650));
      expect(_shownAsset(tester), frames[1].asset);
      tester
          .element(find.byType(TrainingGameCareActionScreen))
          .markNeedsBuild();
      await tester.pump();
      expect(_shownAsset(tester), frames[1].asset);
      await tester.pump(const Duration(milliseconds: 650));
      expect(_shownAsset(tester), frames[0].asset);
      await tester.tapAt(const Offset(2, 200));
      await tester.pump();
      expect(_shownAsset(tester), done.asset);
      await tester.pump(const Duration(milliseconds: 499));
      expect(result, isNull);
      expect(_shownAsset(tester), done.asset);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('タップして戻る'), findsOneWidget);
      await tester.tap(find.text('タップして戻る'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      result = null;
      await tester.tap(find.text('open meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_shownAsset(tester), frames[0].asset);
      await tester.tap(find.byTooltip('お世話を中止'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }
}
