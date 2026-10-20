import 'package:html/parser.dart' as html;

/// Product information explicitly published in the website's TOP GOODS area.
class WebsiteGoods {
  const WebsiteGoods({
    required this.url,
    required this.imageUrl,
    required this.name,
    required this.priceLabel,
  });

  final Uri url;
  final Uri imageUrl;
  final String name;
  final String priceLabel;

  static List<WebsiteGoods> parseHomepage(String source, Uri homepage) {
    final document = html.parse(source);
    final seen = <String>{};
    final products = <WebsiteGoods>[];
    // Use the server's published order. Swiper may rotate the browser DOM.
    for (final card in document.querySelectorAll('.top-goods a.goods-card')) {
      final url = _https(homepage, card.attributes['href']);
      final image =
          _https(homepage, card.querySelector('img')?.attributes['src']);
      final name = card
              .querySelector('.goods-card__name')
              ?.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim() ??
          '';
      final price = card
              .querySelector('.goods-card__price')
              ?.text
              .replaceAll(RegExp(r'\s+'), '') ??
          '';
      if (url == null ||
          image == null ||
          name.isEmpty ||
          url.host != 'bluesharks.base.shop' ||
          !RegExp(r'^/items/[0-9]+/?$').hasMatch(url.path) ||
          !RegExp(r'^[¥￥](?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)$')
              .hasMatch(price)) {
        continue;
      }
      final key = url.path.replaceFirst(RegExp(r'/$'), '');
      if (!seen.add(key)) continue;
      products.add(WebsiteGoods(
          url: url, imageUrl: image, name: name, priceLabel: price));
    }
    return List.unmodifiable(products);
  }

  static Uri? _https(Uri base, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final relative = Uri.tryParse(value.trim());
    if (relative == null) return null;
    final uri = base.resolveUri(relative);
    return uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty &&
            uri.port == 443
        ? uri
        : null;
  }
}
