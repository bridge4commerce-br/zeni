import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../../core/widgets/inputs/zeni_multiline_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/models/mission.dart';
import '../../data/models/mission_log.dart';

enum TaskChildDetailAction { complete, cancelSubmission, undoCompletion }

class TaskChildDetailResult {
  const TaskChildDetailResult({required this.action, this.note});

  final TaskChildDetailAction action;
  final String? note;
}

Future<TaskChildDetailResult?> showTaskChildDetailModal({
  required BuildContext context,
  required Mission mission,
  required VoidCallback onListenToMissionDetails,
  MissionLog? log,
  bool canUndoCompletion = false,
  bool showListenActions = true,
  Future<void> Function()? onDismiss,
}) {
  final content = TaskChildDetailSheet(
    mission: mission,
    onListenToMissionDetails: onListenToMissionDetails,
    log: log,
    canUndoCompletion: canUndoCompletion,
    showListenActions: showListenActions,
  );

  final Future<TaskChildDetailResult?> modal;
  if (ZeniAdaptiveModal.usesDialog(context)) {
    modal = showDialog<TaskChildDetailResult>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(ZeniSpacing.xl),
        child: ZeniAdaptiveModalFrame(child: content),
      ),
    );
  } else {
    modal = showModalBottomSheet<TaskChildDetailResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: content,
      ),
    );
  }

  if (onDismiss == null) return modal;
  return modal.whenComplete(() {
    unawaited(onDismiss());
  });
}

class TaskChildDetailSheet extends StatefulWidget {
  const TaskChildDetailSheet({
    super.key,
    required this.mission,
    required this.onListenToMissionDetails,
    this.log,
    this.canUndoCompletion = false,
    this.showListenActions = true,
  });

  final Mission mission;
  final VoidCallback onListenToMissionDetails;
  final MissionLog? log;
  final bool canUndoCompletion;
  final bool showListenActions;

  @override
  State<TaskChildDetailSheet> createState() => _TaskChildDetailSheetState();
}

class _TaskChildDetailSheetState extends State<TaskChildDetailSheet> {
  final _noteController = TextEditingController();
  bool _isNoteFieldVisible = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final log = widget.log;
    final status = log?.status ?? MissionLogStatus.pending;

    return ZeniModalSheetContainer(
      title: 'Detalhes da missão',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniSurface(
              role: ZeniSurfaceRole.highlight,
              mode: ZeniVisualMode.kids,
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
                          style: ZeniTypography.of(context).cardTitle,
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
              'Sobre a missão',
              style: ZeniTypography.of(context).sectionTitle,
            ),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(mission.description, style: ZeniTypography.of(context).body),
            const SizedBox(height: ZeniSpacing.lg),
            _TaskMetadataSurface(mission: mission),
            const SizedBox(height: ZeniSpacing.xl),
            if (status == MissionLogStatus.awaitingApproval &&
                (log?.note?.trim().isNotEmpty ?? false)) ...[
              Text(
                'Sua observação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(log!.note!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: ZeniSpacing.xl),
            ],
            if (widget.showListenActions) ...[
              _TaskSpeechActionButton(
                label: 'Ouvir missão',
                semanticLabel: 'Ouvir missão',
                onPressed: widget.onListenToMissionDetails,
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
            if (status == MissionLogStatus.pending) ...[
              if (!_isNoteFieldVisible)
                ZeniButton(
                  label: 'Adicionar observação',
                  icon: Icons.add_comment_outlined,
                  onPressed: () {
                    setState(() => _isNoteFieldVisible = true);
                  },
                  role: ZeniButtonRole.tertiary,
                  mode: ZeniVisualMode.kids,
                )
              else
                ZeniMultilineInput(
                  controller: _noteController,
                  label: 'Observação opcional',
                  hint: 'Ex.: fiz antes da escola, li meu livro favorito...',
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 120,
                ),
              const SizedBox(height: ZeniSpacing.spaceControl),
              ZeniButton(
                label:
                    mission.approvalMode == MissionApprovalMode.parentApproval
                    ? 'Enviar para aprovação'
                    : 'Concluir missão',
                icon: mission.approvalMode == MissionApprovalMode.parentApproval
                    ? Icons.send_rounded
                    : Icons.check_rounded,
                onPressed: () {
                  final note = _noteController.text.trim();
                  Navigator.of(context).pop(
                    TaskChildDetailResult(
                      action: TaskChildDetailAction.complete,
                      note: note.isEmpty ? null : note,
                    ),
                  );
                },
                role: ZeniButtonRole.primary,
                mode: ZeniVisualMode.kids,
              ),
            ],
            if (status == MissionLogStatus.approved)
              Column(
                children: [
                  if (widget.canUndoCompletion) ...[
                    ZeniButton(
                      label: 'Desfazer conclusão',
                      icon: Icons.undo_rounded,
                      onPressed: () {
                        Navigator.of(context).pop(
                          const TaskChildDetailResult(
                            action: TaskChildDetailAction.undoCompletion,
                          ),
                        );
                      },
                      role: ZeniButtonRole.secondary,
                      mode: ZeniVisualMode.kids,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                  ],
                  ZeniButton(
                    label: 'Fechar',
                    icon: Icons.check_circle_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    role: ZeniButtonRole.secondary,
                    mode: ZeniVisualMode.kids,
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
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: ExcludeSemantics(
          child: ZeniButton(
            label: label,
            icon: Icons.volume_up_rounded,
            onPressed: onPressed,
            role: ZeniButtonRole.tertiary,
            mode: ZeniVisualMode.kids,
          ),
        ),
      ),
    );
  }
}

class _TaskMetadataSurface extends StatelessWidget {
  const _TaskMetadataSurface({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final approval = mission.approvalMode == MissionApprovalMode.parentApproval
        ? const _TaskMetadata(
            key: Key('task-metadata-approval'),
            icon: Icons.verified_user_rounded,
            label: 'Aprovação',
            value: 'Precisa de aprovação',
          )
        : null;

    final stars = _TaskMetadata(
      key: const Key('task-metadata-stars'),
      icon: Icons.star_rounded,
      label: 'Estrelas',
      value: '${mission.stars} estrelas',
      color: context.zeniColors.accentStar,
    );
    final schedule = _TaskMetadata(
      key: const Key('task-metadata-schedule'),
      icon: Icons.schedule_rounded,
      label: 'Horário',
      value: mission.timeGroup.label,
    );

    return ZeniSurface(
      key: const Key('task-metadata-surface'),
      role: ZeniSurfaceRole.grouped,
      mode: ZeniVisualMode.kids,
      child: LayoutBuilder(
        builder: (context, _) {
          if (approval != null && ZeniResponsive.isTablet(context)) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stars),
                const SizedBox(width: ZeniSpacing.spaceControl),
                Expanded(child: schedule),
                const SizedBox(width: ZeniSpacing.spaceControl),
                Expanded(child: approval),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stars),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(child: schedule),
                ],
              ),
              if (approval != null) ...[
                const SizedBox(height: ZeniSpacing.spaceControl),
                approval,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TaskMetadata extends StatelessWidget {
  const _TaskMetadata({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;

    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? colors.textSecondary, size: 22),
            const SizedBox(width: ZeniSpacing.spaceInline),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ZeniTypography.of(context).metadata),
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(value, style: ZeniTypography.of(context).bodyEmphasis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
