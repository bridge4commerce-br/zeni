import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../rewards/presentation/widgets/reward_child_detail_sheet.dart';
import '../../../rewards/presentation/widgets/reward_compact_child_card.dart';

class ChildRewardsTab extends StatelessWidget {
  const ChildRewardsTab({
    super.key,
    required this.childBalance,
    required this.rewards,
    required this.pendingRewardRequests,
    required this.rewardById,
    required this.onRedeemReward,
  });

  final int childBalance;
  final List<Reward> rewards;
  final List<RewardRequest> pendingRewardRequests;
  final Reward? Function(String rewardId) rewardById;
  final ValueChanged<Reward> onRedeemReward;

  @override
  Widget build(BuildContext context) {
    final sortedRewards = [...rewards]
      ..sort((a, b) => a.cost.compareTo(b.cost));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meus mimos', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Toque em um mimo para ver detalhes.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          if (pendingRewardRequests.isNotEmpty) ...[
            Text(
              'Pedidos pendentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            for (final request in pendingRewardRequests) ...[
              _ChildPendingRewardCard(
                request: request,
                reward: rewardById(request.rewardId),
              ),
              const SizedBox(height: ZeniSpacing.sm),
            ],
            const SizedBox(height: ZeniSpacing.xl),
          ],
          Text(
            'Catálogo de mimos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ZeniSpacing.md),
          for (final reward in sortedRewards) ...[
            RewardCompactChildCard(
              reward: reward,
              childBalance: childBalance,
              onTap: () async {
                final action =
                    await showModalBottomSheet<RewardChildDetailAction>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: RewardChildDetailSheet(
                            reward: reward,
                            childBalance: childBalance,
                          ),
                        );
                      },
                    );

                if (!context.mounted) return;

                switch (action) {
                  case RewardChildDetailAction.redeem:
                    onRedeemReward(reward);
                  case null:
                    break;
                }
              },
            ),
            const SizedBox(height: ZeniSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ChildPendingRewardCard extends StatelessWidget {
  const _ChildPendingRewardCard({required this.request, required this.reward});

  final RewardRequest request;
  final Reward? reward;

  @override
  Widget build(BuildContext context) {
    final displayEmoji = reward?.emoji ?? '🎁';
    final displayTitle = reward?.title ?? 'Mimo solicitado';
    final displayCost = reward?.cost ?? 0;

    return ZeniCard(
      child: Row(
        children: [
          Text(displayEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'Aguardando responsável',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Text(
            '$displayCost ⭐',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: ZeniColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
