import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_provider.dart';
import 'package:koto_blue_sharks/presentation/game_guide/controllers/game_guide.controller.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGameGuideProvider extends GameGuideProvider {
  _FakeGameGuideProvider(this.posts);

  List<GameGuidePost> posts;
  bool shouldFail = false;
  final requestedPages = <int>[];
  Future<List<GameGuidePost>> Function(int page)? handler;

  @override
  void onInit() {}

  @override
  Future<List<GameGuidePost>> fetchGuides({
    required int page,
    int perPage = GameGuideProvider.defaultPageSize,
  }) async {
    requestedPages.add(page);
    if (shouldFail) throw const GameGuideRequestException();
    if (handler != null) return handler!(page);
    return posts;
  }
}

GameGuidePost _post(int id) => GameGuidePost(
      id: id,
      title: '記事$id',
      publishedAt: DateTime(2026, 9, 1),
      detailUrl: 'https://example.test/game-guide/$id/',
      season: id.isEven ? '2026' : '2025',
    );

List<GameGuidePost> _page(int firstId) => List.generate(
    GameGuideProvider.defaultPageSize, (index) => _post(firstId + index));

List<int> _cachedIds() =>
    (jsonDecode(MySharedPref.getGameGuideArticlesCache()!) as List)
        .map((item) => (item as Map)['id'] as int)
        .toList();

