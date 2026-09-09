import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/zeni_multiline_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/models/mission.dart';

class TaskCompletionResult {
  const TaskCompletionResult({this.note});

  final String? note;
}

Future<TaskCompletionResult?> showTaskCompletionModal({
  required BuildContext context,
  required Mission mission,
}) {
  final content = TaskCompletionSheet(mission: mission);
  if (ZeniAdaptiveModal.usesDialog(context)) {
    return showDialog<TaskCompletionResult>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(ZeniSpacing.xl),
        child: ZeniAdaptiveModalFrame(child: content),
      ),
    );
  }

  return showModalBottomSheet<TaskCompletionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: content,
    ),
  );
}

class TaskCompletionSheet extends StatefulWidget {
  const TaskCompletionSheet({super.key, required this.mission});

  final Mission mission;

  @override
  State<TaskCompletionSheet> createState() => _TaskCompletionSheetState();
}

class _TaskCompletionSheetState extends State<TaskCompletionSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final needsApproval =
        mission.approvalMode == MissionApprovalMode.parentApproval;

    return ZeniModalSheetContainer(
      title: 'Concluir missão',
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + ZeniSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniCard(
              child: Row(
                children: [
                  Text(mission.emoji, style: const TextStyle(fontSize: 36)),
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
            Wrap(
              spacing: ZeniSpacing.sm,
              runSpacing: ZeniSpacing.sm,
              children: [
                StatusBadge(
                  label: '${mission.stars} estrelas',
                  icon: Icons.star_rounded,
                  tone: StatusBadgeTone.info,
                ),
                StatusBadge(
                  label: needsApproval ? 'Aprovação' : 'Automática',
                  icon: needsApproval
                      ? Icons.verified_user_rounded
                      : Icons.flash_on_rounded,
                  tone: needsApproval
                      ? StatusBadgeTone.warning
                      : StatusBadgeTone.success,
                ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniMultilineInput(
              controller: _noteController,
              label: 'Observação opcional',
              hint: 'Ex.: fiz antes da escola, li meu livro favorito...',
              minLines: 2,
              maxLines: 4,
              maxLength: 120,
            ),
            const SizedBox(height: ZeniSpacing.lg),
            Text(
              needsApproval
                  ? 'Essa missão será enviada para aprovação do responsável.'
                  : 'Essa missão será concluída automaticamente.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
            ),
            if (mission.requiresPhoto) ...[
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Foto ainda não disponível nesta versão. Você pode concluir a missão normalmente.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            SizedBox(
              height: ZeniTouchTargets.childPriority,
              child: ZeniPrimaryButton(
                label: needsApproval
                    ? 'Enviar para aprovação'
                    : 'Concluir agora',
                icon: needsApproval
                    ? Icons.send_rounded
                    : Icons.check_circle_rounded,
                onPressed: () {
                  final note = _noteController.text.trim();

                  Navigator.of(
                    context,
                  ).pop(TaskCompletionResult(note: note.isEmpty ? null : note));
                },
              ),
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniSecondaryButton(
              label: 'Cancelar',
              icon: Icons.close_rounded,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
