import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/playerDetail/player_detail.screen.dart';

class MemberController extends GetxController {
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  Box<Category>? categoryBox;
  Box<Member>? playerBox;
  final MediaProvider mediaProvider = MediaProvider();
  final Map<String, GlobalKey> groupKeys = <String, GlobalKey>{}.obs;

  final RxList<Category> categories = <Category>[].obs;
  final RxMap<int, List<Member>> categoryPlayers = <int, List<Member>>{}.obs;

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
    categoryBox = await Hive.openBox<Category>('categoriesBox');
    playerBox = await Hive.openBox<Member>('playersBox');
    loadCategoriesFromLocal();
  }

  void onSelectPosition(String selectedPos){
    selectedPosition.value = selectedPos;
  }

  void navigateToMemberDetail(Member player){
    Get.to(() => MemberDetailScreen(player));
  }

  void loadCategoriesFromLocal() {
    try {
      // Ensure the categoryBox and playerBox are open
      if (categoryBox == null || playerBox == null) {
        print('Error: Hive boxes are not initialized');
        return;
      }

      // Fetch categories from Hive local storage
      final List<Category> localCategories = categoryBox?.values.toList() ?? [];

      if (localCategories.isEmpty) {
        print("No categories found in local storage.");
      } else {
        categories.addAll(localCategories);
        print("Categories loaded from local: ${categories.length}");
      }

      // Fetch players for each category from Hive local storage
      for (Category category in localCategories) {
        print("loadCategoriesFromLocal ${playerBox?.values}");
        print(" ${category}");
        final List<Member> localPlayers = playerBox?.values
            .where((player) => player.categoryId == category.id) // Make sure the relationship is correct
            .toList() ?? [];

        if (localPlayers.isNotEmpty) {
          categoryPlayers[category.id] = localPlayers;
          print("Players for category ${category.id} loaded: ${localPlayers.length}");
        } else {
          print("No players found for category ${category.id}");
        }
      }

      print("Loaded Category Players Map: $categoryPlayers");
      print("Loaded Categories: $categories");

    } catch (e) {
      print('Error loading data from local storage: $e');
    }
  }

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
            MemberGroup(title: propPlayers.first.categoryName ?? "Prop", players: propPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Hooker', players: hookerPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Lock', players: lockPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Flanker', players: flankerPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'No. 8', players: no8Players),
          ],
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.back.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.back.tr,
          playerGroups: [
            MemberGroup(title: propPlayers.first.categoryName ?? 'Scrumhalf', players: scrumhalfPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Standoff', players: standoffPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Center', players: centerPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Wing', players: wingPlayers),
            MemberGroup(title: propPlayers.first.categoryName ?? 'Fullback', players: fullbackPlayers),
          ],
        ),
      ];
    } else if (selectedPosition.value == LocaleKeys.staff.tr) {
      return [
        CategorizedPlayerGroup(
          categoryTitle: LocaleKeys.staff.tr,
          playerGroups: [
            MemberGroup(title: propPlayers.first.categoryName ?? 'Staff', players: staffPlayers),
          ],
        ),
      ];
    }

    return [
      CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.forward.tr,
        playerGroups: [
          MemberGroup(title: propPlayers.first.categoryName ?? "Prop", players: propPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Hooker', players: hookerPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Lock', players: lockPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Flanker', players: flankerPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'No. 8', players: no8Players),
        ],
      ),
      CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.back.tr,
        playerGroups: [
          MemberGroup(title: propPlayers.first.categoryName ?? 'Scrumhalf', players: scrumhalfPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Standoff', players: standoffPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Center', players: centerPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Wing', players: wingPlayers),
          MemberGroup(title: propPlayers.first.categoryName ?? 'Fullback', players: fullbackPlayers),
        ],
      ),
      CategorizedPlayerGroup(
        categoryTitle: LocaleKeys.staff.tr,
        playerGroups: [
          MemberGroup(title: propPlayers.first.categoryName ?? 'Staff', players: staffPlayers),
        ],
      ),
    ];
  }

}
