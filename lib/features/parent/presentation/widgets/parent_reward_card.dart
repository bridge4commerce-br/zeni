import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../rewards/data/models/reward.dart';

class ParentRewardCard extends StatelessWidget {
  const ParentRewardCard({
    super.key,
    required this.reward,
    this.onEdit,
    this.onDelete,
  });

  final Reward reward;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${reward.cost} estrelas · ${reward.renewal.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          ZeniIconActionButton(
            icon: Icons.edit_rounded,
            tooltip: 'Editar mimo',
            tone: ZeniIconActionTone.primary,
            onPressed: onEdit,
          ),
          const SizedBox(width: ZeniSpacing.sm),
          ZeniIconActionButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Excluir mimo',
            tone: ZeniIconActionTone.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
