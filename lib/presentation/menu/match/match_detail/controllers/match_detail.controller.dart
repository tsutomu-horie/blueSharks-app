import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';
import 'package:koto_blue_sharks/app/data/models/website/renewal_website_content.dart';

class MatchDetailController extends GetxController {
  MatchDetailController({RenewalWebsiteProvider? website})
      : website = website ?? RenewalWebsiteProvider();
  final RenewalWebsiteProvider website;
  final detail = Rxn<RenewalMatchDetail>();
  final loading = false.obs;
  final failed = false.obs;
  int? _matchId;
  int _request = 0;

  Future<void> loadDetail(MatchResultBySeason match,
      {bool retry = false}) async {
    if (_matchId == match.id && !retry) return;
    _matchId = match.id;
    final request = ++_request;
    loading.value = true;
    failed.value = false;
    try {
      final value = await website.matchDetail(match);
      if (!isClosed && request == _request) detail.value = value;
    } catch (_) {
      if (!isClosed && request == _request) failed.value = true;
    } finally {
      if (!isClosed && request == _request) loading.value = false;
    }
  }

  @override
  void onClose() {
    _request++;
    website.httpClient.close();
    super.onClose();
  }

  var selectedIndex = 0.obs; // Observable to track the selected tab index
  final MediaProvider mediaProvider = MediaProvider();

  @override
  void onInit() {
    super.onInit();

    mediaProvider.onInit();
    AnalyticsService.logPageView(Routes.MATCH_DETAIL);
  }

  void changeTab(int index) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Add delay of 200ms
    selectedIndex.value = index; // Update selected tab index after the delay
  }

  void onPageChanged(int index) {
    selectedIndex.value = index;
  }
}
