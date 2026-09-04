import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

/// 育成ゲームのサーバー同期APIを担当します。
class TrainingGameProvider extends GetConnect {
  static final _clock = Stopwatch()..start();
  static Future<void> _pendingSync = Future<void>.value();

  /// 画面遷移中に実行中の同期完了を登録します。
  static void registerPendingSync(Future<void> pendingSync) {
    _pendingSync = pendingSync;
  }

  /// 未完了の同期があれば完了を待ちます。
  static Future<void> waitForPendingSync() => _pendingSync;
  static Future<void> _pendingWrite = Future<void>.value();

  /// APIクライアントを初期化します。
  TrainingGameProvider() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
    httpClient.timeout = const Duration(seconds: 15);
  }

  /// 現在の育成状態を取得します。
  Future<Map<String, dynamic>?> fetchCurrent() async {
    // 直前のバックグラウンド保存を待ってから最新状態を取得します。
    await _pendingWrite;
    final response = await get('game', headers: await _headers());
    return _data(response);
  }

  /// DBのクリア履歴から解放済みポジションを取得します。
  Future<List<String>> fetchUnlockedPositions() async {
    // 直前の完了同期を待ち、履歴登録後の一覧を取得します。
    await _pendingWrite;
    final response = await get('game/clear-history', headers: await _headers());
    final data = _data(response);
    final positions = data?['positions'];
    return positions is List ? positions.whereType<String>().toList() : <String>[];
  }

  /// 新しい育成サイクルをサーバーへ作成します。
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
  }) async {
    // 旧サイクルの同期完了前に新サイクルを作成すると、終了直前の状態で
    // 新しい開始状態が上書きされるため、書き込みを直列化します。
    await _pendingWrite;
    final response = await post(
      'game/start',
      {
        'stage_code': stageCode,
        'parameters': parameters,
        if (forceRestart) 'force_restart': true,
      },
      headers: await _headers(),
    );
    return _data(response) ?? <String, dynamic>{};
  }

  /// デバッグ用に、ログイン会員の育成ゲームデータを初回状態へ削除します。
  Future<Map<String, dynamic>> resetDebugState() async {
    await _pendingWrite;
    final response = await post('game/debug/reset', null, headers: await _headers());
    return _data(response) ?? <String, dynamic>{};
  }

  /// デバッグ用に、現在の育成サイクルの日次アクション利用履歴をリセットします。
  Future<Map<String, dynamic>> resetDebugDailyActionUsage() async {
    final write = _pendingWrite.then((_) async {
      final response = await post(
        'game/debug/reset-daily-actions',
        null,
        headers: await _headers(),
      );
      return _data(response) ?? <String, dynamic>{};
    });
    _pendingWrite = write.then<void>((_) {}, onError: (_, __) {});
    return write;
  }

  /// デバッグ時間操作後のパラメータをサーバーへ保存します。
  Future<Map<String, dynamic>> syncDebugTime({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
  }) async {
    final write = _pendingWrite.then((_) async {
      final response = await post(
        'game/debug/sync-time',
        {
          'stage_code': stageCode,
          'parameters': parameters,
          'lock_version': lockVersion,
        },
        headers: await _headers(),
      );
      return _data(response) ?? <String, dynamic>{};
    });
    _pendingWrite = write.then<void>((_) {}, onError: (_, __) {});
    return write;
  }

  /// ローカルで確定した状態とアクションをサーバーへ同期します。
  Future<Map<String, dynamic>> sync({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
    required int cycleNo,
    String? positionCode,
    String? branchCode,
    String? actionCode,
    double? actionScore,
    double? actionEffectMultiplier,
    String? actionResultCode,
    bool debugBypassCooldown = false,
    String status = 'playing',
  }) async {
    final write = _pendingWrite.then((_) async {
      final response = await post(
        'game/sync',
        {
          'stage_code': stageCode,
          'position_code': positionCode,
          'branch_code': branchCode,
          'status': status,
          'lock_version': lockVersion,
          'parameters': parameters,
          if (actionCode != null)
            'action': {
              'code': actionCode,
              'idempotency_key': '$cycleNo-${_clock.elapsedMicroseconds}-$actionCode',
              'result_code': actionResultCode ?? 'completed',
              if (debugBypassCooldown) 'debug_bypass_cooldown': true,
              if (actionScore != null) 'score': actionScore,
              if (actionEffectMultiplier != null) 'effect_multiplier': actionEffectMultiplier,
            },
        },
        headers: await _headers(),
      );
      return _data(response) ?? <String, dynamic>{};
    });
    // 次の取得が書き込み完了を待てるよう、エラーを吸収したFutureを保持します。
    _pendingWrite = write.then<void>((_) {}, onError: (_, __) {});
    return write;
  }

  /// 認証ヘッダーを作成します。
  Future<Map<String, String>> _headers() async {
    final token = await AuthToken().getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('認証が必要です。');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// GetConnectのレスポンスをAPIデータへ変換します。
  Map<String, dynamic>? _data(Response<dynamic> response) {
    if (response.hasError) {
      final body = response.body;
      final message = body is Map ? body['message']?.toString() : null;
      throw TrainingGameApiException(
        statusCode: response.statusCode,
        message: message ?? response.statusText ?? '育成ゲームAPIエラー',
      );
    }
    final body = response.body;
    if (body is! Map) throw Exception('育成ゲームAPIのレスポンス形式が不正です。');
    final data = body['data'];
    if (data == null) return null;
    if (data is! Map) throw Exception('育成ゲームAPIのデータ形式が不正です。');
    final result = Map<String, dynamic>.from(data);
    ServerTimeClock.instance.synchronizeFromPayload(result);
    return result;
  }
}

/// 育成ゲームAPIのHTTPエラーを、通信障害と業務エラーに分類できる例外です。
class TrainingGameApiException implements Exception {
  const TrainingGameApiException({
    required this.statusCode,
    required this.message,
  });

  final int? statusCode;
  final String message;

  @override
  String toString() => 'TrainingGameApiException($statusCode): $message';
}
