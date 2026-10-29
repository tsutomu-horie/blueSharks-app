enum PointTransactionType { grant, spend, expire, reversal, adjust }

enum PointHistoryFilter { all, earned, spent, expired }

enum PointQrResult { idle, pending, granted, rejected, failed, awaitingSync }

class PointQrResultArguments {
  const PointQrResultArguments({required this.result, this.failureCode});

  final PointQrResult result;
  final String? failureCode;
}

enum PointRewardStatus {
  available,
  insufficientPoints,
  ended,
  customerLimitReached,
}

enum PointRankingType { monthly, yearly, season }

class PointAccount {
  const PointAccount({
    required this.balance,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    this.exchangeableBalance,
    this.lastTransactionAt,
  });

  final int balance;
  final int? exchangeableBalance;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final DateTime? lastTransactionAt;

  int get exchangeableBalanceForRedemption => exchangeableBalance ?? balance;

  PointAccount copyWith({
    int? balance,
    int? exchangeableBalance,
    int? lifetimeEarned,
    int? lifetimeSpent,
    DateTime? lastTransactionAt,
  }) {
    return PointAccount(
      balance: balance ?? this.balance,
      exchangeableBalance: exchangeableBalance ?? this.exchangeableBalance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeSpent: lifetimeSpent ?? this.lifetimeSpent,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
    );
  }
}

class PointLot {
  const PointLot({
    required this.id,
    required this.reason,
    required this.originalAmount,
    required this.remainingAmount,
    required this.grantedAt,
    required this.expiresAt,
  });

  final String id;
  final String reason;
  final int originalAmount;
  final int remainingAmount;
  final DateTime grantedAt;
  final DateTime expiresAt;
}

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.balanceAfter,
    required this.occurredAt,
    required this.sourceType,
    this.sourceId,
    this.reversedTransactionId,
    this.expiresAt,
    this.venue,
    this.exchangeId,
  });

  final String id;
  final PointTransactionType type;
  final String title;
  final int amount;
  final int balanceAfter;
  final DateTime occurredAt;
  final String sourceType;
  final String? sourceId;
  final String? reversedTransactionId;
  final DateTime? expiresAt;
  final String? venue;
  final String? exchangeId;
}

class PointRankingEntry {
  const PointRankingEntry({
    this.customerId,
    this.rank,
    required this.nickname,
    required this.points,
  });

  final int? customerId;
  final int? rank;
  final String nickname;
  final int points;
}

class PointRanking {
  const PointRanking({
    required this.type,
    required this.periodName,
    required this.entries,
    required this.myEntry,
    required this.calculatedAt,
  });

  final PointRankingType type;
  final String periodName;
  final List<PointRankingEntry> entries;
  final PointRankingEntry myEntry;
  final DateTime calculatedAt;
}

class PointReward {
  const PointReward({
    required this.id,
    required this.offerId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.requiredPoints,
    this.perCustomerLimit = 0,
    this.customerExchangeCount,
    this.exchangeStartsAt,
    this.exchangeEndsAt,
    required this.pickupLocation,
    required this.notice,
    required this.status,
  });

  final String id;
  final String offerId;
  final String name;
  final String description;
  final String? imageUrl;
  final int requiredPoints;
  final int perCustomerLimit;
  final int? customerExchangeCount;
  final DateTime? exchangeStartsAt;
  final DateTime? exchangeEndsAt;
  final String pickupLocation;
  final String notice;
  final PointRewardStatus status;

  PointReward copyWith({
    int? customerExchangeCount,
    PointRewardStatus? status,
  }) {
    return PointReward(
      id: id,
      offerId: offerId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      requiredPoints: requiredPoints,
      perCustomerLimit: perCustomerLimit,
      customerExchangeCount:
          customerExchangeCount ?? this.customerExchangeCount,
      exchangeStartsAt: exchangeStartsAt,
      exchangeEndsAt: exchangeEndsAt,
      pickupLocation: pickupLocation,
      notice: notice,
      status: status ?? this.status,
    );
  }
}

class PointRewardExchange {
  const PointRewardExchange({
    required this.id,
    required this.exchangeNumber,
    required this.rewardId,
    required this.rewardName,
    required this.spentPoints,
    required this.requestedAt,
    required this.maskedMemberId,
    this.deliveryToken,
    this.deliveryTokenExpiresAt,
  });

  final String id;
  final String exchangeNumber;
  final String rewardId;
  final String rewardName;
  final int spentPoints;
  final DateTime requestedAt;
  final String maskedMemberId;
  final String? deliveryToken;
  final DateTime? deliveryTokenExpiresAt;
}

class PointQrToken {
  const PointQrToken({
    required this.token,
    required this.maskedMemberId,
    required this.issuedAt,
  });

  final String token;
  final String maskedMemberId;
  final DateTime issuedAt;
}

class PointOperationException implements Exception {
  const PointOperationException(this.code, this.message);

  final String code;
  final String message;
}
