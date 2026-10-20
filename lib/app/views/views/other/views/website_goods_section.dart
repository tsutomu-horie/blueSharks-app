import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_goods.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteGoodsSection extends StatelessWidget {
  const WebsiteGoodsSection({super.key, required this.goods});

  final List<WebsiteGoods> goods;

  @override
  Widget build(BuildContext context) {
    if (goods.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultHeaderTitleView('グッズ', 'GOODS'),
        LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth * .72).clamp(200.0, 320.0);
          final textScaler = MediaQuery.textScalerOf(context);
          final textHeight =
              40 + textScaler.scale(15) * 2.6 + textScaler.scale(16) * 1.3;
          return SizedBox(
            height: width * .75 + textHeight,
            child: ListView.separated(
              key: const ValueKey('website-goods-list'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: goods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = goods[index];
                return SizedBox(
                  width: width,
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      key: ValueKey('goods-${product.url.path}'),
                      onTap: () => _openProduct(context, product.url),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              product.imageUrl.toString(),
                              fit: BoxFit.contain,
                              semanticLabel: product.name,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xfff2f2f2),
                                child: Center(
                                    child: Icon(Icons.shopping_bag_outlined)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontSize: 15, height: 1.3)),
                          const SizedBox(height: 6),
                          Text(product.priceLabel,
                              style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.3,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openProduct(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A failed handoff leaves the carousel available for another attempt.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品ページを開けませんでした。')),
      );
    }
  }
}
