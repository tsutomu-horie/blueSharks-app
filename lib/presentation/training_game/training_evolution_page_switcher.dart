import 'package:flutter/material.dart';

/// 進化画面への出入りだけを白い光でつなぎ、通常の切り替えは既存のフェードを保ちます。
class TrainingEvolutionPageSwitcher extends StatefulWidget {
  const TrainingEvolutionPageSwitcher({
    super.key,
    required this.pageKey,
    required this.child,
  });

  final String pageKey;
  final Widget child;

  @override
  State<TrainingEvolutionPageSwitcher> createState() =>
      _TrainingEvolutionPageSwitcherState();
}

class _TrainingEvolutionPageSwitcherState
    extends State<TrainingEvolutionPageSwitcher>
    with SingleTickerProviderStateMixin {
  static const _light = Color(0xfff8fcff);
  late final AnimationController _animation = AnimationController(vsync: this)
    ..addListener(_tick);
  late String _displayedKey = widget.pageKey;
  late Widget _displayed = widget.child;
  bool _transitioning = false;
  bool _swapped = false;
  bool _useLight = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _showTarget() {
    _displayedKey = widget.pageKey;
    _displayed = widget.child;
  }

  void _updateTarget() {
    if (_displayedKey == widget.pageKey || _reduceMotion) {
      _showTarget();
      return;
    }
    if (_displayedKey.startsWith('evolution-') ||
        widget.pageKey.startsWith('evolution-')) {
      _transitioning = true;
      _useLight = true;
      _swapped = false;
      _animation.duration = Duration(
        milliseconds: widget.pageKey.startsWith('evolution-') ? 900 : 700,
      );
      _animation.forward(from: 0);
    } else {
      _useLight = false;
      _showTarget();
    }
  }

  void _tick() {
    if (!_transitioning) return;
    setState(() {
      if (!_swapped && _animation.value >= .5) {
        _showTarget();
        _swapped = true;
      }
      if (_animation.value >= 1) {
        _transitioning = false;
        // 外部の状態更新が光の後半に来た場合も、最後の画面まで進めます。
        _updateTarget();
      }
    });
  }

  @override
  void didUpdateWidget(TrainingEvolutionPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_transitioning) {
      if (_displayedKey == widget.pageKey) _displayed = widget.child;
    } else {
      _updateTarget();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _transitioning = false;
      _animation.stop();
      _showTarget();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _animation.value;
    final eased = t * t * (3 - 2 * t);
    final lightOpacity =
        _transitioning ? (eased < .5 ? eased * 2 : (1 - eased) * 2) : 0.0;
    return IgnorePointer(
      ignoring: _transitioning,
      child: ExcludeSemantics(
        excluding: _transitioning,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: _useLight || _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) =>
                  _useLight || _reduceMotion
                      ? currentChild ?? const SizedBox.shrink()
                      : AnimatedSwitcher.defaultLayoutBuilder(
                          currentChild, previousChildren),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final leaving = animation.status == AnimationStatus.reverse;
                    return IgnorePointer(
                      ignoring: leaving,
                      child: ExcludeSemantics(
                        excluding: leaving,
                        child: child!,
                      ),
                    );
                  },
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_displayedKey),
                child: _displayed,
              ),
            ),
            if (_transitioning)
              Positioned.fill(
                child: Opacity(
                  key: const ValueKey('evolution-transition-light'),
                  opacity: lightOpacity,
                  child: const ColoredBox(color: _light),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
