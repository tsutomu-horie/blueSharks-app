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

/// Groups simultaneous warnings while retaining each episode's original copy.
class TrainingRetirementWarningsPanel extends StatefulWidget {
  const TrainingRetirementWarningsPanel({
    required this.warnings,
    required this.collapsed,
    required this.onCollapse,
    required this.onExpand,
    super.key,
  });

  final List<TrainingRetirementWarning> warnings;
  final bool collapsed;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;

  @override
  State<TrainingRetirementWarningsPanel> createState() =>
      _TrainingRetirementWarningsPanelState();
}

class _TrainingRetirementWarningsPanelState
    extends State<TrainingRetirementWarningsPanel> {
  String? _selectedEpisode;

  @override
  Widget build(BuildContext context) {
    final selected = widget.warnings.firstWhere(
      (warning) => warning.episode == _selectedEpisode,
      orElse: () => widget.warnings.first,
    );
    const ink = Color(0xff243c52);
    const amber = Color(0xff955d16);
    const border = Color(0xffe6c080);
    const paper = Color(0xfffffdf7);
    const style = TextStyle(
        fontFamily: 'LINESeedJP', color: ink, fontSize: 13, height: 1.5);
    if (widget.collapsed) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          key: const ValueKey('retirement-warning-chip'),
          color: paper,
          shape: const StadiumBorder(side: BorderSide(color: border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline, size: 18, color: amber),
                const SizedBox(width: 6),
                Text('警告 ${widget.warnings.length}件',
                    style: style.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more, size: 20, color: amber),
              ]),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        key: const ValueKey('retirement-warning-card'),
        color: paper,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 2),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text('警告 ${widget.warnings.length}件',
                    style: style.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                key: const ValueKey('retirement-warning-close'),
                tooltip: '警告を小さくする',
                onPressed: widget.onCollapse,
                icon: const Icon(Icons.close, size: 20, color: ink),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              key: ValueKey('retirement-warning-body-${selected.episode}'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 4, runSpacing: 4, children: [
                      for (final warning in widget.warnings)
                        Semantics(
                          selected: warning.episode == selected.episode,
                          button: true,
                          child: OutlinedButton(
                            key: ValueKey(
                                'retirement-warning-tab-${warning.meterName}'),
                            onPressed: () => setState(
                                () => _selectedEpisode = warning.episode),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  warning.episode == selected.episode
                                      ? const Color(0xfff6e8c9)
                                      : paper,
                              foregroundColor: ink,
                              side: const BorderSide(color: border),
                              minimumSize: const Size(44, 44),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: Text(warning.meterName, style: style),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Text(selected.title,
                        style: style.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(selected.body, style: style),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}
