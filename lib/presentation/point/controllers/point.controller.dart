import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/mock_point_repository.dart';
import 'package:koto_blue_sharks/app/providers/point/point_repository.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';

class PointController extends GetxController {
  PointController({PointRepository? repository})
      : repository = repository ?? MockPointRepository.instance;

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
  Future<void>? _initialization;
  int _activeLoadCount = 0;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() {
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    final token = await AuthToken().getAccessToken();
    isAuthenticated.value = token != null;
    if (token != null) {
      await loadOverview();
    }
  }

  Future<void> loadOverview() async {
    await _run(() async {
      final results = await Future.wait([
        repository.getAccount(),
        repository.getExpiringLots(),
      ]);
      account.value = results[0] as PointAccount;
      expiringLots.assignAll(results[1] as List<PointLot>);
    });
  }

  Future<void> loadQr() async {
    await _run(() async {
      qrToken.value = await repository.getQrToken();
      qrResult.value = PointQrResult.idle;
      qrFailureCode.value = null;
    });
  }

  Future<void> loadTransactions() async {
    await _run(() async {
      transactions.assignAll(await repository.getTransactions());
    });
  }

  Future<void> loadTransaction(String id) async {
    _transactionRequestId = id;
    selectedTransaction.value = null;
    await _run(() async {
      final transaction = await repository.getTransaction(id);
      if (_transactionRequestId != id) {
        return;
      }
      selectedTransaction.value = transaction;
    });
  }

  Future<void> loadRanking([PointRankingType? type]) async {
    if (type != null) rankingType.value = type;
    await _run(() async {
      ranking.value = await repository.getRanking(rankingType.value);
    });
  }

  Future<void> loadRewards() async {
    await _run(() async {
      rewards.assignAll(await repository.getRewards());
      account.value = await repository.getAccount();
    });
  }

  Future<void> loadReward(String id) async {
    _rewardRequestId = id;
    selectedReward.value = null;
    await _run(() async {
      final results = await Future.wait([
        repository.getReward(id),
        repository.getAccount(),
      ]);
      if (_rewardRequestId != id) {
        return;
      }
      selectedReward.value = results[0] as PointReward;
      account.value = results[1] as PointAccount;
    });
  }

  Future<bool> exchangeSelectedReward() async {
    final reward = selectedReward.value;
    if (reward == null) return false;
    isProcessing.value = true;
    errorMessage.value = null;
    try {
      selectedExchange.value = await repository.exchangeReward(
        reward.id,
        idempotencyKey:
            'exchange-${reward.id}-${DateTime.now().microsecondsSinceEpoch}',
      );
      account.value = await repository.getAccount();
      transactions.assignAll(await repository.getTransactions());
      return true;
    } on PointOperationException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value = '交換処理に失敗しました。もう一度お試しください。';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> loadExchange(String id) async {
    _exchangeRequestId = id;
    selectedExchange.value = null;
    await _run(() async {
      final exchange = await repository.getExchange(id);
      if (_exchangeRequestId != id) {
        return;
      }
      selectedExchange.value = exchange;
    });
  }

  PointRewardStatus rewardStatusFor(PointReward reward) {
    if (reward.status == PointRewardStatus.ended) {
      return PointRewardStatus.ended;
    }
    final currentBalance = account.value?.balance ?? 0;
    return currentBalance >= reward.requiredPoints
        ? PointRewardStatus.available
        : PointRewardStatus.insufficientPoints;
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

  void setMockQrResult(PointQrResult result, {String? failureCode}) {
    qrResult.value = result;
    qrFailureCode.value = failureCode;
  }

  Future<void> _run(Future<void> Function() action) async {
    _activeLoadCount += 1;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await action();
    } on PointOperationException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'データを取得できませんでした。再読み込みしてください。';
    } finally {
      _activeLoadCount -= 1;
      isLoading.value = _activeLoadCount > 0;
    }
  }
}
