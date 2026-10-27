import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

void main() {
  group('mini-game audio session', () {
    test('uses the iOS ambient category', () {
      expect(
        trainingGameAudioSessionConfiguration.avAudioSessionCategory,
        AVAudioSessionCategory.ambient,
      );
    });

    test('configures the session once before playing effects', () async {
      final events = <String>[];
      final service = TrainingGameSoundService(
        configureAudioSession: () async => events.add('configured'),
        createPlayer: (_) => _FakeEffectPlayer(
          onPlay: () => events.add('played'),
        ),
      );

      await service.play(TrainingGameSoundEffect.passReceived);
      await service.play(TrainingGameSoundEffect.passFailed);

      expect(events, ['configured', 'played', 'played']);
      await service.dispose();
    });
  });

  group('TrainingGameSoundEffect', () {
    test('maps the game effects to bundled assets', () {
      expect(TrainingGameSoundEffect.values, [
        TrainingGameSoundEffect.passReceived,
        TrainingGameSoundEffect.passFailed,
        TrainingGameSoundEffect.resultDisplayed,
        TrainingGameSoundEffect.parameterRecovered,
        TrainingGameSoundEffect.evolutionNormal,
        TrainingGameSoundEffect.evolutionFirstTeam,
        TrainingGameSoundEffect.hatching,
        TrainingGameSoundEffect.tackleOk,
        TrainingGameSoundEffect.tackleGood,
        TrainingGameSoundEffect.tackleGreat,
        TrainingGameSoundEffect.tacklePerfect,
        TrainingGameSoundEffect.tackleMiss,
      ]);
      expect(
        TrainingGameSoundEffect.values.map((effect) => effect.assetPath),
        [
          'assets/audio/training_game/basket-path1.mp3',
          'assets/audio/training_game/cute-sad1.mp3',
          'assets/audio/training_game/sceneswitch1.mp3',
          'assets/audio/training_game/gauge-recovery3.mp3',
          'assets/audio/training_game/evolution-normal.m4a',
          'assets/audio/training_game/evolution-first-team.m4a',
          'assets/audio/training_game/hatching-charge.m4a',
          'assets/audio/training_game/tackle-ok.m4a',
          'assets/audio/training_game/tackle-good.m4a',
          'assets/audio/training_game/tackle-great.m4a',
          'assets/audio/training_game/tackle-perfect.m4a',
          'assets/audio/training_game/tackle-miss.m4a',
        ],
      );
    });
  });

  group('TrainingGameSoundService', () {
    test('does not create a player when disposed during session setup',
        () async {
      final configured = Completer<void>();
      var createdPlayers = 0;
      final service = TrainingGameSoundService(
        configureAudioSession: () => configured.future,
        createPlayer: (_) {
          createdPlayers++;
          return _FakeEffectPlayer();
        },
      );

      final playback = service.play(TrainingGameSoundEffect.passReceived);
      await service.dispose();
      configured.complete();
      await playback;
      await service.play(TrainingGameSoundEffect.passFailed);

      expect(createdPlayers, 0);
    });

    test('reuses a player for repeated playback and disposes it', () async {
      final createdPaths = <String>[];
      final players = <String, _FakeEffectPlayer>{};
      final service = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (assetPath) {
          createdPaths.add(assetPath);
          return players.putIfAbsent(assetPath, _FakeEffectPlayer.new);
        },
      );

      await service.play(TrainingGameSoundEffect.passReceived);
      await service.play(TrainingGameSoundEffect.passReceived);

      expect(createdPaths, [
        'assets/audio/training_game/basket-path1.mp3',
      ]);
      expect(players.values.single.playCount, 2);

      await service.dispose();
      expect(players.values.single.isDisposed, isTrue);
    });

    test('swallows player errors so gameplay can continue', () async {
      final service = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (_) => _FakeEffectPlayer(throwsOnPlay: true),
      );

      await expectLater(
        service.play(TrainingGameSoundEffect.passFailed),
        completes,
      );
      await service.dispose();
    });
  });
}

class _FakeEffectPlayer implements TrainingGameEffectPlayer {
  _FakeEffectPlayer({this.throwsOnPlay = false, this.onPlay});

  final bool throwsOnPlay;
  final void Function()? onPlay;
  int playCount = 0;
  bool isDisposed = false;

  @override
  Future<void> play() async {
    playCount++;
    onPlay?.call();
    if (throwsOnPlay) throw StateError('test playback failure');
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}
