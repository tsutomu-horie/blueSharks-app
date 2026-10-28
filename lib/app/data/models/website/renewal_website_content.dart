import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';

/// Parsed match data plus the images used by the renewed site's Member section.
/// Images stay outside the persistent CustomField/Hive model.
class RenewalMatchDetail {
  const RenewalMatchDetail({
    required this.match,
    this.startingImage,
    this.reserveImage,
  });

  final MatchResultBySeason match;
  final String? startingImage;
  final String? reserveImage;
}

/// Adapts the renewed site's public content to the existing native/Hive models.
/// Missing fields stay missing; the original screens retain their placeholders.
class RenewalWebsiteContent {
  static String text(Element? element) =>
      (element?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static Uri? siteUrl(Uri site, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final url = site.resolve(value.trim());
      return url.scheme == 'https' &&
              url.host == site.host &&
              url.port == 443 &&
              url.userInfo.isEmpty
          ? url
          : null;
    } on FormatException {
      return null;
    }
  }

  static Map<int, Element> memberCards(String source, Uri site) {
    final result = <int, Element>{};
    for (final card
        in html.parse(source).querySelectorAll('main .member-card')) {
      final url = siteUrl(site, card.attributes['href']);
      final id = url == null ? null : _postId(url, 'members');
      if (id != null) result[id] = card;
    }
    return result;
  }

  static Member member(Map<String, dynamic> post, int categoryId,
      String? categorySlug, Element? card, Uri site) {
    final link = siteUrl(site, post['link'] as String?);
    if (link == null || _postId(link, 'members') != post['id']) {
      throw const FormatException('Invalid member link.');
    }
    final name = text(card?.querySelector('.member-card__name'));
    final image = siteUrl(
        site, card?.querySelector('.member-card__image')?.attributes['src']);
    return Member.fromJson({
      ...post,
      if (name.isNotEmpty) 'title': {'rendered': name},
      'categoryId': categoryId,
      'categorySlug': categorySlug,
      'custom_field': {
        if (image != null) 'profile_image_1': [image.toString()],
      },
    });
  }

  static Member memberDetail(String source, Member member, Uri site) {
    final section = html.parse(source).querySelector('main .member-detail');
    if (section == null) throw const FormatException('Missing member detail.');
    final fields = <String, dynamic>{...?member.custom_field?.toJson()};
    const labels = {
      'ポジション': 'data_position',
      '役職': 'data_position',
      'プレーポジション': 'data_play_position',
      '個人番号': 'data_number',
      '生年月日': 'data_birthday',
      '身長／体重': 'data_height_weight',
      '出身地（都道府県＋市町村）': 'data_birthplace',
      '出身スクール・出身中学': 'data_school',
      '出身高校': 'data_highschool',
      '出身大学': 'data_university',
      '代表歴': 'data_career',
      '所属会社': 'data_belong',
      'チームでの受賞歴（SNS賞など）': 'data_award',
      '在籍年数': 'data_enrolledyears',
      '公式戦キャップ数': 'data_caps',
      'ニックネーム': 'words_nickname',
      '子どもの頃の夢': 'words_dream_child_age',
      'ラグビーを始めたきっかけ': 'words_opportunity',
      '今シーズン見て欲しいプレー': 'words_playsseason',
      'ブルーシャークスの魅力': 'words_goodplay',
      '1つ願いが叶うなら…': 'words_wish',
      'マイブーム': 'words_myboom',
      '好きなブランド': 'words_favoritebrand',
      '好きな色': 'words_color',
      'オススメのお店': 'words_shop',
      'もらって嬉しかったプレゼント': 'words_gift',
      '好きな食べ物': 'words_favoritefood',
      '地元（故郷）のおすすめ料理・場所': 'words_localfood',
    };
    for (final row in section.querySelectorAll('.data-list__item')) {
      final field = labels[text(row.querySelector('dt'))];
      final value = text(row.querySelector('dd'));
      if (field != null && value.isNotEmpty) fields[field] = [value];
    }
    void image(String field, String? value) {
      final url = siteUrl(site, value);
      if (url != null) fields[field] = [url.toString()];
    }

    image('main_image',
        section.querySelector('.member-photo__image')?.attributes['src']);
    final photos = section.querySelectorAll('[data-gallery-thumb]');
    if (photos.length > 1) {
      image('profile_image_2', photos[1].attributes['data-image']);
    }
    final video = Uri.tryParse(section
            .querySelector('.member-detail__movie iframe')
            ?.attributes['src'] ??
        '');
    if (video != null &&
        video.scheme == 'https' &&
        const {'youtube.com', 'www.youtube.com', 'www.youtube-nocookie.com'}
            .contains(video.host) &&
        video.path.startsWith('/embed/')) {
      fields['youtube_embed_src'] = [video.toString()];
    }
    return member.copyWith(custom_field: CustomField.fromJson(fields));
  }

  static Map<int, Element> matchCards(String source, Uri site) {
    final section = html.parse(source).querySelector('main .season');
    if (section == null) throw const FormatException('Missing season.');
    final result = <int, Element>{};
    for (final card in section.querySelectorAll('article.match-card')) {
      for (final action in card.querySelectorAll('.match-card__actions a')) {
        final url = siteUrl(site, action.attributes['href']);
        final id = url == null ? null : _postId(url, 'schedule-and-result');
        if (id != null) result[id] = card;
      }
    }
    return result;
  }

