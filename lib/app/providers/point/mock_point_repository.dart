import 'dart:async';

import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/point_repository.dart';

class MockPointRepository implements PointRepository {
  MockPointRepository._();

  static final MockPointRepository instance = MockPointRepository._();

  PointAccount _account = PointAccount(
    balance: 1250,
    lifetimeEarned: 12500,
    lifetimeSpent: 11250,
    lastTransactionAt: DateTime(2026, 7, 27, 10, 24),
  );

  final List<PointLot> _lots = [
    PointLot(
      id: 'LOT-0001',
      reason: '来場ポイント',
      originalAmount: 100,
      remainingAmount: 100,
      grantedAt: DateTime(2026, 5, 31),
      expiresAt: DateTime(2026, 8, 31, 23, 59, 59),
    ),
    PointLot(
      id: 'LOT-0002',
      reason: '来場ポイント',
      originalAmount: 50,
      remainingAmount: 50,
      grantedAt: DateTime(2026, 6, 30),
      expiresAt: DateTime(2026, 9, 30, 23, 59, 59),
    ),
  ];

  final List<PointTransaction> _transactions = [
    PointTransaction(
      id: 'TX-0004',
      type: PointTransactionType.grant,
      title: 'ホームゲーム来場',
      amount: 100,
      balanceAfter: 1350,
      occurredAt: DateTime(2026, 7, 27, 10, 24),
      sourceType: 'qr',
      sourceId: 'GAME-20260727',
      expiresAt: DateTime(2026, 10, 31, 23, 59, 59),
      venue: '江東区夢の島競技場',
    ),
    PointTransaction(
      id: 'TX-0003',
      type: PointTransactionType.spend,
      title: '景品交換：限定タオル',
      amount: -1000,
      balanceAfter: 350,
      occurredAt: DateTime(2026, 7, 27, 10, 30),
      sourceType: 'reward',
      sourceId: 'REWARD-001',
      exchangeId: 'EX-000001',
    ),
    PointTransaction(
      id: 'TX-0002',
      type: PointTransactionType.expire,
      title: 'ポイント失効',
      amount: -50,
      balanceAfter: 300,
      occurredAt: DateTime(2026, 7, 1),
      sourceType: 'system',
    ),
    PointTransaction(
      id: 'TX-0001',
      type: PointTransactionType.reversal,
      title: '交換取消・返却',
      amount: 1000,
      balanceAfter: 1300,
      occurredAt: DateTime(2026, 6, 30, 18, 12),
      sourceType: 'admin',
      reversedTransactionId: 'TX-0000',
    ),
  ];

  final List<PointReward> _rewards = [
    PointReward(
      id: 'REWARD-001',
      name: 'BlueSharks 限定タオル',
      description: '会場限定デザインのオリジナルタオルです。',
      requiredPoints: 1000,
      exchangeStartsAt: DateTime(2026, 7, 27),
      exchangeEndsAt: DateTime(2026, 8, 31, 23, 59, 59),
      pickupLocation: '会場インフォメーション',
      notice: 'スタッフの前で交換してください。',
      status: PointRewardStatus.available,
    ),
    PointReward(
      id: 'REWARD-002',
      name: '選手カード',
      description: '選手の限定ビジュアルカードです。',
      requiredPoints: 2000,
      exchangeStartsAt: DateTime(2026, 7, 27),
      exchangeEndsAt: DateTime(2026, 8, 31, 23, 59, 59),
      pickupLocation: '会場インフォメーション',
      notice: 'スタッフの前で交換してください。',
      status: PointRewardStatus.insufficientPoints,
    ),
    PointReward(
      id: 'REWARD-003',
      name: '限定ステッカー',
      description: 'BlueSharksロゴの限定ステッカーです。',
      requiredPoints: 500,
      exchangeStartsAt: DateTime(2026, 6, 1),
      exchangeEndsAt: DateTime(2026, 7, 20, 23, 59, 59),
      pickupLocation: '会場インフォメーション',
      notice: '受付期間は終了しました。',
      status: PointRewardStatus.ended,
    ),
  ];

  final Map<String, PointRewardExchange> _exchanges = {
    'EX-000001': PointRewardExchange(
      id: 'EX-000001',
      exchangeNumber: 'BS-7K3M-26',
      rewardId: 'REWARD-001',
      rewardName: 'BlueSharks 限定タオル',
      spentPoints: 1000,
      requestedAt: DateTime(2026, 7, 27, 10, 30),
      maskedMemberId: 'C-******01',
    ),
  };
  final Set<String> _idempotencyKeys = {};

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<PointAccount> getAccount() async {
    await _delay();
    return _account;
  }

