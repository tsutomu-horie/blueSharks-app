import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/member/controllers/member.controller.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/register_email.screen.dart';
import 'package:koto_blue_sharks/presentation/wallpaper_set_player/controllers/wallpaper_set_player.controller.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

import '../member.dart';

class PlayerCardView extends GetView {
  const PlayerCardView(this.player, this.position, this.onSet, this.mediaProvider, this.isSetWallpaper, this.onTap, {super.key});

  final Member player;
  final String position;
  final Function(String, String)? onSet;
  final MediaProvider mediaProvider;
  final bool isSetWallpaper;
  final Function(String, String) onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getImage(mediaProvider,
          "${player.custom_field?.profile_image_1?.first}"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Loading indicator
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else {
          String postImage = "";
          if (isSetWallpaper) {
            postImage = player.link;
          } else {
            postImage = snapshot.data ?? ''; // Fallback in case of null
          }

          // Use your CustomImageView with the fetched image URL
          return InkWell(
            onTap: () {
              onTap(postImage,  position);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextView(
                        player.playerNameKatakana ?? "",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      CustomTextView(
                        player.title.rendered,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ); // Display image
        }
      },
    );
  }
}
