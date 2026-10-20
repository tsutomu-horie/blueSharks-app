import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

class WebsiteMatchAction {
  const WebsiteMatchAction({required this.label, this.url});
  final String label;
  final Uri? url;
}

class WebsiteMatch {
  const WebsiteMatch(
      {required this.date,
      required this.dateLabel,
      required this.day,
      required this.timeLabel,
      required this.league,
      required this.status,
      required this.venue,
      this.venueUrl,
      this.hostLabel,
      required this.opponentName,
      required this.opponentLogo,
      required this.actions});

  /// Date-only UTC value, compared with a Japan-local date (never kickoff).
  final DateTime date;
  final String dateLabel;
  final String day;
  final String timeLabel;
  final String league;
  final String status;
  final String venue;
  final Uri? venueUrl;
  final String? hostLabel;
  final String opponentName;
  final Uri opponentLogo;
  final List<WebsiteMatchAction> actions;
}

class WebsiteSchedule {
  const WebsiteSchedule(
      {required this.season, required this.url, required this.matches});
  final String season;
  final Uri url;
  final List<WebsiteMatch> matches;

  /// Preserve published order, including unknown kickoff times; no arbitrary limit.
  List<WebsiteMatch> upcoming(DateTime now) {
    final japan = now.toUtc().add(const Duration(hours: 9));
    final today = DateTime.utc(japan.year, japan.month, japan.day);
    return List.unmodifiable(matches.where(
        (match) => match.status == '試合前' && !match.date.isBefore(today)));
  }

  static Uri? parseHomepageUrl(String source, Uri homepage) {
    final anchor =
        html.parse(source).querySelector('.top-game a.top-game__button');
    final url = _https(homepage, anchor?.attributes['href']);
    return url != null && isScheduleUrl(url, homepage) ? url : null;
  }

  static bool isScheduleUrl(Uri url, Uri homepage) =>
      url.scheme == 'https' &&
      url.host == homepage.host &&
      url.port == 443 &&
      url.userInfo.isEmpty &&
      url.path == '/schedule-and-result/' &&
      !url.hasQuery &&
      !url.hasFragment;

  static WebsiteSchedule? parse(String source, Uri url) {
    final section = html.parse(source).querySelector('main .season');
    if (section == null) return null;
    final selected =
        section.querySelector('select[name="season"] option[selected]');
    final season = _text(selected);
    if (season.isEmpty) return null;
    final matches = <WebsiteMatch>[];
    for (final card in section.querySelectorAll('article.match-card')) {
      final time = card.querySelector('.match-card__date time[datetime]');
      final date = _date(time?.attributes['datetime']);
      final copy = time?.clone(true);
      copy?.querySelector('.match-card__day')?.remove();
      final dateLabel = _text(copy);
      final day = _text(time?.querySelector('.match-card__day'));
      final league = _text(card.querySelector('.match-card__league'));
      final teams = card.querySelectorAll('.match-card__team');
      final own = teams
          .where((team) =>
              _text(team.querySelector('.match-card__team-name'))
                  .replaceAll(RegExp(r'\s+'), '') ==
              '清水建設江東ブルーシャークス')
          .toList();
      // The first team is not evidence of HOST/VISITOR. Identify our published name.
      if (date == null ||
          dateLabel.isEmpty ||
          league.isEmpty ||
          teams.length != 2 ||
          own.length != 1) {
        return null;
      }
      final opponent = teams.firstWhere((team) => !identical(team, own.single));
      final name = _text(opponent.querySelector('.match-card__team-name'));
      final logo = _https(url,
          opponent.querySelector('img.match-card__logo')?.attributes['src']);
      if (name.isEmpty || logo == null) return null;
      final actions = <WebsiteMatchAction>[];
      for (final item in card
          .querySelectorAll('.match-card__actions .match-card__action')) {
        final button = item.querySelector('.button');
        final label = _text(button);
        if (label.isEmpty) return null;
        final href = button?.localName == 'a' &&
                !button!.classes.contains('button--disabled') &&
                button.attributes['aria-disabled'] != 'true' &&
                !button.attributes.containsKey('disabled')
            ? _https(url, button.attributes['href'])
            : null;
        actions.add(WebsiteMatchAction(
            label: label,
            url: href != null && href.host == url.host ? href : null));
      }
      const labels = {'チケット情報', 'ホストイベント情報', 'マッチレポート', '試合情報'};
      if (actions.length != 4 ||
          actions.map((a) => a.label).toSet().length != 4 ||
          !actions.every((a) => labels.contains(a.label))) {
        return null;
      }
      final host = _text(card.querySelector('.match-card__badge--host'));
      matches.add(WebsiteMatch(
          date: date,
          dateLabel: dateLabel,
          day: day,
          timeLabel: _text(card.querySelector('.match-card__time')),
          league: league,
          status: _text(card.querySelector('.match-card__badge--result')),
          venue: _text(card.querySelector('.match-card__venue')),
          venueUrl: _https(
              url,
              card
                  .querySelector('.match-card__venue-link')
                  ?.attributes['href']),
          hostLabel: host.isEmpty ? null : host,
          opponentName: name,
          opponentLogo: logo,
          actions: List.unmodifiable(actions)));
    }
    return WebsiteSchedule(
        season: season, url: url, matches: List.unmodifiable(matches));
  }

  static DateTime? _date(String? value) {
    if (value == null ||
        !RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse(value);
    if (date == null || date.toIso8601String().substring(0, 10) != value) {
      return null;
    }
    return DateTime.utc(date.year, date.month, date.day);
  }

  static String _text(dom.Element? element) {
    String visit(dom.Node node) => node is dom.Text
        ? node.data
        : node is dom.Element && node.localName == 'br'
            ? ' '
            : node.nodes.map(visit).join();
    return element == null
        ? ''
        : visit(element).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Uri? _https(Uri base, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final relative = Uri.tryParse(value.trim());
    if (relative == null) return null;
    final uri = base.resolveUri(relative);
    return uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.port == 443 &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}
