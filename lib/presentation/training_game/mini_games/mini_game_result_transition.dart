import 'package:flutter/material.dart';

/// Reveals mini-game result overlays with a short, shared transition.
///
/// Keep this widget in the game screen's [Stack] while the game is active and
/// toggle [visible] when the result phase begins. The result content remains
/// interactive during the entrance animation.
class MiniGameResultTransition extends StatelessWidget {
  const MiniGameResultTransition({
    super.key,
    required this.visible,
    required this.child,
  });

  static const Duration _duration = Duration(milliseconds: 200);
  static const Key _switcherKey =
      ValueKey<String>('mini-game-result-transition-switcher');
  static const Key _visibleKey = ValueKey<String>('mini-game-result-visible');
  static const Key _hiddenKey = ValueKey<String>('mini-game-result-hidden');
  static final Tween<Offset> _slideTween = Tween<Offset>(
    begin: Offset(0, .02),
    end: Offset.zero,
  );

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations ? Duration.zero : _duration;

    // This widget is used as a Stack child so it can fill the mini-game field.
    return Positioned.fill(
      child: AnimatedSwitcher(
        key: _switcherKey,
        duration: duration,
        reverseDuration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (transitionChild, animation) {
          if (disableAnimations) return transitionChild;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: _slideTween.animate(animation),
              child: transitionChild,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: visible
            ? KeyedSubtree(key: _visibleKey, child: child)
            : const SizedBox.expand(key: _hiddenKey),
      ),
    );
  }
}
