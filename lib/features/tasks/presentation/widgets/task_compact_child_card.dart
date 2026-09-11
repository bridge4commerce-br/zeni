import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_log.dart';

class TaskCompactChildCard extends StatelessWidget {
  const TaskCompactChildCard({
    super.key,
    required this.mission,
    this.log,
    this.onTap,
  });

  final Mission mission;
  final MissionLog? log;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = log?.status ?? MissionLogStatus.pending;
    final isCompleted = status == MissionLogStatus.approved;
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return Semantics(
      button: true,
      label: '${mission.title}, ${status.label}, ${mission.stars} estrelas',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeniSpacing.spaceCard,
                vertical: ZeniSpacing.spaceControl,
              ),
              child: Row(
                children: [
                  _StatusIcon(status: status),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Text(mission.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.cardTitle.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isCompleted
                                ? colors.textSecondary
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ZeniSpacing.spaceInlineTight),
                        Text(
                          _subtitle(status),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.metadata,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceInline),
                  Text(
                    '+${mission.stars} ⭐',
                    style: typography.bodyEmphasis.copyWith(
                      color: isCompleted
                          ? colors.textSecondary
                          : colors.actionPrimary,
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

  String _subtitle(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => '${mission.timeGroup.label} · Pendente',
      MissionLogStatus.awaitingApproval => 'Enviado · aguardando responsável',
      MissionLogStatus.approved => 'Concluída hoje',
      MissionLogStatus.rejected => 'Precisa tentar de novo',
      MissionLogStatus.skipped => 'Pulada hoje',
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MissionLogStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      MissionLogStatus.pending => Icons.hourglass_empty_rounded,
      MissionLogStatus.awaitingApproval => Icons.hourglass_top_rounded,
      MissionLogStatus.approved => Icons.check_circle_rounded,
      MissionLogStatus.rejected => Icons.cancel_rounded,
      MissionLogStatus.skipped => Icons.next_plan_rounded,
    };

    final color = switch (status) {
      MissionLogStatus.pending => ZeniColors.warning,
      MissionLogStatus.awaitingApproval => ZeniColors.primaryDark,
      MissionLogStatus.approved => ZeniColors.success,
      MissionLogStatus.rejected => ZeniColors.error,
      MissionLogStatus.skipped => ZeniColors.mutedText,
    };

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
