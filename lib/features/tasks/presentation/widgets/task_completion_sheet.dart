import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ZeniColors.mutedText,
                        ),
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
                label: mission.approvalMode.label,
                icon: needsApproval
                    ? Icons.verified_user_rounded
                    : Icons.flash_on_rounded,
                tone: needsApproval
                    ? StatusBadgeTone.warning
                    : StatusBadgeTone.success,
              ),
              if (mission.requiresPhoto)
                const StatusBadge(
                  label: 'Foto recomendada',
                  icon: Icons.photo_camera_rounded,
                  tone: StatusBadgeTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          if (mission.requiresPhoto) ...[
            _PhotoPlaceholder(missionTitle: mission.title),
            const SizedBox(height: ZeniSpacing.lg),
          ],
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
          const SizedBox(height: ZeniSpacing.xl),
          ZeniPrimaryButton(
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
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.missionTitle});

  final String missionTitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Adicionar foto para comprovar a missão $missionTitle',
      button: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ZeniSpacing.lg),
        decoration: BoxDecoration(
          color: ZeniColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ZeniColors.primary.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              color: ZeniColors.primaryDark,
              size: 34,
            ),
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              'Foto da missão',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'A câmera será conectada em uma próxima etapa.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
