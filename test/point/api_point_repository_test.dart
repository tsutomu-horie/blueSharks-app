import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/point/api_point_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiPointRepository account parsing', () {
    test('preserves explicit zero exchangeable balance', () {
      final account = ApiPointRepository.instance.accountFromResponseData({
        'balance': 100,
        'exchangeable_balance': 0,
        'lifetime_earned': 100,
        'lifetime_spent': 0,
      });

      expect(account.balance, 100);
      expect(account.exchangeableBalance, 0);
      expect(account.exchangeableBalanceForRedemption, 0);
    });

    test('falls back to legacy balance only when the key is absent', () {
      final account = ApiPointRepository.instance.accountFromResponseData({
        'balance': 100,
        'lifetime_earned': 100,
        'lifetime_spent': 0,
      });

      expect(account.exchangeableBalance, isNull);
      expect(account.exchangeableBalanceForRedemption, 100);
    });
  });
}
