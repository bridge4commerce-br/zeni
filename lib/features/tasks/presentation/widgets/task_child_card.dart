import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_log.dart';

class TaskChildCard extends StatelessWidget {
  const TaskChildCard({
    super.key,
    required this.mission,
    this.log,
    this.onComplete,
    this.onCancelSubmission,
  });

  final Mission mission;
  final MissionLog? log;
  final VoidCallback? onComplete;
  final VoidCallback? onCancelSubmission;

  @override
  Widget build(BuildContext context) {
    final status = log?.status ?? MissionLogStatus.pending;

    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      mission.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          Wrap(
            spacing: ZeniSpacing.sm,
            runSpacing: ZeniSpacing.sm,
            children: [
              StatusBadge(
                label: status.label,
                icon: _statusIcon(status),
                tone: _statusTone(status),
              ),
              StatusBadge(
                label: '${mission.stars} estrelas',
                icon: Icons.star_rounded,
                tone: StatusBadgeTone.info,
              ),
              if (mission.requiresPhoto)
                const StatusBadge(
                  label: 'Foto',
                  icon: Icons.photo_camera_rounded,
                  tone: StatusBadgeTone.neutral,
                ),
            ],
          ),
          if (status == MissionLogStatus.pending) ...[
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: 'Concluir missão',
              icon: Icons.check_rounded,
              onPressed: onComplete,
            ),
          ],
          if (status == MissionLogStatus.awaitingApproval) ...[
            const SizedBox(height: ZeniSpacing.lg),
            ZeniSecondaryButton(
              label: 'Cancelar envio',
              icon: Icons.undo_rounded,
              onPressed: onCancelSubmission,
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => Icons.schedule_rounded,
      MissionLogStatus.awaitingApproval => Icons.hourglass_top_rounded,
      MissionLogStatus.approved => Icons.check_circle_rounded,
      MissionLogStatus.rejected => Icons.cancel_rounded,
      MissionLogStatus.skipped => Icons.next_plan_rounded,
    };
  }

  StatusBadgeTone _statusTone(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => StatusBadgeTone.warning,
      MissionLogStatus.awaitingApproval => StatusBadgeTone.info,
      MissionLogStatus.approved => StatusBadgeTone.success,
      MissionLogStatus.rejected => StatusBadgeTone.error,
      MissionLogStatus.skipped => StatusBadgeTone.neutral,
    };
  }
}
