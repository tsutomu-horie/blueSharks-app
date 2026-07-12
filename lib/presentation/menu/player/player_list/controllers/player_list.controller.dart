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

  final List<String> playerCategory = [
    LocaleKeys.forward_short.tr,
    LocaleKeys.back_short.tr,
    LocaleKeys.staff.tr
  ];
  final List<String> playerCategoryFull = [
    LocaleKeys.forward.tr,
    LocaleKeys.back.tr,
    LocaleKeys.staff.tr
  ];

  final Map<String, String> preloadedImages = <String, String>{}.obs;
  final isImageLoading = true.obs;

  void addGroupKey(String identifier) {
    groupKeys[identifier] = GlobalKey();
  }

  final Map<String, int> positionPriority = {
    'prop': 0,
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
    debugPrint("scrollToGroup: ${groupIdentifier}");
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
        // **Fetch categories**
        final List<Category> categoryList =
            await memberProvider.getCategories(page: categoryPage);

        if (categoryList.isEmpty) {
          hasMoreCategories = false;
          continue;
        }

        // ✅ **Sort categories BEFORE fetching players**
        categoryList.sort((a, b) {
          int priorityA = positionPriority[a.slug.toLowerCase()] ?? 999;
          int priorityB = positionPriority[b.slug.toLowerCase()] ?? 999;
          return priorityA.compareTo(priorityB);
        });

        // ✅ **Fetch players for each sorted category**
        for (Category category in categoryList) {
          categories.add(category);
          await fetchPlayersForCategory(
              category.id, category.slug, category.name);
        }

        categoryPage++;
      }
    } catch (e) {
      print('Error loading categories and players: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPlayersForCategory(
      int categoryId, String categorySlug, String categoryName) async {
    int playerPage = 1;
    bool hasMorePlayers = true;
    final List<Member> allPlayers = [];
    Set<int> addedPlayerIds =
        categoryPlayers[categoryId]?.map((player) => player.id).toSet() ?? {};

    while (hasMorePlayers) {
      final List<Member> players = await memberProvider
          .getPlayersByCategory(categoryId, page: playerPage);

      if (players.isEmpty) {
        hasMorePlayers = false;
      } else {
        print("Fetching players for category: $categoryName");

        // **Sort players before adding**
        players.sort((a, b) {
          int priorityA =
              positionPriority[a.categorySlug?.toLowerCase() ?? ""] ?? 999;
          int priorityB =
              positionPriority[b.categorySlug?.toLowerCase() ?? ""] ?? 999;

          if (priorityA == priorityB) {
            return a.title.rendered.compareTo(
                b.title.rendered); // Sort alphabetically if same priority
          }
          return priorityA.compareTo(priorityB);
        });

        // **Create categorized players**
        final List<Member> categorizedPlayers = players
            .map((player) {
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
                  custom_field: player.custom_field);
            })
            .where((player) => !addedPlayerIds.contains(player.id))
            .toList();

        addedPlayerIds.addAll(categorizedPlayers.map((player) => player.id));
        allPlayers.addAll(categorizedPlayers);
        playerPage++;
      }
    }

    // ✅ **Assign the sorted players to categoryPlayers**
    categoryPlayers[categoryId] = allPlayers;
  }

  void onSelectPosition(String selectedPos) {
    selectedPosition.value = selectedPos;
  }

  void navigateToMemberDetail(Member player) {
    Get.to(() => PlayerDetailScreen(player));
  }

  List<Member> combineAllPlayersFromCategories(
      Map<int, List<Member>> categoryPlayers) {
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
            (i + 10) > memberGroup.players.length
                ? memberGroup.players.length
                : (i + 10));

        await Future.wait(batch.map((player) async {
          final imageUrl = "${player.custom_field?.profile_image_1?.first}";
          final loadedImage = await getImage(mediaProvider, imageUrl);
          preloadedImages[imageUrl] = loadedImage;
        }));
      }
    }
  }

  List<CategorizedPlayerGroup> groupPlayersByCategory(
      Map<int, List<Member>> categoryPlayers) {
    List<Member> allPlayers = combineAllPlayersFromCategories(categoryPlayers);

    if (allPlayers.isEmpty) {
      return [];
    }

    // Filter players based on position type
    List<Member> forwardPlayers = allPlayers
        .where((p) => ['prop', 'hooker', 'lock', 'flanker', 'no8']
            .contains(p.categorySlug?.toLowerCase()))
        .toList();

    List<Member> backPlayers = allPlayers
        .where((p) => ['scrumhalf', 'standoff', 'center', 'wing', 'fullback']
            .contains(p.categorySlug?.toLowerCase()))
        .toList();

    List<Member> staffPlayers = allPlayers
        .where((p) => p.categorySlug?.toLowerCase() == 'staff')
        .toList();

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

    // ✅ **Sort players within each group**
    groupedPlayers.forEach((slug, members) {
      members.sort((a, b) {
        return a.title.rendered
            .compareTo(b.title.rendered); // Alphabetical order
      });
    });

    // ✅ **Sort groups by position priority**
    List<MemberGroup> groups = groupedPlayers.entries.map((entry) {
      return MemberGroup(
          title: entry.key.capitalizeFirst ?? "", players: entry.value);
    }).toList();

    groups.sort((a, b) {
      int priorityA = positionPriority[a.title.toLowerCase()] ?? 999;
      int priorityB = positionPriority[b.title.toLowerCase()] ?? 999;
      return priorityA.compareTo(priorityB);
    });

    return groups;
  }

  String imageCompressor(String bactchImage) {
    print("compress ${bactchImage}");
    return "https://wsrv.nl/?url=$bactchImage&dpr=1";
  }
}