  static Map<String, dynamic> _matchFields(Element card, Uri site) {
    final teams = card.querySelectorAll('.match-card__team');
    final rawDate =
        card.querySelector('.match-card__date time')?.attributes['datetime'];
    final date = DateTime.tryParse(rawDate ?? '');
    if (teams.length != 2 || date == null) {
      throw const FormatException('Missing match teams/date.');
    }
    final names = teams
        .map((team) => text(team.querySelector('.match-card__team-name')))
        .toList();
    const ownNames = {'清水建設江東ブルーシャークス', '清水建設ブルーシャークス'};
    if (names
            .where((name) => ownNames.contains(name.replaceAll(' ', '')))
            .length !=
        1) {
      throw const FormatException('Missing Blue Sharks team.');
    }
    final scores = RegExp(r'^(\d+)\s*-\s*(\d+)$')
        .firstMatch(text(card.querySelector('.match-card__score')));
    final badge = text(card.querySelector('.match-card__badge--host'));
    final fields = <String, dynamic>{
      'game_date': [
        '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日（${'月火水木金土日'[date.weekday - 1]}）'
      ],
      'game_time': [text(card.querySelector('.match-card__time'))],
      'location': [text(card.querySelector('.match-card__venue'))],
      'game_result':
          text(card.querySelector('.match-card__badge--result')).isEmpty
              ? null
              : [text(card.querySelector('.match-card__badge--result'))],
      'game_serial': [
        badge.contains('HOST')
            ? 'host'
            : badge.contains('VISITOR')
                ? 'visitor'
                : ''
      ],
      'team_score_1': [scores?.group(1) ?? ''],
      'team_score_2': [scores?.group(2) ?? ''],
    };
    for (var i = 0; i < teams.length; i++) {
      fields['team_${i + 1}'] = [names[i]];
      final logo = siteUrl(
          site, teams[i].querySelector('.match-card__logo')?.attributes['src']);
      fields['team_logo_${i + 1}'] = [logo?.toString() ?? ''];
    }
    return fields;
  }

  static MatchResultBySeason match(
      Map<String, dynamic> post, int seasonId, Element card, Uri site) {
    final link = siteUrl(site, post['link'] as String?);
    if (link == null || _postId(link, 'schedule-and-result') != post['id']) {
      throw const FormatException('Invalid match link.');
    }
    // These legacy WordPress metadata fields are not displayed by the app.
    return MatchResultBySeason.fromJson({
      'author': 0,
      'featured_media': 0,
      'comment_status': '',
      'ping_status': '',
      'sticky': false,
      'format': '',
      'tags': <dynamic>[],
      ...post,
      'categories': [seasonId],
      'custom_field': _matchFields(card, site),
      'content': {'rendered': ''},
    });
  }

  static RenewalMatchDetail matchDetail(
      String source, MatchResultBySeason match, Uri site) {
    final section = html.parse(source).querySelector('main .match-detail');
    final card = section?.querySelector('article.match-card');
    if (section == null || card == null) {
      throw const FormatException('Missing match detail.');
    }
    final fields = _matchFields(card, site);
    const rows = {
      'T': 'T',
      'G': 'G',
      'PG': 'PG',
      'DG': 'DG',
      'subtotal': 'RESULT'
    };
    for (final row in section.querySelectorAll('.score-table__row')) {
      final label = rows[text(row.querySelector('.score-table__head'))];
      final values =
          row.querySelectorAll('.score-table__cell').map(text).toList();
      if (label == null || values.length != 4) continue;
      fields['team_${label}_first_half_1'] = [values[0]];
      fields['team_${label}_second_half_1'] = [values[1]];
      fields['team_${label}_first_half_2'] = [values[2]];
      fields['team_${label}_second_half_2'] = [values[3]];
    }
    String? captain;
    for (final lineup in section.querySelectorAll('.lineup')) {
      final title = text(lineup.querySelector('.lineup__title'));
      final entries = <String>[];
      for (final item in lineup.querySelectorAll('.lineup__item')) {
        final copy = item.clone(true);
        final isCaptain = copy.querySelector('.lineup__captain') != null;
        copy.querySelector('.lineup__captain')?.remove();
        final name = text(copy).replaceFirstMapped(
            RegExp(r'^(\d+|R)\.\s*'), (match) => '${match.group(1)} ');
        entries.add(name);
        if (isCaptain) captain = name.split(' ').skip(1).join(' ');
      }
      if (title == 'Starting 15') fields['member_starting'] = entries;
      if (title == 'Reserves') fields['member_reserves'] = entries;
    }
    if (captain != null) fields['member_captain'] = [captain];
    String? startingImage;
    String? reserveImage;
    for (final image in section.querySelectorAll('img[alt]')) {
      final url = siteUrl(site, image.attributes['src']);
      if (url == null) continue;
      final alt = image.attributes['alt']?.trim();
      if (alt == 'スターティングメンバー') {
        startingImage = url.toString();
      } else if (alt == 'リザーブメンバー') {
        reserveImage = url.toString();
      }
    }
    fields['photos'] = section
        .querySelectorAll('.gallery-modal__image')
        .map((img) => siteUrl(site, img.attributes['src'])?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final report = section
        .querySelectorAll('.match-detail__section')
        .where((element) => text(element.querySelector('h2')) == '試合経過')
        .map((element) => element.innerHtml)
        .join();
    return RenewalMatchDetail(
      match: match.copyWith(
          custom_field: CustomField.fromJson(fields),
          content: Rendered(rendered: report)),
      startingImage: startingImage,
      reserveImage: reserveImage,
    );
  }

  static int? _postId(Uri url, String type) {
    final match =
        RegExp('^/$type/[^/]+/\\d{4}/\\d{2}/(\\d+)/?\$').firstMatch(url.path);
    if (type == 'schedule-and-result') {
      return int.tryParse(RegExp(r'^/schedule-and-result/\d{4}/\d{2}/(\d+)/?$')
              .firstMatch(url.path)
              ?.group(1) ??
          '');
    }
    return int.tryParse(match?.group(1) ?? '');
  }
}
