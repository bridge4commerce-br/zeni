import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';
import '../../theme/zeni_spacing.dart';

class ZeniBalancePill extends StatelessWidget {
  const ZeniBalancePill({
    super.key,
    required this.stars,
    this.label = 'estrelas',
  });

  final int stars;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$stars $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.md,
          vertical: ZeniSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ZeniColors.accent.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(ZeniRadius.pill),
          border: Border.all(color: ZeniColors.accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: ZeniSpacing.xs),
            Text(
              '$stars',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
