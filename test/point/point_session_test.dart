import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/point_repository.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';

class SessionRepository implements PointRepository {
  int balance = 5000;
  int reads = 0;
  DateTime serverNow = DateTime.utc(2026, 10, 28);
  PointAccount Function(DateTime now)? accountAt;
  Completer<PointAccount>? pending;
  Completer<PointQrToken>? pendingQr;
  Completer<PointRewardExchange>? pendingExchange;
  PointReward? rewardToLoad;
  List<PointRewardExchange> exchangeResponses = [];
  int exchangeRequests = 0;

  @override
  Future<PointAccount> getAccount() {
    reads++;
    return pending?.future ??
        Future.value(
          accountAt?.call(serverNow) ??
              PointAccount(
                balance: balance,
                lifetimeEarned: balance,
                lifetimeSpent: 0,
              ),
        );
  }

  @override
  Future<List<PointLot>> getExpiringLots() async => [];

  @override
  Future<PointQrToken> getQrToken() => pendingQr!.future;

  @override
  Future<List<PointTransaction>> getTransactions() async => [];

  @override
  Future<PointReward> getReward(String id) async => rewardToLoad!;

  @override
  Future<PointRewardExchange> exchangeReward(
    String rewardId, {
    required String idempotencyKey,
  }) {
    exchangeRequests++;
    return pendingExchange?.future ??
        Future.value(exchangeResponses[exchangeRequests - 1]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> drain() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  String? token;
  late SessionRepository repository;
  late PointController controller;

  setUp(() async {
    token = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (call) async {
          switch (call.method) {
            case 'read':
              return token;
            case 'write':
              token = call.arguments['value'] as String;
              return null;
            case 'delete':
            case 'deleteAll':
              token = null;
              return null;
          }
          return null;
        });
    repository = SessionRepository();
    controller = PointController(repository: repository)..onInit();
    await controller.initialize();
  });

  tearDown(() {
    controller.onClose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null);
  });

  test(
    'login refreshes an already initialized anonymous points controller',
    () async {
      expect(controller.isAuthenticated.value, false);
      await AuthToken().saveAccessToken('test-session-a');
      await drain();
      expect(controller.isAuthenticated.value, true);
      expect(controller.account.value?.balance, 5000);
      expect(repository.reads, 1);
    },
  );

  test('logout immediately clears account and private point data', () async {
    await AuthToken().saveAccessToken('test-session-a');
    await drain();
    controller.errorMessage.value = 'old session error';
    controller.qrToken.value = PointQrToken(
      token: 'test-only-qr',
      maskedMemberId: 'test',
      issuedAt: DateTime(2026),
    );
    controller.transactions.add(
      PointTransaction(
        id: 'old',
        type: PointTransactionType.grant,
        title: 'test',
        amount: 5000,
        balanceAfter: 5000,
        occurredAt: DateTime(2026),
        sourceType: 'test',
      ),
    );
    final logout = AuthToken().deleteToken();
    await logout;
    await drain();
    expect(controller.isAuthenticated.value, false);
    expect(controller.account.value, null);
    expect(controller.errorMessage.value, null);
    expect(controller.qrToken.value, null);
    expect(controller.transactions, isEmpty);
  });

  test('late account response cannot restore data after logout', () async {
    repository.pending = Completer<PointAccount>();
    await AuthToken().saveAccessToken('test-session-a');
    await drain();
    final oldLoad = controller.initialize();
    await AuthToken().deleteToken();
    await drain();
    repository.pending!.complete(
      const PointAccount(balance: 5000, lifetimeEarned: 5000, lifetimeSpent: 0),
    );
    await oldLoad;
    expect(controller.isAuthenticated.value, false);
    expect(controller.account.value, null);
    expect(controller.isLoading.value, false);
  });

  test(
    'account switch ignores old failures and loads the new balance',
    () async {
      repository.pending = Completer<PointAccount>();
      await AuthToken().saveAccessToken('test-session-a');
      await drain();
      final oldLoad = controller.initialize();
      final old = repository.pending!;
      repository.pending = null;
      repository.balance = 10;
      await AuthToken().saveAccessToken('test-session-b');
      await drain();
      old.completeError(const PointOperationException('old', 'old failure'));
      await oldLoad;
      expect(controller.account.value?.balance, 10);
      expect(controller.errorMessage.value, null);
      expect(controller.isLoading.value, false);
    },
  );

  test(
    'refreshed summary drops expired points at the exact boundary',
    () async {
      final expiresAt = DateTime.utc(2026, 10, 29);
      const beforeExpiry = PointAccount(
        balance: 100,
        exchangeableBalance: 40,
        lifetimeEarned: 100,
        lifetimeSpent: 0,
      );
      const atExpiry = PointAccount(
        balance: 60,
        exchangeableBalance: 0,
        lifetimeEarned: 100,
        lifetimeSpent: 0,
      );
      final reward = PointReward(
        id: 'EXPIRING-REWARD',
        offerId: 'EXPIRING-OFFER',
        name: 'テスト景品',
        description: '',
        requiredPoints: 1,
        exchangeStartsAt: DateTime(2026),
        exchangeEndsAt: DateTime(2027),
        pickupLocation: '',
        notice: '',
        status: PointRewardStatus.available,
      );
      repository.accountAt = (now) =>
          now.isBefore(expiresAt) ? beforeExpiry : atExpiry;
      repository.serverNow = expiresAt.subtract(
        const Duration(microseconds: 1),
      );
      await AuthToken().saveAccessToken('test-expiry-boundary');
      await drain();

      expect(controller.account.value?.balance, 100);
      expect(controller.account.value?.exchangeableBalanceForRedemption, 40);
      expect(controller.rewardStatusFor(reward), PointRewardStatus.available);

      repository.serverNow = expiresAt;
      await controller.loadOverview();

      expect(controller.account.value?.balance, 60);
      expect(controller.account.value?.exchangeableBalanceForRedemption, 0);
      expect(
        controller.rewardStatusFor(reward),
        PointRewardStatus.insufficientPoints,
      );
    },
  );

