import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/mock_point_repository.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockPointRepository', () {
    test('残高と生涯累計を別の値として返す', () async {
      final repository = MockPointRepository.instance;

      final account = await repository.getAccount();

      expect(account.balance, 1250);
      expect(account.lifetimeEarned, 12500);
      expect(account.lifetimeSpent, 11250);
    });

    test('失効ロットを期限の古い順に返す', () async {
      final repository = MockPointRepository.instance;

      final lots = await repository.getExpiringLots();

      expect(lots, hasLength(2));
      expect(lots.first.expiresAt.isBefore(lots.last.expiresAt), isTrue);
      expect(lots.fold<int>(0, (sum, lot) => sum + lot.remainingAmount), 150);
    });

    test('景品の交換可否を現在残高から判定する', () {
      final controller = PointController(
        repository: MockPointRepository.instance,
      );
      final reward = PointReward(
        id: 'REWARD-TEST',
        offerId: 'OFFER-TEST',
        name: 'テスト景品',
        description: '',
        requiredPoints: 1000,
        exchangeStartsAt: DateTime(2026),
        exchangeEndsAt: DateTime(2027),
        pickupLocation: '',
        notice: '',
        status: PointRewardStatus.available,
      );

      controller.account.value = const PointAccount(
        balance: 1250,
        lifetimeEarned: 12500,
        lifetimeSpent: 11250,
      );
      expect(
        controller.rewardStatusFor(reward),
        PointRewardStatus.available,
      );

      controller.account.value = const PointAccount(
        balance: 250,
        lifetimeEarned: 12500,
        lifetimeSpent: 12250,
      );
      expect(
        controller.rewardStatusFor(reward),
        PointRewardStatus.insufficientPoints,
      );
    });

    test('景品交換で残高を減らし追記型の利用履歴を追加する', () async {
      final repository = MockPointRepository.instance;

      final exchange = await repository.exchangeReward(
        'REWARD-001',
        idempotencyKey: 'test-exchange-001',
      );
      final account = await repository.getAccount();
      final transactions = await repository.getTransactions();

      expect(exchange.rewardId, 'REWARD-001');
      expect(account.balance, 250);
      expect(account.lifetimeEarned, 12500);
      expect(account.lifetimeSpent, 12250);
      expect(transactions.first.type, PointTransactionType.spend);
      expect(transactions.first.amount, -1000);
      expect(transactions.first.balanceAfter, 250);
      expect(transactions.first.exchangeId, exchange.id);
    });

    test('同じ冪等キーの交換要求を拒否する', () async {
      final repository = MockPointRepository.instance;

      expect(
        () => repository.exchangeReward(
          'REWARD-001',
          idempotencyKey: 'test-exchange-001',
        ),
        throwsA(
          isA<PointOperationException>().having(
            (error) => error.code,
            'code',
            'duplicate_request',
          ),
        ),
      );
    });
  });
}
