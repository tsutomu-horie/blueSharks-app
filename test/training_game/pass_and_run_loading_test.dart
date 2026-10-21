import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';

class _DelayedImages extends CachingAssetBundle {
  final ready = Completer<void>();
  @override
  Future<ByteData> load(String key) async {
    if (key.contains('pass_run_') && key.endsWith('.png')) await ready.future;
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('17画像の準備が終わるまで開始を防ぎ、準備待ちで15秒を消費しない', (t) async {
    imageCache.clear();
    imageCache.clearLiveImages();
    final bundle = _DelayedImages();
    var clock = DateTime.utc(2026, 10, 21);
    await t.pumpWidget(DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(home: PassAndRunGameScreen(now: () => clock))));
    expect(find.text('準備中…'), findsOneWidget);
    expect(
        t
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '準備中…'))
            .onPressed,
        isNull);
    clock = clock.add(const Duration(seconds: 8));
    await t.pump(const Duration(seconds: 8));
    expect(find.text('準備中…'), findsOneWidget);
    bundle.ready.complete();
    final context = t.element(find.byType(PassAndRunGameScreen));
    await t.runAsync(() async {
      for (final path in PassAndRunCharacterVisual.assets) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await t.pump();
    expect(find.text('スタート'), findsOneWidget);
    // All upcoming states remain live even if other app images clear the LRU cache.
    for (final path in PassAndRunCharacterVisual.assets) {
      final key = await AssetImage(path)
          .obtainKey(createLocalImageConfiguration(context));
      expect(imageCache.statusForKey(key).live, isTrue, reason: path);
    }
    imageCache.clear();
    await t.tap(find.text('スタート'));
    await t.pump();
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    for (var i = 0; i < 400; i++) {
      clock = clock.add(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 16));
      for (final key in ['pass-player', 'pass-mate']) {
        final sprite = find.byKey(ValueKey(key));
        final image = t.widget<Image>(
            find.descendant(of: sprite, matching: find.byType(Image)));
        expect(image.gaplessPlayback, isTrue);
        final raw = t.renderObject<RenderImage>(
            find.descendant(of: sprite, matching: find.byType(RawImage)));
        expect(raw.image, isNotNull,
            reason: '$key must never disappear on a facing/frame change');
      }
    }
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
}
