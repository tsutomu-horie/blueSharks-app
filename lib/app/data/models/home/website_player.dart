import 'package:html/parser.dart' as html;

/// The fields explicitly published on a TOP PLAYERS card.
class WebsitePlayer {
  const WebsitePlayer(
      {required this.name,
      required this.kana,
      required this.imageUrl,
      required this.url});
  final String name;
  final String kana;
  final Uri imageUrl;
  final Uri url;
}

class WebsitePlayers {
  const WebsitePlayers({required this.players, this.viewAllUrl});
  final List<WebsitePlayer> players;
  final Uri? viewAllUrl;

  static WebsitePlayers? parseHomepage(String source, Uri homepage) {
    final section = html.parse(source).querySelector('.top-players');
    if (section == null) return null;
    final players = <WebsitePlayer>[];
    final seen = <String>{};
    for (final card in section.querySelectorAll('a.player-card')) {
      final url = _https(homepage, card.attributes['href']);
      final image = _https(homepage,
          card.querySelector('img.player-card__image')?.attributes['src']);
      final name = card
              .querySelector('.player-card__name')
              ?.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim() ??
          '';
      final kana = card
              .querySelector('.player-card__kana')
              ?.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim() ??
          '';
      if (url == null ||
          url.host != homepage.host ||
          !RegExp(r'^/members/[a-z0-9-]+/[0-9]{4}/[0-9]{2}/[0-9]+/?$')
              .hasMatch(url.path) ||
          image == null ||
          name.isEmpty ||
          kana.isEmpty) {
        continue;
      }
      if (!seen.add(url.path.replaceFirst(RegExp(r'/$'), ''))) continue;
      players.add(
          WebsitePlayer(name: name, kana: kana, imageUrl: image, url: url));
    }
    if (players.isEmpty) return null;
    final all = _https(homepage,
        section.querySelector('a.top-players__button')?.attributes['href']);
    return WebsitePlayers(
        players: List.unmodifiable(players),
        viewAllUrl:
            all != null && all.host == homepage.host && all.path == '/members/'
                ? all
                : null);
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
