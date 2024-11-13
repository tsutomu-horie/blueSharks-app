import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/info/info_provider.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class ListTopicsController extends GetxController {
  final InfoProvider apiProvider = InfoProvider();
  final MediaProvider mediaProvider = MediaProvider();

  PageController pageController = PageController();
  var selectedIndex = 0.obs; // Observable to track the selected tab index

  final RxList<Post> matchInformation = RxList<Post>();
  final RxList<Post> notice = RxList<Post>();
  final RxList<Post> eventInformation = RxList<Post>();
  final RxList<Post> activities = RxList<Post>();
  final RxList<Post> interview = RxList<Post>();

  final ScrollController matchScrollController = ScrollController();
  final ScrollController noticeScrollController = ScrollController();
  final ScrollController eventScrollController = ScrollController();
  final ScrollController activitiesScrollController = ScrollController();
  final ScrollController interviewScrollController = ScrollController();

  // Track page numbers for pagination
  final RxMap<int, int> pageNumbers = RxMap<int, int>({0: 1, 1: 1, 2: 1, 3: 1, 4: 1});

  // Loading states for each tab
  final RxMap<int, bool> isLoading = RxMap<int, bool>({0: false, 1: false, 2: false, 3: false, 4: false});

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    mediaProvider.onInit();
    getInfo(0);

    matchScrollController.addListener(() => onScroll(0, matchScrollController));
    noticeScrollController.addListener(() => onScroll(1, noticeScrollController));
    eventScrollController.addListener(() => onScroll(2, eventScrollController));
    activitiesScrollController.addListener(() => onScroll(3, activitiesScrollController));
    interviewScrollController.addListener(() => onScroll(4, interviewScrollController));

    AnalyticsService.logPageView(Routes.LIST_TOPICS);

  }

  void getInfo(int tabIndex) async {
    if (isLoading[tabIndex]!) return; // Avoid multiple API calls at the same time

    isLoading[tabIndex] = true; // Set loading to true
    int page = pageNumbers[tabIndex]!; // Get the current page number for the tab

    try {
      // Fetch data based on the tab
      List<Post> newData = await _fetchDataForTab(tabIndex, page);

      // Add data to the corresponding RxList
      switch (tabIndex) {
        case 0:
          matchInformation.addAll(newData);
          break;
        case 1:
          notice.addAll(newData);
          break;
        case 2:
          eventInformation.addAll(newData);
          break;
        case 3:
          activities.addAll(newData);
          break;
        case 4:
          interview.addAll(newData);
          break;
      }

      // Increment page number for the next API call
      pageNumbers[tabIndex] = page + 1;
    } catch (e) {
      print('Error fetching data for tab $tabIndex: $e');
    } finally {
      isLoading[tabIndex] = false; // Set loading to false
    }
  }

// Return the correct ScrollController for each tab
  ScrollController getScrollController(int index) {
    switch (index) {
      case 0:
        return matchScrollController;
      case 1:
        return noticeScrollController;
      case 2:
        return eventScrollController;
      case 3:
        return activitiesScrollController;
      case 4:
        return interviewScrollController;
      default:
        return ScrollController(); // Return a default controller
    }
  }


  // Fetch data for each tab
  Future<List<Post>> _fetchDataForTab(int tabIndex, int page) async {
    switch (tabIndex) {
      case 0:
        return await apiProvider.getMatchInformation(page: page);
      case 1:
        return await apiProvider.getNotice(page: page);
      case 2:
        return await apiProvider.getEventInformation(page: page);
      case 3:
        return await apiProvider.getActivities(page: page);
      case 4:
        return await apiProvider.getInterview(page: page);
      default:
        return [];
    }
  }

  void changeTab(int index) async {
    selectedIndex.value = index; // Update selected tab index after the delay

    selectedIndex.value = index;

    // If the new tab has no data, fetch its data
    if (getTabData(index).isEmpty) {
      getInfo(index);
    }
  }

  RxList<Post> getTabData(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return matchInformation;
      case 1:
        return notice;
      case 2:
        return eventInformation;
      case 3:
        return activities;
      case 4:
        return interview;
      default:
        return RxList<Post>();
    }
  }

  void onScroll(int tabIndex, ScrollController controller) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      getInfo(tabIndex); // Load next page when scrolled to the bottom
    }
  }
  // Method to handle swipe between pages
  void onPageChanged(int index) {
    selectedIndex.value = index;
  }

  Future<String> getNewsImage(String mediaId) async {
    final imageData = await mediaProvider.fetchParentMedia(mediaId);
    print("GET NEWS IMAGE ${imageData}");
    final image = imageData?.media_details.sizes.thumbnail.source_url;
    print("GET NEWS IMAGE ${mediaId}, ${image}");
    return image ?? "";
  }

}
