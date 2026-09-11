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
    final typography = ZeniTypography.of(context);

    return ZeniModalSheetContainer(
      title: 'Concluir missão',
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + ZeniSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniSurface(
              role: ZeniSurfaceRole.highlight,
              mode: ZeniVisualMode.kids,
              child: Row(
                children: [
                  Text(mission.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: ZeniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission.title, style: typography.cardTitle),
                        const SizedBox(height: ZeniSpacing.xs),
                        Text(mission.description, style: typography.metadata),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniSurface(
              role: ZeniSurfaceRole.grouped,
              mode: ZeniVisualMode.kids,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompletionMetadata(
                    icon: Icons.star_rounded,
                    label: '${mission.stars} estrelas',
                    color: context.zeniColors.accentStar,
                  ),
                  const SizedBox(height: ZeniSpacing.spaceControl),
                  _CompletionMetadata(
                    icon: needsApproval
                        ? Icons.verified_user_rounded
                        : Icons.flash_on_rounded,
                    label: needsApproval
                        ? 'Precisa de aprovação'
                        : 'Automática',
                  ),
                ],
              ),
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
              style: typography.metadata,
            ),
            if (mission.requiresPhoto) ...[
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Foto ainda não disponível nesta versão. Você pode concluir a missão normalmente.',
                style: typography.metadata,
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            ZeniButton(
              label: needsApproval ? 'Enviar para aprovação' : 'Concluir agora',
              icon: needsApproval
                  ? Icons.send_rounded
                  : Icons.check_circle_rounded,
              onPressed: () {
                final note = _noteController.text.trim();

                Navigator.of(
                  context,
                ).pop(TaskCompletionResult(note: note.isEmpty ? null : note));
              },
              role: ZeniButtonRole.primary,
              mode: ZeniVisualMode.kids,
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniButton(
              label: 'Cancelar',
              icon: Icons.close_rounded,
              onPressed: () {
                Navigator.of(context).pop();
              },
              role: ZeniButtonRole.secondary,
              mode: ZeniVisualMode.kids,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionMetadata extends StatelessWidget {
  const _CompletionMetadata({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? context.zeniColors.textSecondary),
        const SizedBox(width: ZeniSpacing.spaceInline),
        Expanded(
          child: Text(label, style: ZeniTypography.of(context).metadata),
        ),
      ],
    );
  }
}
