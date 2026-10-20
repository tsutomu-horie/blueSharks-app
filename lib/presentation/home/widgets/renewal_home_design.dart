import 'package:flutter/material.dart';

abstract final class RenewalHomeDesign {
  static const navy = Color(0xff002b6d);
  static const cyan = Color(0xff48a6d5);
}

class RenewalHomeHeading extends StatelessWidget {
  const RenewalHomeHeading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: RenewalHomeDesign.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: RenewalHomeDesign.navy,
                  fontFamily: 'Inter',
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}

class RenewalViewAllButton extends StatelessWidget {
  const RenewalViewAllButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
          backgroundColor: RenewalHomeDesign.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: const RoundedRectangleBorder(),
          side: BorderSide.none,
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800)),
      child: const Text('VIEW ALL'));
}

class RenewalPageDots extends StatelessWidget {
  const RenewalPageDots(
      {super.key, required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Semantics(
      label: '${current + 1}/$count',
      excludeSemantics: true,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
            for (var i = 0; i < count; i++)
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == current
                          ? RenewalHomeDesign.cyan
                          : const Color(0xffd2d2d2))),
          ])));
}
