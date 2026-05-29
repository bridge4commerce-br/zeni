import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../tasks/data/models/mission.dart';

class ChildBonusMissionCard extends StatelessWidget {
  const ChildBonusMissionCard({super.key, required this.mission, this.onOpen});

  final Mission mission;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Missão extra ✨', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ZeniColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: ZeniColors.primaryDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: ZeniSpacing.md),
              Text(mission.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      '${mission.timeGroup.label} · toque para ver',
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
                '+${mission.stars} ⭐',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ZeniColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
