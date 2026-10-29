import 'dart:async';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/api_point_repository.dart';
import 'package:koto_blue_sharks/app/providers/point/point_repository.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';

class PointController extends GetxController {
  PointController({PointRepository? repository})
    : repository = repository ?? ApiPointRepository.instance;

  final PointRepository repository;

  final account = Rxn<PointAccount>();
  final expiringLots = <PointLot>[].obs;
  final transactions = <PointTransaction>[].obs;
  final rewards = <PointReward>[].obs;
  final ranking = Rxn<PointRanking>();
  final qrToken = Rxn<PointQrToken>();
  final selectedReward = Rxn<PointReward>();
  final selectedTransaction = Rxn<PointTransaction>();
  final selectedExchange = Rxn<PointRewardExchange>();
  final customerLimitReachedRewardIds = <String>{}.obs;

  final isLoading = false.obs;
  final isProcessing = false.obs;
  final isAuthenticated = RxnBool();
  final errorMessage = RxnString();
  final historyFilter = PointHistoryFilter.all.obs;
  final rankingType = PointRankingType.monthly.obs;
  final qrResult = PointQrResult.idle.obs;
  final qrFailureCode = RxnString();

  String? _transactionRequestId;
  String? _rewardRequestId;
  String? _exchangeRequestId;
  String? _pendingExchangeKey;
  String? _pendingExchangeRewardId;
  Future<void>? _initialization;
  int _activeLoadCount = 0;
  bool _disposed = false;

  bool _current(int version) =>
      !_disposed && version == AuthToken.sessionVersion;

  void _sessionChanged(int version) {
    _initialization = null;
    _activeLoadCount = 0;
    isLoading.value = false;
    isProcessing.value = false;
    isAuthenticated.value = null;
    account.value = null;
    expiringLots.clear();
    transactions.clear();
    rewards.clear();
    ranking.value = null;
    qrToken.value = null;
    selectedReward.value = null;
    selectedTransaction.value = null;
    selectedExchange.value = null;
    customerLimitReachedRewardIds.clear();
    errorMessage.value = null;
    qrFailureCode.value = null;
    qrResult.value = PointQrResult.idle;
    _transactionRequestId = null;
    _rewardRequestId = null;
    _exchangeRequestId = null;
    _pendingExchangeKey = null;
    _pendingExchangeRewardId = null;
    // Session listeners run before token storage changes. Queue the read, but
    // never await it from the listener (which would deadlock token mutation).
    unawaited(initialize());
  }

  @override
  void onClose() {
    _disposed = true;
    AuthToken.removeSessionChangeListener(_sessionChanged);
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    AuthToken.addSessionChangeListener(_sessionChanged);
    initialize();
  }

  Future<void> initialize() {
    if (_disposed) return Future<void>.value();
    final version = AuthToken.sessionVersion;
    return _initialization ??= _initialize(version).whenComplete(() {
      if (_current(version)) _initialization = null;
    });
  }

  Future<void> _initialize(int version) async {
    final snapshot = await AuthToken().readSessionSnapshot();
    if (!_current(version) || snapshot.sessionVersion != version) return;
    isAuthenticated.value = snapshot.token != null;
    if (snapshot.token != null) {
      await loadOverview();
    }
  }

  Future<void> loadOverview() async {
    await _run((current) async {
      final results = await Future.wait([
        repository.getAccount(),
        repository.getExpiringLots(),
      ]);
      if (!current()) return;
      account.value = results[0] as PointAccount;
      expiringLots.assignAll(results[1] as List<PointLot>);
    });
  }

  Future<void> loadQr() async {
    await _run((current) async {
      final token = await repository.getQrToken();
      if (!current()) return;
      qrToken.value = token;
      qrResult.value = PointQrResult.idle;
      qrFailureCode.value = null;
    });
  }

  Future<void> reissueQr() async {
    await _run((current) async {
      final token = await repository.reissueQrToken();
      if (!current()) return;
      qrToken.value = token;
      qrResult.value = PointQrResult.idle;
      qrFailureCode.value = null;
    });
  }

  Future<void> loadTransactions() async {
    await _run((current) async {
      final items = await repository.getTransactions();
      if (!current()) return;
      transactions.assignAll(items);
    });
  }

  Future<void> loadTransaction(String id) async {
    _transactionRequestId = id;
    selectedTransaction.value = null;
    await _run((current) async {
      final transaction = await repository.getTransaction(id);
      if (!current() || _transactionRequestId != id) {
        return;
      }
      selectedTransaction.value = transaction;
    });
  }

  Future<void> loadRanking([PointRankingType? type]) async {
    if (type != null && type != rankingType.value) {
      rankingType.value = type;
      ranking.value = null;
    }
    await _run((current) async {
      final result = await repository.getRanking(rankingType.value);
      if (!current()) return;
      ranking.value = result;
    });
  }

  Future<void> loadRewards() async {
    await _run((current) async {
      final items = await repository.getRewards();
      if (!current()) return;
      final balance = await repository.getAccount();
      if (!current()) return;
      rewards.assignAll(items);
      for (final reward in items) {
        _reconcileCustomerLimitOverride(reward);
      }
      account.value = balance;
    });
  }

  Future<void> loadReward(String id) async {
    _rewardRequestId = id;
    if (_pendingExchangeRewardId != id) {
      _pendingExchangeKey = null;
      _pendingExchangeRewardId = id;
    }
    selectedReward.value = null;
    await _run((current) async {
      final results = await Future.wait([
        repository.getReward(id),
        repository.getAccount(),
      ]);
      if (!current() || _rewardRequestId != id) {
        return;
      }
      final reward = results[0] as PointReward;
      _reconcileCustomerLimitOverride(reward);
      final rewardIndex = rewards.indexWhere((item) => item.id == reward.id);
      if (rewardIndex >= 0) rewards[rewardIndex] = reward;
      selectedReward.value = reward;
      account.value = results[1] as PointAccount;
    });
  }

