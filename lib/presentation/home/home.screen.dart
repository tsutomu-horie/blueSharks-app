import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
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
    this.onOpenLatestGuide,
    super.key,
  });

  final Function(Post) onOpenDetail;
  final Function() navigateToInfoList;
  final VoidCallback navigateToGameGuide;
  final ValueChanged<GameGuidePost>? onOpenLatestGuide;

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());

    homeController.getWallpaper();
    homeController.screenInit();
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'LINESeedJP'),
      ),
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
                Obx(
                  () => WebsiteBannersSection(
                    banners: homeController.websiteBanners.toList(),
                  ),
                ),
                const RenewalHomeHeading(
                  '次の試合',
                  'NEXT MATCH',
                  key: ValueKey('renewal-next-match-heading'),
                ),
                Obx(
                  () => WebsiteMatchesSection(
                    schedule: homeController.websiteSchedule.value,
                    now: homeController.websiteClock(),
                  ),
                ),
                Obx(
                  () => WebsiteStandingsSection(
                    standings: homeController.websiteStandings.value,
                  ),
                ),
                _gameGuideEntry(),
                if (onOpenLatestGuide != null)
                  Obx(() =>
                      _latestGuideEntry(homeController.latestGuide.value)),
                _trainingGameEntry(),
                const HomePointCard(),
                const RenewalHomeHeading('注目ニュース', 'FEATURED TOPICS'),
                Obx(
                  () => RenewalFeaturedTopics(
                    posts: homeController.topicsData.value.toList(),
                    loadImage: (post) => post.featured_media != null &&
                            post.featured_media != 0
                        ? homeController.getFeaturedImage(
                            '${post.featured_media}',
                          )
                        : homeController.getNewsImage(post.content.rendered),
                    onOpen: onOpenDetail,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RenewalViewAllButton(
                    key: const ValueKey('renewal-featured-view-all'),
                    onPressed: navigateToInfoList,
                  ),
                ),
                const RenewalHomeHeading('公式動画', 'OFFICIAL VIDEO'),
                Obx(
                  () => VideoThumbnailView(
                    videos: homeController.websiteVideos.toList(),
                  ),
                ),
                Obx(
                  () => WebsitePlayersSection(
                    data: homeController.websitePlayers.value,
                  ),
                ),
                Obx(
                  () => WebsiteGoodsSection(
                    goods: homeController.websiteGoods.toList(),
                  ),
                ),
                const RenewalFollowSection(),
              ],
            ),
          ),
        ),
      ),
    );
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
        navigateToGameGuide,
      );

  Widget _latestGuideEntry(GameGuidePost? post) {
    if (post == null) return const SizedBox.shrink();

    final date = post.matchDate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Semantics(
        button: true,
        label: post.title,
        child: Material(
          color: Colors.white,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: BorderColor.primary),
              ),
            ),
            child: InkWell(
              onTap: () => onOpenLatestGuide!(post),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                child: Row(
                  children: [
                    if (post.thumbnailUrl case final imageUrl?) ...[
                      Expanded(
                        flex: 27,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 190,
                              maxHeight: 230,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.scaleDown,
                              errorWidget: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                    ],
                    Expanded(
                      flex: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: TextStyle(
                              color: BrandColor.main,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (date != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy.MM.dd').format(date),
                              style: const TextStyle(
                                color: Color(0xff485870),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(Icons.chevron_right, size: 18, color: BrandColor.main),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
              child: Image.asset(
                asset,
                excludeFromSemantics: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );

  /// ホームから育成ゲームへ遷移する入口を表示します。
  Widget _trainingGameEntry() => _designBanner(
        'assets/images/renewal/training_banner.jpg',
        '鮫太朗育成計画',
        () => Get.toNamed(Routes.TRAINING_GAME_LAUNCH, arguments: true),
      );
}
