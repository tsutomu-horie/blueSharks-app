import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/playerDetail/player_detail.screen.dart';

class MemberController extends GetxController {
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

  void addGroupKey(String identifier) {
    groupKeys[identifier] = GlobalKey();
  }

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

  Future<void> getAllMembers() async {
    isLoading.value = true;
    int categoryPage = 1;
    bool hasMoreCategories = true;
    print("getAllMembers2");
    try {
      print("getAllMembers1");
      // Loop through all category pages
      while (hasMoreCategories) {
        print("getAllMembers");
        final List<Category> categoryList = await memberProvider.getCategories(page: categoryPage);

        if (categoryList.isEmpty) {
          hasMoreCategories = false;
        } else {
          categories.addAll(categoryList);

          // For each category, fetch players and handle pagination
          for (Category category in categoryList) {
            print("getAllMember name ${category.name}");
            await fetchPlayersForCategory(category.id, category.slug, category.name);
          }

          categoryPage++;
        }
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
    Get.to(() => MemberDetailScreen(player));
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

  List<CategorizedPlayerGroup> groupPlayersByCategory(Map<int, List<Member>> categoryPlayers) {
    // Combine all players into one list
    List<Member> allPlayers = combineAllPlayersFromCategories(categoryPlayers);

    if (allPlayers.isEmpty) {
      return []; // Return empty list if no players
    }

    List<Member> propPlayers = [];
    List<Member> hookerPlayers = [];
    List<Member> lockPlayers = [];
    List<Member> flankerPlayers = [];
    List<Member> no8Players = [];
    List<Member> scrumhalfPlayers = [];
    List<Member> standoffPlayers = [];
    List<Member> centerPlayers = [];
    List<Member> wingPlayers = [];
    List<Member> fullbackPlayers = [];
    List<Member> staffPlayers = [];

    // Group players based on their slug
    for (var player in allPlayers) {
      if (player.categorySlug == 'prop') {
        propPlayers.add(player);
      } else if (player.categorySlug == 'hooker') {
        hookerPlayers.add(player);
      } else if (player.categorySlug == 'lock') {
        lockPlayers.add(player);
      } else if (player.categorySlug == 'flanker') {
        flankerPlayers.add(player);
      } else if (player.categorySlug == 'no8') {
        no8Players.add(player);
      } else if (player.categorySlug == 'scrumhalf') {
        scrumhalfPlayers.add(player);
      } else if (player.categorySlug == 'standoff') {
        standoffPlayers.add(player);
      } else if (player.categorySlug == 'center') {
        centerPlayers.add(player);
      } else if (player.categorySlug == 'wing') {
        wingPlayers.add(player);
      } else if (player.categorySlug == 'fullback') {
        fullbackPlayers.add(player);
      } else if (player.categorySlug == 'staff') {
        staffPlayers.add(player);
      }
    }

    if (selectedPosition.value == LocaleKeys.forward.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.forward.tr,
          playerGroups: [
            if (propPlayers.isNotEmpty)
              MemberGroup(title:
              // propPlayers[0].categoryName ??
                  "Prop", players: propPlayers),
            if (hookerPlayers.isNotEmpty)
              MemberGroup(title:
              // hookerPlayers[0].categoryName ??
                  "Hooker", players: hookerPlayers),
            if (lockPlayers.isNotEmpty)
              MemberGroup(title:
              // lockPlayers[0].categoryName ??
                  "Lock", players: lockPlayers),
            if (flankerPlayers.isNotEmpty)
              MemberGroup(title:
              // flankerPlayers[0].categoryName ??
                  "Flanker", players: flankerPlayers),
            if (no8Players.isNotEmpty)
              MemberGroup(title:
              // no8Players[0].categoryName ??
                  "No. 8", players: no8Players),
          ],
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.back.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.back.tr,
          playerGroups: [
            if (scrumhalfPlayers.isNotEmpty)
              MemberGroup(title:
              // scrumhalfPlayers[0].categoryName ??
                  "Scrumhalf", players: scrumhalfPlayers),
            if (standoffPlayers.isNotEmpty)
              MemberGroup(title:
              // standoffPlayers[0].categoryName ??
                  "Standoff", players: standoffPlayers),
            if (centerPlayers.isNotEmpty)
              MemberGroup(title:
              // centerPlayers[0].categoryName ??
                  "Center", players: centerPlayers),
            if (wingPlayers.isNotEmpty)
              MemberGroup(title:
              // wingPlayers[0].categoryName ??
                  "Wing", players: wingPlayers),
            if (fullbackPlayers.isNotEmpty)
              MemberGroup(title:
              // fullbackPlayers[0].categoryName ??
                  "Fullback", players: fullbackPlayers),
          ],
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.staff.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.staff.tr,
          playerGroups: [
            if (staffPlayers.isNotEmpty)
              MemberGroup(title:
              // staffPlayers[0].categoryName ??
                  "Staff", players: staffPlayers),
          ],
        ),
      ];
    }

    return [
      if (propPlayers.isNotEmpty || hookerPlayers.isNotEmpty || lockPlayers.isNotEmpty ||
          flankerPlayers.isNotEmpty || no8Players.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.forward.tr,
          playerGroups: [
            if (propPlayers.isNotEmpty)
              MemberGroup(title:
              // propPlayers[0].categoryName ??
                  "Prop", players: propPlayers),
            if (hookerPlayers.isNotEmpty)
              MemberGroup(title:
              // hookerPlayers[0].categoryName ??
                  "Hooker", players: hookerPlayers),
            if (lockPlayers.isNotEmpty)
              MemberGroup(title:
              // lockPlayers[0].categoryName ??
                  "Lock", players: lockPlayers),
            if (flankerPlayers.isNotEmpty)
              MemberGroup(title:
              // flankerPlayers[0].categoryName ??
                  "Flanker", players: flankerPlayers),
            if (no8Players.isNotEmpty)
              MemberGroup(title:
              // no8Players[0].categoryName ??
                  "No. 8", players: no8Players),
          ],
        ),
      if (scrumhalfPlayers.isNotEmpty || standoffPlayers.isNotEmpty || centerPlayers.isNotEmpty ||
          wingPlayers.isNotEmpty || fullbackPlayers.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.back.tr,
          playerGroups: [
            if (scrumhalfPlayers.isNotEmpty)
              MemberGroup(title:
              // scrumhalfPlayers[0].categoryName ??
                  "Scrumhalf", players: scrumhalfPlayers),
            if (standoffPlayers.isNotEmpty)
              MemberGroup(title:
              // standoffPlayers[0].categoryName ??
                  "Standoff", players: standoffPlayers),
            if (centerPlayers.isNotEmpty)
              MemberGroup(title:
              // centerPlayers[0].categoryName ??
                  "Center", players: centerPlayers),
            if (wingPlayers.isNotEmpty)
              MemberGroup(title:
              // wingPlayers[0].categoryName ??
                  "Wing", players: wingPlayers),
            if (fullbackPlayers.isNotEmpty)
              MemberGroup(title:
              // fullbackPlayers[0].categoryName ??
                  "Fullback", players: fullbackPlayers),
          ],
        ),
      if (staffPlayers.isNotEmpty)
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.staff.tr,
          playerGroups: [
            MemberGroup(title:
            // staffPlayers[0].categoryName ??
                "Staff", players: staffPlayers),
          ],
        ),
    ];
  }
}
