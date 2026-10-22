import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

void main() {
  group('TrainingGameSoundEffect', () {
    test('contains only the three approved No.40 effects', () {
      expect(TrainingGameSoundEffect.values, [
        TrainingGameSoundEffect.passReceived,
        TrainingGameSoundEffect.passFailed,
        TrainingGameSoundEffect.resultDisplayed,
      ]);
      expect(
        TrainingGameSoundEffect.values.map((effect) => effect.assetPath),
        [
          'assets/audio/training_game/basket-path1.mp3',
          'assets/audio/training_game/cute-sad1.mp3',
          'assets/audio/training_game/sceneswitch1.mp3',
        ],
      );
    });
  });

  group('TrainingGameSoundService', () {
    test('reuses a player for repeated playback and disposes it', () async {
      final createdPaths = <String>[];
      final players = <String, _FakeEffectPlayer>{};
      final service = TrainingGameSoundService(
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
  _FakeEffectPlayer({this.throwsOnPlay = false});

  final bool throwsOnPlay;
  int playCount = 0;
  bool isDisposed = false;

  @override
  Future<void> play() async {
    playCount++;
    if (throwsOnPlay) throw StateError('test playback failure');
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}
