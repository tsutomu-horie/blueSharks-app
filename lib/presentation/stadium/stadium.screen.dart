import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/LocalFullScreen/local_full_screen.screen.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/stadium.controller.dart';

class StadiumScreen extends GetView<StadiumController> {
  const StadiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StadiumController controller = Get.put(StadiumController());

    final List<String> stadiumImageByBus = [
      'img-wrapper.png',
      'img-wrapper-1.png',
      'img-wrapper-2.png',
      'img-wrapper-3.png',
      'img-wrapper-4.png',
      'img-wrapper-5.png',
      'img-wrapper-6.png',
      'img-wrapper-7.png'
    ];

    final List<String> stadiumImageParking = [
      'img-wrapper.png',
      'img-wrapper-1.png',
    ];

    final List<String> homeStadiumImage = [
      'home-ground_ph.png',
      'home_g-1.png',
      'home_g-2.png',
      'home_g-3.png',
      'home_g-4.png',
    ];

    final GlobalKey keyAccess = GlobalKey(); // Key for item 10
    final GlobalKey ground = GlobalKey(); // Key for item 10
    final GlobalKey spectator = GlobalKey(); // Key for item 10

    return Scaffold(
      backgroundColor: BrandColor.main,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        "assets/images/image_stadium.png",
                        fit: BoxFit.cover,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 16.w,
                                ),
                                Flexible(
                                    child: Center(
                                        child: CustomTextView(
                                  LocaleKeys.host_stadium.tr,
                                  color: TextColor.inverse,
                                  type: TDSFontType.bodyTextMedium,
                                  align: TextAlign.center,
                                ))),
                                SizedBox(
                                  width: 16.w,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16.w,
                                ),
                                Container(
                                  height: 1,
                                  width: 15.w,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 16.w,
                                ),
                                Flexible(
                                  child: Text(
                                    LocaleKeys.host_stadium_en.tr,
                                    style: TextStyle(
                                        fontSize: 20.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 16.w,
                                ),
                                Container(
                                  height: 1,
                                  width: 15.w,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 16.w,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 32.h,
                            ),
                            CustomTextView(
                              Constants.stadiumName,
                              color: TextColor.inverse,
                              type: TDSFontType.headlineSmall,
                              align: TextAlign.center,
                            ),
                            SizedBox(
                              height: 8.h,
                            ),
                            CustomTextView(
                              Constants.stadiumAddress,
                              color: TextColor.inverse,
                              type: TDSFontType.bodyTextLarge,
                              align: TextAlign.center,
                            ),
                            SizedBox(
                              height: 33.h,
                            ),
                            SizedBox(
                              width: 188.w,
                              height: 40.h,
                              child: ElevatedButton(
                                  onPressed: () {
                                    openGoogleMaps();
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/vectors/ic_stadium.svg",
                                        width: 20.w,
                                        height: 20.h,
                                        color: BrandColor.main,
                                      ),
                                      CustomTextView(
                                        LocaleKeys.stadium_map.tr,
                                        type: TDSFontType.labelLarge,
                                        color: BrandColor.main,
                                      )
                                    ],
                                  )),
                            )
                          ],
                        ),
                      )
                    ],
                  )),
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              children: [
                SizedBox(
                  width: 16.w,
                ),
                buttonNavigation(SvgPicture.asset("assets/vectors/ic_map.svg"),
                    LocaleKeys.access.tr, () {
                  controller.scrollToWidget(keyAccess);
                }),
                SizedBox(
                  width: 16.w,
                ),
                buttonNavigation(
                    SvgPicture.asset("assets/vectors/ic_gallery.svg"),
                    LocaleKeys.ground.tr, () {
                  controller.scrollToWidget(ground);
                }),
                SizedBox(
                  width: 16.w,
                ),
                buttonNavigation(
                    SvgPicture.asset("assets/vectors/iconoir_binocular.svg"),
                    LocaleKeys.spectator_rules.tr, () {
                  controller.scrollToWidget(spectator);
                }),
                SizedBox(
                  width: 16.w,
                ),
              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
                color: Color(0xFFFAFAFA),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 24.h,
                  ),
                  DefaultHeaderTitleView(
                    key: keyAccess,
                    LocaleKeys.access.tr,
                    LocaleKeys.access_en.tr.toUpperCase(),
                    showDivider: false,
                  ),
                  SizedBox(
                    height: 24.h,
                  ),
                  SizedBox(
                      width: 343.w,
                      height: 258.h,
                      child: Image.asset("assets/images/image_location.png")),
                  SizedBox(
                    height: 24.h,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      SvgPicture.asset(
                        "assets/vectors/ic_mascot_fullbody.svg",
                        width: 87.w,
                        height: 155.h,
                      ),
                      SizedBox(
                        width: 24.w,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextView(
                              Constants.stadiumTitle.tr,
                              type: TDSFontType.labelLarge,
                            ),
                            Divider(
                              color: BorderColor.primary,
                              height: 24.h,
                            ),
                            CustomTextView(
                              Constants.stadiumSubtitle.tr,
                              type: TDSFontType.bodyTextMedium,
                            ),
                            Divider(
                              color: BorderColor.primary,
                              height: 24.h,
                            ),
                            CustomTextView(
                              Constants.stadiumDescription.tr,
                              type: TDSFontType.bodyTextSmall,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 24.h,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.w, horizontal: 12.w),
                              width: double.infinity,
                              color: BrandColor.background,
                              child: CustomTextView(
                                align: TextAlign.center,
                                LocaleKeys.access_to_the_ground.tr,
                                type: TDSFontType.labelLarge,
                                color: TextColor.inverse,
                              ),
                            ),
                            SizedBox(
                              height: 12.h,
                            ),
                            Container(
                              color: BackgroundColor.secondary,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: LocaleKeys
                                    .access_to_the_ground_desc.tr
                                    .split("\n")
                                    .map((point) {
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.0.h),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Baseline(
                                          baseline: 16.sp,
                                          // Adjust this value to move the bullet more upwards
                                          baselineType: TextBaseline.alphabetic,
                                          child: Text(
                                            "• ", // Bullet symbol
                                            style: TextStyle(
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: CustomTextView(
                                            point,
                                            type: TDSFontType.labelLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(
                              height: 24.h,
                            ),
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.on_foot.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                            SizedBox(
                              height: 8.h,
                            ),
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.on_foot_desc.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 24.h,
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 2,
                    ),
                    itemCount: stadiumImageByBus.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        "assets/images/image_stadium_bus/${stadiumImageByBus[index]}",
                        fit: BoxFit.fitWidth,
                      );
                    },
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.by_bus.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                            SizedBox(
                              height: 8.h,
                            ),
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.by_bus_desc.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 2,
                    ),
                    itemCount: stadiumImageParking.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        "assets/images/image_stadium_parking/${stadiumImageParking[index]}",
                        fit: BoxFit.fitWidth,
                      );
                    },
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.parking_fee.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                            SizedBox(
                              height: 8.h,
                            ),
                            CustomTextView(
                              align: TextAlign.start,
                              LocaleKeys.parking_fee_desc.tr,
                              type: TDSFontType.titleSmall,
                              color: TextColor.primary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  DefaultHeaderTitleView(
                    key: ground,
                    LocaleKeys.host_ground.tr,
                    LocaleKeys.host_ground_en.tr,
                    showDivider: false,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: 5 / 4,
                          child: SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                                "assets/images/home_stadium/${homeStadiumImage[0]}"),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12.h,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                      ),
                      Flexible(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                          ),
                          itemCount: homeStadiumImage.length - 1,
                          itemBuilder: (context, index) {
                            return Image.asset(
                              "assets/images/home_stadium/${homeStadiumImage[index + 1]}",
                              fit: BoxFit.fitWidth,
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 16.w,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  DefaultHeaderTitleView(
                    key: spectator,
                    LocaleKeys.spectator_rules_sub.tr,
                    LocaleKeys.spectator_rules_sub_en.tr,
                    showDivider: false,
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.w, horizontal: 16.h),
                    child: Container(
                      color: BackgroundColor.secondary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: LocaleKeys.spectator_rules_desc.tr
                            .split("\n")
                            .map((point) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Baseline(
                                  baseline: 16.sp,
                                  // Adjust this value to move the bullet more upwards
                                  baselineType: TextBaseline.alphabetic,
                                  child: Text(
                                    "• ", // Bullet symbol
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: CustomTextView(
                                    point,
                                    type: TDSFontType.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32.h,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonNavigation(SvgPicture icon, String title, Function onScroll) {
    return InkWell(
      onTap: () {
        onScroll();
      },
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0x9e364367),
            borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.symmetric(
          vertical: 12.h,
        ),
        child: Column(
          children: [
            icon,
            SizedBox(
              height: 8.h,
            ),
            Row(
              children: [
                SizedBox(
                  width: 11.8.w,
                ),
                SizedBox(
                  width: 80.w,
                  child: CustomTextView(
                    title,
                    type: TDSFontType.labelMedium,
                    color: TextColor.inverse,
                    align: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 11.8.w,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openGoogleMaps() async {
    // const String googleMapsUrl = 'https://www.google.com/maps?ll=35.648557,139.82359&z=17&t=m&hl=ja&gl=JP&mapclient=embed&cid=1264634736669123728';
    //
    // // Check if the URL can be launched
    // if (await canLaunch(googleMapsUrl)) {
    //   await launch(googleMapsUrl);
    // } else {
    //   throw 'Could not launch $googleMapsUrl';
    // }
    
    Get.to(() => LocalFullScreenScreen(imageUrl: 'assets/images/stadiumImage.jpg'));
  }
}
