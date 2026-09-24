import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
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
    required this.onListenToReward,
    required this.onListenToRewardDetails,
    required this.canListenToReward,
    this.onRefresh,
  });

  final int childBalance;
  final List<Reward> rewards;
  final List<RewardRequest> pendingRewardRequests;
  final Reward? Function(String rewardId) rewardById;
  final ValueChanged<Reward> onRedeemReward;
  final ValueChanged<Reward> onListenToReward;
  final void Function(Reward reward, RewardRequest? request)
  onListenToRewardDetails;
  final bool canListenToReward;
  final Future<void> Function()? onRefresh;

  RewardRequest? _pendingRequestForReward(String rewardId) {
    for (final request in pendingRewardRequests) {
      if (request.rewardId == rewardId) {
        return request;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sortedRewards = [...rewards]
      ..sort((a, b) => a.cost.compareTo(b.cost));

    final content = SingleChildScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceSection,
        bottom: ZeniSpacing.spaceCanvas + MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mimos',
              key: const Key('child-rewards-title'),
              style: ZeniTypography.of(context).pageTitle,
            ),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(
              'Toque em um mimo para ver detalhes.',
              style: ZeniTypography.of(context).body,
            ),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            _RewardsBalanceHeader(childBalance: childBalance),
            if (pendingRewardRequests.isNotEmpty) ...[
              const SizedBox(height: ZeniSpacing.spaceSection),
              Text(
                'Pedidos pendentes',
                style: ZeniTypography.of(context).sectionTitle,
              ),
              const SizedBox(height: ZeniSpacing.spaceCard),
              ZeniSurface(
                key: const Key('child-rewards-pending-list'),
                role: ZeniSurfaceRole.grouped,
                mode: ZeniVisualMode.kids,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < pendingRewardRequests.length;
                      index++
                    ) ...[
                      _ChildPendingRewardCard(
                        request: pendingRewardRequests[index],
                        reward: rewardById(
                          pendingRewardRequests[index].rewardId,
                        ),
                      ),
                      if (index < pendingRewardRequests.length - 1)
                        _ChildRewardDivider(),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: ZeniSpacing.spaceSection),
            Text(
              'Mimos disponíveis',
              style: ZeniTypography.of(context).sectionTitle,
            ),
            const SizedBox(height: ZeniSpacing.spaceCard),
            if (sortedRewards.isEmpty)
              const _RewardsEmptyState()
            else
              ZeniSurface(
                key: const Key('child-rewards-catalog-list'),
                role: ZeniSurfaceRole.grouped,
                mode: ZeniVisualMode.kids,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < sortedRewards.length;
                      index++
                    ) ...[
                      RewardCompactChildCard(
                        key: Key('child-reward-${sortedRewards[index].id}'),
                        reward: sortedRewards[index],
                        childBalance: childBalance,
                        pendingRequest: _pendingRequestForReward(
                          sortedRewards[index].id,
                        ),
                        onTap: () => _openReward(context, sortedRewards[index]),
                      ),
                      if (index < sortedRewards.length - 1)
                        _ChildRewardDivider(),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (onRefresh == null) {
      return content;
    }

    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }

  Future<void> _openReward(BuildContext context, Reward reward) async {
    final pendingRequest = _pendingRequestForReward(reward.id);
    final action = await showRewardChildDetailModal(
      context: context,
      reward: reward,
      childBalance: childBalance,
      onListenToReward: () => onListenToReward(reward),
      onListenToRewardDetails: () {
        onListenToRewardDetails(reward, pendingRequest);
      },
      pendingRequest: pendingRequest,
      showListenActions: canListenToReward,
    );

    if (!context.mounted) return;

    switch (action) {
      case RewardChildDetailAction.redeem:
        onRedeemReward(reward);
      case null:
        break;
    }
  }
}

class _RewardsBalanceHeader extends StatelessWidget {
  const _RewardsBalanceHeader({required this.childBalance});

  final int childBalance;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return ZeniSurface(
      key: const Key('child-rewards-balance'),
      role: ZeniSurfaceRole.highlight,
      mode: ZeniVisualMode.kids,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seu saldo', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text(
                  'Estrelas disponíveis para escolher um mimo.',
                  style: typography.metadata,
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.spaceControl),
          ZeniBalancePill(stars: childBalance),
        ],
      ),
    );
  }
}

class _RewardsEmptyState extends StatelessWidget {
  const _RewardsEmptyState();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return ZeniSurface(
      key: const Key('child-rewards-empty-state'),
      role: ZeniSurfaceRole.grouped,
      mode: ZeniVisualMode.kids,
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: colors.actionPrimary),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nenhum mimo por enquanto', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text(
                  'Quando houver novos mimos, eles aparecerão aqui.',
                  style: typography.metadata,
                ),
              ],
            ),
          ),
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
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final displayEmoji = reward?.emoji ?? '🎁';
    final displayTitle = reward?.title ?? 'Mimo solicitado';
    final displayCost = reward?.cost ?? 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.spaceCard,
          vertical: ZeniSpacing.spaceCard,
        ),
        child: Row(
          children: [
            Text(displayEmoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTitle, style: typography.cardTitle),
                  const SizedBox(height: ZeniSpacing.spaceInline),
                  Text('Aguardando responsável', style: typography.metadata),
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            Text(
              '$displayCost ⭐',
              style: typography.bodyEmphasis.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildRewardDivider extends StatelessWidget {
  const _ChildRewardDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: ZeniSpacing.spaceCard,
    endIndent: ZeniSpacing.spaceCard,
    color: context.zeniColors.borderSubtle,
  );
}
