import 'package:flutter_test/flutter_test.dart';

import 'package:koto_blue_sharks/presentation/wordpress/controllers/wordpress.controller.dart';

void main() {
  test('WordPress管理画面URLは許可されたサイトを指す', () {
    final controller = WordPressController();

    expect(controller.wordpressAdminUri.path, '/wp-admin/');
    expect(controller.canOpenWordPressAdmin, isTrue);
  });
}
