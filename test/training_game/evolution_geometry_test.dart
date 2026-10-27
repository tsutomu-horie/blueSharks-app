import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

typedef _TargetBuilder = Widget Function(Key key);

class _EvolutionCase {
  const _EvolutionCase(this.name, this.before, this.after, this.target);

  final String name;
  final SametarohFrame before;
  final SametarohFrame after;
  final _TargetBuilder target;
}

_TargetBuilder _homeTarget(String bodyKey) => (key) =>
    TrainingHomeCharacterFrameImage(
      frame: TrainingHomeCharacterFrameSet.forBodyKey(bodyKey).idleFrames.first,
      width: 128,
      height: 184,
      semanticLabel: '鮫太郎',
      key: key,
    );

final _cases = <_EvolutionCase>[
  for (final bodyKey in SametarohAssets.supportedBodyKeys) ...[
    _EvolutionCase(
      '育成期/$bodyKey: newborn → body idle初フレーム',
      SametarohAssets.newbornFrame,
      SametarohAssets.idleFramesForBodyKey(bodyKey).first,
      _homeTarget(bodyKey),
    ),
    _EvolutionCase(
      '成長期/$bodyKey: normal → body idle初フレーム',
      SametarohAssets.normalFrames.first,
      SametarohAssets.idleFramesForBodyKey(bodyKey).first,
      _homeTarget(bodyKey),
    ),
  ],
  _EvolutionCase(
    '一軍: PR idle → ウイング通常表示',
    SametarohAssets.idleFramesForBodyKey('pr').first,
    SametarohAssets.positionFrameFor('ウイング')!,
    (key) => SametarohFrameImage(
      frame: SametarohAssets.positionFrameFor('ウイング')!,
      width: 250,
      height: 250,
      alignment: Alignment.bottomCenter,
      semanticLabel: 'ウイング',
      key: key,
    ),
  ),
  _EvolutionCase(
    '一軍fallback: PR idle → home idle初フレーム',
    SametarohAssets.idleFramesForBodyKey('pr').first,
    SametarohAssets.idleFramesForBodyKey('pr').first,
    _homeTarget('pr'),
  ),
];

const _rootKey = ValueKey<String>('root');
const _targetKey = ValueKey<String>('target');
const _afterScaleKey = ValueKey<String>('training-evolution-after-scale');

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _rootKey,
            child: SizedBox(width: 300, height: 390, child: child),
          ),
        ),
      ),
    );