GameGuideController _controller(_FakeGameGuideProvider provider,
        {bool save = true}) =>
    GameGuideController(provider: provider)..saveArticlesEnabled.value = save;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  test('旧サイトの保存記事を更新待ち・通信失敗中も表示せず、保存ON設定は維持する', () async {
    final legacy = GameGuidePost(
      id: 999,
      title: '旧サイトの記事',
      publishedAt: null,
      detailUrl: 'https://blue-sharks.jp/game-guide/999/',
    );
    SharedPreferences.setMockInitialValues({
      'saveGameGuideArticles': true,
      'gameGuideArticlesCache': jsonEncode([legacy.toJson()]),
      'gameGuideArticlesCachedAt': DateTime(2026, 10, 20).toIso8601String(),
    });
    await MySharedPref.init();
    expect(MySharedPref.getSaveGameGuideArticles(), isTrue);
    expect(MySharedPref.getGameGuideArticlesCache(), isNull);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), isNull);
    final pending = Completer<List<GameGuidePost>>();
    final provider = _FakeGameGuideProvider([])
      ..handler = (_) => pending.future;
    final controller = _controller(provider);
    final load = controller.loadInitial();
    expect(controller.guides, isEmpty);
    expect(controller.visibleGuides, isEmpty);
    provider.shouldFail = true;
    pending.completeError(const GameGuideRequestException());
    await load;
    expect(controller.guides, isEmpty);
    expect(controller.visibleGuides, isEmpty);
    expect(controller.syncState.value, GameGuideSyncState.failed);
    expect(MySharedPref.getSaveGameGuideArticles(), isTrue);
  });

  test('WordPress記事の同期成功と復帰時失敗を状態へ反映する', () async {
    final provider = _FakeGameGuideProvider([
      GameGuidePost(
        id: 1,
        title: '記事',
        publishedAt: DateTime(2026, 9, 1),
        detailUrl: 'https://blue-sharks.jp/game-guide/1/',
      ),
    ]);
    final controller = GameGuideController(provider: provider);

    await controller.loadInitial();

    expect(controller.syncState.value, GameGuideSyncState.synced);
    expect(controller.lastSyncedCount.value, 1);
    expect(controller.lastSyncedAt.value, isNotNull);

    provider.shouldFail = true;
    await controller.refreshOnResume();

    expect(controller.syncState.value, GameGuideSyncState.failed);
    expect(controller.syncFailureCount.value, 1);
    expect(controller.guides, hasLength(1));
    expect(controller.showingCachedData.value, isFalse);
  });

  test('保存ONの非空→正常空でsnapshotと日時を更新しoffline新Controllerで旧IDを復活させない', () async {
    final provider = _FakeGameGuideProvider([_post(1)]);
    final controller = _controller(provider);
    await controller.loadInitial();
    expect(_cachedIds(), [1]);
    final oldDate = DateTime(2020);
    await MySharedPref.setGameGuideArticlesCachedAt(oldDate);

    provider.posts = [];
    await controller.refreshOnResume();

    expect(controller.guides, isEmpty);
    expect(controller.visibleGuides, isEmpty);
    expect(controller.hasMore.value, isFalse);
    expect(controller.syncState.value, GameGuideSyncState.synced);
    expect(controller.lastSyncedCount.value, 0);
    expect(MySharedPref.getGameGuideArticlesCache(), '[]');
    final emptyCachedAt = MySharedPref.getGameGuideArticlesCachedAt();
    expect(emptyCachedAt, isNotNull);
    expect(emptyCachedAt!.isAfter(oldDate), isTrue);

    final offlineProvider = _FakeGameGuideProvider([])..shouldFail = true;
    final reopened = _controller(offlineProvider);
    await reopened.loadInitial();

    expect(offlineProvider.requestedPages, [1, 1, 1]);
    expect(reopened.guides, isEmpty);
    expect(reopened.visibleGuides, isEmpty);
    expect(reopened.showingCachedData.value, isTrue);
    expect(reopened.cachedAt.value, emptyCachedAt);
    expect(MySharedPref.getGameGuideArticlesCache(), '[]');
    expect(MySharedPref.getGameGuideArticlesCachedAt(), emptyCachedAt);
  });

  test('保存ONの初回正常空も既存非空snapshotを空へ更新する', () async {
    final seed = _controller(_FakeGameGuideProvider([_post(9)]));
    await seed.loadInitial();
    final fresh = _controller(_FakeGameGuideProvider([]));
    await fresh.loadInitial();
    expect(fresh.guides, isEmpty);
    expect(fresh.showingCachedData.value, isFalse);
    expect(MySharedPref.getGameGuideArticlesCache(), '[]');
  });

  test('初回取得失敗は有効snapshotと保存日時を維持して表示する', () async {
    await _controller(_FakeGameGuideProvider([_post(1)])).loadInitial();
    final saved = MySharedPref.getGameGuideArticlesCache();
    final date = MySharedPref.getGameGuideArticlesCachedAt();
    final provider = _FakeGameGuideProvider([])..shouldFail = true;
    final reopened = _controller(provider);
    await reopened.loadInitial();
    expect(reopened.guides.map((post) => post.id), [1]);
    expect(reopened.showingCachedData.value, isTrue);
    expect(reopened.syncState.value, GameGuideSyncState.cached);
    expect(reopened.errorMessage.value, isNull);
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), date);
  });

  test('再取得失敗後も集積一覧・snapshot・次pageを維持する', () async {
    final provider = _FakeGameGuideProvider(_page(1));
    final controller = _controller(provider);
    await controller.loadInitial();
    provider.posts = _page(11);
    await controller.loadMore();
    final saved = MySharedPref.getGameGuideArticlesCache();
    final date = MySharedPref.getGameGuideArticlesCachedAt();
    provider.shouldFail = true;
    await controller.refreshGuides();
    expect(controller.guides, hasLength(20));
    expect(controller.hasMore.value, isTrue);
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), date);
    provider.shouldFail = false;
    provider.posts = [];
    await controller.loadMore();
    expect(provider.requestedPages, [1, 2, 1, 1, 1, 3]);
    expect(controller.guides, hasLength(20));
    expect(controller.hasMore.value, isFalse);
  });

  test('再取得失敗は末尾到達済みhasMore=falseを変えない', () async {
    final provider = _FakeGameGuideProvider([_post(1)]);
    final controller = _controller(provider);
    await controller.loadInitial();
    provider.shouldFail = true;
    await controller.refreshOnResume();
    await controller.loadMore();
    expect(controller.hasMore.value, isFalse);
    expect(provider.requestedPages, [1, 1, 1, 1]);
    expect(_cachedIds(), [1]);
  });

  test('追加取得失敗は一覧・snapshot・日時・page・hasMoreを変えない', () async {
    final provider = _FakeGameGuideProvider(_page(1));
    final controller = _controller(provider);
    await controller.loadInitial();
    final saved = MySharedPref.getGameGuideArticlesCache();
    final date = MySharedPref.getGameGuideArticlesCachedAt();
    provider.shouldFail = true;
    await controller.loadMore();
    expect(controller.guides, hasLength(10));
    expect(controller.hasMore.value, isTrue);
    expect(controller.isLoadingMore.value, isFalse);
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), date);
    provider.shouldFail = false;
    provider.posts = [];
    await controller.loadMore();
    expect(provider.requestedPages, [1, 2, 2, 2, 2]);
    expect(controller.guides, hasLength(10));
    expect(_cachedIds(), List.generate(10, (index) => index + 1));
  });

  test('追加page末尾[]は集積snapshotを空にしない', () async {
    final provider = _FakeGameGuideProvider(_page(1));
    final controller = _controller(provider);
    await controller.loadInitial();
    provider.posts = [];
    await controller.loadMore();
    expect(controller.guides, hasLength(10));
    expect(controller.visibleGuides, hasLength(10));
    expect(_cachedIds(), List.generate(10, (index) => index + 1));
    expect(controller.lastSyncedCount.value, 10);
    expect(controller.hasMore.value, isFalse);
  });

  test('未取得の追加page[]は既存有効snapshotを空にしない', () async {
    await _controller(_FakeGameGuideProvider([_post(1)])).loadInitial();
    final saved = MySharedPref.getGameGuideArticlesCache();
    final date = MySharedPref.getGameGuideArticlesCachedAt();
    await _controller(_FakeGameGuideProvider([])).loadMore();
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), date);
  });

  test('表示filterが0件でも全体snapshotを保持する', () async {
    final controller = _controller(_FakeGameGuideProvider([_post(1)]));
    await controller.loadInitial();
    final saved = MySharedPref.getGameGuideArticlesCache();
    controller.applyFilters(season: '存在しない');
    expect(controller.visibleGuides, isEmpty);
    await controller.setSaveArticlesEnabled(true);
    expect(controller.guides, hasLength(1));
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    controller.clearFilters();
    expect(controller.visibleGuides, hasLength(1));
  });

  test('未取得emptyで保存ONへのtoggleは有効snapshotを空にしない', () async {
    await _controller(_FakeGameGuideProvider([_post(1)])).loadInitial();
    final saved = MySharedPref.getGameGuideArticlesCache();
    final date = MySharedPref.getGameGuideArticlesCachedAt();
    final uninitialized = _controller(_FakeGameGuideProvider([]), save: false);
    await uninitialized.setSaveArticlesEnabled(true);
    expect(MySharedPref.getGameGuideArticlesCache(), saved);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), date);
  });

  test('保存OFFでは非空/正常空を保存せずOFF toggleは既存キーを削除する', () async {
    final provider = _FakeGameGuideProvider([_post(1)]);
    final controller = _controller(provider, save: false);
    await controller.loadInitial();
    expect(MySharedPref.getGameGuideArticlesCache(), isNull);
    await controller.setSaveArticlesEnabled(true);
    expect(_cachedIds(), [1]);
    await controller.setSaveArticlesEnabled(false);
    expect(MySharedPref.getGameGuideArticlesCache(), isNull);
    expect(MySharedPref.getGameGuideArticlesCachedAt(), isNull);
    provider.posts = [];
    await controller.refreshGuides();
    expect(MySharedPref.getGameGuideArticlesCache(), isNull);
    expect(MySharedPref.getSaveGameGuideArticles(), isFalse);
  });

  test('追加pageは既存一覧と同一page内の重複IDを除く', () async {
    final provider = _FakeGameGuideProvider(_page(1));
    final controller = _controller(provider);
    await controller.loadInitial();
    provider.posts = [_post(1), _post(11), _post(11), _post(12)];
    await controller.loadMore();
    expect(controller.guides.map((post) => post.id),
        List.generate(12, (index) => index + 1));
    expect(_cachedIds(), List.generate(12, (index) => index + 1));
  });

  test('追加取得中の復帰再取得を排他し、完了後の正常空snapshotを再汚染しない', () async {
    final provider = _FakeGameGuideProvider(_page(1));
    final controller = _controller(provider);
    await controller.loadInitial();
    final pending = Completer<List<GameGuidePost>>();
    provider.handler = (_) => pending.future;
    final loadingMore = controller.loadMore();
    await controller.refreshOnResume();
    expect(provider.requestedPages, [1, 2]);
    expect(controller.isLoadingMore.value, isTrue);
    pending.complete([_post(11)]);
    await loadingMore;
    provider.handler = null;
    provider.posts = [];
    await controller.refreshOnResume();
    expect(controller.guides, isEmpty);
    expect(MySharedPref.getGameGuideArticlesCache(), '[]');
  });

  test('初回取得中は追加pageを開始しない', () async {
    final provider = _FakeGameGuideProvider([]);
    final pending = Completer<List<GameGuidePost>>();
    provider.handler = (_) => pending.future;
    final controller = _controller(provider);
    final initial = controller.loadInitial();
    await controller.loadMore();
    expect(provider.requestedPages, [1]);
    pending.complete([]);
    await initial;
    expect(MySharedPref.getGameGuideArticlesCache(), '[]');
  });
}
