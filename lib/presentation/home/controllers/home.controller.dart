import 'dart:ffi';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/info/info_provider.dart';
import 'package:koto_blue_sharks/app/data/api/match/match_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class HomeController extends GetxController {
  final MatchProvider apiProvider = MatchProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final InfoProvider infoProvider = InfoProvider();
  final Rx<List<MatchResultBySeason>> threeLatestMatch =
      Rx<List<MatchResultBySeason>>([]);
  final text = "".obs;
  final Rx<List<Post>> topicsData = Rx([]);
  final selectedWallpaper = "".obs;
  final selectedWallpaperName = "".obs;


  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();
    mediaProvider.onInit();
    infoProvider.onInit();
    fetchMatchResult();
    getTopics();
    getWallpaper();
    print("getwallpaper 1");
  }

  void getWallpaper() async {
    mediaProvider.onInit();

    print("getwallpaper 2");
    final data = await mediaProvider.fetchWallpaper((error){
      print("error $error");
    });

    // final wallpaper = WallpaperPreferences();
    // final wallpaperName = await wallpaper.getWallpaper();
    final wallpaperLink = MySharedPref.getWallpaper();
    final wallpaperName = MySharedPref.getWallpaperName();


    if (wallpaperLink != null) {
      selectedWallpaper.value = wallpaperLink;
      selectedWallpaperName.value = wallpaperName ?? "";
    }
  }

  void getTopics() async {
    print("get info");
    final List<Post> data = await infoProvider.getNotice();

    data.take(3).toList();
    topicsData.value = data;
  }

  void fetchMatchResult() async {
    final Map<String, dynamic>? data = await getSeasonCategoryId();
    if (data != null) {
      final List<MatchResultBySeason> latestMatches =
          await getLatestPosts(data['id'], data['count']);

      threeLatestMatch.value = latestMatches;
      text.value = "${latestMatches.length}";
      for (var match in latestMatches) {
        print("Match Title: ${match.title.rendered}");
      }
    } else {
      print("No data found for the current season.");
    }
  }

  Future<Map<String, dynamic>?> getSeasonCategoryId() async {
    int currentYear = DateTime.now().year; // Get the current year
    int nextYear = currentYear + 1; // Calculate the next year
    String seasonSlug =
        'season_${currentYear}_${nextYear}'; // Construct the slug for the season
    int page = 1; // Start with page 1

    while (true) {
      List<Category> response = await apiProvider.getMatch(page: page);

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
    // const int returnNumber = 3; // Return exactly 4 posts
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

    List<MatchResultBySeason> filteredPosts = posts.where((post) {
      return post.custom_field.game_result == null ||
          post.custom_field.game_result!.isEmpty ||
          post.custom_field.game_result?.first == "試合前";
    }).toList();

    // Return only the first 4 matches after the current date and time
    return filteredPosts.toList();
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

  Future<String> getNewsImage(String mediaId) async {
    final imageData = await mediaProvider.fetchParentMedia(mediaId);
    print("GET NEWS IMAGE ${imageData}");
    final image = imageData?.media_details.sizes.thumbnail.source_url;
    print("GET NEWS IMAGE ${mediaId}, ${image}");
    return image ?? "";
  }
}
