import 'package:flutter/material.dart';

/// 結果発表の演出を挟んでから、各ミニゲームの記録と操作を表示します。
class MiniGameResultTransition extends StatelessWidget {
  const MiniGameResultTransition({
    super.key,
    required this.visible,
    required this.child,
  });

  static const presentationDuration = Duration(milliseconds: 1100);
  static const _entranceDuration = Duration(milliseconds: 200);
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: AnimatedSwitcher(
        key: const Key('mini-game-result-transition-switcher'),
        duration: reducedMotion ? Duration.zero : _entranceDuration,
        reverseDuration: reducedMotion ? Duration.zero : _entranceDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => reducedMotion
            ? child
            : FadeTransition(opacity: animation, child: child),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild
          ],
        ),
        child: visible
            ? _ResultReveal(
                key: const Key('mini-game-result-visible'), child: child)
            : const SizedBox.expand(key: Key('mini-game-result-hidden')),
      ),
    );
  }
}

class _ResultReveal extends StatefulWidget {
  const _ResultReveal({super.key, required this.child});
  final Widget child;

  @override
  State<_ResultReveal> createState() => _ResultRevealState();
}

class _ResultRevealState extends State<_ResultReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: MiniGameResultTransition.presentationDuration);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          if (progress >= .64) {
            final reveal = Curves.easeOutCubic
                .transform(((progress - .64) / .36).clamp(0.0, 1.0));
            return ColoredBox(
              color: const Color(0xff153d5b),
              child: Opacity(
                key: const Key('mini-game-result-reveal-content'),
                opacity: reveal,
                child: IgnorePointer(
                  ignoring: progress < 1,
                  child: ExcludeFocus(
                    excluding: progress < 1,
                    child: ExcludeSemantics(
                      excluding: progress < 1,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - reveal)),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          final pop =
              Curves.easeOutBack.transform((progress / .45).clamp(0.0, 1.0));
          return ColoredBox(
            key: const Key('mini-game-result-prelude'),
            color: const Color(0xff153d5b),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Stack(alignment: Alignment.center, children: [
                      Transform.scale(
                        scale: .5 + progress * 1.4,
                        child: Opacity(
                          opacity: (1 - progress / .64).clamp(0.0, 1.0),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xffffd66b), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: .55 + pop * .45,
                        child: const Icon(Icons.stars_rounded,
                            size: 120, color: Color(0xffffd66b)),
                      ),
                    ]),
                  ),
                  const Text('結果発表',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      );
}
