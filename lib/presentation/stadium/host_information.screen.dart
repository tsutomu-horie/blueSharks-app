import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/app/views/views/site_display_heading.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:url_launcher/url_launcher.dart';

const _navy = Color(0xff002b6d);
const _themeImages =
    '${AppEnvironment.websiteBaseUrl}/wp-content/themes/blue-sharks-2026/assets/images';
const _busAccess = '都営バス 木11、錦18、急行05(土・休日のみ運行) 夢の島停留場下車 徒歩1分';

class HostInformationScreen extends StatefulWidget {
  const HostInformationScreen({super.key});

  @override
  State<HostInformationScreen> createState() => _HostInformationScreenState();
}

class _HostInformationScreenState extends State<HostInformationScreen> {
  final _stadium = GlobalKey();
  final _ground = GlobalKey();
  final _gallery = GlobalKey();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                key: ValueKey('host-top'),
                padding: EdgeInsets.fromLTRB(15, 29, 15, 48),
                child: Column(
                  children: [
                    SiteDisplayHeading('HOST INFORMATION',
                        size: 30.92, accent: 1),
                    SizedBox(height: 12),
                    Text(
                      'ホストのご案内',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 21.23,
                        fontFamily: 'LINESeedJPExtraBold',
                        letterSpacing: 0,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Image.network(
                      '$_themeImages/common/bg-blue-sharks@2x.webp',
                      fit: BoxFit.fitWidth,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    top: 167,
                    left: 0,
                    right: 0,
                    child: Image.network(
                      '$_themeImages/common/bg-wave-white.webp',
                      fit: BoxFit.fitWidth,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16.145,
                      61.83,
                      16.145,
                      82.29,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _anchor('スタジアム', 'stadium', 64, _stadium),
                            const SizedBox(width: 15),
                            _anchor('グラウンド', 'ground', 53, _ground),
                            const SizedBox(width: 15),
                            _anchor('ギャラリー', 'gallery', 58, _gallery),
                          ],
                        ),
                        const SizedBox(height: 61.83),
                        _SectionHeading(
                          key: _stadium,
                          id: 'stadium',
                          initial: 'H',
                          accent: 'O',
                          rest: 'ST STADIUM',
                          label: 'ホストスタジアム',
                        ),
                        const _Venue(
                          label: 'ホストスタジアム',
                          name: '江東区 夢の島競技場',
                          address: '〒136-0081 東京都江東区夢の島1-1-2',
                          access:
                              'JR京葉線、東京メトロ有楽町線、りんかい線 新木場駅下車 徒歩5分\n$_busAccess',
                          image: 'venue-stadium',
                        ),
                        const _Route(
                          key: ValueKey('host-walking'),
                          title: '徒歩の場合',
                          text:
                              '新木場駅出口を右折、直進して首都高速湾岸線の下を横断し、夢の島交差点を直進、明治通りを少し進むと左手に見えてくるのが夢の島競技場です。',
                          images: [
                            'route-1',
                            'route-2',
                            'route-3',
                            'route-5',
                            'route-6',
                            'route-7',
                          ],
                        ),
                        const _Route(
                          key: ValueKey('host-bus'),
                          title: 'バスの場合',
                          text: _busAccess,
                          images: ['bus-stop-1', 'bus-stop-2'],
                          isBus: true,
                        ),
                        const _Route(
                          title: '駐車場',
                          text:
                              '普通車・軽自動車\n1台30分 ただし3時間半を超える部分は1時間／100円\n大型バス（バス専用駐車場）\n1台20分／300円',
                        ),
                        const SizedBox(height: 41.37),
                        _SectionHeading(
                          key: _ground,
                          id: 'ground',
                          initial: 'H',
                          accent: 'O',
                          rest: 'ST GROUND',
                          label: 'ホストグラウンド',
                        ),
                        const _Venue(
                          label: 'ホストグラウンド',
                          name: '荏田グラウンド',
                          address: '〒224-0008 神奈川県横浜市都筑区荏田南町741番地',
                          access:
                              '東急田園都市線「江田駅」より徒歩20分（1.7km）\n横浜市営地下鉄ブルーライン「中川駅」より徒歩15分（1.0km）\n※グランド北側（隣接）の「横浜市立荏田小学校」が目印です。',
                          image: 'venue-ground',
                        ),
                        const SizedBox(height: 41.37),
                        _SectionHeading(
                          key: _gallery,
                          id: 'gallery',
                          initial: 'G',
                          accent: 'A',
                          rest: 'LLERY',
                          label: 'ギャラリー',
                        ),
                        const SizedBox(height: 30),
                        _PhotoGrid(
                          images: [for (var i = 1; i <= 8; i++) 'gallery-$i'],
                          aspectRatio: 290 / 193,
                          spacing: 12.18,
                        ),
                        const SizedBox(height: 41.37),
                        const _TeamBanner(
                          image: 'bnr-team-information',
                          path: '/team/',
                          label: 'TEAM INFORMATION チーム情報',
                        ),
                        const SizedBox(height: 16),
                        const _TeamBanner(
                          image: 'bnr-team-history',
                          path: '/team/history/',
                          label: 'TEAM HISTORY チームの歴史',
                        ),
                        const SizedBox(height: 16),
                        const _TeamBanner(
                          image: 'bnr-official-mascot',
                          path: '/team/mascot/',
                          label: 'OFFICIAL MASCOT 【公式マスコット】鮫太朗の紹介',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _anchor(String label, String icon, double width, GlobalKey key) =>
      Expanded(
        child: InkWell(
          onTap: () {
            final target = key.currentContext;
            if (target != null)
              Scrollable.ensureVisible(
                target,
                duration: const Duration(milliseconds: 320),
              );
          },
          child: Column(
            children: [
              SizedBox(
                height: 53,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SvgPicture.network(
                    '$_themeImages/icon/icon-$icon.svg',
                    width: width,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19.14,
                  height: 1,
                  fontFamily: 'LINESeedJPExtraBold',
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 20,
                height: 10,
                child: CustomPaint(painter: _DownTriangle()),
              ),
            ],
          ),
        ),
      );
}

class _DownTriangle extends CustomPainter {
  const _DownTriangle();

  @override
  void paint(Canvas canvas, Size size) {
    final triangle = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(triangle, Paint()..color = _navy);
  }

  @override
  bool shouldRepaint(_DownTriangle oldDelegate) => false;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    super.key,
    required this.id,
    required this.initial,
    required this.accent,
    required this.rest,
    required this.label,
  });
  final String id;
  final String initial;
  final String accent;
  final String rest;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        key: ValueKey('host-$id'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SiteDisplayHeading(
            '$initial$accent$rest',
            size: 24.46,
            accent: initial.length,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 17.14,
              height: 1,
              fontFamily: 'LINESeedJP',
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xffdddddd)),
        ],
      );
}

class _Venue extends StatelessWidget {
  const _Venue({
    required this.label,
    required this.name,
    required this.address,
    required this.access,
    required this.image,
  });
  final String label;
  final String name;
  final String address;
  final String access;
  final String image;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '清水建設 江東ブルーシャークス\n$label',
              style: const TextStyle(
                fontSize: 17.14,
                height: 1.4,
                fontFamily: 'LINESeedJP',
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: _navy,
                fontSize: 22.37,
                height: 1.4,
                fontFamily: 'LINESeedJPExtraBold',
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              address,
              style: const TextStyle(
                fontSize: 15.05,
                height: 1.6,
                fontFamily: 'LINESeedJP',
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              access,
              style: const TextStyle(
                fontSize: 15.05,
                height: 1.6,
                fontFamily: 'LINESeedJP',
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24.73),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(name)),
                    body: Center(
                      child: InteractiveViewer(
                        child: _HostPhoto('$image-map', 580 / 260),
                      ),
                    ),
                  ),
                ),
              ),
              child: _HostPhoto('$image-map', 580 / 260),
            ),
            const SizedBox(height: 20),
            _HostPhoto(image, 600 / 400),
          ],
        ),
      );
}

