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
    expect(_floorPropAssets(), findsNWidgets(5));

    update(() => cleanliness = 10);
    await tester.pump();
    for (var index = 0; index < itemKeys.length; index++) {
      expect(tester.getRect(find.byKey(itemKeys[index])), firstLayout[index]);
    }

    update(() => cleanliness = 64);
    await tester.pump();
    expect(_floorPropAssets(), findsNWidgets(2));
    expect(tester.getRect(find.byKey(itemKeys[0])), firstLayout[0]);
    expect(tester.getRect(find.byKey(itemKeys[1])), firstLayout[1]);
    expect(find.byKey(itemKeys[2]), findsNothing);

    update(() => cleanliness = 100);
    await tester.pump();
    expect(_floorPropAssets(), findsNothing);
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
      final prop = tester.widget<DecoratedBox>(find.byKey(ValueKey<String>(
        'training-home-floor-litter-asset-$index',
      )));
      final decoration = prop.decoration as BoxDecoration;
      var provider = decoration.image!.image;
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
  for (final width in [375.0, 320.0]) {
    testWidgets('拡大した5小物が${width}px幅でキャラと操作の安全域を守る', (tester) async {
      _setViewport(tester, Size(width, 500));
      for (var seed = 0; seed < 30; seed++) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SizedBox(
          width: width,
          height: 500,
          child: TrainingHomeFloorLitter(
              cleanliness: 0,
              characterFootClearance: 126 * width / 375,
              controlsClearance: 64 * width / 375,
              randomSeed: seed),
        ))));
        await tester.pumpAndSettle();
        final rects = List.generate(
            5,
            (index) => tester.getRect(find.byKey(
                ValueKey<String>('training-home-floor-litter-item-$index'))));
        expect(rects.map((r) => r.width).reduce((a, b) => a > b ? a : b),
            greaterThan(width * .16));
        expect(rects.any((r) => r.top < 500 - 126 * width / 375 - 20), isTrue);
        for (final rect in rects) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.bottom, lessThanOrEqualTo(500 - 64 * width / 375));
          if (rect.top < 500 - 126 * width / 375) {
            expect(
                rect.right <= width * .22 + .0001 ||
                    rect.left >= width * .78 - .0001,
                isTrue);
          }
          for (final other in rects) {
            if (rect != other) expect(rect.overlaps(other), isFalse);
          }
        }
      }
    });
  }
  testWidgets('箒と哺乳瓶は前案より見やすい個別サイズを確保する', (tester) async {
    _setViewport(tester, const Size(375, 500));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: TrainingHomeFloorLitter(
                cleanliness: 0,
                characterFootClearance: 126,
                controlsClearance: 64,
                randomSeed: 20261030))));
    await tester.pumpAndSettle();
    for (var index = 0; index < 5; index++) {
      final target = find
          .byKey(ValueKey<String>('training-home-floor-litter-asset-$index'));
      final box = tester.widget<DecoratedBox>(target);
      var provider = (box.decoration as BoxDecoration).image!.image;
      while (provider is ResizeImage) {
        provider = provider.imageProvider;
      }
      final name = (provider as AssetImage).assetName;
      if (name.contains('baby_bottle') || name.contains('broom')) {
        // 前案の正方形表示枠は瓶43.2px、箒39.0px程度でした。
        expect(tester.getSize(target).width,
            greaterThan(name.contains('broom') ? 48 : 55));
      }
    }
  });
  testWidgets('足元の帯が6pxでも中央の小物は操作領域へ出ない', (tester) async {
    _setViewport(tester, const Size(375, 500));
    for (var seed = 0; seed < 20; seed++) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: TrainingHomeFloorLitter(
                  cleanliness: 0,
                  characterFootClearance: 70,
                  controlsClearance: 64,
                  randomSeed: seed))));
      await tester.pumpAndSettle();
      for (var index = 0; index < 5; index++) {
        final rect = tester.getRect(find
            .byKey(ValueKey<String>('training-home-floor-litter-item-$index')));
        expect(rect.bottom, lessThanOrEqualTo(436));
      }
    }
  });
  for (final width in [375.0, 320.0]) {
    testWidgets('箒の実表示枠はボールより明確に長い $width', (tester) async {
      _setViewport(tester, Size(width, 500));
      for (var seed = 0; seed < 30; seed++) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: TrainingHomeFloorLitter(
                    cleanliness: 0,
                    characterFootClearance: 126,
                    controlsClearance: 64,
                    randomSeed: seed))));
        await tester.pumpAndSettle();
        Rect? broom;
        Rect? ball;
        for (var i = 0; i < 5; i++) {
          final key = ValueKey<String>('training-home-floor-litter-asset-$i');
          final box = tester.widget<DecoratedBox>(find.byKey(key));
          var provider = (box.decoration as BoxDecoration).image!.image;
          while (provider is ResizeImage) {
            provider = provider.imageProvider;
          }
          final name = (provider as AssetImage).assetName;
          final rect = tester.getRect(find
              .byKey(ValueKey<String>('training-home-floor-litter-item-$i')));
          if (name.contains('broom')) broom = rect;
          if (name.contains('rugby_ball')) ball = rect;
        }
        expect(broom!.width, greaterThan(width * .24));
        expect(broom.width / (ball!.width * .71), inInclusiveRange(1.90, 2.10));
        expect(broom.top, greaterThanOrEqualTo(500 - 126));
      }
    });
  }
  testWidgets('散乱できない高さでは箒と他4点の帯を分ける', (tester) async {
    _setViewport(tester, const Size(320, 500));
    for (var seed = 0; seed < 30; seed++) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: TrainingHomeFloorLitter(
                  cleanliness: 0,
                  characterFootClearance: 240,
                  controlsClearance: 150,
                  randomSeed: seed))));
      await tester.pumpAndSettle();
      final rects = List.generate(
          5,
          (i) => tester.getRect(find
              .byKey(ValueKey<String>('training-home-floor-litter-item-$i'))));
      for (var i = 0; i < 5; i++) {
        expect(rects[i].bottom, lessThanOrEqualTo(350));
        for (var j = i + 1; j < 5; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse);
        }
      }
    }
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _floorPropAssets() => find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) return false;
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('training-home-floor-litter-asset-');
    });