  test('late QR response cannot restore another session QR', () async {
    await AuthToken().saveAccessToken('test-session-a');
    await drain();
    repository.pendingQr = Completer<PointQrToken>();
    final request = controller.loadQr();
    await AuthToken().deleteToken();
    await drain();
    repository.pendingQr!.complete(
      PointQrToken(
        token: 'test-only-old-qr',
        maskedMemberId: 'test',
        issuedAt: DateTime(2026),
      ),
    );
    await request;
    expect(controller.qrToken.value, null);
    expect(controller.isAuthenticated.value, false);
  });

  test('concurrent reward exchange taps send only one request', () async {
    repository.pendingExchange = Completer<PointRewardExchange>();
    controller.selectedReward.value = const PointReward(
      id: 'REWARD-1',
      offerId: 'OFFER-1',
      name: 'テスト景品',
      description: '',
      requiredPoints: 100,
      pickupLocation: '',
      notice: '',
      status: PointRewardStatus.available,
    );

    final firstRequest = controller.exchangeSelectedReward();
    final duplicateRequest = controller.exchangeSelectedReward();
    repository.pendingExchange!.completeError(
      const PointOperationException(
        'REWARD_CUSTOMER_LIMIT_REACHED',
        'この景品の交換上限に達しています。',
      ),
    );
    expect(await firstRequest, isFalse);
    expect(await duplicateRequest, isFalse);
    final exchangeRequestCount = repository.exchangeRequests;
    expect(exchangeRequestCount, 1);
    expect(repository.exchangeRequests, 1);
    expect(controller.errorMessage.value, 'この景品の交換上限に達しています。');
    expect(
      controller.rewardStatusFor(controller.selectedReward.value!),
      PointRewardStatus.customerLimitReached,
    );
    expect(controller.isProcessing.value, isFalse);
  });

  test('successful exchanges accumulate toward the customer limit', () async {
    const reward = PointReward(
      id: 'REWARD-2',
      offerId: 'OFFER-2',
      name: 'テスト景品',
      description: '',
      requiredPoints: 100,
      perCustomerLimit: 2,
      customerExchangeCount: 0,
      pickupLocation: '',
      notice: '',
      status: PointRewardStatus.available,
    );
    PointRewardExchange exchange(int id) => PointRewardExchange(
      id: 'EX-$id',
      exchangeNumber: 'EX-$id',
      rewardId: reward.id,
      rewardName: reward.name,
      spentPoints: reward.requiredPoints,
      requestedAt: DateTime(2026),
      maskedMemberId: 'C-***',
    );
    controller.selectedReward.value = reward;
    controller.rewards.assignAll([reward]);
    repository.exchangeResponses = [exchange(1), exchange(2)];

    expect(await controller.exchangeSelectedReward(), isTrue);
    expect(controller.selectedReward.value?.customerExchangeCount, 1);
    expect(
      controller.rewardStatusFor(controller.selectedReward.value!),
      PointRewardStatus.available,
    );

    expect(await controller.exchangeSelectedReward(), isTrue);
    expect(controller.selectedReward.value?.customerExchangeCount, 2);
    expect(
      controller.rewardStatusFor(controller.selectedReward.value!),
      PointRewardStatus.customerLimitReached,
    );
    expect(
      controller.rewardStatusFor(controller.rewards.single),
      PointRewardStatus.customerLimitReached,
    );
  });

  test('a refreshed reward clears a stale customer limit override', () async {
    const reward = PointReward(
      id: 'REWARD-3',
      offerId: 'OFFER-3',
      name: 'テスト景品',
      description: '',
      requiredPoints: 100,
      perCustomerLimit: 2,
      customerExchangeCount: 1,
      pickupLocation: '',
      notice: '',
      status: PointRewardStatus.available,
    );
    const staleReward = PointReward(
      id: 'REWARD-3',
      offerId: 'OFFER-3',
      name: 'テスト景品',
      description: '',
      requiredPoints: 100,
      perCustomerLimit: 1,
      customerExchangeCount: 1,
      pickupLocation: '',
      notice: '',
      status: PointRewardStatus.customerLimitReached,
    );
    controller.rewards.assignAll([
      staleReward,
    ]);
    controller.customerLimitReachedRewardIds.add(reward.id);
    repository.rewardToLoad = reward;

    await controller.loadReward(reward.id);

    expect(controller.customerLimitReachedRewardIds.contains(reward.id), isFalse);
    expect(
      controller.rewardStatusFor(controller.rewards.single),
      PointRewardStatus.available,
    );
  });

  test('closed controller does not refresh on a session change', () async {
    controller.onClose();
    await AuthToken().saveAccessToken('test-session-a');
    await drain();
    expect(repository.reads, 0);
  });
}
