import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_provider.dart';
import 'package:koto_blue_sharks/presentation/game_guide/controllers/game_guide.controller.dart';

class _FakeGameGuideProvider extends GameGuideProvider {
  _FakeGameGuideProvider(this.posts);

  final List<GameGuidePost> posts;
  bool shouldFail = false;

  @override
  void onInit() {}

  @override
  Future<List<GameGuidePost>> fetchGuides({
    required int page,
    int perPage = GameGuideProvider.defaultPageSize,
  }) async {
    if (shouldFail) throw const GameGuideRequestException();
    return posts;
  }
}

void main() {
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
}
