import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/utils/constant.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class MemberProvider extends GetConnect {
  MemberProvider({RenewalWebsiteProvider? renewal})
      : renewal = renewal ?? RenewalWebsiteProvider();
  final RenewalWebsiteProvider renewal;

  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Category>> fetchSinglePage({int page = 1}) =>
      renewal.memberCategories(page: page);

  Future<List<Category>> getCategories({int page = 1}) =>
      renewal.memberCategories(page: page);

  Future<List<Member>> getPlayersByCategory(int categoryId, {int page = 1}) =>
      renewal.members(categoryId, page: page);
}
