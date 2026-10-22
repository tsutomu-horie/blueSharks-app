import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// No.40でユーザーが採用した効果音だけを表します。
enum TrainingGameSoundEffect {
  /// パスを仲間が受け取った時。
  passReceived,

  /// パスを受け取れず失敗した時。
  passFailed,

  /// ミニゲームの結果画面が現れた時。
  resultDisplayed,
}

extension TrainingGameSoundEffectAsset on TrainingGameSoundEffect {
  /// 効果音ラボから取得したアプリ内素材のパスです。
  String get assetPath => switch (this) {
        TrainingGameSoundEffect.passReceived =>
          'assets/audio/training_game/basket-path1.mp3',
        TrainingGameSoundEffect.passFailed =>
          'assets/audio/training_game/cute-sad1.mp3',
        TrainingGameSoundEffect.resultDisplayed =>
          'assets/audio/training_game/sceneswitch1.mp3',
      };
}

/// ゲーム進行から独立して短い効果音を再生します。
class TrainingGameSoundService {
  /// アプリ内で共有する既定サービスです。
  static final instance = TrainingGameSoundService();

  /// プレイヤーを差し替えられるので、テストでは音声プラグインを使いません。
  TrainingGameSoundService({
    TrainingGameEffectPlayer Function(String assetPath)? createPlayer,
  }) : _createPlayer = createPlayer ?? _JustAudioEffectPlayer.new;

  final TrainingGameEffectPlayer Function(String assetPath) _createPlayer;
  final _players = <TrainingGameSoundEffect, TrainingGameEffectPlayer>{};
  bool _disposed = false;

  /// 指定された承認済み効果音を再生します。
  /// 音声再生の失敗でゲーム操作を止めないよう、プレイヤーエラーを抑止します。
  Future<void> play(TrainingGameSoundEffect effect) async {
    if (_disposed) return;
    try {
      final player = _players.putIfAbsent(
        effect,
        () => _createPlayer(effect.assetPath),
      );
      await player.play();
    } on Object {
      // 音声デバイスやプラットフォームプラグインの状態はゲーム進行に影響させません。
    }
  }

  /// テストなど、サービスの所有者が明示的に閉じる場合にプレイヤーを解放します。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait(_players.values.map((player) => player.dispose()));
    _players.clear();
  }
}

/// 音声プラットフォームを差し替えやすくする小さな再生境界です。
abstract interface class TrainingGameEffectPlayer {
  /// 音源を先頭から再生します。
  Future<void> play();

  /// プレイヤーを解放します。
  Future<void> dispose();
}

class _JustAudioEffectPlayer implements TrainingGameEffectPlayer {
  _JustAudioEffectPlayer(String assetPath) {
    _assetLoaded =
        _player.setAsset(assetPath).then((_) => _player.setVolume(.72));
  }

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _assetLoaded;

  @override
  Future<void> play() async {
    await _assetLoaded;
    await _player.seek(Duration.zero);
    unawaited(_player.play().catchError((Object _) {}));
  }

  @override
  Future<void> dispose() => _player.dispose();
}
