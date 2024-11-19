import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  RxString version = "".obs;

  final MemberProvider memberProvider = MemberProvider();
  final RxList<Category> allCategories = <Category>[].obs;
  final RxMap<int, List<Member>> categoryPlayers = <int, List<Member>>{}.obs;
  final RxBool isLoading = false.obs;

  Box<Category>? categoryBox;
  Box<Member>? playerBox;

  @override
  void onInit() async {
    super.onInit();
    getAppVersion();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String bundleID = packageInfo.packageName;
    print("Bundle ID: $bundleID"); // This will print in the console on app start


    memberProvider.onInit();

    categoryBox = await Hive.openBox<Category>('categoriesBox');
    playerBox = await Hive.openBox<Member>('playersBox');

    await playerBox?.clear();
    await categoryBox?.clear();
    getAllMembers();

    AnalyticsService.logPageView(Routes.SPLASH);
    // await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> getAllMembers() async {
    isLoading.value = true;
    int categoryPage = 1;
    bool hasMoreCategories = true;

    try {
      // Loop through all category pages
      while (hasMoreCategories) {
        final List<Category> categoryList =
        await memberProvider.getCategories(page: categoryPage);

        if (categoryList.isEmpty) {
          hasMoreCategories =
          false; // Stop fetching if no more categories are available
        } else {
          allCategories.addAll(categoryList);

          await categoryBox?.addAll(categoryList);
          // For each category, fetch players and handle pagination
          for (Category category in categoryList) {
            await fetchPlayersForCategory(category.id, category.slug, category.name);
          }

          categoryPage++; // Move to the next category page
        }
      }
    } catch (e) {
      print('Error loading categories and players: $e');
    } finally {
      final auth = AuthToken();
      final token = await auth.getAccessToken();
      print("token get ${token}");
      isLoading.value = false;
      final isOpen = MySharedPref.getFirstOpen();

      if (token != null || (isOpen != null && isOpen != "")) {
        Get.offAll(() => const MainScreen());
      } else {
        // Get.offAll(() => FanClubConfirmationScreen());
        Get.offAndToNamed('/wallpaper');
      }
    }
  }

  Future<void> fetchPlayersForCategory(int categoryId, String categorySlug, String categoryName) async {
    int playerPage = 1;
    bool hasMorePlayers = true;
    final List<Member> allPlayers = [];
    // A set to track added player IDs to avoid duplicates
    Set<int> addedPlayerIds = categoryPlayers[categoryId]?.map((player) => player.id).toSet() ?? {};

    // Loop through all player pages for this category
    while (hasMorePlayers) {
      final List<Member> players = await memberProvider.getPlayersByCategory(categoryId, page: playerPage);

      if (players.isEmpty) {
        hasMorePlayers = false; // Stop fetching if no more players are available
      } else {
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
        }).where((player) => !addedPlayerIds.contains(player.id)).toList();  // Filter out duplicate players

        print("data splash ${players}");
        // Add the unique players' IDs to the set
        addedPlayerIds.addAll(categorizedPlayers.map((player) => player.id));

        // Add categorized players to local storage
        await playerBox?.addAll(categorizedPlayers);

        // Add players to in-memory list (only unique players)
        allPlayers.addAll(categorizedPlayers);

        playerPage++; // Move to the next player page
      }
    }

    // Save players for the category
    categoryPlayers[categoryId] = allPlayers;
  }

  void getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version.value = packageInfo.version;
  }
}
