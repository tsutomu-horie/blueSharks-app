import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_media.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';

void main() {
  group('GameGuidePost', () {
    test('WordPressレスポンスから記事を生成できる', () {
      final post = GameGuidePost.fromJson({
        'id': 10,
        'date': '2026-07-27T14:30:00',
        'link': 'https://blue-sharks.jp/game-guide/sample/',
        'title': {
          'rendered': '夢の島&amp;観戦ガイド',
        },
        'acf': {
          'season': '2026-27',
          'location': '夢の島競技場',
          'game_status': '予定',
        },
        '_embedded': {
          'wp:featuredmedia': [
            {
              'source_url': 'https://blue-sharks.jp/image.jpg',
            },
          ],
        },
      });

      expect(post.id, 10);
      expect(post.title, '夢の島&観戦ガイド');
      expect(post.publishedAt, DateTime(2026, 7, 27, 14, 30));
      expect(post.thumbnailUrl, 'https://blue-sharks.jp/image.jpg');
      expect(post.season, '2026-27');
      expect(post.location, '夢の島競技場');
      expect(post.status, '予定');
    });

    test('必須項目が欠損した記事はFormatExceptionになる', () {
      expect(
        () => GameGuidePost.fromJson({
          'id': 10,
          'date': '2026-07-27T14:30:00',
          'title': {'rendered': 'URLなし'},
        }),
        throwsFormatException,
      );
    });

    test('キャッシュ用JSONを往復できる', () {
      final original = GameGuidePost(
        id: 1,
        title: '記事',
        publishedAt: DateTime(2026, 7, 27),
        detailUrl: 'https://blue-sharks.jp/game-guide/1/',
        thumbnailUrl: 'https://blue-sharks.jp/image.jpg',
      );

      final restored = GameGuidePost.fromCacheJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.publishedAt, original.publishedAt);
      expect(restored.detailUrl, original.detailUrl);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
    });
  });

  group('GameGuideMedia', () {
    test('縦長のメインビジュアルから軽量サムネイルを選択する', () {
      final media = [
        GameGuideMedia.fromJsonOrNull({
          'post': 10,
          'source_url': 'https://blue-sharks.jp/gourmet.jpg',
          'title': {'rendered': 'グルメ'},
          'media_details': {
            'width': 600,
            'height': 400,
          },
        })!,
        GameGuideMedia.fromJsonOrNull({
          'post': 10,
          'source_url': 'https://blue-sharks.jp/key-visual.png',
          'title': {'rendered': '2026_428_500_ホストゲーム'},
          'media_details': {
            'width': 856,
            'height': 1000,
            'sizes': {
              'thumbnail': {
                'source_url': 'https://blue-sharks.jp/key-visual-300x200.png',
              },
            },
          },
        })!,
      ];

      expect(
        selectGameGuideThumbnail(media),
        'https://blue-sharks.jp/key-visual-300x200.png',
      );
    });

    test('メインビジュアルを特定できない場合は画像を選ばない', () {
      final media = [
        GameGuideMedia.fromJsonOrNull({
          'post': 10,
          'source_url': 'https://blue-sharks.jp/gourmet.jpg',
          'title': {'rendered': 'グルメ'},
          'media_details': {
            'width': 600,
            'height': 400,
          },
        })!,
      ];

      expect(selectGameGuideThumbnail(media), isNull);
    });

    test('不正な添付画像レスポンスを除外する', () {
      expect(
        GameGuideMedia.fromJsonOrNull({
          'post': 0,
          'source_url': '',
        }),
        isNull,
      );
    });
  });
}
