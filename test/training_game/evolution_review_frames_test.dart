import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

typedef _TargetBuilder = Widget Function(Key key);

class _ReviewSequence {
  const _ReviewSequence(this.directory, this.before, this.after, this.target);

  final String directory;
  final SametarohFrame before;
  final SametarohFrame after;
  final Widget Function(Key key) target;
}

_TargetBuilder _homeTarget(String bodyKey) => (key) =>
    TrainingHomeCharacterFrameImage(
      frame: TrainingHomeCharacterFrameSet.forBodyKey(bodyKey).idleFrames.first,
      width: 128,
      height: 184,
      semanticLabel: '鮫太郎',
      key: key,
    );

final _sequences = <_ReviewSequence>[
  for (final bodyKey in SametarohAssets.supportedBodyKeys) ...[
    _ReviewSequence(
      'stage2_$bodyKey',
      SametarohAssets.newbornFrame,
      SametarohAssets.idleFramesForBodyKey(bodyKey).first,
      _homeTarget(bodyKey),
    ),
    _ReviewSequence(
      'stage3_$bodyKey',
      SametarohAssets.normalFrames.first,
      SametarohAssets.idleFramesForBodyKey(bodyKey).first,
      _homeTarget(bodyKey),
    ),
  ],
  _ReviewSequence(
    'stage4_wing',
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
  _ReviewSequence(
    'stage4_home_fallback',
    SametarohAssets.idleFramesForBodyKey('pr').first,
    SametarohAssets.idleFramesForBodyKey('pr').first,
    _homeTarget('pr'),
  ),
];

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 300, height: 390, child: child),
        ),
      ),
    );

String _sampleRow(
  String route,
  String sample,
  WidgetTester tester,
  Key targetKey,
) {
  final rect = tester.getRect(find.byKey(targetKey));
  final layoutSize = tester.getSize(find.byKey(targetKey));
  final scale = rect.width / layoutSize.width;
  final finalLeft = rect.center.dx - layoutSize.width / 2;
  final finalTop = rect.bottom - layoutSize.height;
  return [
    route,
    sample,
    scale,
    rect.left - finalLeft,
    rect.top - finalTop,
    rect.left,
    rect.top,
    rect.width,
    rect.height,
    rect.bottom,
  ]
      .map((value) =>
          value is String ? value : (value as num).toStringAsFixed(3))
      .join(',');
}

void main() {
  for (final sequence in _sequences) {
    testWidgets('${sequence.directory}: review用geometry sequenceを記録する',
        (tester) async {
      const targetKey = ValueKey<String>('review-target');
      final afterVisual = sequence.target(targetKey);
      await tester.pumpWidget(
        _host(TrainingEvolutionReveal(
          beforeFrame: sequence.before,
          afterFrame: sequence.after,
          afterVisual: afterVisual,
          afterSize: afterVisual is SametarohFrameImage
              ? Size(afterVisual.width, afterVisual.height)
              : const Size(128, 184),
        )),
      );
      await tester.pump();

      final rows = <String>[
        'route,sample,scale,bounds_offset_x,bounds_offset_y,left,top,width,height,foot_line_y',
      ];
      double? footLineY;
      var elapsedMs = 0;
      for (final sampleMs in [0, 350, 700, 1050, 1400, 1699]) {
        if (sampleMs > elapsedMs) {
          await tester.pump(Duration(milliseconds: sampleMs - elapsedMs));
          elapsedMs = sampleMs;
        }
        final rect = tester.getRect(find.byKey(targetKey));
        footLineY ??= rect.bottom;
        expect(rect.bottom, closeTo(footLineY, 0.01));
        rows.add(_sampleRow(
          sequence.directory,
          '${sampleMs}ms',
          tester,
          targetKey,
        ));
      }

      final animationEnd = tester.getRect(find.byKey(targetKey)).bottom;
      await tester.pump(const Duration(milliseconds: 20));
      final completed = tester.getRect(find.byKey(targetKey));
      expect(completed.bottom, closeTo(animationEnd, 0.01));
      expect(
        find.byKey(const ValueKey<String>('training-evolution-after-scale')),
        findsNothing,
      );
      rows.add(_sampleRow(
        sequence.directory,
        'completed_after_1719ms',
        tester,
        targetKey,
      ));

      await tester.pumpWidget(_host(Center(child: afterVisual)));
      final regular = tester.getRect(find.byKey(targetKey));
      expect(regular.bottom, closeTo(completed.bottom, 0.01));
      expect(regular.left, closeTo(completed.left, 0.01));
      expect(regular.top, closeTo(completed.top, 0.01));
      expect(regular.width, closeTo(completed.width, 0.01));
      expect(regular.height, closeTo(completed.height, 0.01));
      rows.add(_sampleRow(
        sequence.directory,
        'normal_first_frame',
        tester,
        targetKey,
      ));

      final file = File(
        'artifacts/evolution-review/${sequence.directory}/geometry.csv',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${rows.join('\n')}\n');
      expect(tester.takeException(), isNull);
    });
  }
}
