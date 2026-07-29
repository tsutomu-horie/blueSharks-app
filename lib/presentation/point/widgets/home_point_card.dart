import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';
import 'package:koto_blue_sharks/presentation/point/widgets/point_widgets.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class HomePointCard extends StatefulWidget {
  const HomePointCard({super.key});

  @override
  State<HomePointCard> createState() => _HomePointCardState();
}

class _HomePointCardState extends State<HomePointCard> {
  late final PointController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PointController>()
        ? Get.find<PointController>()
        : Get.put(PointController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final account = controller.account.value;
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: controller.isAuthenticated.value == false
              ? () async {
                  await Get.toNamed(Routes.REGISTER_EMAIL_FROM_HOME);
                  await controller.initialize();
                }
              : account == null
                  ? null
                  : () => Get.toNamed(Routes.POINT_TOP),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColor.main, BrandColor.hover],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: controller.isAuthenticated.value == null ||
                    (controller.isLoading.value && account == null)
                ? const SizedBox(
                    height: 52,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : controller.isAuthenticated.value == false
                    ? const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: CustomTextView(
                              '会員認証後にポイントを確認できます',
                              color: Colors.white,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      )
                    : account == null
                        ? Row(
                            children: [
                              const Expanded(
                                child: CustomTextView(
                                  'ポイントを取得できませんでした',
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: controller.loadOverview,
                                child: const Text(
                                  '再読み込み',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CustomTextView(
                                      'POINT',
                                      color: Colors.white,
                                      type: TDSFontType.labelMedium,
                                    ),
                                    CustomTextView(
                                      '${formatPoints(account.balance)} pt',
                                      color: Colors.white,
                                      type: TDSFontType.titleLarge,
                                    ),
                                    CustomTextView(
                                      '累計 ${formatPoints(account.lifetimeEarned)} pt',
                                      color: Colors.white,
                                      type: TDSFontType.bodyTextSmall,
                                    ),
                                  ],
                                ),
                              ),
                              const CustomTextView(
                                '詳細 ＞',
                                color: Colors.white,
                                type: TDSFontType.labelMedium,
                              ),
                            ],
                          ),
          ),
        ),
      );
    });
  }
}
