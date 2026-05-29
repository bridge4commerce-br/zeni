import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';

class ParentMissionCard extends StatelessWidget {
  const ParentMissionCard({
    super.key,
    required this.mission,
    required this.child,
    this.onEdit,
    this.onDelete,
  });

  final Mission mission;
  final ChildProfile? child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(mission.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${child?.name ?? 'Criança'} · ${mission.stars} estrelas · ${mission.timeGroup.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          ZeniIconActionButton(
            icon: Icons.edit_rounded,
            tooltip: 'Editar missão',
            tone: ZeniIconActionTone.primary,
            onPressed: onEdit,
          ),
          const SizedBox(width: ZeniSpacing.sm),
          ZeniIconActionButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Excluir missão',
            tone: ZeniIconActionTone.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
