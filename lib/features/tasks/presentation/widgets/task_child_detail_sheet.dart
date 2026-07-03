import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_log.dart';

enum TaskChildDetailAction { complete, cancelSubmission, undoCompletion }

class TaskChildDetailSheet extends StatelessWidget {
  const TaskChildDetailSheet({
    super.key,
    required this.mission,
    required this.onListenToMission,
    required this.onListenToMissionDetails,
    this.log,
    this.canUndoCompletion = false,
    this.showListenActions = true,
  });

  final Mission mission;
  final VoidCallback onListenToMission;
  final VoidCallback onListenToMissionDetails;
  final MissionLog? log;
  final bool canUndoCompletion;
  final bool showListenActions;

  @override
  Widget build(BuildContext context) {
    final status = log?.status ?? MissionLogStatus.pending;

    return ZeniModalSheetContainer(
      title: 'Detalhes da missão',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniCard(
              child: Row(
                children: [
                  Text(mission.emoji, style: const TextStyle(fontSize: 42)),
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
                          _shortStatus(status),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ZeniColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            Text(
              mission.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
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
                StatusBadge(
                  label: mission.timeGroup.label,
                  icon: Icons.schedule_rounded,
                  tone: StatusBadgeTone.neutral,
                ),
                StatusBadge(
                  label: mission.recurrence.label,
                  icon: Icons.repeat_rounded,
                  tone: StatusBadgeTone.neutral,
                ),
                StatusBadge(
                  label: mission.approvalMode.label,
                  icon:
                      mission.approvalMode == MissionApprovalMode.parentApproval
                      ? Icons.verified_user_rounded
                      : Icons.flash_on_rounded,
                  tone:
                      mission.approvalMode == MissionApprovalMode.parentApproval
                      ? StatusBadgeTone.warning
                      : StatusBadgeTone.success,
                ),
                if (mission.requiresPhoto)
                  const StatusBadge(
                    label: 'Pode pedir foto',
                    icon: Icons.photo_camera_rounded,
                    tone: StatusBadgeTone.neutral,
                  ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.xl),
            if (showListenActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _TaskSpeechActionButton(
                      label: 'Missão',
                      semanticLabel: 'Ouvir missão',
                      onPressed: onListenToMission,
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.sm),
                  Expanded(
                    child: _TaskSpeechActionButton(
                      label: 'Completo',
                      semanticLabel: 'Ouvir completo',
                      onPressed: onListenToMissionDetails,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
            if (status == MissionLogStatus.pending)
              ZeniPrimaryButton(
                label: 'Concluir missão',
                icon: Icons.check_rounded,
                onPressed: () {
                  Navigator.of(context).pop(TaskChildDetailAction.complete);
                },
              ),
            if (status == MissionLogStatus.awaitingApproval)
              ZeniSecondaryButton(
                label: 'Cancelar envio',
                icon: Icons.undo_rounded,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(TaskChildDetailAction.cancelSubmission);
                },
              ),
            if (status == MissionLogStatus.approved)
              Column(
                children: [
                  if (canUndoCompletion) ...[
                    ZeniSecondaryButton(
                      label: 'Desfazer conclusão',
                      icon: Icons.undo_rounded,
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(TaskChildDetailAction.undoCompletion);
                      },
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                  ],
                  ZeniSecondaryButton(
                    label: 'Fechar',
                    icon: Icons.check_circle_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _shortStatus(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => 'Ainda falta fazer essa missão.',
      MissionLogStatus.awaitingApproval =>
        'Enviada para o responsável aprovar.',
      MissionLogStatus.approved => 'Missão concluída hoje.',
      MissionLogStatus.rejected => 'O responsável pediu para tentar de novo.',
      MissionLogStatus.skipped => 'Essa missão foi pulada hoje.',
    };
  }

  IconData _statusIcon(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => Icons.hourglass_empty_rounded,
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

class _TaskSpeechActionButton extends StatelessWidget {
  const _TaskSpeechActionButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 150;
          final icon = const Icon(Icons.volume_up_rounded);
          final text = FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
            ),
          );

          return OutlinedButton(
            onPressed: onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: useVerticalLayout
                  ? Column(
                      key: const ValueKey('vertical'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(height: ZeniSpacing.xs),
                        text,
                      ],
                    )
                  : Row(
                      key: const ValueKey('horizontal'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(width: ZeniSpacing.sm),
                        Flexible(child: text),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
