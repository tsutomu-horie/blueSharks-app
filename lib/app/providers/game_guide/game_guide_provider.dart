import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_media.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class GameGuideProvider extends GetConnect {
  static const int defaultPageSize = 10;
  static const int _mediaPageSize = 100;

  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
    httpClient.timeout = const Duration(seconds: 30);
  }

  Future<List<GameGuidePost>> fetchGuides({
    required int page,
    int perPage = defaultPageSize,
  }) async {
    final response = await get<List<dynamic>>(
      'game-guide',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        '_embed': '1',
        // APIで許可されているWordPress既定の表示順をそのまま利用する。
      },
      decoder: (body) => body is List ? body : <dynamic>[],
    );

    if (response.hasError) {
      throw GameGuideRequestException(
        statusCode: response.statusCode,
        message: response.statusText,
      );
    }

    final posts = <GameGuidePost>[];
    for (final item in response.body ?? const <dynamic>[]) {
      if (item is! Map) continue;
      try {
        posts.add(
          GameGuidePost.fromJson(Map<String, dynamic>.from(item)),
        );
      } on FormatException {
        // 欠損記事のみ非表示にし、一覧全体の取得は継続する。
      }
    }
    return _attachFallbackThumbnails(posts);
  }

  Future<List<GameGuidePost>> _attachFallbackThumbnails(
    List<GameGuidePost> posts,
  ) async {
    final targetPostIds = posts
        .where((post) => post.thumbnailUrl == null && post.id > 0)
        .map((post) => post.id)
        .toSet();
    if (targetPostIds.isEmpty) return posts;

    try {
      final mediaByPost = <int, List<GameGuideMedia>>{};
      var page = 1;

      while (true) {
        final response = await get<List<dynamic>>(
          'media',
          query: {
            'parent': targetPostIds.join(','),
            'page': '$page',
            'per_page': '$_mediaPageSize',
            '_fields': 'id,post,title,slug,source_url,media_details',
          },
          decoder: (body) => body is List ? body : <dynamic>[],
        );

        if (response.hasError) {
          // 添付画像の取得失敗だけでは記事一覧を失敗扱いにしない。
          return posts;
        }

        final items = response.body ?? const <dynamic>[];
        for (final item in items) {
          if (item is! Map) continue;
          final media = GameGuideMedia.fromJsonOrNull(
            Map<String, dynamic>.from(item),
          );
          if (media == null) continue;
          mediaByPost.putIfAbsent(media.postId, () => []).add(media);
        }

        if (items.length < _mediaPageSize) break;
        page++;
      }

      return posts.map((post) {
        if (post.thumbnailUrl != null) return post;
        final thumbnailUrl = selectGameGuideThumbnail(
          mediaByPost[post.id] ?? const <GameGuideMedia>[],
        );
        return thumbnailUrl == null ? post : post.withThumbnail(thumbnailUrl);
      }).toList();
    } catch (_) {
      // 一覧表示を優先し、Media APIが使えない場合は画像なしで継続する。
      return posts;
    }
  }
}

class GameGuideRequestException implements Exception {
  const GameGuideRequestException({
    this.statusCode,
    this.message,
  });

  final int? statusCode;
  final String? message;

  @override
  String toString() {
    return 'GameGuideRequestException(statusCode: $statusCode, message: $message)';
  }
}
