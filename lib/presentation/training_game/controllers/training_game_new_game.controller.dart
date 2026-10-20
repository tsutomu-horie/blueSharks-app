import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

/// 孵化演出が完了してから、幼体で新しい育成サイクルを開始します。
class TrainingGameNewGameController extends GetxController {
  TrainingGameNewGameController({TrainingGameProvider? provider})
      : _provider = provider ?? TrainingGameProvider();

  final isStarting = false.obs;
  final errorMessage = ''.obs;
  final TrainingGameProvider _provider;
  final int _session = AuthToken.sessionVersion;
  bool _restartBaselineCaptured = false;
  String? _restartBaseline;
  bool _startAttempted = false;
  String? _startBaseline;
  Map<String, dynamic>? _startedState;

  String? _cycleIdentity(Map<String, dynamic>? state) => state == null
      ? null
      : '${state['id']}:${state['cycle_no']}';

  /// 既存playingは維持し、応答消失後の再試行でもサイクルを重複作成しません。
  Future<Map<String, dynamic>?> startNewGame({bool forceRestart = false}) async {
    if (isStarting.value || isClosed) return null;
    if (_session != AuthToken.sessionVersion) {
      errorMessage.value = 'ログイン状態が変わりました。画面を閉じて、もう一度お試しください。';
      return null;
    }
    if (_startedState != null) return _startedState;
    isStarting.value = true;
    errorMessage.value = '';
    final session = AuthToken.sessionVersion;
    bool ownsSession() => !isClosed && session == AuthToken.sessionVersion;

    try {
      await TrainingGameProvider.waitForPendingSync();
      if (!ownsSession()) return null;
      final current = await _provider.fetchCurrent(
        expectedSessionVersion: session,
      );
      if (!ownsSession()) return null;
      // やり直しで応答だけが失われた場合、更新済みcycleを再度初期化しません。
      final restartAlreadyApplied = forceRestart &&
          _restartBaselineCaptured &&
          _cycleIdentity(current) != _restartBaseline;
      if (current?['status'] == 'playing' &&
          (!forceRestart || restartAlreadyApplied)) {
        final recoveredNewCycle = _startAttempted &&
            _cycleIdentity(current) != _startBaseline &&
            current!['stage_code'] != 'egg';
        return await _rememberState(current!,
            newCycle: recoveredNewCycle, ownsSession: ownsSession);
      }
      if (forceRestart && !_restartBaselineCaptured) {
        _restartBaseline = _cycleIdentity(current);
        _restartBaselineCaptured = true;
      }
      _startBaseline = _cycleIdentity(current);
      _startAttempted = true;
      final data = await _provider.start(
        stageCode: 'child',
        parameters: const {
          'hunger': 100,
          'cleanliness': 50,
          'condition': 50,
          'work': 0,
          'tendency_fw': 0,
          'tendency_command': 0,
          'tendency_backs': 0,
          'tendency_bulk': 0,
          'tendency_tech': 0,
        },
        forceRestart: forceRestart,
        expectedSessionVersion: session,
      );
      if (!ownsSession()) return null;
      // サーバーの保存結果を確認し、表示だけ幼体に置き換えることを防ぎます。
      if (data['stage_code'] != 'child' || data['status'] != 'playing') {
        errorMessage.value = '幼体の開始状態を確認できませんでした。もう一度接続してください。';
        return null;
      }
      return await _rememberState(data,
          newCycle: true, ownsSession: ownsSession);
    } catch (_) {
      if (ownsSession()) {
        errorMessage.value = '育成の開始に失敗しました。通信状態を確認して再度お試しください。';
      }
      return null;
    } finally {
      if (!isClosed) isStarting.value = false;
    }
  }

  Future<Map<String, dynamic>?> _rememberState(
    Map<String, dynamic> data, {
    required bool newCycle,
    required bool Function() ownsSession,
  }) async {
    if (newCycle) {
      await MySharedPref.clearTrainingGameDebugElapsedSeconds();
      if (!ownsSession()) return null;
      await MySharedPref.clearTrainingGameLocalState();
    }
    if (!ownsSession()) return null;
    _startedState = Map<String, dynamic>.from(data);
    if (newCycle) _startedState!['_new_cycle'] = true;
    return _startedState;
  }
}
