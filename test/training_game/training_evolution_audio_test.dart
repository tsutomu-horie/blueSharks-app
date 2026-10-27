import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_screen_transitions.dart';

class _Player
    implements
        TrainingGameResumableEffectPlayer,
        TrainingGamePreparableEffectPlayer {
  _Player({this.ready});
  final Completer<void>? ready;
  final events = <String>[];
  @override
  Future<void> prepare() async {
    await ready?.future;
  }

  @override
  Future<void> play() async {
    events.add('play');
  }

  @override
  Future<void> pause() async {
    events.add('pause');
  }

  @override
  Future<void> resume() async {
    events.add('resume');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  testWidgets('承認済みの進化音2種がアプリのbundleに含まれる', (tester) async {
    for (final effect in [
      TrainingGameSoundEffect.evolutionNormal,
      TrainingGameSoundEffect.evolutionFirstTeam
    ]) {
      final bytes = await rootBundle.load(effect.assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000));
      expect(String.fromCharCodes(bytes.buffer.asUint8List(4, 4)), 'ftyp');
    }
  });
  test('音声セッション準備中のpause→resumeで二重再生しない', () async {
    final configured = Completer<void>();
    final player = _Player();
    final service = TrainingGameSoundService(
        configureAudioSession: () => configured.future,
        createPlayer: (_) => player);
    final playing = service.play(TrainingGameSoundEffect.evolutionNormal);
    await service.pause();
    await service.resume();
    configured.complete();
    await playing;
    await Future<void>.delayed(Duration.zero);
    expect(player.events, ['play']);
    await service.dispose();
  });

  Widget scene(TrainingGameSoundService service,
          {VoidCallback? onTap, bool reduceMotion = false}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Scaffold(
                  body: TrainingEndingEntrance(
                      duration: const Duration(milliseconds: 2400),
                      soundFactory: () => service,
                      soundEffect: TrainingGameSoundEffect.evolutionNormal,
                      builder: (context, animation) => Column(children: [
                            AnimatedBuilder(
                                animation: animation,
                                builder: (_, __) => Text(
                                    animation.value.toStringAsFixed(2),
                                    key: const ValueKey('progress'))),
                            TrainingEndingItem(
                                animation: animation,
                                start: 2.1 / 2.4,
                                span: .3 / 2.4,
                                child: TextButton(
                                    onPressed: onTap,
                                    child: const Text('next'))),
                          ])))));

  testWidgets('音源準備後に映像と音を開始し、中断中はボタンも進めない', (tester) async {
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    var taps = 0;
    final service = TrainingGameSoundService(
        configureAudioSession: () async {}, createPlayer: (_) => player);
    await tester.pumpWidget(scene(service, onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0.00'), findsOneWidget);
    expect(player.events, isEmpty);
    ready.complete();
    await tester.pump();
    await tester.pump();
    expect(player.events, ['play']);
    await tester.pump(const Duration(milliseconds: 800));
    final progress =
        tester.widget<Text>(find.byKey(const ValueKey('progress'))).data;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.widget<Text>(find.byKey(const ValueKey('progress'))).data,
        progress);
    await tester.tap(find.text('next'), warnIfMissed: false);
    expect(taps, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.tap(find.text('next'));
    expect(taps, 1);
    expect(player.events.where((e) => e == 'play').length, 1);
    expect(player.events, containsAllInOrder(['play', 'pause', 'resume']));
    await tester.pumpWidget(const SizedBox());
    expect(player.events.last, 'dispose');
  });

  testWidgets('準備が遅い場合は無音で進み、遅れて再生しない', (tester) async {
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    var taps = 0;
    final service = TrainingGameSoundService(
        configureAudioSession: () async {}, createPlayer: (_) => player);
    await tester.pumpWidget(scene(service, onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();
    expect(player.events, ['dispose']);
    await tester.pump(const Duration(milliseconds: 2420));
    await tester.tap(find.text('next'));
    expect(taps, 1);
    ready.complete();
    await tester.pump();
    expect(player.events, ['dispose']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('準備中の画面破棄後に音を再生しない', (tester) async {
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    final service = TrainingGameSoundService(
        configureAudioSession: () async {}, createPlayer: (_) => player);
    await tester.pumpWidget(scene(service));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    ready.complete();
    await tester.pump();
    expect(player.events, ['dispose']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('動きを減らす設定では準備待ちや不可視ボタンを残さない', (tester) async {
    final player = _Player();
    var taps = 0;
    final service = TrainingGameSoundService(
        configureAudioSession: () async {}, createPlayer: (_) => player);
    await tester
        .pumpWidget(scene(service, reduceMotion: true, onTap: () => taps++));
    await tester.tap(find.text('next'));
    expect(taps, 1);
    expect(player.events, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await service.dispose();
  });
}
