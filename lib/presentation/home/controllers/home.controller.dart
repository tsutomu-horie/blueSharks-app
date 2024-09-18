import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/api/match/match_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class HomeController extends GetxController {
  final MatchProvider apiProvider = MatchProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final Rx<List<MatchResultBySeason>> threeLatestMatch = Rx<List<MatchResultBySeason>>([]);
  final text = "".obs;

  @override
  void onInit() {
    print("init triggered");
    super.onInit();
    apiProvider.onInit();
    mediaProvider.onInit();
    fetchMatchResult();
  }

  void fetchMatchResult() async {
    print("Fetching match results...");

    final Map<String, dynamic>? data = await getSeasonCategoryId();
    if (data != null) {
      final List<MatchResultBySeason> latestMatches =
          await getLatestPosts(data['id'], data['count']);

      threeLatestMatch?.value = latestMatches;
      text.value = "${latestMatches.length}";
      for (var match in latestMatches) {
        print("Match Title: ${match.title.rendered}");
      }
    } else {
      print("No data found for the current season.");
    }
  }

  Future<Map<String, dynamic>?> getSeasonCategoryId() async {
    //todo::dummy
    // int currentYear = 2023;
    int currentYear = DateTime.now().year; // Get the current year
    int nextYear = currentYear + 1; // Calculate the next year
    String seasonSlug =
        'season_${currentYear}_${nextYear}'; // Construct the slug for the season
    int page = 1; // Start with page 1

    while (true) {
      List<MatchResult> response = await apiProvider.getMatch(page: page);

      if (response.isEmpty) {
        break; // If the page is empty, break the loop
      }

      // Find the category that matches the season slug
      for (var category in response) {
        if (category.slug == seasonSlug) {
          // Check if the slug matches
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
    const int returnNumber = 3; // Return exactly 4 posts
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

    // Filter posts based on current date and time
    //todo::dummy
    DateTime now = DateTime.now();
    // DateTime now = DateTime(2023, 12, 30);
    List<MatchResultBySeason> filteredPosts = posts.where((post) {
      if (post.custom_field.gameDate.isEmpty ||
          post.custom_field.gameTime.isEmpty) {
        return false;
      }

      // Parse game_date and game_time into DateTime
      String gameDate = post.custom_field.gameDate.first;
      String gameTime = post.custom_field.gameTime.first;
      DateTime? gameDateTime = parseGameDateTime(gameDate, gameTime);
      return gameDateTime != null && gameDateTime.isAfter(now);
    }).toList();

    // Sort the filtered posts by date
    filteredPosts.sort((a, b) {
      DateTime aDateTime = parseGameDateTime(
          a.custom_field.gameDate.first, a.custom_field.gameTime.first)!;
      DateTime bDateTime = parseGameDateTime(
          b.custom_field.gameDate.first, b.custom_field.gameTime.first)!;
      return aDateTime.compareTo(bDateTime);
    });

    // Return only the first 4 matches after the current date and time
    return filteredPosts.take(returnNumber).toList();
  }

  DateTime? parseGameDateTime(String gameDate, String gameTime) {
    try {
      // Parse game_date (e.g., "2024年02月03日（土）") and game_time ("12:00 K.O")
      String formattedDate = gameDate
          .replaceAll(RegExp(r'[年月日（）]'), '-')
          .replaceAll(' ', '')
          .replaceAll('--', '-');
      formattedDate = formattedDate.substring(
          0, formattedDate.length - 1); // Remove trailing "-"
      DateTime date = DateFormat('yyyy-MM-dd').parse(formattedDate);

      String formattedTime = gameTime.split(' ')[0]; // Remove "K.O"
      DateTime time = DateFormat('HH:mm').parse(formattedTime);

      final formatted =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      return formatted;
    } catch (e) {
      print("Error parsing game date and time: $e");
      return null;
    }
  }

  /*
  * This Function will return isHome, opponentLogo, opponentName
  * */
  Map<String, dynamic> getStatusMatch(CustomField customField) {
    final isHome = customField.team_1.first.contains(Constants.teamName);

    print("get status ${isHome} ${customField.team_1.first}");
    if (isHome) {
      return {
        'isHome': true,
        'opponentLogo': customField.team_logo_2.first,
        'opponentName': customField.team_2.first,
      };
    } else {
      return {
        'isHome': false,
        'opponentLogo': customField.team_logo_1?.first,
        'opponentName': customField.team_1.first,
      };
    }
  }

  Future<String> getImage(String mediaId) async {
    final imageData = await mediaProvider.fetchMedia(mediaId);
    final image = imageData.media_details.sizes.thumbnail.source_url;
    print("getImage success $image");
    return image;
  }
}
