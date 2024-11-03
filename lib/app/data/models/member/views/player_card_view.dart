import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/member/controllers/member.controller.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/register_email.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

import '../member.dart';

class PlayerCardView extends GetView {
  const PlayerCardView(this.player, this.position, this.onSet, this.memberController, this.isSetWallpaper, {super.key});

  final Member player;
  final String position;
  final Function(String)? onSet;
  final MemberController memberController;
  final bool isSetWallpaper;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getImage(memberController.mediaProvider,
          "${player.custom_field?.profile_image_1?.first}"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Loading indicator
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else {
          final postImage = snapshot.data ?? ''; // Fallback in case of null

          // Use your CustomImageView with the fetched image URL
          return InkWell(
            onTap: () {
              if (isSetWallpaper) {
                showSetWallpaper(memberController, context, postImage,
                    player.title.rendered, position, onSet);
              } else {
                memberController.navigateToMemberDetail(player);
              }
            },
            child: Stack(
              children: [
                postImage != ''
                    ? SizedBox(
                        height: double.infinity,
                        child: CustomImageView(
                          image: postImage,
                          radius: 4.r,
                          customFit: BoxFit.fitHeight,
                        ))
                    : Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.w,
                  left: 8.w,
                  right: 8.w,
                  child: CustomTextView(
                    player.title.rendered,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ); // Display image
        }
      },
    );
  }

  void showSetWallpaper(MemberController memberController, BuildContext context,
      String image, String playerName, String playerPosition, Function(String)? onSet) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          height: 292.h, // Fixed height for the bottom sheet
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 44.h,
                child: Row(
                  children: [
                    Flexible(
                        child: SizedBox(
                            width: double.infinity,
                            child: CustomTextView(
                              LocaleKeys.set_wallpaper_title3.tr,
                              type: TDSFontType.titleMedium,
                            ))),
                  ],
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: BorderColor.subtle, width: 1)),
                child: Row(
                  children: [
                    image != ''
                        ? SizedBox(
                        width: 81.w,
                        child: AspectRatio(
                          aspectRatio: 3/4,
                          child: CustomImageView(
                            image: image,
                            radius: 4.r,
                            customFit: BoxFit.fitHeight,
                          ),
                        ))
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(
                      width: 12.w,
                    ),
                    Column(
                      children: [
                        CustomTextView(playerName, type: TDSFontType.titleSmall, color: TextColor.secondary,),
                        SizedBox(height: 12.h,),
                        Container(
                            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                            decoration: BoxDecoration(color: BrandColor.surface, borderRadius: BorderRadius.circular(24.r),),
                            child: CustomTextView(playerPosition, type: TDSFontType.titleSmall, color: TextColor.secondary)),

                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 28.h,),
              Row(
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 48.h,
                      width: double.infinity,
                      child: OutlinedButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.all(BorderSide(
                              color: BrandColor
                                  .main) // Set your desired color here
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        child: CustomTextView(LocaleKeys.cancel.tr, color: BrandColor.main,),

                      ),
                    ),
                  ),
                  SizedBox(width: 16.w,),
                  Flexible(
                    child: SizedBox(
                      height: 48.h,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main, ),
                        onPressed: () {
                          if (onSet != null) {
                            onSet(playerName);
                            Get.back();
                          } else {
                            Get.to(() => RegisterEmailScreen(playerName));
                          }
                        },
                        child: CustomTextView(LocaleKeys.confirm.tr, color: BrandColor.content,),

                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
