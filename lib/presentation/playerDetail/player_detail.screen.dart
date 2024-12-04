import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';
import 'package:koto_blue_sharks/utils/youtube_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/player_detail.controller.dart';

class MemberDetailScreen extends GetView<PlayerDetailController> {
  const MemberDetailScreen(this.playerData, {super.key});

  final Member? playerData;

  @override
  Widget build(BuildContext context) {
    final PlayerDetailController memberController =
    Get.put(PlayerDetailController());

    return Scaffold(
      appBar: AppBar(
        title: CustomTextView(
          LocaleKeys.player_data.tr,
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
      backgroundColor: BrandColor.main,
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<String>(
              future: getImage(controller.mediaProvider,
                  "${playerData?.custom_field?.main_image?.first}"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator()); // Loading indicator
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                } else {
                  final postImage = snapshot.data ??
                      'https://example.com/placeholder.png'; // Fallback in case of null
        
                  // Use your CustomImageView with the fetched image URL
                  return SizedBox(
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 16 / 13,
                      child: CustomImageView(
                        image: postImage,
                        radius: 0,
                      ),
                    ),
                  );
                }
              },
            ),
            if (playerData?.custom_field?.youtube_embed_src?.first != null)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: BrandColor.main,
                    padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
                    child: CustomTextView(LocaleKeys.youtube_en.tr.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w700,
                          color: TextColor.inverse,
                          fontSize: 18.sp),),
                  ),
                  InkWell(
                    onTap: (){
                      launchURL(context, playerData!.custom_field!.youtube_embed_src!.first);
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 8.w,),
                        Flexible(
                          child: Stack(
                            children: [
                              CustomImageView(image: "${getYouTubeThumbnailUrl(playerData?.custom_field?.youtube_embed_src?.first)}", radius: 2.r,),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: SvgPicture.asset("assets/vectors/ic_youtube.svg", width: 152.w, height: 152.h,),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w,),
                      ],
                    ),
                  ),
                ],
              ),

            Row(
              children: [
                SizedBox(width: 8.w,),
                Flexible(
                  child: FutureBuilder<String>(
                    future: getImage(controller.mediaProvider,
                        "${playerData?.custom_field?.graph_image?.first}"),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator()); // Loading indicator
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      } else {
                        final postImage = snapshot.data ??
                            'https://example.com/placeholder.png'; // Fallback in case of null

                        // Use your CustomImageView with the fetched image URL
                        return Column(
                          children: [
                            if (postImage != "")
                              Container(
                                width: double.infinity,
                                color: BrandColor.main,
                                padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
                                child: CustomTextView(LocaleKeys.graph_en.tr.toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      color: TextColor.inverse,
                                      fontSize: 18.sp),),
                              ),

                            CustomImageView(
                              image: postImage,
                              radius: 0,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 8.w,),
              ],
            ),

            if (playerData?.custom_field?.position_image?.first != null && playerData?.custom_field?.position_image?.first != "")
            Container(
              width: double.infinity,
              color: BrandColor.main,
              padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
              child: CustomTextView(LocaleKeys.position_en.tr.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: TextColor.inverse,
                    fontSize: 18.sp),),
            )
            else
              SizedBox(height: 16.h,),
            Row(
              children: [
                SizedBox(width: 8.w,),
                Flexible(
                  child: FutureBuilder<String>(
                    future: getImage(controller.mediaProvider,
                        "${playerData?.custom_field?.position_image?.first}"),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator()); // Loading indicator
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      } else {
                        final postImage = snapshot.data ??
                            'https://example.com/placeholder.png'; // Fallback in case of null
                  
                        // Use your CustomImageView with the fetched image URL
                        return CustomImageView(
                          image: postImage,
                          radius: 0,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 12.w,),
                Flexible(
                  child: FutureBuilder<String>(
                    future: getImage(controller.mediaProvider,
                        "${playerData?.custom_field?.profile_image_2?.first}"),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator()); // Loading indicator
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading data'));
                      } else {
                        final postImage = snapshot.data ??
                            'https://example.com/placeholder.png'; // Fallback in case of null
                  
                        // Use your CustomImageView with the fetched image URL
                        return CustomImageView(
                          image: postImage,
                          radius: 0,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 8.w,),
              ],
            ),
            Container(
              width: double.infinity,
              color: BrandColor.main,
              padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
              child: CustomTextView(LocaleKeys.personal_data.tr.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: TextColor.inverse,
                    fontSize: 18.sp),),
            ),
            memberSectionData(LocaleKeys.position.tr, playerData?.custom_field?.data_position?.first ?? "ー", false),
            memberSectionData(LocaleKeys.play_position.tr, playerData?.custom_field?.data_play_position?.first ?? "ー", false),
            memberSectionData(LocaleKeys.personal_number.tr, playerData?.custom_field?.data_number?.first ?? "ー", false),
            memberSectionData(LocaleKeys.birth_date_age.tr, playerData?.custom_field?.data_birthday?.first ?? "ー", false),
            memberSectionData(LocaleKeys.height_weight.tr, playerData?.custom_field?.data_height_weight?.first ?? "ー", false),
            memberSectionData(LocaleKeys.birth_place.tr, playerData?.custom_field?.data_birthplace?.first ?? "ー", false),
            memberSectionData(LocaleKeys.school.tr, playerData?.custom_field?.data_school?.first ?? "ー", false),
            memberSectionData(LocaleKeys.high_school.tr, playerData?.custom_field?.data_highschool?.first ?? "ー", false),
            memberSectionData(LocaleKeys.university.tr, playerData?.custom_field?.data_university?.first ?? "ー", false),
            memberSectionData(LocaleKeys.representative_history.tr, playerData?.custom_field?.data_career?.first ?? "ー", false),
            memberSectionData(LocaleKeys.related_company.tr, playerData?.custom_field?.data_belong?.first ?? "ー", false),
            memberSectionData(LocaleKeys.team_awards.tr, playerData?.custom_field?.data_award?.first ?? "ー", false),
            memberSectionData(LocaleKeys.years_of_service.tr, playerData?.custom_field?.data_enrolledyears?.first ?? "ー", false),
            memberSectionData(LocaleKeys.official_caps.tr, playerData?.custom_field?.data_caps?.first ?? "ー", true),
            Container(
              width: double.infinity,
              color: BrandColor.main,
              padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 16.w),
              child: CustomTextView(LocaleKeys.personal_words.tr.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w700,
                    color: TextColor.inverse,
                    fontSize: 18.sp),),
            ),
            memberSectionData(LocaleKeys.nickname.tr, playerData?.custom_field?.words_nickname?.first ?? "ー", true),
            memberSectionData(LocaleKeys.childhood_dream.tr, playerData?.custom_field?.words_dream_child_age?.first ?? "ー", true),
            memberSectionData(LocaleKeys.rugby_reason.tr, playerData?.custom_field?.words_opportunity?.first ?? "ー", true),
            memberSectionData(LocaleKeys.season_highlight.tr, playerData?.custom_field?.words_playsseason?.first ?? "ー", true),
            memberSectionData(LocaleKeys.team_attraction.tr, playerData?.custom_field?.words_goodplay?.first ?? "ー", true),
            memberSectionData(LocaleKeys.one_wish.tr, playerData?.custom_field?.words_wish?.first ?? "ー", true),
            memberSectionData(LocaleKeys.current_obsession.tr, playerData?.custom_field?.words_myboom?.first ?? "ー", true),
            memberSectionData(LocaleKeys.favorite_brand.tr, playerData?.custom_field?.words_favoritebrand?.first ?? "ー", true),
            memberSectionData(LocaleKeys.favorite_color.tr, playerData?.custom_field?.words_color?.first ?? "ー", true),
            memberSectionData(LocaleKeys.recommended_shop.tr, playerData?.custom_field?.words_shop?.first ?? "ー", true),
            memberSectionData(LocaleKeys.favorite_gift.tr, playerData?.custom_field?.words_gift?.first ?? "ー", true),
            memberSectionData(LocaleKeys.favorite_food.tr, playerData?.custom_field?.words_favoritefood?.first ?? "ー", true),
            memberSectionData(LocaleKeys.local_gourmet_spot.tr, playerData?.custom_field?.words_localfood?.first ?? "ー", true),
            SizedBox(height: 32.h,),
          ],
        ),
      ),
    );
  }

  Widget memberSectionData(String title, String? value, bool isLast) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          CustomTextView(title, color: BrandColor.background,),
          CustomTextView("$value", color: TextColor.inverse,),
          SizedBox(height: 16.h,),
          if (isLast != true) DottedLine(dashColor: BrandColor.background)
        ],
      ),
    );
  }

  void launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }
}
