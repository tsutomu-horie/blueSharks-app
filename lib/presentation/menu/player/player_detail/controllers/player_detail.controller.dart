import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class PlayerDetailController extends GetxController {
  final MediaProvider mediaProvider = MediaProvider();
  final website = RenewalWebsiteProvider();
  final detail = Rxn<Member>();
  final loading = false.obs;
  final failed = false.obs;
  int? _memberId;

  Future<void> loadDetail(Member member, {bool retry = false}) async {
    if (_memberId == member.id && !retry) return;
    _memberId = member.id;
    loading.value = true;
    failed.value = false;
    try {
      final value = await website.memberDetail(member);
      if (!isClosed && _memberId == member.id) detail.value = value;
    } catch (_) {
      if (!isClosed && _memberId == member.id) failed.value = true;
    } finally {
      if (!isClosed && _memberId == member.id) loading.value = false;
    }
  }

  @override
  void onClose() {
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
