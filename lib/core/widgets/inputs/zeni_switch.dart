import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_spacing.dart';

class ZeniSwitch extends StatelessWidget {
  const ZeniSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.sm),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: value ? ZeniColors.primary : ZeniColors.mutedText,
              ),
              const SizedBox(width: ZeniSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.md),
            Switch(
              value: value,
              activeThumbColor: ZeniColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
