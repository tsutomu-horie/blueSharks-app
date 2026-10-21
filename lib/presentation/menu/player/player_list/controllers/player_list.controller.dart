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
  PlayerListController({MemberProvider? memberProvider})
      : memberProvider = memberProvider ?? MemberProvider();
  final errorMessage = ''.obs;
  int _request = 0;
  final selectedPosition = LocaleKeys.all_position.tr.obs;
  Box<Category>? categoryBox;
  Box<Member>? playerBox;
  final MediaProvider mediaProvider = MediaProvider();
  final MemberProvider memberProvider;
  final Map<String, GlobalKey> groupKeys = <String, GlobalKey>{};

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
    groupKeys.putIfAbsent(identifier, () => GlobalKey());
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

  Future<void> onReloadPage() => getAllMembers();

  Future<void> getAllMembers() async {
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = '';
    final nextCategories = <Category>[];
    final nextPlayers = <int, List<Member>>{};
    try {
      for (var page = 1;; page++) {
        final values = await memberProvider.getCategories(page: page);
        if (isClosed || request != _request) return;
        nextCategories.addAll(values);
        if (values.length < 100) break;
      }
      nextCategories.sort((a, b) =>
          (positionPriority[a.slug.toLowerCase()] ?? 999)
              .compareTo(positionPriority[b.slug.toLowerCase()] ?? 999));
      for (final category in nextCategories) {
        nextPlayers[category.id] = await fetchPlayersForCategory(
            category.id, category.slug, category.name);
        if (isClosed || request != _request) return;
      }
      categories.assignAll(nextCategories);
      categoryPlayers.assignAll(nextPlayers);
    } catch (_) {
      if (!isClosed && request == _request)
        errorMessage.value = '選手情報を取得できませんでした。';
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<List<Member>> fetchPlayersForCategory(
      int categoryId, String categorySlug, String categoryName) async {
    final result = <Member>[];
    final ids = <int>{};
    for (var page = 1;; page++) {
      final players =
          await memberProvider.getPlayersByCategory(categoryId, page: page);
      for (final player in players) {
        if (!ids.add(player.id))
          throw const FormatException('Repeated member page.');
        result.add(player.copyWith(
            categoryId: categoryId,
            categorySlug: categorySlug,
            categoryName: categoryName));
      }
      if (players.length < 100) break;
    }
    result.sort((a, b) => a.title.rendered.compareTo(b.title.rendered));
    return result;
  }

  @override
  void onClose() {
    _request++;
    memberProvider.renewal.httpClient.close();
    memberProvider.httpClient.close();
    mediaProvider.httpClient.close();
    super.onClose();
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
