import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/member/controllers/member.controller.dart';

class WallpaperSetPlayerController extends GetxController {
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  final GalleryProvider apiProvider = GalleryProvider();
  final RxList<CategorizedPlayerGroup> wallpaperList = RxList([]);
  final MediaProvider mediaProvider = MediaProvider();


  @override
  void onInit() {
    super.onInit();
    getWallpaper();
    mediaProvider.onInit();
  }

  void getWallpaper() async {
    apiProvider.onInit();

    final response = await apiProvider.fetchGalleryPlayer((){

    });

    wallpaperList.value = convertToCategorizedPlayerGroups(response);

  }


  List<CategorizedPlayerGroup> convertToCategorizedPlayerGroups(List<WallpaperCategory> categories) {
    // Define the roles under Forward and Back
    const forwardRoles = ["prop", "hooker", "lock", "flanker", "no8"];
    const backRoles = ["scrumhalf", "standoff", "center", "wing", "fullback"];

    // Initialize lists for Forward and Back groups
    List<MemberGroup> forwardGroups = [];
    List<MemberGroup> backGroups = [];

    // Process each category
    for (var category in categories) {
      // Convert wallpapers to Member objects
      List<Member> members = category.wallpapers.map((wallpaper) {
        return Member(
          id: wallpaper.id,
          date: '', // Placeholder, as date is not provided
          modified: '', // Placeholder
          slug: wallpaper.name.toLowerCase(),
          status: 'active', // Assuming status as active
          type: 'player', // Assuming type as player
          link: wallpaper.photo,
          title: Title(rendered: wallpaper.name),
          categoryId: category.id,
          categorySlug: category.name.toLowerCase(),
          categoryName: category.name,
          custom_field: null, // Placeholder, as custom fields are not provided
        );
      }).toList();

      // Create MemberGroup based on category name
      MemberGroup memberGroup = MemberGroup(title: category.name, players: members);

      // Add to Forward or Back group based on category name
      if (forwardRoles.contains(category.name.toLowerCase())) {
        forwardGroups.add(memberGroup);
      } else if (backRoles.contains(category.name.toLowerCase())) {
        backGroups.add(memberGroup);
      }
    }

    // Return a list of CategorizedPlayerGroups
    return [
      CategorizedPlayerGroup(categoryTitle: "Forward", playerGroups: forwardGroups),
      CategorizedPlayerGroup(categoryTitle: "Back", playerGroups: backGroups),
    ];
  }
}
