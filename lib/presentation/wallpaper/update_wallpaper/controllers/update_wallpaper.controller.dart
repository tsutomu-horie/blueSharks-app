import 'package:flutter/material.dart' as materialGlobal;
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/String+extensions.dart';

class UpdateWallpaperController extends GetxController {
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  final GalleryProvider apiProvider = GalleryProvider();
  final RxList<CategorizedPlayerGroup> wallpaperList = RxList([]);
  final MediaProvider mediaProvider = MediaProvider();
  final isLoading = true.obs;
  final Map<String, materialGlobal.GlobalKey> groupKeys = <String, materialGlobal.GlobalKey>{}.obs;
  final Map<String, int> positionPriority = {
    'props': 0,
    'hooker': 1,
    'lock': 2,
    'flanker': 3,
    'number8': 4,
    'scrumhalf': 5,
    'standoff': 6,
    'center': 7,
    'wing': 8,
    'fullback': 9,
    'staff': 10,
  };
  // Store both original categories and processed player groups
  List<WallpaperCategory> _originalCategories = [];
  List<CategorizedPlayerGroup> _allPlayerGroups = [];

  final List<String> playerCategory = [LocaleKeys.forward_short.tr, LocaleKeys.back_short.tr];
  final List<String> playerCategoryFull = [LocaleKeys.forward.tr, LocaleKeys.back.tr];

  void addGroupKey(String identifier) {
    groupKeys[identifier] = materialGlobal.GlobalKey();
  }

  void scrollToGroup(String groupIdentifier) {
    final groupKey = groupKeys[groupIdentifier];
    print("groupKey is ${groupKeys} & ${groupIdentifier}");
    if (groupKey != null && groupKey.currentContext != null) {
      materialGlobal.Scrollable.ensureVisible(
        groupKey.currentContext!,
        duration: Duration(seconds: 1),
        curve: materialGlobal.Curves.easeInOut,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    getWallpaper();
    mediaProvider.onInit();

    AnalyticsService.logPageView(Routes.WALLPAPER_SET_PLAYER);
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
    const forwardRoles = ['props', "hooker", "lock", "flanker", "number8"];
    const backRoles = ["scrumhalf", "standoff", "center", "wing", "fullback"];
    const staffRoles = ["staff"];

    Map<String, List<Member>> positionGroups = {};

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

      positionGroups[category.name.toLowerCase()] = members;
    }

    // Create and sort forward groups
    List<MemberGroup> forwardGroups = [];
    for (var role in forwardRoles) {
      if (positionGroups.containsKey(role)) {
        forwardGroups.add(MemberGroup(
          title: role.toUpperCase(),
          players: positionGroups[role]!,
        ));
      }
    }

    // Create and sort back groups
    List<MemberGroup> backGroups = [];
    for (var role in backRoles) {
      if (positionGroups.containsKey(role)) {
        backGroups.add(MemberGroup(
          title: role.toUpperCase(),
          players: positionGroups[role]!,
        ));
      }
    }

    // Create staff groups
    List<MemberGroup> staffGroups = [];
    for (var role in staffRoles) {
      if (positionGroups.containsKey(role)) {
        staffGroups.add(MemberGroup(
          title: role.toUpperCase(),
          players: positionGroups[role]!,
        ));
      }
    }

    // Sort groups based on position priority
    void sortMemberGroups(List<MemberGroup> groups) {
      groups.sort((a, b) {
        String slugA = a.title.toLowerCase();
        String slugB = b.title.toLowerCase();
        print("asjdka $slugA");
        return (positionPriority[slugA] ?? 999).compareTo(positionPriority[slugB] ?? 999);
      });
    }

    sortMemberGroups(forwardGroups);
    sortMemberGroups(backGroups);
    sortMemberGroups(staffGroups);

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
    if (selectedPosition.value == "FW") {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.forward.tr).toList();
    } else if (selectedPosition.value == "BK") {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.back.tr).toList();
    } else if (selectedPosition.value == LocaleKeys.staff.tr) {
      return allGroups.where((group) => group.categoryTitle == LocaleKeys.staff.tr).toList();
    }
    return allGroups;
  }
}
