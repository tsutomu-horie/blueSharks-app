import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_goods.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';
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
        const RenewalHomeHeading('グッズ', 'GOODS'),
        LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth * .55).clamp(170.0, 260.0);
          final textScaler = MediaQuery.textScalerOf(context);
          final textHeight =
              40 + textScaler.scale(15) * 2.6 + textScaler.scale(20) * 1.3;
          return SizedBox(
            height: width + textHeight,
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
                    color: RenewalHomeDesign.cyan,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('goods-${product.url.path}'),
                      onTap: () => _openProduct(context, product.url),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
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
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.3))),
                          const SizedBox(height: 6),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(product.priceLabel,
                                      maxLines: 1,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          height: 1.3,
                                          fontWeight: FontWeight.bold)))),
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