  Future<bool> exchangeSelectedReward() async {
    if (isProcessing.value) return false;
    final version = AuthToken.sessionVersion;
    final reward = selectedReward.value;
    if (reward == null || _disposed) return false;
    isProcessing.value = true;
    errorMessage.value = null;
    try {
      _pendingExchangeKey ??=
          'exchange-${reward.id}-${DateTime.now().microsecondsSinceEpoch}';
      final exchange = await repository.exchangeReward(
        reward.id,
        idempotencyKey: _pendingExchangeKey!,
      );
      if (!_current(version)) return false;
      selectedExchange.value = exchange;
      _pendingExchangeKey = null;
      _recordSuccessfulRewardExchange(reward);
      final balance = await repository.getAccount();
      if (!_current(version)) return false;
      account.value = balance;
      final items = await repository.getTransactions();
      if (!_current(version)) return false;
      transactions.assignAll(items);
      return true;
    } on PointOperationException catch (error) {
      if (_current(version)) {
        if (error.code == 'REWARD_CUSTOMER_LIMIT_REACHED') {
          customerLimitReachedRewardIds.add(reward.id);
        }
        errorMessage.value = error.message;
      }
      return false;
    } catch (_) {
      if (_current(version)) {
        errorMessage.value = '交換処理に失敗しました。もう一度お試しください。';
      }
      return false;
    } finally {
      if (_current(version)) isProcessing.value = false;
    }
  }

  Future<void> loadExchange(String id) async {
    _exchangeRequestId = id;
    selectedExchange.value = null;
    await _run((current) async {
      final exchange = await repository.getExchange(id);
      if (!current() || _exchangeRequestId != id) {
        return;
      }
      selectedExchange.value = exchange;
    });
  }

  PointRewardStatus rewardStatusFor(PointReward reward) {
    if (reward.status == PointRewardStatus.ended) {
      return PointRewardStatus.ended;
    }
    if (reward.status == PointRewardStatus.customerLimitReached ||
        customerLimitReachedRewardIds.contains(reward.id)) {
      return PointRewardStatus.customerLimitReached;
    }
    final exchangeableBalance =
        account.value?.exchangeableBalanceForRedemption ?? 0;
    return exchangeableBalance >= reward.requiredPoints
        ? PointRewardStatus.available
        : PointRewardStatus.insufficientPoints;
  }

  void _recordSuccessfulRewardExchange(PointReward reward) {
    final rewardIndex = rewards.indexWhere((item) => item.id == reward.id);
    final listReward = rewardIndex < 0 ? null : rewards[rewardIndex];
    final selectedCount = reward.customerExchangeCount ?? 0;
    final listCount = listReward?.customerExchangeCount ?? 0;
    final latestCount = listCount > selectedCount ? listCount : selectedCount;
    final nextCount = latestCount + 1;
    final reachedLimit = reward.perCustomerLimit > 0 &&
        nextCount >= reward.perCustomerLimit;
    final updatedStatus = reachedLimit
        ? PointRewardStatus.customerLimitReached
        : reward.status;

    selectedReward.value = reward.copyWith(
      customerExchangeCount: nextCount,
      status: updatedStatus,
    );
    if (rewardIndex >= 0) {
      rewards[rewardIndex] = rewards[rewardIndex].copyWith(
        customerExchangeCount: nextCount,
        status: reachedLimit
            ? PointRewardStatus.customerLimitReached
            : rewards[rewardIndex].status,
      );
    }
    if (reachedLimit) customerLimitReachedRewardIds.add(reward.id);
  }

  void _reconcileCustomerLimitOverride(PointReward reward) {
    final customerExchangeCount = reward.customerExchangeCount;
    if (customerExchangeCount == null) return;
    if (reward.perCustomerLimit > 0 &&
        customerExchangeCount >= reward.perCustomerLimit) {
      customerLimitReachedRewardIds.add(reward.id);
    } else {
      customerLimitReachedRewardIds.remove(reward.id);
    }
  }

  List<PointTransaction> get filteredTransactions {
    return transactions.where((transaction) {
      return switch (historyFilter.value) {
        PointHistoryFilter.all => true,
        PointHistoryFilter.earned =>
          transaction.type == PointTransactionType.grant ||
              transaction.type == PointTransactionType.reversal ||
              (transaction.type == PointTransactionType.adjust &&
                  transaction.amount > 0),
        PointHistoryFilter.spent =>
          transaction.type == PointTransactionType.spend ||
              (transaction.type == PointTransactionType.adjust &&
                  transaction.amount < 0),
        PointHistoryFilter.expired =>
          transaction.type == PointTransactionType.expire,
      };
    }).toList();
  }

  Future<void> _run(Future<void> Function(bool Function()) action) async {
    final version = AuthToken.sessionVersion;
    if (!_current(version)) return;
    bool current() => _current(version);
    _activeLoadCount += 1;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await action(current);
    } on PointOperationException catch (error) {
      if (current()) errorMessage.value = error.message;
    } catch (_) {
      if (current()) {
        errorMessage.value = 'データを取得できませんでした。再読み込みしてください。';
      }
    } finally {
      if (current()) {
        _activeLoadCount -= 1;
        isLoading.value = _activeLoadCount > 0;
      }
    }
  }
}
