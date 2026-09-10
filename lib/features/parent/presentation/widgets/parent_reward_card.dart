import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
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
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Semantics(
      container: true,
      label:
          '${reward.title}, ${reward.cost} estrelas, ${reward.renewal.label}',
      child: Padding(
        key: Key('parent-reward-${reward.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.spaceCard,
          vertical: ZeniSpacing.spaceControl,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: Center(
                child: Text(reward.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.title, style: typography.cardTitle),
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(
                    '${reward.cost} estrelas · ${reward.renewal.label}',
                    style: typography.metadata,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            PopupMenuButton<_ParentRewardAction>(
              key: Key('parent-reward-actions-${reward.id}'),
              tooltip: 'Mais ações para ${reward.title}',
              icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
              onSelected: (action) {
                switch (action) {
                  case _ParentRewardAction.edit:
                    onEdit?.call();
                  case _ParentRewardAction.archive:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ParentRewardAction.edit,
                  child: _RewardMenuLabel(
                    icon: Icons.edit_rounded,
                    label: 'Editar mimo',
                  ),
                ),
                PopupMenuItem(
                  value: _ParentRewardAction.archive,
                  child: _RewardMenuLabel(
                    icon: Icons.archive_outlined,
                    label: 'Arquivar mimo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ParentRewardAction { edit, archive }

class _RewardMenuLabel extends StatelessWidget {
  const _RewardMenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon),
      const SizedBox(width: ZeniSpacing.spaceControl),
      Flexible(child: Text(label)),
    ],
  );
}
