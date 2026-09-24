import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';

class RewardCompactChildCard extends StatelessWidget {
  const RewardCompactChildCard({
    super.key,
    required this.reward,
    required this.childBalance,
    this.pendingRequest,
    this.onTap,
  });

  final Reward reward;
  final int childBalance;
  final RewardRequest? pendingRequest;
  final VoidCallback? onTap;

  bool get canRedeem => childBalance >= reward.cost;
  bool get isPending => pendingRequest != null;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final missingStars = reward.cost - childBalance;
    final status = isPending
        ? 'Aguardando responsável'
        : canRedeem
        ? 'Pode pedir agora'
        : 'Faltam $missingStars estrelas';
    final semanticLabel = isPending
        ? '${reward.title}, pedido aguardando responsável, custa ${reward.cost} estrelas'
        : canRedeem
        ? '${reward.title}, pode pedir, custa ${reward.cost} estrelas'
        : '${reward.title}, faltam $missingStars estrelas';
    final statusColor = isPending || !canRedeem
        ? ZeniColors.warning
        : colors.actionPrimary;

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeniSpacing.spaceCard,
                vertical: ZeniSpacing.spaceCard,
              ),
              child: Row(
                children: [
                  Text(reward.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.cardTitle,
                        ),
                        const SizedBox(height: ZeniSpacing.spaceInline),
                        Text(
                          status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.metadata.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceInline),
                  Text(
                    '${reward.cost} ⭐',
                    style: typography.bodyEmphasis.copyWith(
                      color: canRedeem
                          ? colors.actionPrimary
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceInlineTight),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
