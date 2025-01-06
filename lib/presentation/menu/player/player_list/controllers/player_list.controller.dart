import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_detail/player_detail.screen.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

class PlayerListController extends GetxController {
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  Box<Category>? categoryBox;
  Box<Member>? playerBox;
  final MediaProvider mediaProvider = MediaProvider();
  final MemberProvider memberProvider = MemberProvider();
  final Map<String, GlobalKey> groupKeys = <String, GlobalKey>{}.obs;

  final RxList<Category> categories = <Category>[].obs;
  final RxMap<int, List<Member>> categoryPlayers = <int, List<Member>>{}.obs;
  final RxBool isLoading = true.obs;

  final List<String> playerCategory = [LocaleKeys.forward_short.tr, LocaleKeys.back_short.tr, LocaleKeys.staff.tr];
  final List<String> playerCategoryFull = [LocaleKeys.forward.tr, LocaleKeys.back.tr, LocaleKeys.staff.tr];

  final Map<String, String> preloadedImages = <String, String>{}.obs;
  final isImageLoading = true.obs;

  void addGroupKey(String identifier) {
    groupKeys[identifier] = GlobalKey();
  }

  final Map<String, int> positionPriority = {
    'props': 0,
    'hooker': 1,
    'lock': 2,
    'flanker': 3,
    'no8': 4,
    'scrumhalf': 5,
    'standoff': 6,
    'center': 7,
    'wing': 8,
    'fullback': 9,
    'staff': 10,
  };

  void scrollToGroup(String groupIdentifier) {
    final groupKey = groupKeys[groupIdentifier];
    print("groupKey is ${groupKeys} & ${groupIdentifier}");
    if (groupKey != null && groupKey.currentContext != null) {
      Scrollable.ensureVisible(
        groupKey.currentContext!,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onInit() async {
    super.onInit();
    mediaProvider.onInit();
    memberProvider.onInit();
    getAllMembers();
    print("getAllMembers3");

    AnalyticsService.logPageView(Routes.MEMBER);

  }

  void onReloadPage() {
  categories.value = [];
  categoryPlayers.value = {};
  getAllMembers();
}

  Future<void> getAllMembers() async {
    isLoading.value = true;
    int categoryPage = 1;
    bool hasMoreCategories = true;

    try {
      while (hasMoreCategories) {
        final List<Category> categoryList = await memberProvider.getCategories(page: categoryPage);
        if (categoryList.isEmpty) {
          hasMoreCategories = false;
          continue;
        }

        // Process one category at a time
        for (Category category in categoryList) {
          // 1. Add category
          categories.add(category);

          // 2. Load players for this category
          await fetchPlayersForCategory(category.id, category.slug, category.name);

          // 3. Load images for players in this category
          List<Member> categoryMembers = categoryPlayers[category.id] ?? [];
          for (var i = 0; i < categoryMembers.length; i += 5) {
            final batch = categoryMembers.sublist(
                i,
                (i + 5) > categoryMembers.length ? categoryMembers.length : (i + 5)
            );

            await Future.wait(
                batch.map((player) async {
                  final imageUrl = "${player.custom_field?.profile_image_1?.first}";
                  if (!preloadedImages.containsKey(imageUrl)) {
                    final loadedImage = await getImage(mediaProvider, imageUrl);
                    preloadedImages[imageUrl] = loadedImage;
                  }
                })
            );
          }
        }
        categoryPage++;
      }

    } catch (e) {
      print('Error loading categories and players: $e');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> fetchPlayersForCategory(int categoryId, String categorySlug, String categoryName) async {
    int playerPage = 1;
    bool hasMorePlayers = true;
    final List<Member> allPlayers = [];
    Set<int> addedPlayerIds = categoryPlayers[categoryId]?.map((player) => player.id).toSet() ?? {};

    while (hasMorePlayers) {
      final List<Member> players = await memberProvider.getPlayersByCategory(categoryId, page: playerPage);

      if (players.isEmpty) {
        hasMorePlayers = false;
      } else {
        print("this is name $categoryName" );
        final List<Member> categorizedPlayers = players.map((player) {
          return Member(
              id: player.id,
              date: player.date,
              modified: player.modified,
              slug: player.slug,
              status: player.status,
              type: player.type,
              link: player.link,
              title: player.title,
              categoryId: categoryId,
              categorySlug: categorySlug,
              categoryName: categoryName,
              custom_field: player.custom_field
          );
        }).where((player) => !addedPlayerIds.contains(player.id)).toList();

        addedPlayerIds.addAll(categorizedPlayers.map((player) => player.id));
        allPlayers.addAll(categorizedPlayers);
        playerPage++;
      }
    }

    categoryPlayers[categoryId] = allPlayers;
  }

  void onSelectPosition(String selectedPos){
    selectedPosition.value = selectedPos;
  }

  void navigateToMemberDetail(Member player){
    Get.to(() => PlayerDetailScreen(player));
  }

  // void loadCategoriesFromLocal() {
  //   try {
  //     // Ensure the categoryBox and playerBox are open
  //     if (categoryBox == null || playerBox == null) {
  //       print('Error: Hive boxes are not initialized');
  //       return;
  //     }
  //
  //     // Fetch categories from Hive local storage
  //     final List<Category> localCategories = categoryBox?.values.toList() ?? [];
  //
  //     if (localCategories.isEmpty) {
  //       print("No categories found in local storage.");
  //     } else {
  //       categories.addAll(localCategories);
  //       print("Categories loaded from local: ${categories.length}");
  //     }
  //
  //     // Fetch players for each category from Hive local storage
  //     for (Category category in localCategories) {
  //       print("loadCategoriesFromLocal ${playerBox?.values}");
  //       print(" ${category}");
  //       final List<Member> localPlayers = playerBox?.values
  //           .where((player) => player.categoryId == category.id) // Make sure the relationship is correct
  //           .toList() ?? [];
  //
  //       if (localPlayers.isNotEmpty) {
  //         categoryPlayers[category.id] = localPlayers;
  //         print("Players for category ${category.id} loaded: ${localPlayers.length}");
  //       } else {
  //         print("No players found for category ${category.id}");
  //       }
  //     }
  //
  //     print("Loaded Category Players Map: $categoryPlayers");
  //     print("Loaded Categories: $categories");
  //
  //   } catch (e) {
  //     print('Error loading data from local storage: $e');
  //   }
  // }

  List<Member> combineAllPlayersFromCategories(Map<int, List<Member>> categoryPlayers) {
    List<Member> allPlayers = [];

    // Iterate over each category and add the players to the allPlayers list
    categoryPlayers.forEach((categoryId, players) {
      allPlayers.addAll(players); // Combine all players from all categories
    });


    return allPlayers;
  }

  Future<void> preloadImagesForGroup(CategorizedPlayerGroup group) async {
    for (var memberGroup in group.playerGroups) {
      for (var i = 0; i < memberGroup.players.length; i += 10) {
        final batch = memberGroup.players.sublist(
            i,
            (i + 10) > memberGroup.players.length ? memberGroup.players.length : (i + 10)
        );

        await Future.wait(
            batch.map((player) async {
              final imageUrl = "${player.custom_field?.profile_image_1?.first}";
              final loadedImage = await getImage(mediaProvider, imageUrl);
              preloadedImages[imageUrl] = loadedImage;
            })
        );
      }
    }
  }

  List<CategorizedPlayerGroup> groupPlayersByCategory(Map<int, List<Member>> categoryPlayers) {
    List<Member> allPlayers = combineAllPlayersFromCategories(categoryPlayers);

    if (allPlayers.isEmpty) {
      return [];
    }

    // Filter players based on position type
    List<Member> forwardPlayers = allPlayers.where((p) =>
        ['props', 'hooker', 'lock', 'flanker', 'no8'].contains(p.categorySlug?.toLowerCase())).toList();

    List<Member> backPlayers = allPlayers.where((p) =>
        ['scrumhalf', 'standoff', 'center', 'wing', 'fullback'].contains(p.categorySlug?.toLowerCase())).toList();

    List<Member> staffPlayers = allPlayers.where((p) =>
    p.categorySlug?.toLowerCase() == 'staff').toList();

    if (selectedPosition.value == LocaleKeys.forward.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.forward.tr,
          playerGroups: createSortedPlayerGroups(forwardPlayers),
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.back.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.back.tr,
          playerGroups: createSortedPlayerGroups(backPlayers),
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.staff.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.staff.tr,
          playerGroups: createSortedPlayerGroups(staffPlayers),
        ),
      ];
    }

    // Show all positions
    List<CategorizedPlayerGroup> result = [];

    if (forwardPlayers.isNotEmpty) {
      result.add(CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.forward.tr,
        playerGroups: createSortedPlayerGroups(forwardPlayers),
      ));
    }

    if (backPlayers.isNotEmpty) {
      result.add(CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.back.tr,
        playerGroups: createSortedPlayerGroups(backPlayers),
      ));
    }

    if (staffPlayers.isNotEmpty) {
      result.add(CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.staff.tr,
        playerGroups: createSortedPlayerGroups(staffPlayers),
      ));
    }

    return result;
  }

