import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class MatchListController extends GetxController {
  MatchListController({MatchProvider? apiProvider, DateTime Function()? now})
      : apiProvider = apiProvider ?? MatchProvider(),
        _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final MatchProvider apiProvider;
  final mediaProvider = MediaProvider();
  final matchCategory = Rx<List<Category>>([]);
  final seasonSlug = ''.obs;
  final selectedYear = ''.obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final listMatch = Rx<List<MatchResultBySeason>>([]);
  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    mediaProvider.onInit();
    fetchMatchResult();
    AnalyticsService.logPageView(Routes.GAME_INFO);
  }

  Future<void> selectYear(Category season) async {
    final request = ++_request;
    selectedYear.value = season.name;
    seasonSlug.value = season.slug;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final values = await getLatestPosts(season.id, season.count);
      if (!isClosed && request == _request) listMatch.value = values;
    } catch (_) {
      if (!isClosed && request == _request)
        errorMessage.value = '試合情報を取得できませんでした。';
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<void> fetchMatchResult() async {
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final categories = <Category>[];
      for (var page = 1;; page++) {
        final values = await apiProvider.getMatch(page: page);
        if (isClosed || request != _request) return;
        categories.addAll(values);
        if (values.length < 100) break;
      }
      matchCategory.value = categories;
      final chosen = categories
              .firstWhereOrNull((s) => s.slug == seasonSlug.value) ??
          categories.firstWhereOrNull(
              (s) => s.slug == 'season_${_now().year}_${_now().year + 1}') ??
          categories.firstWhereOrNull(
              (s) => s.slug == 'season_${_now().year - 1}_${_now().year}');
      if (chosen == null) {
        selectedYear.value = '';
        listMatch.value = [];
        return;
      }
      selectedYear.value = chosen.name;
      seasonSlug.value = chosen.slug;
      final values = await getLatestPosts(chosen.id, chosen.count);
      if (!isClosed && request == _request) listMatch.value = values;
    } catch (_) {
      if (!isClosed && request == _request)
        errorMessage.value = '試合情報を取得できませんでした。';
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  DateTime? parseJapaneseDate(String value) {
    final m = RegExp(r'(\d+)年(\d+)月(\d+)日').firstMatch(value);
    return m == null
        ? null
        : DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  Future<List<MatchResultBySeason>> getLatestPosts(
      int categoryId, int count) async {
    final result = <MatchResultBySeason>[];
    final ids = <int>{};
    // Imported taxonomy counts can be stale. Follow the actual post pages.
    for (var page = 1;; page++) {
      final values =
          await apiProvider.getMatchBySeasonId(categoryId, page: page);
      for (final match in values) {
        if (!ids.add(match.id))
          throw const FormatException('Repeated match page.');
        result.add(match);
      }
      if (values.length < 10) break;
    }
    result.sort((a, b) {
      final x = parseJapaneseDate(a.custom_field.gameDate?.firstOrNull ?? '');
      final y = parseJapaneseDate(b.custom_field.gameDate?.firstOrNull ?? '');
      return x == null || y == null ? 0 : y.compareTo(x);
    });
    return result;
  }

  @override
  void onClose() {
    _request++;
    apiProvider.renewal.httpClient.close();
    apiProvider.httpClient.close();
    mediaProvider.httpClient.close();
    super.onClose();
  }
}
