import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/video_thumbnail_view.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_goods_section.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_matches_section.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_banners_section.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_players_section.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_standings_section.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_featured_topics.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_follow_section.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/point/widgets/home_point_card.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/home.controller.dart';

class HomeScreen extends GetView<MainController> {
  const HomeScreen(
    this.onOpenDetail,
    this.navigateToInfoList,
    this.navigateToGameGuide, {
    super.key,
  });

  final Function(Post) onOpenDetail;
  final Function() navigateToInfoList;
  final VoidCallback navigateToGameGuide;

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());

    homeController.getWallpaper();
    homeController.screenInit();
    return Theme(
        data: Theme.of(context).copyWith(
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: 'LINESeedJP')),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: RefreshIndicator(
            onRefresh: () async {
              homeController.isLoading.value = true;
              homeController.getWallpaper();
              homeController.screenInit(refreshWebsiteContent: true);
            },
            child: SingleChildScrollView(
                child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 9 / 9.3,
                  child: Obx(() {
                    return homeController.selectedWallpaper.value != ""
                        ? CustomImageView(
                            image: homeController.selectedWallpaper.value,
                            radius: 0.r,
                            customFit: BoxFit.cover,
                          )
                        : Image.asset(
                            "assets/images/default_wallpaper.png",
                            fit: BoxFit.cover,
                          );
                  }),
                ),
                Obx(() => WebsiteBannersSection(
                    banners: homeController.websiteBanners.toList())),
                const RenewalHomeHeading('次の試合', 'NEXT MATCH',
                    key: ValueKey('renewal-next-match-heading')),
                Obx(() => WebsiteMatchesSection(
                      schedule: homeController.websiteSchedule.value,
                      now: homeController.websiteClock(),
                    )),
                Obx(() => WebsiteStandingsSection(
                    standings: homeController.websiteStandings.value)),
                _trainingGameEntry(),
                _gameGuideEntry(),
                const HomePointCard(),
                const RenewalHomeHeading('注目ニュース', 'FEATURED TOPICS'),
                Obx(() => RenewalFeaturedTopics(
                    posts: homeController.topicsData.value.toList(),
                    loadImage: (post) => post.featured_media != null &&
                            post.featured_media != 0
                        ? homeController
                            .getFeaturedImage('${post.featured_media}')
                        : homeController.getNewsImage(post.content.rendered),
                    onOpen: onOpenDetail)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RenewalViewAllButton(
                        key: const ValueKey('renewal-featured-view-all'),
                        onPressed: navigateToInfoList)),
                const RenewalHomeHeading('公式動画', 'OFFICIAL VIDEO'),
                Obx(() => VideoThumbnailView(
                      videos: homeController.websiteVideos.toList(),
                    )),
                Obx(() => WebsitePlayersSection(
                      data: homeController.websitePlayers.value,
                    )),
                Obx(() => WebsiteGoodsSection(
                      goods: homeController.websiteGoods.toList(),
                    )),
                const RenewalFollowSection(),
              ],
            )),
          ),
        ));
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: BorderColor.disabled,
      highlightColor: BorderColor.subtle,
      child: Container(
        width: 320.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: BorderColor.disabled,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }

  Widget _gameGuideEntry() => _designBanner(
      'assets/images/renewal/guide_banner.jpg',
      'ホストゲームの楽しみ方',
      navigateToGameGuide);

  Widget _designBanner(String asset, String label, VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Semantics(
              button: true,
              label: label,
              child: Material(
                  color: Colors.white,
                  child: InkWell(
                      onTap: onTap,
                      child: Image.asset(asset,
                          excludeFromSemantics: true, fit: BoxFit.contain)))));

  /// ホームから育成ゲームへ遷移する入口を表示します。
  Widget _trainingGameEntry() => _designBanner(
      'assets/images/renewal/training_banner.jpg',
      '鮫太朗育成計画',
      () => Get.toNamed(Routes.TRAINING_GAME_LAUNCH, arguments: true));
}
