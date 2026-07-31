import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';
import 'package:koto_blue_sharks/presentation/point/widgets/point_widgets.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PointTopScreen extends StatefulWidget {
  const PointTopScreen({super.key});

  @override
  State<PointTopScreen> createState() => _PointTopScreenState();
}

class _PointTopScreenState extends State<PointTopScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: 'ポイント',
      child: Obx(() {
        if (controller.isAuthenticated.value == false) {
          return _PointAuthenticationRequired(
            onAuthenticate: () async {
              await Get.toNamed(Routes.REGISTER_EMAIL_FROM_HOME);
              await controller.initialize();
            },
          );
        }
        if (controller.isLoading.value && controller.account.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null &&
            controller.account.value == null) {
          return PointErrorView(
            message: controller.errorMessage.value!,
            onRetry: controller.loadOverview,
          );
        }
        final account = controller.account.value;
        if (account == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: controller.loadOverview,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              PointBalanceCard(
                balance: account.balance,
                lifetimeEarned: account.lifetimeEarned,
                onTapExpiring: () => Get.toNamed(Routes.POINT_EXPIRING),
              ),
              SizedBox(height: 12.h),
              if (controller.expiringLots.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: WarningColor.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: CustomTextView(
                    '90日以内に失効予定：${formatPoints(controller.expiringLots.fold(0, (sum, lot) => sum + lot.remainingAmount))} pt',
                    color: WarningColor.main,
                  ),
                ),
              SizedBox(height: 16.h),
              _PointMenuTile(
                icon: Icons.qr_code_2,
                title: '会員QRを表示',
                subtitle: '来場ポイントを獲得',
                onTap: () => Get.toNamed(Routes.POINT_QR),
              ),
              _PointMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'ポイント履歴',
                subtitle: '付与・消費・失効を確認',
                onTap: () => Get.toNamed(Routes.POINT_HISTORY),
              ),
              _PointMenuTile(
                icon: Icons.emoji_events_outlined,
                title: 'ランキング',
                subtitle: '月・年・シーズン',
                onTap: () => Get.toNamed(Routes.POINT_RANKING),
              ),
              _PointMenuTile(
                icon: Icons.card_giftcard,
                title: '景品と交換',
                subtitle: 'ポイントを使う',
                onTap: () => Get.toNamed(Routes.POINT_REWARDS),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class PointExpiringScreen extends StatefulWidget {
  const PointExpiringScreen({super.key});

  @override
  State<PointExpiringScreen> createState() => _PointExpiringScreenState();
}

class _PointExpiringScreenState extends State<PointExpiringScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: '失効予定',
      child: Obx(() => ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              const CustomTextView(
                '期限が近いポイント',
                type: TDSFontType.titleSmall,
              ),
              SizedBox(height: 12.h),
              ...controller.expiringLots.map(
                (lot) => Card(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    title: Text(formatPointDate(lot.expiresAt)),
                    subtitle: Text(lot.reason),
                    trailing: Text(
                      '-${formatPoints(lot.remainingAmount)} pt',
                      style: TextStyle(
                        color: DangerColor.main,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              CustomTextView(
                'ポイントは有効期限が近い付与分から使用されます。',
                color: TextColor.secondary,
                type: TDSFontType.bodyTextSmall,
              ),
              SizedBox(height: 20.h),
              PointPrimaryButton(
                label: 'ポイント履歴を見る',
                onPressed: () => Get.toNamed(Routes.POINT_HISTORY),
              ),
            ],
          )),
    );
  }
}

class PointQrScreen extends StatefulWidget {
  const PointQrScreen({super.key});

  @override
  State<PointQrScreen> createState() => _PointQrScreenState();
}

class _PointQrScreenState extends State<PointQrScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadQr();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: '会員QR',
      child: Obx(() {
        if (controller.isLoading.value && controller.qrToken.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final token = controller.qrToken.value;
        if (token == null) {
          return PointErrorView(
            message: controller.errorMessage.value ?? 'QRを取得できませんでした。',
            onRetry: controller.loadQr,
          );
        }
        return ListView(
          padding: EdgeInsets.all(24.w),
          children: [
            const CustomTextView(
              '会場端末にこの画面を\nかざしてください',
              type: TDSFontType.titleMedium,
              align: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Center(
              child: Container(
                padding: EdgeInsets.all(16.w),
                color: Colors.white,
                child: QrImageView(
                  data: token.token,
                  version: QrVersions.auto,
                  size: 220.w,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (token.maskedMemberId.isNotEmpty)
              CustomTextView(
                '会員ID  ${token.maskedMemberId}',
                align: TextAlign.center,
                color: TextColor.secondary,
              ),
            SizedBox(height: 16.h),
            const CustomTextView(
              '会場スタッフの読み取り完了後、ポイント履歴を更新してご確認ください。',
              align: TextAlign.center,
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.POINT_HISTORY),
              child: const Text('ポイント履歴を確認'),
            ),
          ],
        );
      }),
    );
  }
}

class PointQrProcessingScreen extends StatelessWidget {
  const PointQrProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: '会員QR',
      footerEnabled: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, size: 56.w, color: BrandColor.main),
              SizedBox(height: 20.h),
              const CustomTextView(
                '会場端末で読み取り中',
                type: TDSFontType.titleMedium,
              ),
              SizedBox(height: 8.h),
              const CustomTextView(
                '読み取り完了後、ポイント履歴で付与結果をご確認ください。',
                align: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              PointPrimaryButton(
                label: 'ポイント履歴を確認',
                onPressed: () => Get.offNamed(Routes.POINT_HISTORY),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PointQrResultScreen extends StatelessWidget {
  const PointQrResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments is PointQrResultArguments
        ? Get.arguments as PointQrResultArguments
        : const PointQrResultArguments(result: PointQrResult.failed);
    final isFailure = arguments.result == PointQrResult.failed;
    final isRejected = arguments.result == PointQrResult.rejected;
    return PointScaffold(
      title: '会員QR',
      child: ListView(
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          _QrResultView(
            result: arguments.result,
            failureCode: arguments.failureCode,
          ),
          SizedBox(height: 24.h),
          if (isFailure)
            PointPrimaryButton(
              label: 'もう一度試す',
              onPressed: () => Get.offNamed(Routes.POINT_QR_PROCESSING),
            ),
          if (isFailure || isRejected)
            TextButton(
              onPressed: () => Get.toNamed(Routes.POINT_HISTORY),
              child: Text(isRejected ? '履歴を確認' : '履歴で付与済みか確認'),
            ),
          if (!isFailure && !isRejected)
            PointPrimaryButton(
              label: '閉じる',
              onPressed: () => Get.until(
                (route) => route.settings.name == Routes.POINT_TOP,
              ),
            ),
        ],
      ),
    );
  }
}

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: 'ポイント履歴',
      child: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: PointHistoryFilter.values.map((filter) {
                  final label = switch (filter) {
                    PointHistoryFilter.all => 'すべて',
                    PointHistoryFilter.earned => '獲得',
                    PointHistoryFilter.spent => '利用',
                    PointHistoryFilter.expired => '失効',
                  };
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: controller.historyFilter.value == filter,
                      onSelected: (_) =>
                          controller.historyFilter.value = filter,
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadTransactions,
                child: ListView.builder(
                  itemCount: controller.filteredTransactions.length,
                  itemBuilder: (_, index) {
                    final item = controller.filteredTransactions[index];
                    return ListTile(
                      tileColor: Colors.white,
                      title: Text(item.title),
                      subtitle: Text(
                        '${formatPointDate(item.occurredAt, withTime: true)}　残高${formatPoints(item.balanceAfter)}pt'
                        '${item.exchangeId != null ? '\n受渡確認用' : ''}',
                      ),
                      isThreeLine: item.exchangeId != null,
                      trailing: Text(
                        '${item.amount > 0 ? '+' : ''}${formatPoints(item.amount)} pt',
                        style: TextStyle(
                          color: item.amount > 0
                              ? SuccessColor.main
                              : TextColor.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => item.exchangeId != null
                          ? Get.toNamed(
                              Routes.POINT_EXCHANGE_RECEIPT,
                              arguments: item.exchangeId,
                            )
                          : Get.toNamed(
                              Routes.POINT_HISTORY_DETAIL,
                              arguments: item.id,
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class PointHistoryDetailScreen extends StatefulWidget {
  const PointHistoryDetailScreen({super.key});

  @override
  State<PointHistoryDetailScreen> createState() =>
      _PointHistoryDetailScreenState();
}

class _PointHistoryDetailScreenState extends State<PointHistoryDetailScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadTransaction(Get.arguments as String);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: '履歴詳細',
      child: Obx(() {
        final item = controller.selectedTransaction.value;
        if (item == null) {
          if (controller.errorMessage.value != null) {
            return PointErrorView(
              message: controller.errorMessage.value!,
              onRetry: () =>
                  controller.loadTransaction(Get.arguments as String),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            CustomTextView(item.title, type: TDSFontType.titleMedium),
            SizedBox(height: 16.h),
            _DetailRow(
                '処理日時', formatPointDate(item.occurredAt, withTime: true)),
            _DetailRow('種別', transactionTypeLabel(item.type)),
            _DetailRow(
              '増減',
              '${item.amount > 0 ? '+' : ''}${formatPoints(item.amount)} pt',
            ),
            _DetailRow('処理後残高', '${formatPoints(item.balanceAfter)} pt'),
            _DetailRow('対象', item.title),
            if (item.venue != null) _DetailRow('会場', item.venue!),
            _DetailRow('履歴ID', item.id),
          ],
        );
      }),
    );
  }
}

class PointRankingScreen extends StatefulWidget {
  const PointRankingScreen({super.key});

  @override
  State<PointRankingScreen> createState() => _PointRankingScreenState();
}

class _PointRankingScreenState extends State<PointRankingScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: 'ランキング',
      child: Obx(() {
        final data = controller.ranking.value;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  _RankingTab(
                    label: '月間',
                    type: PointRankingType.monthly,
                    selectedType: controller.rankingType.value,
                    onTap: controller.loadRanking,
                  ),
                  _RankingTab(
                    label: '年間',
                    type: PointRankingType.yearly,
                    selectedType: controller.rankingType.value,
                    onTap: controller.loadRanking,
                  ),
                  _RankingTab(
                    label: 'シーズン',
                    type: PointRankingType.season,
                    selectedType: controller.rankingType.value,
                    onTap: controller.loadRanking,
                  ),
                ],
              ),
            ),
            if (controller.isLoading.value && data == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (data == null && controller.errorMessage.value != null)
              Expanded(
                child: PointErrorView(
                  message: controller.errorMessage.value!,
                  onRetry: controller.loadRanking,
                ),
              )
            else if (data != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: CustomTextView(
                  data.periodName,
                  type: TDSFontType.titleSmall,
                ),
              ),
              Expanded(
                child: ListView(
                  children: data.entries
                      .map((entry) => _RankingTile(entry: entry))
                      .toList(),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                color: BrandColor.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextView(
                      'あなたの順位',
                      type: TDSFontType.labelMedium,
                    ),
                    _RankingTile(entry: data.myEntry, compact: true),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class PointRewardsScreen extends StatefulWidget {
  const PointRewardsScreen({super.key});

  @override
  State<PointRewardsScreen> createState() => _PointRewardsScreenState();
}

class _PointRewardsScreenState extends State<PointRewardsScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: '景品一覧',
      child: Obx(() {
        final account = controller.account.value;
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            if (account != null)
              PointBalanceCard(
                balance: account.balance,
                lifetimeEarned: account.lifetimeEarned,
              ),
            SizedBox(height: 16.h),
            if (controller.isLoading.value && controller.rewards.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (controller.errorMessage.value != null &&
                controller.rewards.isEmpty)
              PointErrorView(
                message: controller.errorMessage.value!,
                onRetry: controller.loadRewards,
              )
            else if (controller.rewards.isEmpty)
              const CustomTextView(
                '現在交換できる景品はありません。',
                align: TextAlign.center,
              ),
            ...controller.rewards.map(
              (reward) => Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  onTap: () => Get.toNamed(
                    Routes.POINT_REWARD_DETAIL,
                    arguments: reward.id,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Container(
                          width: 84.w,
                          height: 84.w,
                          decoration: BoxDecoration(
                            color: BrandColor.surface,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child:
                              Icon(Icons.card_giftcard, color: BrandColor.main),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextView(
                                reward.name,
                                type: TDSFontType.titleSmall,
                              ),
                              SizedBox(height: 8.h),
                              CustomTextView(
                                '${formatPoints(reward.requiredPoints)} pt',
                                type: TDSFontType.titleMedium,
                              ),
                              CustomTextView(
                                _rewardStatusLabel(
                                  controller.rewardStatusFor(reward),
                                ),
                                color: _rewardStatusColor(
                                  controller.rewardStatusFor(reward),
                                ),
                                type: TDSFontType.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class PointRewardDetailScreen extends StatefulWidget {
  const PointRewardDetailScreen({super.key});

  @override
  State<PointRewardDetailScreen> createState() =>
      _PointRewardDetailScreenState();
}

class _PointRewardDetailScreenState extends State<PointRewardDetailScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadReward(Get.arguments as String);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reward = controller.selectedReward.value;
      final account = controller.account.value;
      final status = reward == null ? null : controller.rewardStatusFor(reward);
      final enabled = reward != null &&
          account != null &&
          status == PointRewardStatus.available;
      return PointScaffold(
        title: '景品詳細',
        bottomNavigationBar: reward == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: PointPrimaryButton(
                    label: enabled ? 'この景品と交換する' : '交換できません',
                    enabled: enabled,
                    onPressed: () => Get.toNamed(Routes.POINT_EXCHANGE_CONFIRM),
                  ),
                ),
              ),
        child: reward == null
            ? controller.errorMessage.value != null
                ? PointErrorView(
                    message: controller.errorMessage.value!,
                    onRetry: () =>
                        controller.loadReward(Get.arguments as String),
                  )
                : const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Container(
                    height: 220.h,
                    decoration: BoxDecoration(
                      color: BrandColor.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      size: 72.w,
                      color: BrandColor.main,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomTextView(reward.name, type: TDSFontType.titleLarge),
                  SizedBox(height: 16.h),
                  _DetailRow(
                    '必要ポイント',
                    '${formatPoints(reward.requiredPoints)} pt',
                  ),
                  _DetailRow(
                    '交換期間',
                    _rewardPeriod(reward),
                  ),
                  _DetailRow('受渡場所', reward.pickupLocation),
                  _DetailRow('注意事項', reward.notice),
                  if (!enabled && account != null)
                    Container(
                      margin: EdgeInsets.only(top: 16.h),
                      padding: EdgeInsets.all(16.w),
                      color: WarningColor.surface,
                      child: CustomTextView(
                        status == PointRewardStatus.ended
                            ? '受付は終了しました'
                            : 'ポイントが不足しています\n必要 ${formatPoints(reward.requiredPoints)} pt／保有 ${formatPoints(account.balance)} pt',
                        align: TextAlign.center,
                        color: WarningColor.main,
                      ),
                    ),
                ],
              ),
      );
    });
  }
}

class PointExchangeConfirmScreen extends StatelessWidget {
  const PointExchangeConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PointController>();
    return Obx(() {
      final reward = controller.selectedReward.value;
      final account = controller.account.value;
      if (reward == null || account == null) {
        return const PointScaffold(
          title: '交換確認',
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return PointScaffold(
        title: '交換確認',
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            CustomTextView(reward.name, type: TDSFontType.titleLarge),
            SizedBox(height: 20.h),
            _DetailRow('利用ポイント', '-${formatPoints(reward.requiredPoints)} pt'),
            _DetailRow(
              '交換後残高',
              '${formatPoints(account.balance - reward.requiredPoints)} pt',
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              color: WarningColor.surface,
              child: const CustomTextView(
                '交換後はユーザー自身で取り消せません。',
                align: TextAlign.center,
              ),
            ),
            SizedBox(height: 24.h),
            PointPrimaryButton(
              label: 'ポイントを消費して交換',
              onPressed: () async {
                final succeeded = await controller.exchangeSelectedReward();
                if (succeeded) {
                  Get.offNamed(Routes.POINT_EXCHANGE_COMPLETE);
                } else {
                  Get.snackbar(
                    '交換できませんでした',
                    controller.errorMessage.value ?? 'もう一度お試しください。',
                  );
                }
              },
            ),
            TextButton(onPressed: Get.back, child: const Text('戻る')),
            if (controller.isProcessing.value)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                padding: EdgeInsets.all(24.w),
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('交換処理中\n画面を閉じずにお待ちください'),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class PointExchangeCompleteScreen extends StatelessWidget {
  const PointExchangeCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PointController>();
    return Obx(() => _ExchangeReceiptContent(
          title: '交換完了',
          exchange: controller.selectedExchange.value,
          closeLabel: '閉じる',
          onClose: () => Get.until(
            (route) => route.settings.name == Routes.POINT_TOP,
          ),
        ));
  }
}

class PointExchangeReceiptScreen extends StatefulWidget {
  const PointExchangeReceiptScreen({super.key});

  @override
  State<PointExchangeReceiptScreen> createState() =>
      _PointExchangeReceiptScreenState();
}

class _PointExchangeReceiptScreenState
    extends State<PointExchangeReceiptScreen> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PointController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadExchange(Get.arguments as String);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => _ExchangeReceiptContent(
          title: '交換履歴',
          exchange: controller.selectedExchange.value,
          onRetry: () => controller.loadExchange(Get.arguments as String),
        ));
  }
}

class _ExchangeReceiptContent extends StatelessWidget {
  const _ExchangeReceiptContent({
    required this.title,
    required this.exchange,
    this.closeLabel,
    this.onClose,
    this.onRetry,
  });

  final String title;
  final PointRewardExchange? exchange;
  final String? closeLabel;
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PointScaffold(
      title: title,
      child: exchange == null
          ? onRetry != null &&
                  Get.find<PointController>().errorMessage.value != null
              ? PointErrorView(
                  message: Get.find<PointController>().errorMessage.value!,
                  onRetry: onRetry!,
                )
              : const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                Icon(Icons.check_circle, size: 56.w, color: SuccessColor.main),
                SizedBox(height: 12.h),
                const CustomTextView(
                  'スタッフ確認用',
                  type: TDSFontType.titleMedium,
                  align: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                CustomTextView(
                  exchange!.rewardName,
                  type: TDSFontType.titleLarge,
                  align: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                _DetailRow(
                  '消費済み',
                  '${formatPoints(exchange!.spentPoints)} pt',
                ),
                _DetailRow(
                  '交換日時',
                  formatPointDate(exchange!.requestedAt, withTime: true),
                ),
                _DetailRow('交換番号', exchange!.exchangeNumber),
                _DetailRow('履歴ID', exchange!.id),
                if (exchange!.maskedMemberId.isNotEmpty)
                  _DetailRow('会員ID', exchange!.maskedMemberId),
                if (exchange!.deliveryToken != null) ...[
                  SizedBox(height: 16.h),
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(12.w),
                      child: QrImageView(
                        data: exchange!.deliveryToken!,
                        version: QrVersions.auto,
                        size: 180.w,
                      ),
                    ),
                  ),
                  if (exchange!.deliveryTokenExpiresAt != null)
                    CustomTextView(
                      '表示期限：${formatPointDate(exchange!.deliveryTokenExpiresAt!, withTime: true)}',
                      align: TextAlign.center,
                      color: TextColor.secondary,
                    ),
                ],
                SizedBox(height: 16.h),
                const CustomTextView(
                  'この画面をスタッフに見せてください',
                  align: TextAlign.center,
                  type: TDSFontType.titleSmall,
                ),
                if (closeLabel != null) ...[
                  SizedBox(height: 24.h),
                  PointPrimaryButton(label: closeLabel!, onPressed: onClose!),
                ],
              ],
            ),
    );
  }
}

class _PointMenuTile extends StatelessWidget {
  const _PointMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(icon, color: BrandColor.main),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _PointAuthenticationRequired extends StatelessWidget {
  const _PointAuthenticationRequired({required this.onAuthenticate});

  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48.w, color: BrandColor.main),
            SizedBox(height: 16.h),
            const CustomTextView(
              '会員認証が必要です',
              type: TDSFontType.titleMedium,
            ),
            SizedBox(height: 8.h),
            CustomTextView(
              'ポイント機能を利用するには\n会員情報を認証してください。',
              align: TextAlign.center,
              color: TextColor.secondary,
            ),
            SizedBox(height: 20.h),
            PointPrimaryButton(
              label: '会員認証へ',
              onPressed: onAuthenticate,
            ),
          ],
        ),
      ),
    );
  }
}

class _QrResultView extends StatelessWidget {
  const _QrResultView({required this.result, this.failureCode});

  final PointQrResult result;
  final String? failureCode;

  @override
  Widget build(BuildContext context) {
    if (result == PointQrResult.idle) return const SizedBox.shrink();
    final (icon, title, description, color) = switch (result) {
      PointQrResult.pending => (
          Icons.sync,
          'ポイント付与処理中',
          '画面を閉じずにお待ちください',
          InfoColor.main,
        ),
      PointQrResult.granted => (
          Icons.check_circle,
          'ポイントを獲得しました',
          '+100 pt',
          SuccessColor.main,
        ),
      PointQrResult.rejected => (
          Icons.info_outline,
          failureCode == 'already_redeemed' ? 'すでに獲得済みです' : '受付できませんでした',
          'この試合の来場ポイントはすでに付与されています。',
          WarningColor.main,
        ),
      PointQrResult.failed => (
          Icons.error_outline,
          'ポイント付与に失敗しました',
          '通信状態を確認して、もう一度お試しください。',
          DangerColor.main,
        ),
      PointQrResult.awaitingSync => (
          Icons.cloud_off,
          '受付済み・反映待ち',
          '会場端末がオンラインに戻った後に反映されます。',
          InfoColor.main,
        ),
      PointQrResult.idle => (Icons.info, '', '', Colors.transparent),
    };
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36.w),
          SizedBox(height: 8.h),
          CustomTextView(title, type: TDSFontType.titleSmall),
          CustomTextView(description, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BorderColor.primary)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112.w,
            child: CustomTextView(label, color: TextColor.secondary),
          ),
          Expanded(child: CustomTextView(value)),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry, this.compact = false});

  final PointRankingEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: compact,
      tileColor: compact ? Colors.transparent : Colors.white,
      leading: SizedBox(
        width: 40.w,
        child: Text(
          entry.rank == null ? '—' : '${entry.rank}位',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(entry.nickname),
      trailing: Text(
        '${formatPoints(entry.points)} pt',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  final String label;
  final PointRankingType type;
  final PointRankingType selectedType;
  final ValueChanged<PointRankingType> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = type == selectedType;
    return Expanded(
      child: SizedBox(
        height: 44.h,
        child: OutlinedButton(
          onPressed: () => onTap(type),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: selected ? BrandColor.main : Colors.white,
            foregroundColor: selected ? Colors.white : TextColor.primary,
            side: BorderSide(color: BrandColor.main),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }
}

String _rewardStatusLabel(PointRewardStatus status) {
  return switch (status) {
    PointRewardStatus.available => '交換可能',
    PointRewardStatus.insufficientPoints => 'ポイント不足',
    PointRewardStatus.ended => '受付終了',
  };
}

String _rewardPeriod(PointReward reward) {
  final startsAt = reward.exchangeStartsAt;
  final endsAt = reward.exchangeEndsAt;
  if (startsAt == null && endsAt == null) return '期間指定なし';
  if (startsAt == null) return '〜${formatPointDate(endsAt!)}';
  if (endsAt == null) return '${formatPointDate(startsAt)}〜';
  return '${formatPointDate(startsAt)}〜${formatPointDate(endsAt)}';
}

Color _rewardStatusColor(PointRewardStatus status) {
  return switch (status) {
    PointRewardStatus.available => SuccessColor.main,
    PointRewardStatus.insufficientPoints => WarningColor.main,
    PointRewardStatus.ended => TextColor.disabled,
  };
}
