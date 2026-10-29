import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// ミニゲームの短い効果音向け。iOSの消音スイッチに従い、他アプリの音声と共存します。
@visibleForTesting
const trainingGameAudioSessionConfiguration = AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
);

/// 育成ゲームで使用する効果音です。
enum TrainingGameSoundEffect {
  /// パスを仲間が受け取った時。
  passReceived,

  /// パスを受け取れず失敗した時。
  passFailed,

  /// ミニゲームの結果画面が現れた時。
  resultDisplayed,

  /// お世話でパラメーターが回復した時。
  parameterRecovered,

  /// 承認済みの進化プレビューと同じ溜め音・お披露目音です。
  evolutionNormal,
  evolutionFirstTeam,

  /// 孵化A案の上昇する溜め音と誕生のきらめき。
  hatching,

  /// タックル判定SE（接触時に1回再生）。
  tackleOk,
  tackleGood,
  tackleGreat,
  tacklePerfect,
  tackleMiss,

  /// ボールが手を離れた時の短い風切り音。
  passThrown,
  homeTapSoft,
  homeTapTouch,
  homeTapHappy,

  /// パス＆ランの結果画面（従来の場面切替音）。
  passResultDisplayed,
}

extension TrainingGameSoundEffectAsset on TrainingGameSoundEffect {
  /// 効果音ラボから取得したアプリ内素材のパスです。
  String get assetPath => switch (this) {
        // 効果音ラボ「ぷよん」「ちょこっと触る」「ニュッ3」。承認済み音量。
        // https://soundeffect-lab.info/sound/anime/
        TrainingGameSoundEffect.homeTapSoft =>
          'assets/audio/training_game/home-tap-soft.m4a',
        TrainingGameSoundEffect.homeTapTouch =>
          'assets/audio/training_game/home-tap-touch.m4a',
        TrainingGameSoundEffect.homeTapHappy =>
          'assets/audio/training_game/home-tap-happy.m4a',
        // 効果音ラボ「軽いパンチ2」＋決定29/30/53/成功音。MISSはキャンセル6。
        // 0.42〜0.95秒、-20 LUFS目標へ加工。出典・加工条件: tool/mini_game_audio_sources.json。
        // https://soundeffect-lab.info/sound/button/
        // https://soundeffect-lab.info/sound/battle/
        TrainingGameSoundEffect.tackleOk =>
          'assets/audio/training_game/tackle-ok.m4a',
        TrainingGameSoundEffect.tackleGood =>
          'assets/audio/training_game/tackle-good.m4a',
        TrainingGameSoundEffect.tackleGreat =>
          'assets/audio/training_game/tackle-great.m4a',
        TrainingGameSoundEffect.tacklePerfect =>
          'assets/audio/training_game/tackle-perfect.m4a',
        TrainingGameSoundEffect.tackleMiss =>
          'assets/audio/training_game/tackle-miss.m4a',
        // 効果音ラボ: magic-statusup2を0.65秒、cute-pose1を2.5秒から合成。
        // https://soundeffect-lab.info/sound/battle/
        // https://soundeffect-lab.info/sound/anime/
        TrainingGameSoundEffect.hatching =>
          'assets/audio/training_game/hatching-charge.m4a',
        // 効果音ラボ: battle/magic-statusup1（頭0.7秒）を0.45秒から、
        // button/decision37またはdecision21を1.05秒から合成した承認済み音源。
        // https://soundeffect-lab.info/sound/battle/
        // https://soundeffect-lab.info/sound/button/
        TrainingGameSoundEffect.evolutionNormal =>
          'assets/audio/training_game/evolution-normal.m4a',
        TrainingGameSoundEffect.evolutionFirstTeam =>
          'assets/audio/training_game/evolution-first-team.m4a',
        // 出典: https://soundeffect-lab.info/sound/button/ （ゲージ回復3）
        TrainingGameSoundEffect.parameterRecovered =>
          'assets/audio/training_game/gauge-recovery3.mp3',
        // パス＆ランは修正前の投球音へ復元。パンチ素振りの頭0.22秒。
        // https://soundeffect-lab.info/sound/battle/
        TrainingGameSoundEffect.passThrown =>
          'assets/audio/training_game/pass-throw.m4a',
        // パス＆ランは修正前の受球音・ミス音を使用。
        TrainingGameSoundEffect.passReceived =>
          'assets/audio/training_game/basket-path1.mp3',
        TrainingGameSoundEffect.passFailed =>
          'assets/audio/training_game/cute-sad1.mp3',
        TrainingGameSoundEffect.passResultDisplayed =>
          'assets/audio/training_game/sceneswitch1.mp3',
        // タックル結果: レベルアップ。1.8秒に調整。
        // https://soundeffect-lab.info/sound/anime/
        TrainingGameSoundEffect.resultDisplayed =>
          'assets/audio/training_game/mini-game-result.m4a',
      };
}

/// ゲーム進行から独立して短い効果音を再生します。
class TrainingGameSoundService {
  /// アプリ内で共有する既定サービスです。
  static final instance = TrainingGameSoundService();

  /// プレイヤーとセッション設定を差し替えられるので、テストでは音声プラグインを使いません。
  TrainingGameSoundService({
    TrainingGameEffectPlayer Function(String assetPath)? createPlayer,
    Future<void> Function()? configureAudioSession,
    double volume = .72,
  })  : _createPlayer = createPlayer ??
            ((assetPath) => _JustAudioEffectPlayer(assetPath, volume)),
        _configureAudioSession =
            configureAudioSession ?? _configureMiniGameAudioSession;