  @override
  Future<List<PointLot>> getExpiringLots() async {
    await _delay();
    final result = [..._lots]
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return result;
  }

  @override
  Future<PointQrToken> getQrToken() async {
    await _delay();
    return PointQrToken(
      token: 'bspt_mock_9f4c7a2e1d8b6c3a',
      maskedMemberId: 'C-******01',
      issuedAt: DateTime(2026, 7, 27),
    );
  }

  @override
  Future<List<PointTransaction>> getTransactions() async {
    await _delay();
    return List.unmodifiable(_transactions);
  }

  @override
  Future<PointTransaction> getTransaction(String id) async {
    await _delay();
    return _transactions.firstWhere((transaction) => transaction.id == id);
  }

  @override
  Future<PointRanking> getRanking(PointRankingType type) async {
    await _delay();
    final periodName = switch (type) {
      PointRankingType.monthly => '2026年7月',
      PointRankingType.yearly => '2026年',
      PointRankingType.season => '2026-27',
    };
    return PointRanking(
      type: type,
      periodName: periodName,
      entries: const [
        PointRankingEntry(
            customerId: 1, rank: 1, nickname: 'サメ太郎', points: 12500),
        PointRankingEntry(
            customerId: 2, rank: 2, nickname: 'BlueFan', points: 11800),
        PointRankingEntry(
            customerId: 3, rank: 2, nickname: 'KOTO12', points: 11800),
        PointRankingEntry(
            customerId: 4, rank: 4, nickname: 'RUGBY5', points: 10400),
      ],
      myEntry: const PointRankingEntry(
        customerId: 128,
        rank: 128,
        nickname: 'あなた',
        points: 2350,
      ),
      calculatedAt: DateTime(2026, 7, 28),
    );
  }

  @override
  Future<List<PointReward>> getRewards() async {
    await _delay();
    return List.unmodifiable(_rewards);
  }

  @override
  Future<PointReward> getReward(String id) async {
    await _delay();
    return _rewards.firstWhere((reward) => reward.id == id);
  }

  @override
  Future<PointRewardExchange> exchangeReward(
    String rewardId, {
    required String idempotencyKey,
  }) async {
    await _delay();
    if (!_idempotencyKeys.add(idempotencyKey)) {
      throw const PointOperationException(
        'duplicate_request',
        'この交換処理はすでに受け付けています。',
      );
    }
    final reward = await getReward(rewardId);
    if (reward.status == PointRewardStatus.ended) {
      throw const PointOperationException('reward_ended', 'この景品の受付は終了しました。');
    }
    if (_account.balance < reward.requiredPoints) {
      throw const PointOperationException(
        'insufficient_points',
        'ポイントが不足しています。',
      );
    }

    final now = DateTime.now();
    final exchangeId =
        'EX-${(_exchanges.length + 1).toString().padLeft(6, '0')}';
    final exchange = PointRewardExchange(
      id: exchangeId,
      exchangeNumber: 'BS-MOCK-${_exchanges.length + 1}',
      rewardId: reward.id,
      rewardName: reward.name,
      spentPoints: reward.requiredPoints,
      requestedAt: now,
      maskedMemberId: 'C-******01',
    );
    final nextBalance = _account.balance - reward.requiredPoints;
    _account = _account.copyWith(
      balance: nextBalance,
      lifetimeSpent: _account.lifetimeSpent + reward.requiredPoints,
      lastTransactionAt: now,
    );
    _exchanges[exchangeId] = exchange;
    _transactions.insert(
      0,
      PointTransaction(
        id: 'TX-${(_transactions.length + 1).toString().padLeft(4, '0')}',
        type: PointTransactionType.spend,
        title: '景品交換：${reward.name}',
        amount: -reward.requiredPoints,
        balanceAfter: nextBalance,
        occurredAt: now,
        sourceType: 'reward',
        sourceId: reward.id,
        exchangeId: exchangeId,
      ),
    );
    return exchange;
  }

  @override
  Future<PointRewardExchange> getExchange(String id) async {
    await _delay();
    final exchange = _exchanges[id];
    if (exchange == null) {
      throw const PointOperationException('not_found', '交換履歴が見つかりません。');
    }
    return exchange;
  }
}
