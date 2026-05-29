import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../rewards/data/models/reward.dart';

class RewardCompactChildCard extends StatelessWidget {
  const RewardCompactChildCard({
    super.key,
    required this.reward,
    required this.childBalance,
    this.onTap,
  });

  final Reward reward;
  final int childBalance;
  final VoidCallback? onTap;

  bool get canRedeem => childBalance >= reward.cost;

  @override
  Widget build(BuildContext context) {
    final missingStars = reward.cost - childBalance;

    return Semantics(
      button: true,
      label: canRedeem
          ? '${reward.title}, pode pedir, custa ${reward.cost} estrelas'
          : '${reward.title}, faltam $missingStars estrelas',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.lg,
            vertical: ZeniSpacing.md,
          ),
          decoration: BoxDecoration(
            color: canRedeem
                ? ZeniColors.success.withValues(alpha: 0.08)
                : ZeniColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canRedeem
                  ? ZeniColors.success.withValues(alpha: 0.30)
                  : ZeniColors.primary.withValues(alpha: 0.22),
              width: canRedeem ? 2 : 1,
            ),
            boxShadow: canRedeem
                ? [
                    BoxShadow(
                      color: ZeniColors.success.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _StatusIcon(canRedeem: canRedeem),
              const SizedBox(width: ZeniSpacing.md),
              Text(reward.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      canRedeem
                          ? 'Pode pedir agora'
                          : 'Faltam $missingStars estrelas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeniSpacing.md),
              Text(
                '${reward.cost} ⭐',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: canRedeem
                      ? ZeniColors.success
                      : ZeniColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.canRedeem});

  final bool canRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
      ),
      child: Icon(
        canRedeem ? Icons.check_circle_rounded : Icons.stars_rounded,
        color: canRedeem ? ZeniColors.success : ZeniColors.primaryDark,
        size: 24,
      ),
    );
  }
}
