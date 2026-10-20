import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteBannersSection extends StatefulWidget {
  const WebsiteBannersSection({super.key, required this.banners});
  final List<WebsiteBanner> banners;
  @override
  State<WebsiteBannersSection> createState() => _WebsiteBannersSectionState();
}

class _WebsiteBannersSectionState extends State<WebsiteBannersSection> {
  final _pages = PageController(viewportFraction: .9);
  int _current = 0;

  @override
  void didUpdateWidget(covariant WebsiteBannersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.banners.length != widget.banners.length ||
        List.generate(widget.banners.length, (i) => i).any((i) =>
            oldWidget.banners[i].url != widget.banners[i].url ||
            oldWidget.banners[i].imageUrl != widget.banners[i].imageUrl);
    if (changed) {
      _current = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(builder: (context, constraints) {
          final imageWidth = math.max(1.0, constraints.maxWidth * .9 - 12);
          final height = widget.banners
              .map((b) => imageWidth / b.aspectRatio)
              .reduce(math.max);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                height: height,
                child: PageView.builder(
                    key: const ValueKey('website-banners-pager'),
                    controller: _pages,
                    onPageChanged: (index) => setState(() {
                          _current = index;
                        }),
                    itemCount: widget.banners.length,
                    itemBuilder: (context, index) {
                      final banner = widget.banners[index];
                      final label = banner.alt.isEmpty
                          ? 'TOPバナー ${index + 1}'
                          : banner.alt;
                      return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Center(
                              child: AspectRatio(
                                  aspectRatio: banner.aspectRatio,
                                  child: Semantics(
                                      button: true,
                                      label: label,
                                      child: Material(
                                          color: const Color(0xfff2f2f2),
                                          child: InkWell(
                                              key: ValueKey(
                                                  'website-banner-$index'),
                                              onTap: () =>
                                                  _open(context, banner.url),
                                              child: Image.network(
                                                  banner.imageUrl.toString(),
                                                  fit: BoxFit.contain,
                                                  excludeFromSemantics: true,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Center(
                                                          child: Text(
                                                              'バナー画像を読み込めませんでした。',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow
                                                                  .ellipsis)))))))));
                    })),
            if (widget.banners.length > 1)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                      label: 'TOPバナー ${_current + 1}/${widget.banners.length}',
                      excludeSemantics: true,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < widget.banners.length; i++)
                              Container(
                                  width: 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == _current
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey)),
                          ]))),
          ]);
        }));
  }

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A failed handoff must not discard the banners or prevent another tap.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('TOPバナーのページを開けませんでした。')));
    }
  }
}
