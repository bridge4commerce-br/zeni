import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';

class ChildNextMissionCard extends StatelessWidget {
  const ChildNextMissionCard({
    super.key,
    required this.mission,
    this.log,
    this.onOpen,
    this.onCancelSubmission,
  });

  final Mission mission;
  final MissionLog? log;
  final VoidCallback? onOpen;
  final VoidCallback? onCancelSubmission;

  @override
  Widget build(BuildContext context) {
    final status = log?.status ?? MissionLogStatus.pending;

    return ZeniCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Próxima missão', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          Row(
            children: [
              _StatusIcon(status: status),
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
                  color: ZeniColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => '${mission.timeGroup.label} · toque para ver',
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
