import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';

class ParentChildSummaryCard extends StatelessWidget {
  const ParentChildSummaryCard({super.key, required this.child, this.onTap});

  final ChildProfile child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      onTap: onTap,
      child: Row(
        children: [
          ZeniAvatar(label: child.name, emoji: child.emoji, size: 60),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${child.streakCount} dias de sequência',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          ZeniBalancePill(stars: child.starBalance),
        ],
      ),
    );
  }
}