  final TrainingGameEffectPlayer Function(String assetPath) _createPlayer;
  final Future<void> Function() _configureAudioSession;
  final _players = <TrainingGameSoundEffect, TrainingGameEffectPlayer>{};
  Future<void>? _audioSessionConfiguration;
  bool _disposed = false;
  bool _paused = false;
  final _pendingEffects = <TrainingGameSoundEffect>{};
  final _inFlightEffects = <TrainingGameSoundEffect>{};
  final _playFinished = <TrainingGameSoundEffect, Completer<void>>{};

  /// 指定された承認済み効果音を再生します。
  /// 音声再生の失敗でゲーム操作を止めないよう、プレイヤーエラーを抑止します。
  Future<void> play(TrainingGameSoundEffect effect) async {
    if (_disposed || !_inFlightEffects.add(effect)) return;
    _pendingEffects.add(effect);
    final finished = Completer<void>();
    _playFinished[effect] = finished;
    try {
      await _ensureAudioSessionConfigured();
      if (_disposed || _paused) return;
      _pendingEffects.remove(effect);
      final player = _players.putIfAbsent(
        effect,
        () => _createPlayer(effect.assetPath),
      );
      await player.play();
    } on Object {
      // 音声デバイスやプラットフォームプラグインの状態はゲーム進行に影響させません。
      _pendingEffects.remove(effect);
    } finally {
      _inFlightEffects.remove(effect);
      _playFinished.remove(effect);
      finished.complete();
    }
  }

  /// 読み込み完了後に映像と同時に再生できるよう事前準備します。
  Future<bool> prepare(TrainingGameSoundEffect effect) async {
    if (_disposed) return false;
    try {
      await _ensureAudioSessionConfigured();
      if (_disposed) return false;
      final player =
          _players.putIfAbsent(effect, () => _createPlayer(effect.assetPath));
      if (player is TrainingGamePreparableEffectPlayer) await player.prepare();
      return !_disposed;
    } on Object {
      return false;
    }
  }

  Future<void> _ensureAudioSessionConfigured() async {
    final configured = _audioSessionConfiguration;
    if (configured != null) {
      await configured;
      return;
    }

    final pending = _configureAudioSession();
    _audioSessionConfiguration = pending;
    try {
      await pending;
    } on Object {
      if (identical(_audioSessionConfiguration, pending)) {
        _audioSessionConfiguration = null;
      }
      rethrow;
    }
  }

  Future<void> pause() async {
    _paused = true;
    for (final player in _players.values.toList()) {
      if (player is TrainingGameResumableEffectPlayer) {
        try {
          await player.pause();
        } on Object {/* 音声失敗で進行を止めません。 */}
      }
    }
  }

  Future<void> resume() async {
    if (_disposed) return;
    _paused = false;
    for (final entry in _players.entries.toList()) {
      final starting = _playFinished[entry.key];
      if (starting != null) await starting.future;
      if (_disposed || _paused) return;
      final player = entry.value;
      if (player is TrainingGameResumableEffectPlayer) {
        try {
          await player.resume();
        } on Object {/* 音声失敗で進行を止めません。 */}
      }
    }
    for (final effect in _pendingEffects.toList()) {
      if (!_inFlightEffects.contains(effect)) unawaited(play(effect));
    }
  }

  /// テストなど、サービスの所有者が明示的に閉じる場合にプレイヤーを解放します。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait(_players.values
        .map((player) => player.dispose().catchError((Object _) {})));
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

abstract interface class TrainingGameResumableEffectPlayer
    implements TrainingGameEffectPlayer {
  Future<void> pause();
  Future<void> resume();
}

abstract interface class TrainingGamePreparableEffectPlayer
    implements TrainingGameEffectPlayer {
  Future<void> prepare();
}

class _JustAudioEffectPlayer
    implements
        TrainingGameResumableEffectPlayer,
        TrainingGamePreparableEffectPlayer {
  _JustAudioEffectPlayer(String assetPath, double volume) {
    _assetLoaded =
        _player.setAsset(assetPath).then((_) => _player.setVolume(volume));
  }

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _assetLoaded;
  bool _paused = false;
  bool _disposed = false;
  bool _starting = false;

  @override
  Future<void> prepare() => _assetLoaded;

  @override
  Future<void> play() async {
    _starting = true;
    await _assetLoaded;
    if (_disposed) return;
    await _player.seek(Duration.zero);
    _starting = false;
    if (!_paused && !_disposed) {
      unawaited(_player.play().catchError((Object _) {}));
    }
  }

  @override
  Future<void> pause() async {
    _paused = true;
    await _assetLoaded;
    if (!_disposed) await _player.pause();
  }

  @override
  Future<void> resume() async {
    _paused = false;
    await _assetLoaded;
    if (!_paused &&
        !_disposed &&
        !_starting &&
        !_player.playing &&
        _player.processingState != ProcessingState.completed) {
      unawaited(_player.play().catchError((Object _) {}));
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _player.dispose();
  }
}

Future<void> _configureMiniGameAudioSession() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

  final session = await AudioSession.instance;
  await session.configure(trainingGameAudioSessionConfiguration);
}

/// 合成済みの進化音は承認プレビューの音量をそのまま使います。
TrainingGameSoundService createTrainingEvolutionSound() =>
    TrainingGameSoundService(volume: 1);

/// 孵化A案の合成済み音源を、承認プレビューと同じ音量で再生します。
TrainingGameSoundService createTrainingHatchingSound() =>
    TrainingGameSoundService(volume: 1);

/// 判定音は承認プレビューと同じ合成済み音量を使います。
TrainingGameSoundService createTackleFeedbackSound() =>
    TrainingGameSoundService(volume: 1);

/// 承認済みホームタップSEの加工済み音量を保持します。
TrainingGameSoundService createTrainingHomeTapSound() =>
    TrainingGameSoundService(volume: 1);
