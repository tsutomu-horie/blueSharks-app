import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';

/// Records sound paths requested by gameplay widgets without initializing an
/// audio plugin or contacting a platform device.
class RecordingTrainingGameSound {
  RecordingTrainingGameSound() {
    service = TrainingGameSoundService(
      createPlayer: (assetPath) {
        createdAssetPaths.add(assetPath);
        return _RecordingEffectPlayer(assetPath, playedAssetPaths);
      },
    );
  }

  late final TrainingGameSoundService service;
  final createdAssetPaths = <String>[];
  final playedAssetPaths = <String>[];

  Future<void> dispose() => service.dispose();
}

class _RecordingEffectPlayer implements TrainingGameEffectPlayer {
  _RecordingEffectPlayer(this.assetPath, this.playedAssetPaths);

  final String assetPath;
  final List<String> playedAssetPaths;

  @override
  Future<void> play() async {
    playedAssetPaths.add(assetPath);
  }

  @override
  Future<void> dispose() async {}
}
