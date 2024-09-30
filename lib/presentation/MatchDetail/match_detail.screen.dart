import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';
import 'package:koto_blue_sharks/app/views/views/html_text_view.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/match_detail.controller.dart';

class MatchDetailScreen extends GetView<MatchDetailController> {
  const MatchDetailScreen(this.data, {super.key});

  final MatchResultBySeason? data;

  @override
  Widget build(BuildContext context) {
    final MatchDetailController controller = Get.put(MatchDetailController());

    final gameDate = data?.custom_field.gameDate ?? [];
    final date = gameDate.isNotEmpty
        ? convertJapaneseDate(gameDate.first)
        : {'formattedDate': "", "dayOfWeek": ""};
    final matchStatus =
        data?.custom_field != null ? getStatusMatch(data!.custom_field) : null;
    final customField = data?.custom_field;

    final List<String> tabs = [
      'Member',
      'Report',
      'Gallery',
    ];

    return Scaffold(
      appBar: AppBar(
        title: CustomTextView(
          LocaleKeys.game_detail.tr,
          type: TDSFontType.titleMedium,
          color: TextColor.inverse,
        ),
        centerTitle: true,
        backgroundColor: BrandColor.main,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: IconColor.inverse,
          ),
          // Change this to your desired icon
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: data != null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 16.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                          child: CustomTextView(
                        data!.title.rendered,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TextColor.primary,
                            fontSize: 18.sp),
                        align: TextAlign.center,
                      )),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                          child: CustomTextView(date['formattedDate'] ?? "",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: BrandColor.main,
                                  fontSize: 20.sp))),
                      SizedBox(
                        width: 6.w,
                      ),
                      CustomTextView(date['dayOfWeek'] ?? "",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: TextColor.secondary,
                              fontSize: 12.sp)),
                      SizedBox(
                        width: 4.w,
                      ),
                      CustomTextView(data?.custom_field.gameTime?.first ?? "",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: BrandColor.main,
                              fontSize: 16.sp)),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        color: matchStatus?["isHome"] == true
                            ? DangerColor.main
                            : BrandColor.main,
                        child: CustomTextView(
                            matchStatus?["isHome"] ? "HOME" : "VISITOR",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: TextColor.inverse,
                                fontSize: 14.sp)),
                      ),
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: BrandColor.main,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/vectors/ic_stadium.svg",
                                width: 20.w,
                                height: 20.w,
                              ),
                              SizedBox(
                                width: 10.w,
                              ),
                              CustomTextView(
                                  formatLocation(
                                      data!.custom_field.location?.first ?? ""),
                                  color: TextColor.inverse),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            FutureBuilder<String>(
                              future:
                                  controller.getImage(matchStatus?["teamLogo"]),
                              // Wait for the image URL to resolve
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 12.w),
                                    child: shimmer(),
                                  );
                                } else if (snapshot.hasError) {
                                  return SizedBox(
                                      width: 64.w,
                                      height: 64.w,
                                      child: const Center(
                                        child: Icon(Icons.warning),
                                      ));
                                } else {
                                  // Use the actual image URL returned from the Future
                                  final teamLogo = snapshot.data ??
                                      'https://example.com/placeholder.png'; // Fallback in case of null

                                  return SizedBox(
                                      width: 64.w,
                                      height: 64.w,
                                      child: CustomImageView(
                                        image: teamLogo,
                                        customFit: BoxFit.fitWidth,
                                      ));
                                }
                              },
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            SizedBox(
                                height: 40.h,
                                width: 104.w,
                                child: HtmlTextView(
                                  matchStatus?["teamName"],
                                  style: Style(
                                      fontSize: FontSize(12.sp),
                                      color: PrimaryColor.pressed,
                                      fontWeight: FontWeight.w700,
                                      maxLines: 2,
                                      textOverflow: TextOverflow.ellipsis,
                                      alignment: Alignment.center),
                                )),
                          ],
                        ),
                        SizedBox(
                          width: 120.w,
                          height: 82.h,
                          child: Column(
                            children: [
                              Container(
                                width: 56.w,
                                height: 32.h,
                                color: BrandColor.background,
                                child: Center(
                                  child: CustomTextView(
                                    customField?.game_result?.first != null &&
                                            customField!.game_result!.first !=
                                                "試合前"
                                        ? customField.game_result!.first
                                        : "-",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: TextColor.inverse),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 4.h,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomTextView(
                                    customField?.team_score_1?.first != null &&
                                            customField!.team_score_1!.first !=
                                                "試合前"
                                        ? customField.team_score_1!.first
                                        : "0",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: BrandColor.hover,
                                        fontSize: 32.sp),
                                  ),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  CustomTextView("-",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: TextColor.primary,
                                          fontSize: 32.sp)),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  CustomTextView(
                                      customField?.team_score_2?.first !=
                                                  null &&
                                              customField!
                                                      .team_score_2!.first !=
                                                  "試合前"
                                          ? customField.team_score_2!.first
                                          : "0",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: TextColor.primary,
                                          fontSize: 32.sp)),
                                ],
                              )
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            FutureBuilder<String>(
                              future:
                              controller.getImage(matchStatus?["opponentLogo"]),
                              // Wait for the image URL to resolve
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 12.w),
                                    child: shimmer(),
                                  );
                                } else if (snapshot.hasError) {
                                  return SizedBox(
                                      width: 64.w,
                                      height: 64.w,
                                      child: const Center(
                                        child: Icon(Icons.warning),
                                      ));
                                } else {
                                  // Use the actual image URL returned from the Future
                                  final opponentLogo = snapshot.data ??
                                      'https://example.com/placeholder.png'; // Fallback in case of null

                                  return SizedBox(
                                      width: 64.w,
                                      height: 64.w,
                                      child: CustomImageView(
                                        image: opponentLogo,
                                        customFit: BoxFit.fitWidth,
                                      ));
                                }
                              },
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            SizedBox(
                                height: 40.h,
                                width: 104.w,
                                child: HtmlTextView(
                                  matchStatus?["teamName"],
                                  style: Style(
                                      fontSize: FontSize(12.sp),
                                      color: PrimaryColor.pressed,
                                      fontWeight: FontWeight.w700,
                                      maxLines: 2,
                                      textOverflow: TextOverflow.ellipsis,
                                      alignment: Alignment.center),
                                )),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Table(
                    border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.white)),
                    children: [
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              LocaleKeys.first_half.tr,
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              LocaleKeys.second_half.tr,
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              " ",
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              LocaleKeys.first_half.tr,
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              LocaleKeys.second_half.tr,
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ]),
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_T_first_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_T_second_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              "T",
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.labelMedium,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_T_first_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_T_second_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ]),
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_G_first_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_G_second_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              "G",
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.labelMedium,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_G_first_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_G_second_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ]),
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_PG_first_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_PG_second_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              "PG",
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.labelMedium,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_PG_first_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_PG_second_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ]),
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_DG_first_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_DG_second_half_1?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              "DG",
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.labelMedium,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_DG_first_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_DG_second_half_2?.first ?? "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ]),
                      TableRow(children: [
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_RESULT_first_half_1?.first ??
                                  "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_RESULT_second_half_1?.first ??
                                  "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BrandColor.main,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              LocaleKeys.total_amount.tr,
                              align: TextAlign.center,
                              color: TextColor.inverse,
                              type: TDSFontType.labelMedium,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_RESULT_first_half_2?.first ??
                                  "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                        Container(
                            width: 72.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: BackgroundColor.secondary,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Center(
                                child: CustomTextView(
                              customField?.team_RESULT_second_half_2?.first ??
                                  "0",
                              align: TextAlign.center,
                              color: TextColor.secondary,
                              type: TDSFontType.bodyTextSmall,
                            ))),
                      ])
                    ],
                  ),
                  if (customField?.game_result?.first != null &&
                      customField?.game_result?.first != "試合前")
                    Column(
                      children: [
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          child: Row(
                            children: List.generate(tabs.length, (index) {
                              return Expanded(
                                child: InkWell(
                                  onTap: () => controller.changeTab(index),
                                  child: Obx(() {
                                    final bool isSelected =
                                        controller.selectedIndex.value == index;

                                    return Stack(
                                      alignment: Alignment.bottomCenter,
                                      // Ensure the bottom border sticks at the bottom
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w, vertical: 12.h),
                                          child: Center(
                                            child: Text(
                                              tabs[index],
                                              style: TDSTypography.labelLarge
                                                  .copyWith(
                                                color: isSelected
                                                    ? BrandColor.main
                                                    : TextColor.tertiary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // The bottom border part
                                        if (isSelected)
                                          Positioned(
                                            bottom: 0, // Stick to the bottom
                                            child: Container(
                                              width: 117.w,
                                              // Adjust as per your design (can be based on the tab width)
                                              height: 4.h,
                                              // Thicker border for selected tab
                                              decoration: BoxDecoration(
                                                color: BrandColor.main,
                                                // Border color when selected
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(8.r),
                                                  // Add top left radius
                                                  topRight: Radius.circular(8
                                                      .r), // Add top right radius
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ),
                        Obx(() {
                          return IndexedStack(
                            index: controller.selectedIndex.value,
                            children: [
                              Center(child: Text("Team")),
                              ReportView(data?.content.rendered ?? ""),
                              Center(child: Text("Partner")),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  String formatLocation(String title) {
    // Replace all occurrences of "／" with "・"
    final formattedTitle = title.replaceAll("／", "・");

    // Check if the title contains <br> and split if it does
    if (formattedTitle.contains("<br>")) {
      // Split the string at <br> and return the text before <br>
      return formattedTitle.split("<br>").first.trim();
    }

    // Return the formatted title if <br> is not found
    return formattedTitle;
  }

  Widget ReportView(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultHeaderTitleView(
            LocaleKeys.report.tr, LocaleKeys.report_en.tr.toUpperCase()),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          color: BrandColor.main,
          child: HtmlWidget(
            content,
            textStyle: const TextStyle(
              color: Colors.white, // Set the default text color to white
            ),
            customStylesBuilder: (element) {
              if (element.localName == 'img') {
                return {
                  'max-width': '100%',
                  'height': 'auto'
                }; // Ensure image doesn't overflow
              }
              if (['p', 'span', 'br'].contains(element.localName)) {
                return {'color': 'white'}; // White color
              }
              return null;
            },
          ),
        ),
        Container(
          height: 20.h,
          color: BrandColor.main,
        )
      ],
    );
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: BorderColor.disabled,
      highlightColor: BorderColor.subtle,
      child: Container(
        width: 64.w,
        height: 64.w,
        decoration: BoxDecoration(
          color: BorderColor.disabled,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }
}
