class Constants {

  static const isRelease = true;

  static const baseUrl = isRelease ? 'https://blue-sharks.jp/wp-json/wp/v2/' : 'https://blue-sharks.donati.jp/wp-json/wp/v2/';
  static const baseUrlAuthApi = isRelease ? 'https://app.blue-sharks.jp/api/mobile/v1/' : 'https://dev-blueshark.tmdsite.my.id/api/mobile/v1/';
  static const topic = isRelease ? 'news_prod' : 'news_dev';


  static const baseUrlWeb = isRelease ? 'https://app.blue-sharks.jp/api/' : 'https://dev-blueshark.tmdsite.my.id/api';
  static const teamName = 'シャークス';
  static const videoUrl ='https://www.youtube.com/watch?v=JJqanLQ3y0Q';

  static const leagueTitle ='NTTジャパンラグビーリーグ1 2023-24';
  static const division ='Division 2';
  static const rank ='2';
  static const totalRank ='6';
  static const teamHistory ='1976年、清水建設社内にてラグビー経験者を集め、清水建設ラグビー部として創部されました。\n1989年には関東社会人リーグ1部へ昇格し、2001年には元ワラビーズのティム・ホラン選手が名付け親である「清水建設ブルーシャークス」へ名称を変更し、クラブチームとして活動を続けてきました。\n2021年に東京都江東区と連携協定を結び、江東区をホストエリア・夢の島競技場をホストスタジアムとして活動を開始し、\n\n2022年より新リーグ「JAPAN RUGBY LEAGUE ONE」に「清水建設江東ブルーシャークス」として参入しました。 社業とラグビーの双方に高い目標を掲げ、社会貢献および応援してくださるファンの皆様のご期待へ応えるべく、日々を全力で取り組んで参ります。';
  static const stadiumName = '江東区 夢の島競技場';
  static const stadiumAddress = '〒136-0081 東京都江東区夢の島1-1-2';

  static const stadiumTitle = '清水建設 江東ブルーシャークス\nホストスタジアム';
  static const stadiumSubtitle = '江東区 夢の島競技場';
  static const stadiumDescription = '〒136-0081 東京都江東区夢の島1-1-2\ntel：03-3522-0846';


  static const ticketsUrl = isRelease ? 'https://blue-sharks.jp/tickets/' : 'https://blue-sharks.donati.jp/tickets/';
  static const fanClubUrl = isRelease ? 'https://blue-sharks.jp/fanclub/' : 'https://blue-sharks.donati.jp/fanclub/';
  static const shopUrl = isRelease ? 'https://bluesharks.base.shop/' : 'https://bluesharks.base.shop/';
  static const instagramUrl = 'https://www.instagram.com/shimz.bluesharks/';
  static const xUrl = 'https://x.com/Bluesharks_2020';
  static const partnerUrl = isRelease ? 'https://blue-sharks.jp/partner/' : 'https://blue-sharks.donati.jp/partner/';
  static const teamUrl = isRelease ? 'https://blue-sharks.jp/team/' : 'https://blue-sharks.donati.jp/team/';
}