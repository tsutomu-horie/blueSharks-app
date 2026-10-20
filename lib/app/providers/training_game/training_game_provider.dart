import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

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
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    // 直前のバックグラウンド保存を待ってから最新状態を取得します。
    await _pendingWrite;
    final headers = await _headers(expectedSessionVersion);
    _assertSessionVersion(expectedSessionVersion);
    final response = await get('game', headers: headers);
    return _data(response);
  }

  /// DBのクリア履歴から解放済みポジションを取得します。
  Future<List<String>> fetchUnlockedPositions(
      {int? expectedSessionVersion}) async {
    // 直前の完了同期を待ち、履歴登録後の一覧を取得します。
    await _pendingWrite;
    final headers = await _headers(expectedSessionVersion);
    _assertSessionVersion(expectedSessionVersion);
    final response = await get('game/clear-history', headers: headers);
    final data = _data(response);
    final positions = data?['positions'];
    return positions is List
        ? positions.whereType<String>().toList()
        : <String>[];
  }

  /// 新しい育成サイクルをサーバーへ作成します。
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async {
    // 旧サイクルの同期完了前に新サイクルを作成すると、終了直前の状態で
    // 新しい開始状態が上書きされるため、書き込みを直列化します。
    await _pendingWrite;
    final headers = await _headers(expectedSessionVersion);
    _assertSessionVersion(expectedSessionVersion);
    final response = await post(
      'game/start',
      {
        'stage_code': stageCode,
        'parameters': parameters,
        if (forceRestart) 'force_restart': true,
      },
      headers: headers,
    );
    return _data(response) ?? <String, dynamic>{};
  }

  /// デバッグ用に、ログイン会員の育成ゲームデータを初回状態へ削除します。
  Future<Map<String, dynamic>> resetDebugState(
      {int? expectedSessionVersion}) async {
    await _pendingWrite;
    final headers = await _headers(expectedSessionVersion);
    _assertSessionVersion(expectedSessionVersion);
    final response = await post('game/debug/reset', null, headers: headers);
    return _data(response) ?? <String, dynamic>{};
  }

  /// デバッグ用に、現在の育成サイクルの日次アクション利用履歴をリセットします。
  Future<Map<String, dynamic>> resetDebugDailyActionUsage({
    int? expectedSessionVersion,
  }) async {
    final write = _pendingWrite.then((_) async {
      final headers = await _headers(expectedSessionVersion);
      _assertSessionVersion(expectedSessionVersion);
      final response = await post(
        'game/debug/reset-daily-actions',
        null,
        headers: headers,
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
    int? expectedSessionVersion,
  }) async {
    final write = _pendingWrite.then((_) async {
      final headers = await _headers(expectedSessionVersion);
      _assertSessionVersion(expectedSessionVersion);
      final response = await post(
        'game/debug/sync-time',
        {
          'stage_code': stageCode,
          'parameters': parameters,
          'lock_version': lockVersion,
        },
        headers: headers,
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
    String? actionIdempotencyKey,
    int? expectedSessionVersion,
    double? actionScore,
    double? actionEffectMultiplier,
    String? actionResultCode,
    String? actionResultPolicy,
    int? actionAttemptCount,
    int? actionSuccessCount,
    int? actionSuccessfulReactionTotalUs,
    bool debugBypassCooldown = false,
    String status = 'playing',
  }) async {
    final hasTackleMetadata = actionResultPolicy != null ||
        actionAttemptCount != null ||
        actionSuccessCount != null ||
        actionSuccessfulReactionTotalUs != null;
    if (hasTackleMetadata &&
        (actionCode != 'tackle' ||
            actionResultPolicy != 'tackle_v2_750_penalty_mean' ||
            actionAttemptCount != 3 ||
            actionSuccessCount == null ||
            actionSuccessCount < 0 ||
            actionSuccessCount > 3 ||
            actionSuccessfulReactionTotalUs == null ||
            actionSuccessfulReactionTotalUs < 0 ||
            actionSuccessfulReactionTotalUs > actionSuccessCount * 750000)) {
      throw ArgumentError('Incomplete or invalid tackle action metadata');
    }
    final write = _pendingWrite.then((_) async {
      final headers = await _headers(expectedSessionVersion);
      _assertSessionVersion(expectedSessionVersion);
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
              'idempotency_key': actionIdempotencyKey ??
                  '$cycleNo-${_clock.elapsedMicroseconds}-$actionCode',
              'result_code': actionResultCode ?? 'completed',
              if (hasTackleMetadata) ...{
                'result_policy': actionResultPolicy,
                'attempt_count': actionAttemptCount,
                'success_count': actionSuccessCount,
                'successful_reaction_total_us': actionSuccessfulReactionTotalUs,
              },
              if (debugBypassCooldown) 'debug_bypass_cooldown': true,
              if (actionScore != null) 'score': actionScore,
              if (actionEffectMultiplier != null)
                'effect_multiplier': actionEffectMultiplier,
            },
        },
        headers: headers,
      );
      return _data(response) ?? <String, dynamic>{};
    });
    // 次の取得が書き込み完了を待てるよう、エラーを吸収したFutureを保持します。
    _pendingWrite = write.then<void>((_) {}, onError: (_, __) {});
    return write;
  }

  /// 認証ヘッダーを作成します。
  Future<Map<String, String>> _headers([int? expectedSessionVersion]) async {
    _assertSessionVersion(expectedSessionVersion);
    final token = await AuthToken().getAccessToken();
    _assertSessionVersion(expectedSessionVersion);
    if (token == null || token.isEmpty) {
      throw Exception('認証が必要です。');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  void _assertSessionVersion(int? expectedSessionVersion) {
    if (expectedSessionVersion != null &&
        AuthToken.sessionVersion != expectedSessionVersion) {
      throw const AuthSessionChangedException();
    }
  }

  /// GetConnectのレスポンスをAPIデータへ変換します。
  Map<String, dynamic>? _data(Response<dynamic> response) {
    if (response.hasError) {
      final body = response.body;
      final message = body is Map ? body['message']?.toString() : null;
      throw TrainingGameApiException(
        statusCode: response.statusCode,
        message: message ?? response.statusText ?? '育成ゲームAPIエラー',
        retryAfter: parseRetryAfterHeader(response.headers),
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

  /// Retry-After を秒数または HTTP-date として読み取ります。
  /// ヘッダー名はHTTP仕様に従い、大文字小文字を区別しません。
  static Duration? parseRetryAfterHeader(
    Map<String, String>? headers, {
    DateTime? now,
  }) {
    if (headers == null) return null;
    String? value;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        value = entry.value.trim();
        break;
      }
    }
    if (value == null || value.isEmpty) return null;

    final seconds = int.tryParse(value);
    if (seconds != null) {
      if (seconds < 0 || seconds > const Duration(days: 36500).inSeconds) {
        return null;
      }
      return Duration(seconds: seconds);
    }

    try {
      final retryAt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseUtc(value);
      final delay = retryAt.difference((now ?? DateTime.now()).toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    }
  }
}

/// 育成ゲームAPIのHTTPエラーを、通信障害と業務エラーに分類できる例外です。
class TrainingGameApiException implements Exception {
  const TrainingGameApiException({
    required this.statusCode,
    required this.message,
    this.retryAfter,
  });

  final int? statusCode;
  final String message;
  final Duration? retryAfter;

  @override
  String toString() => 'TrainingGameApiException($statusCode): $message';
}
