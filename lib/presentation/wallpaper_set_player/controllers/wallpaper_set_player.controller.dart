import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/member/controllers/member.controller.dart';
import 'package:koto_blue_sharks/utils/String+extensions.dart';

class WallpaperSetPlayerController extends GetxController {
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  final GalleryProvider apiProvider = GalleryProvider();
  final RxList<CategorizedPlayerGroup> wallpaperList = RxList([]);
  final MediaProvider mediaProvider = MediaProvider();
  final isLoading = true.obs;

  // Store both original categories and processed player groups
  List<WallpaperCategory> _originalCategories = [];
  List<CategorizedPlayerGroup> _allPlayerGroups = [];

  final List<String> playerCategory = [LocaleKeys.forward_short.tr, LocaleKeys.back_short.tr, LocaleKeys.staff.tr];

  @override
  void onInit() {
    super.onInit();
    getWallpaper();
    mediaProvider.onInit();
  }

  void getWallpaper() async {
    apiProvider.onInit();

    final response = await apiProvider.fetchGalleryPlayer((){
      getWallpaper();
    });

    // Store the original response
    _originalCategories = response;
    // Process and store all player groups
    _allPlayerGroups = processWallpaperCategories(_originalCategories);
    // Set initial wallpaper list
    wallpaperList.value = filterPlayerGroups(_allPlayerGroups);
    isLoading.value = false;

  }
  void onSelectPosition(String selectedPos) {
    selectedPosition.value = selectedPos;
    // Filter existing processed data without fetching or reprocessing
    wallpaperList.value = filterPlayerGroups(_allPlayerGroups);
    print("filter wallpaper ${filterPlayerGroups(_allPlayerGroups)}");
  }

  List<CategorizedPlayerGroup> processWallpaperCategories(List<WallpaperCategory> categories) {
    print("processWallpaperCategories ${categories}");
    const forwardRoles = ["prop", "hooker", "lock", "flanker", "no8"];
    const backRoles = ["scrumhalf", "standoff", "center", "wing", "fullback"];
    const staffRoles = ["staff"];

    List<MemberGroup> forwardGroups = [];
    List<MemberGroup> backGroups = [];
    List<MemberGroup> staffGroups = [];

    // Process each category
    for (var category in categories) {
      List<Member> members = category.wallpapers.map((wallpaper) {
        return Member(
          id: wallpaper.id,
          date: '',
          modified: '',
          slug: wallpaper.name.toLowerCase(),
          status: 'active',
          type: 'player',
          playerNameKatakana: wallpaper.kat_name,
          link: wallpaper.photo,
          title: Title(rendered: wallpaper.kan_name),
          categoryId: category.id,
          categorySlug: category.name.toLowerCase(),
          categoryName: category.name,
          custom_field: null,
        );
      }).toList();

      MemberGroup memberGroup = MemberGroup(title: category.name.capitalizeText(), players: members);

      if (forwardRoles.contains(category.name.toLowerCase())) {
        forwardGroups.add(memberGroup);
        print("processWallpaperCategories 2 ${forwardGroups}");
      } else if (backRoles.contains(category.name.toLowerCase())) {
        backGroups.add(memberGroup);
      } else if (staffRoles.contains(category.name.toLowerCase())) {
        staffGroups.add(memberGroup);
      }
    }

    return [
      if (forwardGroups.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.forward.tr,
          playerGroups: forwardGroups,
        ),
      if (backGroups.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.back.tr,
          playerGroups: backGroups,
        ),
      if (staffGroups.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.staff.tr,
          playerGroups: staffGroups,
        ),
    ];
  }

  List<CategorizedPlayerGroup> filterPlayerGroups(List<CategorizedPlayerGroup> allGroups) {
    // Filter based on selected position
    print("selectedPos ${selectedPosition.value}");
    if (selectedPosition.value == "FW") {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.forward.tr).toList();
    } else if (selectedPosition.value == "BK") {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.back.tr).toList();
    } else if (selectedPosition.value == LocaleKeys.staff.tr) {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.staff.tr).toList();
    }

    // Return all groups if no specific position is selected
    return allGroups;
  }
}
