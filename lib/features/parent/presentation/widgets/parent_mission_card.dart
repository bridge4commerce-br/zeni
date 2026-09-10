import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
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
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final isCompact =
        ZeniResponsive.windowClass(context) == ZeniWindowClass.compact;
    final approval = mission.approvalMode == MissionApprovalMode.parentApproval
        ? 'Aprovação do responsável'
        : null;

    return Semantics(
      container: true,
      label:
          '${mission.title}, ${child?.name ?? 'Criança'}, ${mission.stars} estrelas, ${mission.recurrence.label}, ${mission.timeGroup.label}${approval == null ? '' : ', $approval'}',
      child: Padding(
        key: Key('parent-mission-${mission.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.spaceCard,
          vertical: ZeniSpacing.spaceControl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: Text(
                    mission.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.title, style: typography.cardTitle),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      '${child?.name ?? 'Criança'} · ${mission.stars} estrelas',
                      style: typography.metadata,
                    ),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      [
                        mission.recurrence.label,
                        mission.timeGroup.label,
                        ?approval,
                      ].join(' · '),
                      style: typography.metadata,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            if (!isCompact)
              ZeniIconActionButton(
                icon: Icons.edit_rounded,
                tooltip: 'Editar missão',
                tone: ZeniIconActionTone.primary,
                onPressed: onEdit,
              ),
            PopupMenuButton<_ParentMissionAction>(
              key: Key('parent-mission-actions-${mission.id}'),
              tooltip: 'Mais ações para ${mission.title}',
              icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
              onSelected: (action) {
                switch (action) {
                  case _ParentMissionAction.edit:
                    onEdit?.call();
                  case _ParentMissionAction.archive:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (isCompact)
                  const PopupMenuItem(
                    value: _ParentMissionAction.edit,
                    child: _MissionMenuLabel(
                      icon: Icons.edit_rounded,
                      label: 'Editar missão',
                    ),
                  ),
                const PopupMenuItem(
                  value: _ParentMissionAction.archive,
                  child: _MissionMenuLabel(
                    icon: Icons.archive_outlined,
                    label: 'Arquivar missão',
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

enum _ParentMissionAction { edit, archive }

class _MissionMenuLabel extends StatelessWidget {
  const _MissionMenuLabel({required this.icon, required this.label});

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
