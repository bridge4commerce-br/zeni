import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';

class ParentMetricCard extends StatelessWidget {
  const ParentMetricCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.onTap,
  });

  final String emoji;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: ZeniSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
      ),
    );
  }
}
