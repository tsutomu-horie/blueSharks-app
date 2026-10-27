import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'tackle_test_driver.dart';
import 'recording_training_game_sound.dart';

class _Watch implements Stopwatch {
  _Watch(this.value);
  final Duration value;
  bool running = false;
  @override
  Duration get elapsed => value;
  @override
  int get elapsedMicroseconds => value.inMicroseconds;
  @override
  int get elapsedMilliseconds => value.inMilliseconds;
  @override
  int get elapsedTicks => value.inMicroseconds;
  @override
  int get frequency => 1000000;
  @override
  bool get isRunning => running;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  @override
  void reset() {}
}

class _Player
    implements TrainingGameEffectPlayer, TrainingGamePreparableEffectPlayer {
  _Player(this.path, this.session);
  final String path;
  final _Session session;
  @override
  Future<void> prepare() async {
    await session.ready?.future;
  }

  @override
  Future<void> play() async {
    session.played.add(path);
  }

  @override
  Future<void> dispose() async {
    session.disposed.add(path);
  }
}

class _Session {
  _Session({this.ready}) {
    service = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (p) => _Player(p, this));
  }
  final Completer<void>? ready;
  final played = <String>[], disposed = <String>[];
  late final TrainingGameSoundService service;
}

void main() {
  Future<void> mount(WidgetTester tester,
      {required List<_Session> sessions,
      int reaction = 0,
      Completer<void>? ready}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
        home: TackleGameScreen(
            random: FixedTackleRandom(
                hasFeint: false, downward: true, approachMs: 1350),
            reactionWatchFactory: () =>
                _Watch(Duration(milliseconds: reaction)),
            soundService: silentTrainingGameSound(),
            feedbackSoundFactory: () {
              final s = _Session(ready: ready);
              sessions.add(s);
              return s.service;
            })));
    expect(sessions, isEmpty, reason: '開始前に音源作成や再生をしない');
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
  }

  for (final row in <String, (int, TrainingGameSoundEffect)>{
    'OK': (410, TrainingGameSoundEffect.tackleOk),
    'GOOD': (280, TrainingGameSoundEffect.tackleGood),
    'GREAT': (175, TrainingGameSoundEffect.tackleGreat),
    'PERFECT': (0, TrainingGameSoundEffect.tacklePerfect),
    'MISS': (0, TrainingGameSoundEffect.tackleMiss),
  }.entries) {
    testWidgets('${row.key}のSEを判定演出に合わせて1回だけ再生する', (tester) async {
      final sessions = <_Session>[];
      await mount(tester, sessions: sessions, reaction: row.value.$1);
      await tester.tap(find.byKey(
          ValueKey(row.key == 'MISS' ? 'tackle-tap-up' : 'tackle-tap-down')));
      await tester.pump();
      expect(find.text(row.key), findsOneWidget);
      await tester.pump(Duration(milliseconds: row.key == 'MISS' ? 79 : 290));
      expect(sessions.single.played, isEmpty);
      await tester.pump(const Duration(milliseconds: 40));
      expect(sessions.single.played, [row.value.$2.assetPath]);
      await tester.tap(find.byKey(const Key('tackle-tap-down')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(sessions.single.played, [row.value.$2.assetPath]);
      await tester.pumpWidget(const SizedBox());
      expect(sessions.single.disposed.length, 5);
    });
  }
  testWidgets('準備が遅れても接触後に遅れて鳴らさない', (tester) async {
    final sessions = <_Session>[];
    final ready = Completer<void>();
    await mount(tester, sessions: sessions, ready: ready);
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(sessions.single.played, isEmpty);
    ready.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(sessions.single.played, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('接触前の中断・復帰で古い音を再生しない', (tester) async {
    final sessions = <_Session>[];
    await mount(tester, sessions: sessions);
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(sessions.expand((s) => s.played), isEmpty);
    await tester.tap(find.text('SET 1 / 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(sessions.last.played,
        [TrainingGameSoundEffect.tacklePerfect.assetPath]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('画面退出後に音を鳴らさない', (tester) async {
    final sessions = <_Session>[];
    await mount(tester, sessions: sessions);
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(sessions.single.played, isEmpty);
    expect(sessions.single.disposed.length, 5);
  });
  testWidgets('次セットの手動一時停止で前セットの余韻を止める', (tester) async {
    final sessions = <_Session>[];
    await mount(tester, sessions: sessions);
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(sessions.single.played,
        [TrainingGameSoundEffect.tacklePerfect.assetPath]);
    await tester.tap(find.text('SET 1 / 3'));
    await tester.pump();
    await tester.tap(find.byTooltip('一時停止'));
    await tester.pump();
    expect(sessions.single.disposed.length, 5);
    await tester.tap(find.byTooltip('再開'));
    await tester.pump();
    expect(sessions.length, 2);
    expect(sessions.last.played, isEmpty);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(sessions.last.played,
        [TrainingGameSoundEffect.tacklePerfect.assetPath]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('5種類のSEがアプリbundleに含まれる', (tester) async {
    for (final effect in [
      TrainingGameSoundEffect.tackleOk,
      TrainingGameSoundEffect.tackleGood,
      TrainingGameSoundEffect.tackleGreat,
      TrainingGameSoundEffect.tacklePerfect,
      TrainingGameSoundEffect.tackleMiss
    ]) {
      final bytes = await rootBundle.load(effect.assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000));
    }
  });
}
