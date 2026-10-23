import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class PlayerDetailController extends GetxController {
  PlayerDetailController({RenewalWebsiteProvider? website})
      : website = website ?? RenewalWebsiteProvider();
  final MediaProvider mediaProvider = MediaProvider();
  final RenewalWebsiteProvider website;
  final detail = Rxn<Member>();
  final loading = false.obs;
  final failed = false.obs;
  int? _memberId;
  int _request = 0;

  Future<void> loadDetail(Member member, {bool retry = false}) async {
    if (_memberId == member.id && !retry) return;
    _memberId = member.id;
    final request = ++_request;
    loading.value = true;
    failed.value = false;
    try {
      final value = await website.memberDetail(member);
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

  @override
  void onInit() async {
    super.onInit();
    mediaProvider.onInit();

    AnalyticsService.logPageView(Routes.PLAYER_DETAIL);
  }
}
