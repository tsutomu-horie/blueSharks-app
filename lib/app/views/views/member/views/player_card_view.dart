import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/controllers/player_list.controller.dart';
import 'package:koto_blue_sharks/presentation/profile/mypage/mypage.screen.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class PlayerCardView extends GetView<PlayerListController> {
  const PlayerCardView(this.player, this.position, this.onSet,
      this.mediaProvider, this.isSetWallpaper, this.onTap,
      {super.key});

  final Member player;
  final String position;
  final Function(String, String)? onSet;
  final MediaProvider mediaProvider;
  final bool isSetWallpaper;
  final Function(String, String) onTap;



  @override
  Widget build(BuildContext context) {
    print("get player image ${player}");
    final PlayerListController controller = Get.put(PlayerListController());

    final imageUrl = "${player.custom_field?.profile_image_1?.first}";

    if (!isSetWallpaper) {
      final preloadedImage = controller.preloadedImages[imageUrl];


      if (preloadedImage != null) {
        return buildPlayerCard(preloadedImage);
      }

      return FutureBuilder<String>(
        future: getImage(mediaProvider, imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return buildPlayerCard(snapshot.data!);
          }
          return Center(child: shimmer());
        },
      );
    } else {
      return InkWell(
        onTap: () {
          onTap(player.link, position);
        },
        child: Stack(
          children: [
            player.link != ''
                ? SizedBox(
              height: double.infinity,
              child:
              CustomImageView(
                image: controller.imageCompressor(player.link),
                radius: 4.r,
                customFit: BoxFit.fitHeight,
              ),)
                :
            Container(
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
                  Text(
                    player.title.rendered,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ); // Display image
    }
  }

  Widget buildPlayerCard(String postImage) {
    return InkWell(
      onTap: () => onTap(postImage, position),
      child: Stack(
        children: [
          postImage != ''
              ? SizedBox(
                  height: double.infinity,
                  child: CustomImageView(
                    image: controller.imageCompressor(postImage),
                    radius: 4.r,
                    customFit: BoxFit.fitHeight,
                  ))
              :
          Container(
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
                Text(
                  player.title.rendered,
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
