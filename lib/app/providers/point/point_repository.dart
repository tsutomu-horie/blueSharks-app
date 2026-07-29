import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';

abstract class PointRepository {
  Future<PointAccount> getAccount();
  Future<List<PointLot>> getExpiringLots();
  Future<PointQrToken> getQrToken();
  Future<List<PointTransaction>> getTransactions();
  Future<PointTransaction> getTransaction(String id);
  Future<PointRanking> getRanking(PointRankingType type);
  Future<List<PointReward>> getRewards();
  Future<PointReward> getReward(String id);
  Future<PointRewardExchange> exchangeReward(
    String rewardId, {
    required String idempotencyKey,
  });
  Future<PointRewardExchange> getExchange(String id);
}
