import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';
import '../../theme/zeni_spacing.dart';

enum StatusBadgeTone { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusBadgeTone.neutral,
  });

  final String label;
  final IconData? icon;
  final StatusBadgeTone tone;

  Color get _color {
    return switch (tone) {
      StatusBadgeTone.success => ZeniColors.success,
      StatusBadgeTone.warning => ZeniColors.warning,
      StatusBadgeTone.error => ZeniColors.error,
      StatusBadgeTone.info => ZeniColors.info,
      StatusBadgeTone.neutral => ZeniColors.mutedText,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.md,
          vertical: ZeniSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ZeniRadius.pill),
          border: Border.all(color: _color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: _color),
              const SizedBox(width: ZeniSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
