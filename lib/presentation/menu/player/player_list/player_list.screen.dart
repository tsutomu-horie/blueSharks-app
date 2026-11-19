import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/app/views/views/site_display_heading.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/presentation/menu/widgets/menu_data_status.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

import 'controllers/player_list.controller.dart';

const _navy = Color(0xff002b6d);
const _wave =
    '${AppEnvironment.websiteBaseUrl}/wp-content/themes/blue-sharks-2026/assets/images/common/bg-wave-white.webp';
const _lettering =
    '${AppEnvironment.websiteBaseUrl}/wp-content/themes/blue-sharks-2026/assets/images/common/bg-blue-sharks@2x.webp';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen(this.onSet, {super.key});
  final Function(String, String)? onSet;

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final _controller = Get.isRegistered<PlayerListController>()
      ? Get.find<PlayerListController>()
      : Get.put(PlayerListController());
  String _position = '';
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static const _labels = {
    'prop': 'プロップ',
    'hooker': 'フッカー',
    'lock': 'ロック',
    'flanker': 'フランカー',
    'no8': 'No.8',
    'scrumhalf': 'スクラムハーフ',
    'standoff': 'スタンドオフ',
    'center': 'センター',
    'wing': 'ウイング',
    'fullback': 'フルバック',
    'utility-backs': 'ユーティリティ・バックス',
    'staff': 'スタッフ',
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 768
        ? 2
        : width < 1024
            ? 3
            : 4;
    final textTheme =
        Theme.of(context).textTheme.apply(fontFamily: 'LINESeedJP');
    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _scroll,
                  builder: (_, child) => Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        308 - (_scroll.hasClients ? _scroll.offset : 0),
                      ),
                      child: child,
                    ),
                  ),
                  child: Image.network(
                    _wave,
                    width: width,
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Obx(() {
              final positions = _controller.categories
                  .where(
                    (category) =>
                        _controller.categoryPlayers[category.id]?.isNotEmpty ??
                        false,
                  )
                  .toList();
              final selected =
                  positions.any((category) => category.slug == _position)
                      ? _position
                      : '';
              return RefreshIndicator(
                onRefresh: _controller.onReloadPage,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      key: ValueKey('member-top'),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 29, 16, 48),
                        child: Column(
                          children: [
                            SiteDisplayHeading(
                              'MeMBeRS',
                              size: 30.92,
                              accent: 1,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'メンバー',
                              style: TextStyle(
                                fontSize: 21.23,
                                letterSpacing: 0,
                                fontFamily: 'LINESeedJPExtraBold',
                                height: 1,
                                color: _navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_controller.isLoading.value)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(),
                      ),
                    if (_controller.errorMessage.value.isNotEmpty)
                      SliverToBoxAdapter(
                        child: MenuDataStatus(
                          message: _controller.errorMessage.value,
                          onRetry: _controller.onReloadPage,
                        ),
                      ),
                    if (positions.isEmpty &&
                        !_controller.isLoading.value &&
                        _controller.errorMessage.value.isEmpty)
                      const SliverToBoxAdapter(
                        child: MenuDataStatus(message: '選手情報はまだ登録されていません。'),
                      ),
                    if (positions.isNotEmpty)
                      SliverToBoxAdapter(
                        key: const ValueKey('member-cards'),
                        child: Stack(
                          children: [
                            Image.network(
                              _lettering,
                              width: width,
                              fit: BoxFit.fitWidth,
                              excludeFromSemantics: true,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16.145,
                                61.83,
                                16.145,
                                0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 300,
                                  height: 44.72,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: _navy),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.37,
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selected,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: SvgPicture.string(
                                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 14"><path fill="#002b6d" d="M0 0h24L12 14z"/></svg>',
                                            width: 16.37,
                                            height: 9.55,
                                            excludeFromSemantics: true,
                                          ),
                                          style: const TextStyle(
                                            fontFamily: 'LINESeedJPExtraBold',
                                            fontSize: 16.37,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w800,
                                            color: _navy,
                                          ),
                                          onChanged: (value) => setState(
                                            () => _position = value ?? '',
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: '',
                                              child: Text(
                                                'ALL',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            for (final position in positions)
                                              DropdownMenuItem(
                                                value: position.slug,
                                                child: Text(
                                                  position.slug
                                                      .replaceAll('-', ' ')
                                                      .toUpperCase(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final position in positions)
                      if (selected.isEmpty || position.slug == selected) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.145,
                              41.37,
                              16.145,
                              16.37,
                            ),
                            child: Wrap(
                              key: ValueKey('member-${position.slug}'),
                              spacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                SiteDisplayHeading(
                                  position.slug
                                      .replaceAll('-', ' ')
                                      .split('')
                                      .map(
                                        (c) => c == 'e' ? c : c.toUpperCase(),
                                      )
                                      .join(),
                                  size: 24.46,
                                  accent: 1,
                                ),
                                Text(
                                  _labels[position.slug] ?? position.name,
                                  style: const TextStyle(
                                    color: _navy,
                                    height: 1,
                                    fontSize: 17.14,
                                    letterSpacing: 0,
                                    fontFamily: 'LINESeedJPExtraBold',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _members(
                          _controller.categoryPlayers[position.id]!,
                          columns,
                        ),
                      ],
                    const SliverToBoxAdapter(child: SizedBox(height: 82)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _members(List<Member> members, int columns) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.145),
        sliver: SliverList.builder(
          itemCount: (members.length / columns).ceil(),
          itemBuilder: (_, row) => Padding(
            padding: EdgeInsets.only(
              bottom: (row + 1) * columns < members.length ? 20.46 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col != 0) const SizedBox(width: 8),
                  Expanded(
                    child: row * columns + col < members.length
                        ? _card(members[row * columns + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _card(Member player) {
    final image = player.custom_field?.profile_image_1?.firstOrNull;
    final labels = _controller.memberProvider.renewal.memberLabels[player.id];
    return InkWell(
      onTap: () => _controller.navigateToMemberDetail(player),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 294 / 327,
            child: ColoredBox(
              color: const Color(0xffe5e7ef),
              child: image == null
                  ? const Icon(Icons.image_not_supported_outlined)
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      semanticLabel: player.title.rendered,
                      frameBuilder: (_, child, frame, synchronous) =>
                          frame == null && !synchronous
                              ? const Center(child: CircularProgressIndicator())
                              : child,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            player.title.rendered,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              height: 1.4,
              fontSize: 17.14,
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (labels != null && labels.english.isNotEmpty)
            Text(
              labels.english,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff909090),
                height: 1.4,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0,
              ),
            ),
          if (labels != null && labels.role.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              labels.role,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff5f5f5f),
                height: 1.4,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