void main() {
  testWidgets('進化先更新と復帰は最新画像を使い足位置と進行を保持する', (tester) async {
    Widget reveal(String body) => _host(TrainingEvolutionReveal(
          key: const ValueKey('same-evolution'),
          beforeFrame: SametarohAssets.normalFrames.first,
          afterFrame: SametarohAssets.idleFramesForBodyKey(body).first,
          afterVisual: _homeTarget(body)(_targetKey),
          afterSize: const Size(128, 184),
        ));
    await tester.pumpWidget(reveal('pr'));
    await tester.pump(const Duration(milliseconds: 900));
    final foot = tester.getRect(find.byKey(_targetKey)).bottom;
    final scale = tester
        .widget<Transform>(find.byKey(_afterScaleKey))
        .transform
        .entry(0, 0);
    for (final body in ['sh', 'wtb', 'pr']) {
      await tester.pumpWidget(reveal(body));
      final image = tester
          .widget<TrainingHomeCharacterFrameImage>(find.byKey(_targetKey));
      expect(
          image.frame.asset,
          TrainingHomeCharacterFrameSet.forBodyKey(body)
              .idleFrames
              .first
              .asset);
      expect(tester.getRect(find.byKey(_targetKey)).bottom, closeTo(foot, 1));
      expect(
          tester
              .widget<Transform>(find.byKey(_afterScaleKey))
              .transform
              .entry(0, 0),
          closeTo(scale, 0.001));
      expect(find.byType(TrainingEvolutionReveal), findsOneWidget);
    }
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(_afterScaleKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OS中断再開は進行と足位置を保持し完了後に再生しない', (tester) async {
    await tester.pumpWidget(_host(TrainingEvolutionReveal(
      beforeFrame: SametarohAssets.normalFrames.first,
      afterFrame: SametarohAssets.idleFramesForBodyKey('pr').first,
      afterVisual: _homeTarget('pr')(_targetKey),
      afterSize: const Size(128, 184),
    )));
    await tester.pump(const Duration(milliseconds: 900));
    final before = tester.getRect(find.byKey(_targetKey));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.getRect(find.byKey(_targetKey)), before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.getRect(find.byKey(_targetKey)).bottom,
        closeTo(before.bottom, 1));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(_afterScaleKey), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(_afterScaleKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('破棄後の再入は新しい進化先だけを一度表示する', (tester) async {
    for (final body in ['pr', 'sh', 'wtb']) {
      await tester.pumpWidget(_host(TrainingEvolutionReveal(
        beforeFrame: SametarohAssets.normalFrames.first,
        afterFrame: SametarohAssets.idleFramesForBodyKey(body).first,
        afterVisual: _homeTarget(body)(_targetKey),
        afterSize: const Size(128, 184),
      )));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TrainingEvolutionReveal), findsOneWidget);
      expect(
          tester
              .widget<TrainingHomeCharacterFrameImage>(find.byKey(_targetKey))
              .frame
              .asset,
          TrainingHomeCharacterFrameSet.forBodyKey(body)
              .idleFrames
              .first
              .asset);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    }
  });

  test('旧easeOutBackの終盤はscale 1を越えてから戻る', () {
    final overshoot = 0.62 + 0.38 * Curves.easeOutBack.transform(0.7);
    expect(overshoot, greaterThan(1));

    var previous = 0.62;
    for (var sample = 1; sample <= 10; sample++) {
      final progress = sample / 10;
      final scale = 0.62 + 0.38 * Curves.easeOutCubic.transform(progress);
      expect(scale, greaterThanOrEqualTo(previous));
      expect(scale, lessThanOrEqualTo(1));
      previous = scale;
    }
  });

  testWidgets('旧完了分岐のtight制約は演出中246x351から300x390へ跳ねる', (tester) async {
    const targetKey = ValueKey<String>('legacy-target');
    const frameWidth = 300 * 0.82;
    const frameHeight = 390 * 0.9;
    final frame = SametarohAssets.normalFrames.first;

    await tester.pumpWidget(
      _host(
        Stack(
          alignment: Alignment.center,
          children: [
            SametarohFrameImage(
              frame: frame,
              width: frameWidth,
              height: frameHeight,
              alignment: Alignment.bottomCenter,
              key: targetKey,
            ),
          ],
        ),
      ),
    );
    final animatedRect = tester.getRect(find.byKey(targetKey));
    expect(animatedRect.width, closeTo(246, 0.01));
    expect(animatedRect.height, closeTo(351, 0.01));

    // 旧コードはisCompleted分岐で同じSizedBox画像をStackの外へ直返し。
    await tester.pumpWidget(
      _host(
        SametarohFrameImage(
          frame: frame,
          width: frameWidth,
          height: frameHeight,
          alignment: Alignment.bottomCenter,
          key: targetKey,
        ),
      ),
    );
    final completedRect = tester.getRect(find.byKey(targetKey));
    expect(completedRect.width, closeTo(300, 0.01));
    expect(completedRect.height, closeTo(390, 0.01));
    expect(completedRect.bottom, greaterThan(animatedRect.bottom));
  });

  test('PR98のnormal脚anchorとwalk viewportを保持する', () {
    final normal = TrainingHomeCharacterFrameSet.forBodyKey(null);

    expect(SametarohAssets.normalFrames[1].footAnchorX, 87.5);
    expect(normal.walkFrames, hasLength(2));
    for (final frame in [...normal.idleFrames, ...normal.walkFrames]) {
      expect(
          frame.visibleBounds.bottom, closeTo(normal.canvasSize.height, 0.001));
    }
    for (final frame in normal.walkFrames) {
      expect(
        frame.renderCanvasSize?.width,
        closeTo(2 * 80 * 302 / 301, 0.001),
      );
      expect(frame.renderCanvasSize?.height, normal.canvasSize.height);
    }
  });

  for (final scenario in _cases) {
    testWidgets('${scenario.name}: 完了tickと通常初フレームのscale/translationが連続',
        (tester) async {
      final afterVisual = scenario.target(_targetKey);
      await tester.pumpWidget(
        _host(
          TrainingEvolutionReveal(
            beforeFrame: scenario.before,
            afterFrame: scenario.after,
            afterVisual: afterVisual,
            afterSize: afterVisual is SametarohFrameImage
                ? Size(afterVisual.width, afterVisual.height)
                : const Size(128, 184),
          ),
        ),
      );

      // 完了直前の最後のanimation frameと、isCompleted分岐の最初のframe。
      await tester.pump(const Duration(milliseconds: 1699));
      expect(find.byKey(_afterScaleKey), findsOneWidget);
      final lastScale = tester.widget<Transform>(find.byKey(_afterScaleKey));
      final lastRect = tester.getRect(find.byKey(_targetKey));
      expect(lastScale.transform.entry(0, 0), closeTo(1, 0.0001));
      expect(lastScale.transform.entry(1, 1), closeTo(1, 0.0001));
      expect(lastScale.transform.getTranslation().x, closeTo(0, 0.0001));
      expect(lastScale.transform.getTranslation().y, closeTo(0, 0.0001));
      final targetSize = tester.getSize(find.byKey(_targetKey));
      expect(lastRect.width, closeTo(targetSize.width, 0.01));
      expect(lastRect.height, closeTo(targetSize.height, 0.01));

      // Ticker starts on its first scheduled frame, so cross the duration
      // plus one vsync boundary before asserting the completed branch.
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(_afterScaleKey), findsNothing);
      final completedRect = tester.getRect(find.byKey(_targetKey));

      expect(completedRect.width, closeTo(lastRect.width, 0.01));
      expect(completedRect.height, closeTo(lastRect.height, 0.01));
      expect(completedRect.left, closeTo(lastRect.left, 0.01));
      expect(completedRect.top, closeTo(lastRect.top, 0.01));

      // 次画面の最初のidle/position widgetを同じ演出枠へ置き、実renderを比較。
      await tester
          .pumpWidget(_host(Center(child: scenario.target(_targetKey))));
      final normalRect = tester.getRect(find.byKey(_targetKey));
      expect(completedRect.left, closeTo(normalRect.left, 0.01));
      expect(completedRect.top, closeTo(normalRect.top, 0.01));
      expect(completedRect.width, closeTo(normalRect.width, 0.01));
      expect(completedRect.height, closeTo(normalRect.height, 0.01));
    });
  }
}
