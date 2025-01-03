import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MatchListController extends GetxController {
  final MatchProvider apiProvider = MatchProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final Rx<List<Category>> matchCategory =
  Rx<List<Category>>([]);
  final seasonSlug = ''.obs;
  final selectedYear = "".obs;
  final isLoading = true.obs;

  final Rx<List<MatchResultBySeason>> listMatch =
  Rx<List<MatchResultBySeason>>([]);

  @override
  void onInit() {
    super.onInit();
    int currentYear = DateTime.now().year; // Get the current year
    int nextYear = currentYear + 1; // Calculate the next year
    seasonSlug.value = 'season_${currentYear}_${nextYear}'; // Construct the slug for the season

    apiProvider.onInit();
    mediaProvider.onInit();
    fetchMatchResult();

    AnalyticsService.logPageView(Routes.GAME_INFO);

  }

  void selectYear(Category selectedDate) async {
    selectedYear.value = selectedDate.name;
    seasonSlug.value = selectedDate.slug;
    listMatch.value.clear();
    final List<MatchResultBySeason> latestMatches =
        await getLatestPosts(selectedDate.id, selectedDate.count);

    listMatch.value = latestMatches;
    print("selectYear ${latestMatches}");
  }

  // void fetchMatchResult() async {
  //   final Map<String, dynamic>? data = await getSeasonCategoryId();
  //   if (data != null) {
  //     final List<MatchResultBySeason> latestMatches =
  //     await getLatestPosts(data['id'], data['count']);
  //
  //     listMatch.value = latestMatches;
  //     isLoading.value = false;
  //   } else {
  //     print("No data found for the current season.");
  //   }
  // }
  void fetchMatchResult() async {
    print("fetch match result");
    final Map<String, dynamic>? data = await getSeasonCategoryId();
    if (data != null) {
      try {
        final List<MatchResultBySeason> sortedMatches =
        await getLatestPosts(data['id'], data['count']);

        listMatch.value = sortedMatches;
        isLoading.value = false;
      } catch (e) {
        print("Error fetching match results: $e");
        isLoading.value = false;
      }
    } else {
      print("No data found for the current season.");
      isLoading.value = false;
    }
  }

// Helper function to parse Japanese date format
  DateTime? parseJapaneseDate(String japaneseDate) {
    try {
      // Remove day of week in parentheses and split the string
      String dateStr = japaneseDate.replaceAll(RegExp(r'（[月火水木金土日]）'), '');

      // Extract year, month, and day using RegExp
      RegExp exp = RegExp(r'(\d+)年(\d+)月(\d+)日');
      var match = exp.firstMatch(dateStr);

      if (match != null) {
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);

        return DateTime(year, month, day);
      }
      return null;
    } catch (e) {
      print("Error parsing Japanese date: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSeasonCategoryId() async {
    print("get latest getSeasonCategoryId");
    int currentYear = DateTime.now().year;
    int nextYear = currentYear + 1;

    // Try current season first
    String currentSeasonSlug = 'season_${currentYear}_${nextYear}';
    Map<String, dynamic>? result = await tryFindSeason(currentSeasonSlug);

    // If not found, try previous season
    if (result == null) {
      String previousSeasonSlug = 'season_${currentYear-1}_${currentYear}';
      seasonSlug.value = previousSeasonSlug;
      result = await tryFindSeason(previousSeasonSlug);
    }

    return result;
  }

  Future<Map<String, dynamic>?> tryFindSeason(String targetSlug) async {
    int page = 1;

    while (true) {
      List<Category> response = await apiProvider.getMatch(page: page);

      if (response.isEmpty) break;

      matchCategory.value = response;

      for (var category in response) {
        if (category.slug == targetSlug) {
          selectedYear.value = category.name;
          return {
            'id': category.id,
            'count': category.count,
          };
        }
      }
      page++;
    }
    return null;
  }

  Future<List<MatchResultBySeason>> getLatestPosts(
      int categoryId, int count) async {
    print("get latest post");
    int postsPerPage = 10;
    int totalPages = (count / postsPerPage).ceil();
    List<MatchResultBySeason> allPosts = []; // Collect all posts first

    // Fetch all pages
    for (int page = 1; page <= totalPages; page++) {
      List<MatchResultBySeason> pagePosts =
      await apiProvider.getMatchBySeasonId(categoryId, page: page);
      allPosts.addAll(pagePosts);
    }

    // Sort all collected posts at once
    allPosts.sort((a, b) {
      try {
        String? dateStrA = a.custom_field.gameDate?.firstOrNull;
        String? dateStrB = b.custom_field.gameDate?.firstOrNull;

        if (dateStrA == null || dateStrB == null) {
          return 0;
        }

        DateTime? dateA = parseJapaneseDate(dateStrA);
        DateTime? dateB = parseJapaneseDate(dateStrB);

        if (dateA == null || dateB == null) {
          return 0;
        }

        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        print("Error sorting game dates: $e");
        print("Date A: ${a.custom_field.gameDate}");
        print("Date B: ${b.custom_field.gameDate}");
        return 0;
      }
    });

    return allPosts;
  }
}
