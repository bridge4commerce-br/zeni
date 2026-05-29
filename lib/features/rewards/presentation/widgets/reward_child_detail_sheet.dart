import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/models/reward.dart';

enum RewardChildDetailAction { redeem }

class RewardChildDetailSheet extends StatelessWidget {
  const RewardChildDetailSheet({
    super.key,
    required this.reward,
    required this.childBalance,
  });

  final Reward reward;
  final int childBalance;

  bool get canRedeem => childBalance >= reward.cost;

  @override
  Widget build(BuildContext context) {
    final missingStars = reward.cost - childBalance;

    return ZeniModalSheetContainer(
      title: 'Detalhes do mimo',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniCard(
              child: Row(
                children: [
                  Text(reward.emoji, style: const TextStyle(fontSize: 42)),
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
                          canRedeem
                              ? 'Você já pode pedir esse mimo.'
                              : 'Junte mais estrelas para pedir.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ZeniColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            Text(
              reward.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
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
                StatusBadge(
                  label: canRedeem
                      ? 'Pode pedir'
                      : 'Faltam $missingStars estrelas',
                  icon: canRedeem
                      ? Icons.check_circle_rounded
                      : Icons.stars_rounded,
                  tone: canRedeem
                      ? StatusBadgeTone.success
                      : StatusBadgeTone.info,
                ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.xl),
            if (canRedeem)
              ZeniPrimaryButton(
                label: 'Pedir mimo',
                icon: Icons.card_giftcard_rounded,
                onPressed: () {
                  Navigator.of(context).pop(RewardChildDetailAction.redeem);
                },
              )
            else
              ZeniSecondaryButton(
                label: 'Continuar juntando estrelas',
                icon: Icons.stars_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