  List<MemberGroup> createSortedPlayerGroups(List<Member> players) {
    Map<String, List<Member>> groupedPlayers = {};

    // Group players by category slug
    for (var player in players) {
      String slug = player.categorySlug ?? "";
      if (!groupedPlayers.containsKey(slug)) {
        groupedPlayers[slug] = [];
      }
      groupedPlayers[slug]!.add(player);
    }

    // Create MemberGroup list and sort it
    List<MemberGroup> groups = [];

    if (groupedPlayers['props']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Props", players: groupedPlayers['props']!));
    }
    if (groupedPlayers['hooker']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Hooker", players: groupedPlayers['hooker']!));
    }
    if (groupedPlayers['lock']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Lock", players: groupedPlayers['lock']!));
    }
    if (groupedPlayers['flanker']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Flanker", players: groupedPlayers['flanker']!));
    }
    if (groupedPlayers['no8']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "No. 8", players: groupedPlayers['no8']!));
    }
    if (groupedPlayers['scrumhalf']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Scrumhalf", players: groupedPlayers['scrumhalf']!));
    }
    if (groupedPlayers['standoff']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Standoff", players: groupedPlayers['standoff']!));
    }
    if (groupedPlayers['center']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Center", players: groupedPlayers['center']!));
    }
    if (groupedPlayers['wing']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Wing", players: groupedPlayers['wing']!));
    }
    if (groupedPlayers['fullback']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Fullback", players: groupedPlayers['fullback']!));
    }
    if (groupedPlayers['staff']?.isNotEmpty ?? false) {
      groups.add(MemberGroup(title: "Staff", players: groupedPlayers['staff']!));
    }

    // Sort groups based on position priority
    groups.sort((a, b) {
      String slugA = a.players.first.categorySlug?.toLowerCase() ?? "";
      String slugB = b.players.first.categorySlug?.toLowerCase() ?? "";
      return (positionPriority[slugA] ?? 999).compareTo(positionPriority[slugB] ?? 999);
    });

    return groups;
  }
}
