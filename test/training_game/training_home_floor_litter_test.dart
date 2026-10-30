import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_floor_litter.dart';

void main() {
  group('TrainingHomeFloorLitter.itemCountForCleanliness', () {
    test('清潔値が下がる段階に応じて0〜5個を表示する', () {
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(120), 0);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(80), 0);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(79.99), 1);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(65), 1);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(64.99), 2);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(50), 2);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(49.99), 3);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(35), 3);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(34.99), 4);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(20), 4);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(19.99), 5);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(0), 5);
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(-10), 5);
      expect(
        TrainingHomeFloorLitter.itemCountForCleanliness(double.infinity),
        0,
      );
      expect(TrainingHomeFloorLitter.itemCountForCleanliness(double.nan), 0);
    });
  });

  testWidgets('清潔回復で小物が減り、同じ画面の再描画では位置を保つ', (tester) async {
    _setViewport(tester, const Size(375, 420));
    var cleanliness = 0.0;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 375,
              height: 420,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      TrainingHomeFloorLitter(
                        cleanliness: cleanliness,
                        characterFootClearance: 126,
                        controlsClearance: 64,
                        randomSeed: 20261030,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final itemKeys = List.generate(
      5,
      (index) => ValueKey<String>('training-home-floor-litter-item-$index'),
    );
    final firstLayout =
        itemKeys.map((key) => tester.getRect(find.byKey(key))).toList();
    expect(find.byType(Image), findsNWidgets(5));

    update(() => cleanliness = 10);
    await tester.pump();
    for (var index = 0; index < itemKeys.length; index++) {
      expect(tester.getRect(find.byKey(itemKeys[index])), firstLayout[index]);
    }

    update(() => cleanliness = 64);
    await tester.pump();
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.getRect(find.byKey(itemKeys[0])), firstLayout[0]);
    expect(tester.getRect(find.byKey(itemKeys[1])), firstLayout[1]);
    expect(find.byKey(itemKeys[2]), findsNothing);

    update(() => cleanliness = 100);
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('5つの承認済み候補素材を使い、床・画面内に重ならず収める', (tester) async {
    _setViewport(tester, const Size(360, 420));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 420,
              child: const TrainingHomeFloorLitter(
                cleanliness: 0,
                characterFootClearance: 126,
                controlsClearance: 64,
                randomSeed: 7,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const expectedAssets = <String>{
      'assets/images/training_game/home_floor_litter/dumbbell_candidate.png',
      'assets/images/training_game/home_floor_litter/baby_bottle_candidate.png',
      'assets/images/training_game/home_floor_litter/work_pc_candidate.png',
      'assets/images/training_game/home_floor_litter/broom_candidate.png',
      'assets/images/training_game/home_floor_litter/rugby_ball_floor_candidate.png',
    };
    final actualAssets = <String>{};
    final rects = <Rect>[];
    for (var index = 0; index < 5; index++) {
      final image = tester.widget<Image>(find.byKey(ValueKey<String>(
        'training-home-floor-litter-asset-$index',
      )));
      var provider = image.image;
      while (provider is ResizeImage) {
        provider = provider.imageProvider;
      }
      actualAssets.add((provider as AssetImage).assetName);

      final rect = tester.getRect(find.byKey(ValueKey<String>(
        'training-home-floor-litter-item-$index',
      )));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
      expect(
        rect.top,
        greaterThanOrEqualTo(420 - (700 - 422) * 360 / 485),
      );
      expect(rect.bottom, lessThanOrEqualTo(420 - 64));
      if (rect.top < 420 - 126) {
        // 足元より奥にある小物は、歩行範囲の外側へ置きます。
        expect(
          rect.right <= 360 * .22 || rect.left >= 360 * .78,
          isTrue,
        );
      }
      for (final existing in rects) {
        expect(rect.overlaps(existing), isFalse);
      }
      rects.add(rect);
    }
    expect(actualAssets, expectedAssets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('狭い画面と低い高さでも小物を縮めて操作を遮らない', (tester) async {
    _setViewport(tester, const Size(280, 240));
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped = true,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                  const TrainingHomeFloorLitter(
                    cleanliness: 0,
                    randomSeed: 2,
                    characterFootClearance: 110,
                    controlsClearance: 56,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rects = <Rect>[];
    for (var index = 0; index < 5; index++) {
      final rect = tester.getRect(find.byKey(ValueKey<String>(
        'training-home-floor-litter-item-$index',
      )));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(280));
      expect(
        rect.top,
        greaterThanOrEqualTo(240 - (700 - 422) * 280 / 485),
      );
      expect(rect.bottom, lessThanOrEqualTo(240 - 56));
      if (rect.top < 240 - 110) {
        expect(
          rect.right <= 280 * .22 || rect.left >= 280 * .78,
          isTrue,
        );
      }
      for (final existing in rects) {
        expect(rect.overlaps(existing), isFalse);
      }
      rects.add(rect);
    }

    await tester.tapAt(rects.first.center);
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('部屋のサイズ変更時は同じseedで再配置し、その後の再描画で固定する', (tester) async {
    _setViewport(tester, const Size(400, 500));
    var roomSize = const Size(360, 420);
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SizedBox(
                  key: const ValueKey('floor-litter-test-room'),
                  width: roomSize.width,
                  height: roomSize.height,
                  child: TrainingHomeFloorLitter(
                    cleanliness: 0,
                    characterFootClearance: 126,
                    controlsClearance: 64,
                    randomSeed: 13,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    List<Rect> localItemRects(Size size) {
      final roomOrigin = tester
          .getTopLeft(find.byKey(const ValueKey('floor-litter-test-room')));
      final rects = <Rect>[];
      for (var index = 0; index < 5; index++) {
        final rect = tester
            .getRect(find.byKey(ValueKey<String>(
              'training-home-floor-litter-item-$index',
            )))
            .shift(Offset(-roomOrigin.dx, -roomOrigin.dy));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(
          rect.top,
          greaterThanOrEqualTo(size.height - (700 - 422) * size.width / 485),
        );
        expect(rect.bottom, lessThanOrEqualTo(size.height - 64));
        if (rect.top < size.height - 126) {
          expect(
            rect.right <= size.width * .22 || rect.left >= size.width * .78,
            isTrue,
          );
        }
        for (final existing in rects) {
          expect(rect.overlaps(existing), isFalse);
        }
        rects.add(rect);
      }
      return rects;
    }

    await tester.pumpAndSettle();
    final initial = localItemRects(roomSize);
    roomSize = const Size(280, 240);
    update(() {});
    await tester.pumpAndSettle();
    final resized = localItemRects(roomSize);

    update(() {});
    await tester.pump();
    expect(localItemRects(roomSize), resized);
    expect(resized, isNot(equals(initial)));
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
