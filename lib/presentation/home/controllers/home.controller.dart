import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_video.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_match.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_banner.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_player.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_goods.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/providers/info/info_provider.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeController extends GetxController {
  HomeController(
      {WebsiteVideoProvider? websiteVideoProvider,
      DateTime Function()? websiteClock})
      : websiteVideoProvider = websiteVideoProvider ?? WebsiteVideoProvider(),
        websiteClock = websiteClock ?? DateTime.now;

  final WebsiteVideoProvider websiteVideoProvider;
  final DateTime Function() websiteClock;
  final websiteSchedule = Rxn<WebsiteSchedule>();
  final websiteBanners = <WebsiteBanner>[].obs;
  final websiteVideos = <WebsiteVideo>[].obs;
  final websiteGoods = <WebsiteGoods>[].obs;
  final websiteStandings = Rxn<WebsiteStandings>();
  final websitePlayers = Rxn<WebsitePlayers>();
  Uri? _websiteScheduleUrl;
  bool _websiteNextMatchesRequested = false;
  bool _websiteNextMatchesLoading = false;
  bool _websiteContentRequested = false;
  bool _websiteContentLoading = false;

  Future<void> fetchWebsiteContent({bool force = false}) async {
    if (_websiteContentLoading || (_websiteContentRequested && !force)) {
      return;
    }
    _websiteContentRequested = true;
    _websiteContentLoading = true;
    try {
      final content = await websiteVideoProvider.fetchContent();
      if (!isClosed) {
        websiteVideos.assignAll(content.videos);
        websiteGoods.assignAll(content.goods);
        websiteStandings.value = content.standings;
        websitePlayers.value = content.players;
        websiteBanners.assignAll(content.banners);
        _websiteScheduleUrl = content.scheduleUrl;
      }
    } catch (_) {
      // Keep the previous successful media, or the original static video.
    } finally {
      _websiteContentLoading = false;
    }
  }

  /// Screen orchestration keeps the existing four-section fetch independent.
  Future<void> fetchWebsiteNextMatches({bool force = false}) async {
    if (isClosed ||
        _websiteNextMatchesLoading ||
        _websiteContentLoading ||
        (_websiteNextMatchesRequested && !force)) {
      return;
    }
    _websiteNextMatchesRequested = true;
    _websiteNextMatchesLoading = true;
    try {
      await fetchWebsiteContent(force: force);
      if (isClosed) return;
      final url = _websiteScheduleUrl;
      if (url == null) {
        websiteSchedule.value = null;
      } else {
        try {
          final schedule = await websiteVideoProvider.fetchSchedule(url);
          if (!isClosed) websiteSchedule.value = schedule;
        } catch (_) {
          // Schedule failure must not undo successful homepage sections.
        }
      }
    } finally {
      _websiteNextMatchesLoading = false;
    }
  }

  @override
  void onClose() {
    websiteVideoProvider.httpClient.close();
    super.onClose();
  }

  final MatchProvider apiProvider = MatchProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final InfoProvider infoProvider = InfoProvider();
  final Rx<List<MatchResultBySeason>> threeLatestMatch =
      Rx<List<MatchResultBySeason>>([]);
  final text = "".obs;
  final Rx<List<Post>> topicsData = Rx([]);
  List<CustomBanner> bannerData = [];
  final selectedWallpaper = "".obs;
  final selectedWallpaperName = "".obs;
  final isLoading = false.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();
    mediaProvider.onInit();
    infoProvider.onInit();
  }

  void screenInit({bool refreshWebsiteContent = false}) {
    fetchWebsiteNextMatches(force: refreshWebsiteContent);
    getTopics();

    // isLoading.value = false;
  }

  void setBannerData(List<CustomBanner> data) {
    bannerData = data.reversed.toList();
    // Use update instead of .value assignment
    update(['banner_slider']); // Update only the banner slider
  }

  void getBanner() async {
    final response = await mediaProvider.fetchBanner();

    debugPrint("Success fetch banner");
    setBannerData(response);
  }

  void getWallpaper() async {
    mediaProvider.onInit();

    final wallpaperLink = MySharedPref.getWallpaper();
    final wallpaperName = MySharedPref.getWallpaperName();

    debugPrint("getwallpaper 2 $wallpaperName");
    if (wallpaperLink != null) {
      selectedWallpaper.value = wallpaperLink;
      selectedWallpaperName.value = wallpaperName ?? "";
    }
  }

  void getTopics() async {
    debugPrint("get info");
    final List<Post> data = await infoProvider.getNotice();

    topicsData.value = data.take(3).toList(); // Update this line
  }

  void fetchMatchResult() async {
    debugPrint("getwallpaper 1");

    final Map<String, dynamic>? data = await getSeasonCategoryId();
    debugPrint("get season is $data");
    if (data != null) {
      final List<MatchResultBySeason> latestMatches =
          await getLatestPosts(data['id'], data['count']);

      // Sort latestMatches by custom_field.gameDate
      latestMatches.sort((a, b) {
        DateTime? dateA =
            parseGameDateTime(a.custom_field.gameDate?.first ?? "");
        DateTime? dateB =
            parseGameDateTime(b.custom_field.gameDate?.first ?? "");

        // Handle null cases
        if (dateA == null && dateB == null) return 0; // Both are null
        if (dateA == null) return 1; // dateA is null, so dateB is "less"
        if (dateB == null) return -1; // dateB is null, so dateA is "greater"

        return dateA.compareTo(dateB); // Compare the two dates
      });

      threeLatestMatch.value = latestMatches;
      text.value = "${latestMatches.length}";
      for (var match in latestMatches) {
        debugPrint("Match Title: ${match.custom_field.gameDate}");
      }
    } else {
      debugPrint("No data found for the current season.");
    }
  }

  Future<Map<String, dynamic>?> tryFindSeason(String seasonSlug) async {
    int page = 1;

    while (true) {
      List<Category> response = await apiProvider.getMatch(page: page);

      if (response.isEmpty) break;

      for (var category in response) {
        if (category.slug == seasonSlug) {
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

  Future<Map<String, dynamic>?> getSeasonCategoryId() async {
    int currentYear = DateTime.now().year;
    int nextYear = currentYear + 1;

    // Try current season first
    String seasonSlug = 'season_${currentYear}_${nextYear}';
    Map<String, dynamic>? result = await tryFindSeason(seasonSlug);

    // If not found, try previous season
    if (result == null) {
      String previousSeasonSlug = 'season_${currentYear - 1}_${currentYear}';
      result = await tryFindSeason(previousSeasonSlug);
    }

    return result;
    // int currentYear = DateTime.now().year; // Get the current year
    // int nextYear = currentYear + 1; // Calculate the next year
    // String seasonSlug =
    //     'season_${currentYear}_${nextYear}'; // Construct the slug for the season
    // int page = 1; // Start with page 1
    //
    // while (true) {
    //   List<Category> response = await apiProvider.getMatch(page: page);
    //
    //   print("response data is ${response}");
    //   if (response.isEmpty) {
    //     break; // If the page is empty, break the loop
    //   }
    //
    //   // Find the category that matches the season slug
    //   for (var category in response) {
    //     if (category.slug == seasonSlug) {
    //       // Check if the slug matches
    //       return {
    //         'id': category.id,
    //         'count': category.count, // Return both id and count
    //       };
    //     }
    //   }
    //
    //   // Increment page number to fetch the next page
    //   page++;
    // }
    //
    // return null; // If not found, return null
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

  DateTime? parseGameDateTime(String gameDate) {
    try {
      // Parse game_date (e.g., "2025年05月04日（日）")
      String formattedDate = gameDate
          .replaceAll(RegExp(r'[年月日（）]'), '-') // Replace Japanese characters
          .replaceAll(' ', '') // Remove spaces
          .replaceAll('--', '-'); // Remove double dashes

      // Remove trailing "-"
      if (formattedDate.endsWith('-')) {
        formattedDate = formattedDate.substring(0, formattedDate.length - 1);
      }

      // Parse the date and set time to midnight (00:00)
      DateTime date = DateFormat('yyyy-MM-dd').parse(formattedDate);
      return DateTime(
          date.year, date.month, date.day, 0, 0); // Set time to 00:00
    } catch (e) {
      debugPrint("Error parsing game date: $e");
      return null;
    }
  }

  void launchExternalWeb(String url) async {
    final Uri webUrl = Uri.parse(url); // Replace with your profile URL
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    } else {
      throw 'Could not launch $webUrl';
    }
  }

  Future<String> getNewsImage(String content) async {
    // Define your regex to find the first <img> tag's src
    final regex = RegExp(r'<img[^>]+src=\"(?<src>[^\"]+)\"[^>]*>');
    // Search for the first match
    final match = regex.firstMatch(content);

    print("get image ${match?.namedGroup('src')}");
    // If a match is found, extract the 'src' group
    if (match != null && match.namedGroup('src') != null) {
      return match.namedGroup('src')!;
    } else {
      return '';
    }

    // If no match is found, fallback to fetching via mediaProvider
    final mediaProvider = MediaProvider();
    final imageData = await mediaProvider.fetchParentMedia("mediaId");
    return imageData.media_details.sizes.thumbnail.source_url ?? "";
  }

  Future<String> getFeaturedImage(String mediaId) async {
    final imageData = await mediaProvider.fetchMedia(mediaId);
    print("GET NEWS IMAGE ${imageData}");
    final image = imageData.media_details.sizes.thumbnail.source_url;
    print("GET NEWS IMAGE ${mediaId}, ${image}");
    return image ?? "";
  }
}
