import 'package:flutter_test/flutter_test.dart';

import 'package:koto_blue_sharks/presentation/wordpress/controllers/wordpress.controller.dart';

void main() {
  test('WordPress管理リンクはHTTPS・許可ホスト・末尾スラッシュを保つ', () {
    final controller = WordPressController();
    final uri = controller.wordpressAdminUri;

    expect(uri.scheme, 'https');
    expect(uri.host, 'blue-sharks.jp');
    expect(uri.path, '/wp-admin/');
    expect(uri.toString(), 'https://blue-sharks.jp/wp-admin/');
    expect(controller.canOpenWordPressAdmin, isTrue);
  });
}
