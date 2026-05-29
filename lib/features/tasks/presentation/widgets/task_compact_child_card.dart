import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
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
    final isPending = status == MissionLogStatus.pending;

    return Semantics(
      button: true,
      label: '${mission.title}, ${status.label}, ${mission.stars} estrelas',
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
            color: _backgroundColor(status),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _borderColor(status),
              width: isPending ? 2 : 1,
            ),
            boxShadow: isPending
                ? [
                    BoxShadow(
                      color: ZeniColors.warning.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _StatusIcon(status: status),
              const SizedBox(width: ZeniSpacing.md),
              Text(mission.emoji, style: const TextStyle(fontSize: 30)),
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
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted ? ZeniColors.mutedText : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      _subtitle(status),
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
                  color: isCompleted
                      ? ZeniColors.mutedText
                      : ZeniColors.primaryDark,
                ),
              ),
            ],
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

  Color _backgroundColor(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => ZeniColors.warning.withValues(alpha: 0.12),
      MissionLogStatus.awaitingApproval => ZeniColors.primary.withValues(
        alpha: 0.08,
      ),
      MissionLogStatus.approved => ZeniColors.success.withValues(alpha: 0.08),
      MissionLogStatus.rejected => ZeniColors.error.withValues(alpha: 0.08),
      MissionLogStatus.skipped => ZeniColors.border.withValues(alpha: 0.35),
    };
  }

  Color _borderColor(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => ZeniColors.warning.withValues(alpha: 0.50),
      MissionLogStatus.awaitingApproval => ZeniColors.primary.withValues(
        alpha: 0.28,
      ),
      MissionLogStatus.approved => ZeniColors.success.withValues(alpha: 0.28),
      MissionLogStatus.rejected => ZeniColors.error.withValues(alpha: 0.28),
      MissionLogStatus.skipped => ZeniColors.border,
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
