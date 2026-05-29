import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../data/models/reward.dart';

class ChildRewardCard extends StatelessWidget {
  const ChildRewardCard({
    super.key,
    required this.reward,
    required this.childBalance,
    this.onRedeem,
    this.onNeedMoreStars,
  });

  final Reward reward;
  final int childBalance;
  final VoidCallback? onRedeem;
  final VoidCallback? onNeedMoreStars;

  bool get canRedeem => childBalance >= reward.cost;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      reward.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          Wrap(
            spacing: ZeniSpacing.sm,
            runSpacing: ZeniSpacing.sm,
            children: [
              StatusBadge(
                label: '${reward.cost} estrelas',
                icon: Icons.star_rounded,
                tone: canRedeem
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.warning,
              ),
              StatusBadge(
                label: reward.renewal.label,
                icon: Icons.refresh_rounded,
                tone: StatusBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniPrimaryButton(
            label: canRedeem ? 'Pedir mimo' : 'Juntar estrelas',
            icon: canRedeem ? Icons.card_giftcard_rounded : Icons.stars_rounded,
            onPressed: canRedeem ? onRedeem : onNeedMoreStars,
          ),
        ],
      ),
    );
  }
}
