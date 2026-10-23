import 'dart:convert';
import 'dart:io';
import 'package:koto_blue_sharks/presentation/game_guide/controllers/game_guide.controller.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_provider.dart';

Map<String, dynamic> _post(int id, {bool thumbnail = true}) => {
      'id': id,
      'title': {'rendered': '記事$id'},
      'link': 'https://example.test/game-guide/$id/',
      if (thumbnail) 'thumbnail_url': 'https://example.test/$id.jpg',
    };

void main() {
  late HttpServer server;
  late GameGuideProvider provider;
  late Future<void> Function(HttpRequest) respond;
  late List<Uri> requests;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = [];
    respond = (request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write('[]');
      await request.response.close();
    };
    server.listen((request) async {
      requests.add(request.uri);
      await respond(request);
    });
    provider = GameGuideProvider();
    provider.onInit();
    expect(provider.httpClient.baseUrl,
        'https://blue-sharks.donati.jp/wp-json/wp/v2/');
    provider.httpClient.baseUrl = 'http://127.0.0.1:${server.port}/';
  });

  tearDown(() async {
    provider.httpClient.close();
    await server.close(force: true);
  });

  void body(String value, {int status = 200, bool json = true}) {
    respond = (request) async {
      request.response.statusCode = status;
      if (json) request.response.headers.contentType = ContentType.json;
      request.response.write(value);
      await request.response.close();
    };
  }

  test('先頭ページの欠損記事だけを除外し、元件数を使って後続記事まで絞り込み対象にする', () async {
    respond = (request) async {
      request.response.headers.contentType = ContentType.json;
      final page = request.uri.queryParameters['page'];
      request.response.write(jsonEncode(page == '1'
          ? [
              ...List.generate(9, (i) => _post(i + 1)),
              {
                'id': 99,
                'title': {'rendered': 'URLなし'}
              }
            ]
          : [_post(11)]));
      await request.response.close();
    };
    final c = GameGuideController(provider: provider);
    await c.loadInitial();
    expect(c.guides, hasLength(9));
    expect(c.hasMore.value, isTrue);
    expect(await c.loadAllForFilters(), isTrue);
    expect(c.guides.map((p) => p.id), [...List.generate(9, (i) => i + 1), 11]);
    expect(c.hasMore.value, isFalse);
    expect(requests.map((r) => r.queryParameters['page']), ['1', '2']);
  });

  test('最終ページのWordPress終端400だけを空として扱う', () async {
    body('{"code":"rest_post_invalid_page"}', status: 400);
    expect(await provider.fetchGuides(page: 2), isEmpty);
    await expectLater(provider.fetchGuides(page: 1),
        throwsA(isA<GameGuideRequestException>()));
    body('{"code":"rest_invalid_param"}', status: 400);
    await expectLater(provider.fetchGuides(page: 2),
        throwsA(isA<GameGuideRequestException>()));
  });

  test('実HTTPの正常raw[]だけを空成功にしpage/perPage契約を保つ', () async {
    expect(await provider.fetchGuides(page: 2, perPage: 7), isEmpty);
    expect(requests.single.path, '/game-guide');
    expect(requests.single.queryParameters,
        {'page': '2', 'per_page': '7', '_embed': '1'});
  });

  test('正常非空と欠損記事の混在では既存parserの有効記事だけを公開する', () async {
    body(jsonEncode([
      _post(1),
      {
        'id': 2,
        'title': {'rendered': 'URLなし'}
      },
      null,
      42,
      _post(3),
    ]));
    final posts = await provider.fetchGuides(page: 1);
    expect(posts.map((post) => post.id), [1, 3]);
    expect(posts.first.publishedAt, isNull);
  });

  test('ID/dateを独自に必須化せず既存parserを維持する', () async {
    body(jsonEncode([
      {
        'title': {'rendered': '記事'},
        'link': 'https://example.test/guide/'
      },
    ]));
    final posts = await provider.fetchGuides(page: 1);
    expect(posts.single.id, 0);
    expect(posts.single.publishedAt, isNull);
  });

  for (final value in [
    'null',
    '{}',
    '{"posts":[]}',
    '"[]"',
    '42',
    'not JSON',
    '[',
    '',
    '[null,42,"article"]',
    '[{"id":1,"title":{"rendered":"URLなし"}}]',
  ]) {
    test('実GetConnectの不正応答$valueを失敗にする', () async {
      body(value);
      await expectLater(provider.fetchGuides(page: 1),
          throwsA(isA<GameGuideRequestException>()));
    });
  }

  for (final status in [204, 400, 500]) {
    test('HTTP$statusの本文欠如/エラーを空成功にしない', () async {
      body(status == 204 ? '' : '[]', status: status);
      await expectLater(provider.fetchGuides(page: 1),
          throwsA(isA<GameGuideRequestException>()));
    });
  }

  test('2xxの妥当raw配列をContent-Type正規化に依存せず検証する', () async {
    body('[]', status: 201, json: false);
    expect(await provider.fetchGuides(page: 1), isEmpty);
  });

  test('Media取得失敗でも妥当な記事を残す', () async {
    respond = (request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/media') {
        request.response.statusCode = 500;
        request.response.write('{}');
      } else {
        request.response.write(jsonEncode([_post(1, thumbnail: false)]));
      }
      await request.response.close();
    };
    final posts = await provider.fetchGuides(page: 1);
    expect(posts.single.id, 1);
    expect(posts.single.thumbnailUrl, isNull);
    expect(requests.last.path, '/media');
  });

  test('timeoutをerrorSafety経由でも失敗にする', () async {
    provider.httpClient.timeout = const Duration(milliseconds: 30);
    respond = (request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await request.response.close();
    };
    await expectLater(provider.fetchGuides(page: 1),
        throwsA(isA<GameGuideRequestException>()));
  });

  test('接続失敗のstatusCode=nullを空成功にしない', () async {
    await server.close(force: true);
    await expectLater(provider.fetchGuides(page: 1),
        throwsA(isA<GameGuideRequestException>()));
  });
}
