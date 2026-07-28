import 'dart:convert';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_provider.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class GameGuideController extends GetxController {
  final GameGuideProvider provider = GameGuideProvider();

  final guides = <GameGuidePost>[].obs;
  final visibleGuides = <GameGuidePost>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final showingCachedData = false.obs;
  final cachedAt = Rxn<DateTime>();
  final saveArticlesEnabled = false.obs;
  final openingGuideId = RxnInt();

  final selectedSeason = RxnString();
  final selectedLocation = RxnString();
  final selectedStatus = RxnString();

  int _currentPage = 0;

  List<String> get seasons => _filterOptions(
        guides.map((item) => item.season),
      );

  List<String> get locations => _filterOptions(
        guides.map((item) => item.location),
      );

  List<String> get statuses => _filterOptions(
        guides.map((item) => item.status),
      );

  bool get hasActiveFilters =>
      selectedSeason.value != null ||
      selectedLocation.value != null ||
      selectedStatus.value != null;

  @override
  void onInit() {
    super.onInit();
    provider.onInit();
    saveArticlesEnabled.value = MySharedPref.getSaveGameGuideArticles();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = null;
    _currentPage = 0;
    hasMore.value = true;

    if (saveArticlesEnabled.value) {
      _loadCache();
    }

    try {
      final firstPage = await _fetchWithRetry(1);
      guides.assignAll(firstPage);
      _currentPage = 1;
      hasMore.value = firstPage.length == GameGuideProvider.defaultPageSize;
      showingCachedData.value = false;
      cachedAt.value = null;
      _applyFilters();
      await _persistCacheIfEnabled();
    } catch (_) {
      if (guides.isEmpty) {
        errorMessage.value = '記事を取得できませんでした。';
      } else {
        showingCachedData.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshGuides() => loadInitial();

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) {
      return;
    }

    isLoadingMore.value = true;
    errorMessage.value = null;
    try {
      final nextPage = _currentPage + 1;
      final nextItems = await _fetchWithRetry(nextPage);
      final existingIds = guides.map((item) => item.id).toSet();
      guides.addAll(
        nextItems.where((item) => !existingIds.contains(item.id)),
      );
      _currentPage = nextPage;
      hasMore.value = nextItems.length == GameGuideProvider.defaultPageSize;
      showingCachedData.value = false;
      _applyFilters();
      await _persistCacheIfEnabled();
    } catch (_) {
      errorMessage.value = '追加の記事を取得できませんでした。';
    } finally {
      isLoadingMore.value = false;
    }
  }

  void applyFilters({
    String? season,
    String? location,
    String? status,
  }) {
    selectedSeason.value = _normalizeFilter(season);
    selectedLocation.value = _normalizeFilter(location);
    selectedStatus.value = _normalizeFilter(status);
    _applyFilters();
  }

  void clearFilters() {
    selectedSeason.value = null;
    selectedLocation.value = null;
    selectedStatus.value = null;
    _applyFilters();
  }

  Future<void> setSaveArticlesEnabled(bool enabled) async {
    saveArticlesEnabled.value = enabled;
    await MySharedPref.setSaveGameGuideArticles(enabled);
    if (enabled) {
      await _persistCacheIfEnabled();
    } else {
      await MySharedPref.clearGameGuideArticlesCache();
      showingCachedData.value = false;
      cachedAt.value = null;
    }
  }

  Future<List<GameGuidePost>> _fetchWithRetry(int page) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await provider.fetchGuides(page: page);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('Failed to load game guides.');
  }

  void _applyFilters() {
    visibleGuides.assignAll(
      guides.where((item) {
        return _matches(item.season, selectedSeason.value) &&
            _matches(item.location, selectedLocation.value) &&
            _matches(item.status, selectedStatus.value);
      }),
    );
  }

  bool _matches(String? value, String? selected) {
    return selected == null || value == selected;
  }

  String? _normalizeFilter(String? value) {
    return value == null || value.isEmpty ? null : value;
  }

  List<String> _filterOptions(Iterable<String?> values) {
    final options = values
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    options.sort();
    return options;
  }

  Future<void> _persistCacheIfEnabled() async {
    if (!saveArticlesEnabled.value || guides.isEmpty) return;

    await MySharedPref.setGameGuideArticlesCache(
      jsonEncode(guides.map((item) => item.toJson()).toList()),
    );
    final now = DateTime.now();
    await MySharedPref.setGameGuideArticlesCachedAt(now);
  }

  void _loadCache() {
    final rawCache = MySharedPref.getGameGuideArticlesCache();
    if (rawCache == null || rawCache.isEmpty) return;

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! List) return;
      final cachedGuides = decoded
          .whereType<Map>()
          .map(
            (item) => GameGuidePost.fromCacheJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) => item.title.isNotEmpty && item.detailUrl.isNotEmpty,
          )
          .toList();
      if (cachedGuides.isEmpty) return;

      guides.assignAll(cachedGuides);
      cachedAt.value = MySharedPref.getGameGuideArticlesCachedAt();
      showingCachedData.value = true;
      _applyFilters();
    } catch (_) {
      // 壊れたキャッシュは表示せず、ネットワーク取得を継続する。
    }
  }
}
