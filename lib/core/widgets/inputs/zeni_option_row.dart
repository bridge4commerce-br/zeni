import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';
import '../../theme/zeni_spacing.dart';

class ZeniOptionRow extends StatelessWidget {
  const ZeniOptionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = selected ? ZeniColors.primary : ZeniColors.border;
    final backgroundColor = selected
        ? ZeniColors.primary.withValues(alpha: 0.10)
        : Theme.of(context).colorScheme.surface;

    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ZeniRadius.lg),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.all(ZeniSpacing.lg),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(ZeniRadius.lg),
              border: Border.all(color: typeColor),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: ZeniSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: ZeniSpacing.xs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ZeniColors.mutedText),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: ZeniSpacing.md),
                  trailing!,
                ] else if (selected) ...[
                  const SizedBox(width: ZeniSpacing.md),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ZeniColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
