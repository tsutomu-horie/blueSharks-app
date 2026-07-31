import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/point_repository.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class ApiPointRepository extends GetConnect implements PointRepository {
  ApiPointRepository._() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
    httpClient.timeout = const Duration(seconds: 15);
  }

  static final ApiPointRepository instance = ApiPointRepository._();

  @override
  Future<PointAccount> getAccount() async {
    final data = _asMap(await _getData('points'));
    return PointAccount(
      balance: _asInt(data['balance']),
      lifetimeEarned: _asInt(data['lifetime_earned']),
      lifetimeSpent: _asInt(data['lifetime_spent']),
      lastTransactionAt: _asDateTime(data['last_transaction_at']),
    );
  }

  @override
  Future<List<PointLot>> getExpiringLots() async {
    final data = _asMap(await _getData('points/expirations'));
    final items = _asList(data['items']);
    return items.map((item) {
      final json = _asMap(item);
      final expirationDate = _asDateTime(json['expiration_date'])!;
      final amount = _asInt(json['amount']);
      return PointLot(
        id: 'expiration-${json['expiration_date']}',
        reason: 'ポイント失効予定',
        originalAmount: amount,
        remainingAmount: amount,
        grantedAt: expirationDate,
        expiresAt: expirationDate,
      );
    }).toList();
  }

  @override
  Future<PointQrToken> getQrToken() async {
    final data = _asMap(await _getData('points/qr'));
    return PointQrToken(
      token: data['payload'] as String,
      maskedMemberId: '',
      issuedAt: _asDateTime(data['issued_at'])!,
    );
  }

  @override
  Future<List<PointTransaction>> getTransactions() async {
    final data = _asList(
      await _getData('points/transactions?per_page=100'),
    );
    return data.map((item) => _transactionFromJson(_asMap(item))).toList();
  }

  @override
  Future<PointTransaction> getTransaction(String id) async {
    final transactions = await getTransactions();
    try {
      return transactions.firstWhere((item) => item.id == id);
    } on StateError {
      throw const PointOperationException(
        'transaction_not_found',
        'ポイント履歴が見つかりません。',
      );
    }
  }

  @override
  Future<PointRanking> getRanking(PointRankingType type) async {
    final typeValue = type.name;
    final periods = _asList(
      await _getData('points/rankings?period_type=$typeValue'),
    );
    if (periods.isEmpty) {
      throw const PointOperationException(
        'ranking_not_published',
        '公開中のランキングはありません。',
      );
    }

    final period = _asMap(periods.first);
    final data = _asMap(
      await _getData('points/rankings/${period['id']}?limit=100'),
    );
    final detailPeriod = _asMap(data['period']);
    final entries = _asList(data['entries'])
        .map((item) => _rankingEntryFromJson(_asMap(item)))
        .toList();
    final me = _rankingEntryFromJson(_asMap(data['me']));

    return PointRanking(
      type: type,
      periodName: detailPeriod['name'] as String,
      entries: entries,
      myEntry: me,
      calculatedAt: _asDateTime(detailPeriod['published_at']) ?? DateTime.now(),
    );
  }

  @override
  Future<List<PointReward>> getRewards() async {
    final data = _asList(await _getData('points/rewards?per_page=100'));
    return data.map((item) => _rewardFromJson(_asMap(item))).toList();
  }

  @override
  Future<PointReward> getReward(String id) async {
    final data = _asMap(await _getData('points/rewards/$id'));
    return _rewardFromJson(data);
  }

  @override
  Future<PointRewardExchange> exchangeReward(
    String rewardId, {
    required String idempotencyKey,
  }) async {
    final reward = await getReward(rewardId);
    final data = _asMap(
      await _postData(
        'points/reward-exchanges',
        {
          'offer_id': int.parse(reward.offerId),
          'idempotency_key': idempotencyKey,
        },
      ),
    );
    return _exchangeFromResponse(data);
  }

  @override
  Future<PointRewardExchange> getExchange(String id) async {
    final exchange = _asMap(
      await _getData('points/reward-exchanges/$id'),
    );
    if (exchange['status'] != 'consumed') {
      return _exchangeFromJson(exchange);
    }
    final data = _asMap(
      await _postData('points/reward-exchanges/$id/delivery-token', {}),
    );
    return _exchangeFromResponse(data);
  }

  Future<dynamic> _getData(String path) async {
    final response = await get(path, headers: await _headers());
    return _handle(response);
  }

  Future<dynamic> _postData(String path, Map<String, dynamic> body) async {
    final response = await post(path, body, headers: await _headers());
    return _handle(response);
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthToken().getAccessToken();
    if (token == null || token.isEmpty) {
      throw const PointOperationException(
        'unauthenticated',
        'ポイント機能を利用するにはログインが必要です。',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  dynamic _handle(Response<dynamic> response) {
    if (!response.hasError) {
      final body = response.body;
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    final body = response.body;
    final error = body is Map ? body['error'] : null;
    final code = error is Map
        ? (error['code']?.toString() ?? 'http_${response.statusCode}')
        : 'http_${response.statusCode}';
    final serverMessage = error is Map ? error['message']?.toString() : null;
    throw PointOperationException(
      code,
      _messageFor(code, response.statusCode, serverMessage),
    );
  }

  String _messageFor(String code, int? statusCode, String? serverMessage) {
    return switch (code) {
      'INSUFFICIENT_POINT_BALANCE' ||
      'INSUFFICIENT_USABLE_POINTS' =>
        'ポイントが不足しています。',
      'REWARD_NOT_AVAILABLE' => 'この景品は現在交換できません。',
      'REWARD_OFFER_OUTSIDE_PERIOD' => '景品の交換期間外です。',
      'REWARD_CUSTOMER_LIMIT_REACHED' => 'この景品の交換上限に達しています。',
      'REWARD_TOTAL_LIMIT_REACHED' || 'REWARD_OUT_OF_STOCK' => '景品の在庫がありません。',
      _ when statusCode == 401 => 'ログインの有効期限が切れました。再度ログインしてください。',
      _ when statusCode == 404 => '対象のデータが見つかりません。',
      _ => serverMessage?.isNotEmpty == true
          ? serverMessage!
          : '通信に失敗しました。時間をおいて再度お試しください。',
    };
  }

  PointTransaction _transactionFromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? _asMap(json['metadata'])
        : <String, dynamic>{};
    return PointTransaction(
      id: json['id'].toString(),
      type: PointTransactionType.values.byName(json['type'] as String),
      title: json['title'] as String? ?? 'ポイント処理',
      amount: _asInt(json['amount']),
      balanceAfter: _asInt(json['balance_after']),
      occurredAt: _asDateTime(json['occurred_at'])!,
      sourceType: json['source_type'] as String? ?? '',
      sourceId: json['source_id']?.toString(),
      reversedTransactionId: json['reversed_transaction_id']?.toString(),
      expiresAt: _asDateTime(json['expires_at']),
      venue: metadata['venue_name'] as String?,
      exchangeId: json['exchange_id']?.toString(),
    );
  }

  PointRankingEntry _rankingEntryFromJson(Map<String, dynamic> json) {
    return PointRankingEntry(
      rank: json['rank'] == null ? null : _asInt(json['rank']),
      nickname: json['display_name'] as String? ?? '',
      points: _asInt(json['points']),
    );
  }

  PointReward _rewardFromJson(Map<String, dynamic> json) {
    final offers = _asList(json['offers']);
    if (offers.isEmpty) {
      throw const PointOperationException(
        'reward_offer_not_found',
        '交換可能な景品設定が見つかりません。',
      );
    }
    final offer = _asMap(offers.first);
    return PointReward(
      id: json['id'].toString(),
      offerId: offer['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      requiredPoints: _asInt(json['required_points']),
      exchangeStartsAt: _asDateTime(offer['starts_at']),
      exchangeEndsAt: _asDateTime(offer['ends_at']),
      pickupLocation: json['pickup_location'] as String? ?? '',
      notice: json['terms'] as String? ?? '',
      status: PointRewardStatus.available,
    );
  }

  PointRewardExchange _exchangeFromResponse(Map<String, dynamic> data) {
    final exchange = _asMap(data['exchange']);
    return _exchangeFromJson(
      exchange,
      deliveryToken: data['delivery_token'] as String?,
      deliveryTokenExpiresAt: _asDateTime(data['delivery_token_expires_at']),
    );
  }

  PointRewardExchange _exchangeFromJson(
    Map<String, dynamic> exchange, {
    String? deliveryToken,
    DateTime? deliveryTokenExpiresAt,
  }) {
    return PointRewardExchange(
      id: exchange['id'].toString(),
      exchangeNumber: exchange['exchange_no'] as String,
      rewardId: exchange['reward_id'].toString(),
      rewardName: exchange['reward_name_snapshot'] as String,
      spentPoints: _asInt(exchange['spent_points']),
      requestedAt: _asDateTime(exchange['requested_at'])!,
      maskedMemberId: '',
      deliveryToken: deliveryToken,
      deliveryTokenExpiresAt: deliveryTokenExpiresAt,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  List<dynamic> _asList(dynamic value) {
    return List<dynamic>.from(value as List);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.parse(value.toString()).toLocal();
  }
}
