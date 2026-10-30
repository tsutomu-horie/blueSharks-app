import 'package:flutter/material.dart';

import 'models/training_retirement_warning.dart';

/// Lives exclusively in the room's empty space above the character. A bounded
/// scroll area keeps long text readable without covering the game controls.
class TrainingRetirementWarningPanel extends StatelessWidget {
  const TrainingRetirementWarningPanel({
    required this.warning,
    required this.collapsed,
    required this.onCollapse,
    required this.onExpand,
    super.key,
  });

  final TrainingRetirementWarning warning;
  final bool collapsed;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;

  static const _ink = Color(0xff243c52);
  static const _amber = Color(0xff955d16);
  static const _border = Color(0xffe6c080);
  static const _paper = Color(0xfffffdf7);

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontFamily: 'LINESeedJP',
      color: _ink,
      fontSize: 13,
      height: 1.5,
    );
    if (collapsed) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          key: const ValueKey('retirement-warning-chip'),
          color: _paper,
          shape: const StadiumBorder(side: BorderSide(color: _border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _amber),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(warning.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 20, color: _amber),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        key: const ValueKey('retirement-warning-card'),
        color: _paper,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(warning.title,
                        style: style.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    key: const ValueKey('retirement-warning-close'),
                    tooltip: '警告を小さくする',
                    onPressed: onCollapse,
                    icon: const Icon(Icons.close, size: 20, color: _ink),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                key: const ValueKey('retirement-warning-body-scroll'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(warning.body, style: style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
