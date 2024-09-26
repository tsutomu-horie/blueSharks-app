import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/match/match_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class GameInfoController extends GetxController {
  final MatchProvider apiProvider = MatchProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final Rx<List<MatchResult>> matchCategory =
  Rx<List<MatchResult>>([]);
  final seasonSlug = ''.obs;  final selectedYear = "".obs;

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
  }

  void selectYear(MatchResult selectedDate) async {
    selectedYear.value = selectedDate.name;
    seasonSlug.value = selectedDate.slug;
    listMatch.value.clear();
    final List<MatchResultBySeason> latestMatches =
        await getLatestPosts(selectedDate.id, selectedDate.count);

    listMatch.value = latestMatches;
    print("selectYear ${latestMatches}");
  }

  void fetchMatchResult() async {
    final Map<String, dynamic>? data = await getSeasonCategoryId();
    if (data != null) {
      final List<MatchResultBySeason> latestMatches =
      await getLatestPosts(data['id'], data['count']);

      listMatch.value = latestMatches;
    } else {
      print("No data found for the current season.");
    }
  }

  Future<Map<String, dynamic>?> getSeasonCategoryId() async {
    int page = 1; // Start with page 1

    while (true) {
      List<MatchResult> response = await apiProvider.getMatch(page: page);

      if (response.isEmpty) {
        break; // If the page is empty, break the loop
      }

      matchCategory.value = response;

      for (var category in response) {
        if (category.slug == seasonSlug.value) {
          selectedYear.value = category.name;
          return {
            'id': category.id,
            'count': category.count, // Return both id and count
          };
        }
      }

      // Increment page number to fetch the next page
      page++;
    }

    return null; // If not found, return null
  }

  Future<List<MatchResultBySeason>> getLatestPosts(
      int categoryId, int count) async {
    int postsPerPage = 10; // Each page returns 10 posts
    int totalPages =
    (count / postsPerPage).ceil(); // Calculate total number of pages
    int lastPage = totalPages; // Start with the last page

    List<MatchResultBySeason> posts = [];

    while (lastPage > 0) {
      List<MatchResultBySeason> pagePosts =
      await apiProvider.getMatchBySeasonId(categoryId, page: lastPage);
      posts.addAll(pagePosts);
      lastPage--;
    }

    // Return only the first 4 matches after the current date and time
    return posts.toList();
  }

  /*
  * This Function will return isHome, opponentLogo, opponentName
  * */
  Map<String, dynamic> getStatusMatch(CustomField customField) {
    final team1 = customField.team_1 ?? [];
    final team2 = customField.team_2 ?? [];
    final team2Logo = customField.team_logo_2 ?? [];

    try {
      final isHome = team1.first.contains(Constants.teamName);
      print("get status ${isHome} ${team1.first}");
      if (isHome) {
        return {
          'isHome': true,
          'opponentLogo': team2Logo.first,
          'opponentName': team2.first,
        };
      } else {
        return {
          'isHome': false,
          'opponentLogo': customField.team_logo_1?.first,
          'opponentName': team1.first,
        };
      }
    } catch (e) {
      return {
        'isHome': false,
        'opponentLogo': customField.team_logo_1?.first,
        'opponentName': "",
      };
    }
  }

  Future<String> getImage(String mediaId) async {

    final imageData = await mediaProvider.fetchMedia(mediaId);
    final image = imageData.media_details.sizes.thumbnail.source_url;
    return image;
  }
}
