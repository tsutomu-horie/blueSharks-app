import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/presentation/menu/gallery/gallery_list/controllers/gallery.controller.dart';

class GalleryApi extends GalleryProvider {
  final requests = <String>[];
  @override
  Future<Response<T>> get<T>(String url,
      {Map<String, String>? headers,
      String? contentType,
      Map<String, dynamic>? query,
      T Function(dynamic)? decoder}) async {
    requests.add(url);
    final album = {
      'id': 9,
      'name': '登録されたアルバム',
      'date': '2026-10-21T03:00:00.000000Z',
      'photo': 'https://example.test/storage/registered.jpg'
    };
    final dynamic result = url.startsWith('galleries/albums')
        ? {
            'data': [album]
          }
        : {
            'data': [
              {
                'album': album,
                'galleries': {
                  'id': 91,
                  'photo': album['photo'],
                  'name': '登録された写真',
                  'date': album['date']
                }
              }
            ]
          };
    return Response<T>(statusCode: 200, body: result as T);
  }
}

void main() {
  test('サーバーの実レスポンス形式で登録済みアルバムと写真詳細を既存モデルへ渡す', () async {
    final api = GalleryApi();
    final albums = await api.fetchGalleryList(1, '2026', () {});
    expect(albums.single.id, 9);
    expect(albums.single.name, '登録されたアルバム');
    expect(albums.single.photo, 'https://example.test/storage/registered.jpg');
    final photos = await api.fetchGalleryDetail(albums.single.id, () {});
    expect(photos.single.album.id, 9);
    expect(photos.single.galleries.id, 91);
    expect(photos.single.galleries.photo, albums.single.photo);
    expect(api.requests,
        ['galleries/albums?category_id=1&year=2026', 'galleries?album_id=9']);
    api.httpClient.close();
  });
  test('登録済みデータがあればGALLERYは未登録状態にならず、再取得でも表示を維持する', () async {
    final controller = GalleryController(apiProvider: GalleryApi());
    await controller.getGalleryList();
    expect(controller.album, hasLength(1));
    expect(controller.errorMessage.value, isEmpty);
    expect(controller.isLoading.value, isFalse);
    await controller.onRefresh();
    expect(controller.album.single.name, '登録されたアルバム');
    controller.onDelete();
  });
}