class _Route extends StatelessWidget {
  const _Route({
    super.key,
    required this.title,
    required this.text,
    this.images = const [],
    this.isBus = false,
  });
  final String title;
  final String text;
  final List<String> images;
  final bool isBus;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24.73),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 17.14,
                height: 1.4,
                fontFamily: 'LINESeedJPExtraBold',
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.09,
                height: 1.6,
                fontFamily: 'LINESeedJP',
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 20),
              _PhotoGrid(
                images: images,
                labels: [
                  for (var i = 0; i < images.length; i++)
                    isBus ? 'バス停' : '${i + 1}',
                ],
              ),
            ],
          ],
        ),
      );
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.images,
    this.labels,
    this.aspectRatio = 292 / 195,
    this.spacing = 12,
  });
  final List<String> images;
  final List<String>? labels;
  final double aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: images.length,
        itemBuilder: (_, index) => Stack(
          children: [
            _HostPhoto(images[index], aspectRatio),
            if (labels case final labels?)
              Container(
                constraints: BoxConstraints(
                  minWidth: labels[index].length > 1 ? 60 : 30,
                  minHeight: 30,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: _navy,
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1,
                      fontFamily: 'LINESeedJP',
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _TeamBanner extends StatelessWidget {
  const _TeamBanner({
    required this.image,
    required this.path,
    required this.label,
  });

  final String image;
  final String path;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        label: label,
        child: InkWell(
          onTap: () async {
            try {
              final opened = await launchUrl(
                Uri.parse('${AppEnvironment.websiteBaseUrl}$path'),
                mode: LaunchMode.inAppBrowserView,
              );
              // On iOS, closing Safari before its initial load returns false.
              // Launch and load failures are reported as PlatformExceptions.
              if (opened ||
                  (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)) {
                return;
              }
            } on PlatformException {
              // Show the same feedback for a reported launch or load failure.
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ページを開けませんでした')),
              );
            }
          },
          child: AspectRatio(
            aspectRatio: 585 / 200,
            child: Image.network(
              '$_themeImages/common/$image.webp',
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: _navy,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _HostPhoto extends StatelessWidget {
  const _HostPhoto(this.file, this.ratio);
  final String file;
  final double ratio;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: ratio,
        child: Image.network(
          '$_themeImages/host-information/$file.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xfff5f5f5),
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
}
