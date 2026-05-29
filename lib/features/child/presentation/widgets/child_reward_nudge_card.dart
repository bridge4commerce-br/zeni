import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../rewards/data/models/reward.dart';

class ChildRewardNudgeCard extends StatelessWidget {
  const ChildRewardNudgeCard({
    super.key,
    required this.reward,
    required this.currentBalance,
    this.onTap,
  });

  final Reward reward;
  final int currentBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final missing = reward.cost - currentBalance;
    final canRedeem = missing <= 0;

    return ZeniCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canRedeem
                      ? 'Você já pode pedir um mimo 🎁'
                      : 'Você está perto de um mimo 🎁',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  canRedeem
                      ? '${reward.title} custa ${reward.cost} estrelas.'
                      : 'Faltam $missing estrelas para ${reward.title}.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
