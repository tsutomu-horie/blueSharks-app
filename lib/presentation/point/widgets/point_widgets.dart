import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_app_bar_view.dart';
import 'package:koto_blue_sharks/app/views/views/app_bottom_navigation_bar.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class PointScaffold extends StatelessWidget {
  const PointScaffold({
    required this.title,
    required this.child,
    this.bottomNavigationBar,
    this.footerEnabled = true,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? bottomNavigationBar;
  final bool footerEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor.secondary,
      appBar: const DefaultAppBarView(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottomNavigationBar != null) bottomNavigationBar!,
          AppBottomNavigationBar(
            selectedIndex: 0,
            enabled: footerEnabled,
            onTap: _navigateToMainTab,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: CustomTextView(
                title,
                type: TDSFontType.titleLarge,
                align: TextAlign.center,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _navigateToMainTab(int index) {
    if (Get.isRegistered<MainController>()) {
      final controller = Get.find<MainController>();
      controller.selectedTopicId.value = null;
      controller.selectedIndex.value = index;
      Get.until((route) => route.isFirst);
      return;
    }
    Get.offAllNamed(Routes.MAIN);
  }
}

class PointBalanceCard extends StatelessWidget {
  const PointBalanceCard({
    required this.balance,
    required this.lifetimeEarned,
    this.onTapExpiring,
    super.key,
  });

  final int balance;
  final int lifetimeEarned;
  final VoidCallback? onTapExpiring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: BrandColor.main,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomTextView(
            '利用可能ポイント',
            color: Colors.white,
            type: TDSFontType.bodyTextSmall,
          ),
          SizedBox(height: 4.h),
          CustomTextView(
            '${formatPoints(balance)} pt',
            color: Colors.white,
            type: TDSFontType.headlineLarge,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomTextView(
                  '累計 ${formatPoints(lifetimeEarned)} pt',
                  color: Colors.white,
                  type: TDSFontType.bodyTextMedium,
                ),
              ),
              if (onTapExpiring != null)
                InkWell(
                  onTap: onTapExpiring,
                  child: const CustomTextView(
                    '失効予定を見る ＞',
                    color: Colors.white,
                    type: TDSFontType.labelMedium,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PointErrorView extends StatelessWidget {
  const PointErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DangerColor.main, size: 40.w),
            SizedBox(height: 12.h),
            CustomTextView(message, align: TextAlign.center),
            SizedBox(height: 16.h),
            OutlinedButton(onPressed: onRetry, child: const Text('再読み込み')),
          ],
        ),
      ),
    );
  }
}

class PointPrimaryButton extends StatelessWidget {
  const PointPrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColor.main,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

String formatPoints(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}

String formatPointDate(DateTime value, {bool withTime = false}) {
  final date =
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  if (!withTime) return date;
  return '$date ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String transactionTypeLabel(dynamic type) {
  return switch (type.toString().split('.').last) {
    'grant' => 'ポイント獲得',
    'spend' => 'ポイント利用',
    'expire' => 'ポイント失効',
    'reversal' => '取消・返却',
    'adjust' => 'ポイント調整',
    _ => '',
  };
}
