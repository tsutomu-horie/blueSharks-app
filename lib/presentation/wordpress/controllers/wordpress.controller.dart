import 'package:get/get.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

class WordPressController extends GetxController {
  static const _allowedHosts = {
    'blue-sharks.jp',
    'blue-sharks.donati.jp',
  };

  Uri get wordpressAdminUri => Uri.parse(Constants.wordpressAdminUrl);

  bool get canOpenWordPressAdmin {
    final uri = wordpressAdminUri;
    return (uri.scheme == 'https' || uri.scheme == 'http') &&
        _allowedHosts.contains(uri.host.toLowerCase());
  }
}
