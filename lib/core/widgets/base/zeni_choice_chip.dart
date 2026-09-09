import 'package:flutter/material.dart';

import '../../layout/zeni_responsive.dart';
import '../../theme/zeni_colors.dart';
import '../../theme/zeni_typography.dart';
import '../../theme/zeni_visual_mode.dart';

class ZeniChoiceChip extends StatelessWidget {
  const ZeniChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.mode,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final ZeniVisualMode mode;
  final Widget? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    final visualHeight = mode == ZeniVisualMode.kids ? 48.0 : 44.0;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ZeniTouchTargets.minimum),
        child: Center(
          child: SizedBox(
            height: visualHeight,
            child: ChoiceChip(
              avatar: icon,
              label: Text(label),
              selected: selected,
              onSelected: enabled ? onSelected : null,
              selectedColor: colors.surfaceSubtle,
              backgroundColor: colors.surface,
              disabledColor: colors.surface.withValues(alpha: .48),
              side: BorderSide(
                color: selected ? colors.actionPrimary : colors.borderSubtle,
              ),
              labelStyle: typography.chip.copyWith(
                color: !enabled
                    ? colors.textSecondary.withValues(alpha: .55)
                    : selected
                    ? colors.actionPrimary
                    : colors.textPrimary,
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              showCheckmark: selected,
              checkmarkColor: colors.actionPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
