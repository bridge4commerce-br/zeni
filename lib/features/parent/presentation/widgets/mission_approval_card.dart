import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';

class MissionApprovalCard extends StatelessWidget {
  const MissionApprovalCard({
    super.key,
    required this.log,
    required this.mission,
    required this.child,
    this.onApprove,
    this.onReject,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final MissionLog log;
  final Mission? mission;
  final ChildProfile? child;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final missionTitle = mission?.title ?? 'Missão';
    final childName = child?.name ?? 'Criança';

    return ZeniCard(
      onTap: () {
        if (isSelectionMode) {
          onSelectionChanged?.call(!isSelected);
          return;
        }

        _openDetails(context);
      },
      child: Row(
        children: [
          if (isSelectionMode) ...[
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                onSelectionChanged?.call(value ?? false);
              },
            ),
            const SizedBox(width: ZeniSpacing.sm),
          ] else ...[
            const _ApprovalStatusIcon(),
            const SizedBox(width: ZeniSpacing.md),
          ],
          Text(mission?.emoji ?? '✅', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '$childName · aguardando aprovação',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Text(
            '+${log.starsAwarded} ⭐',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ZeniColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ZeniModalSheetContainer(
            title: 'Aprovar missão',
            child: SingleChildScrollView(
              child: _MissionApprovalDetails(
                log: log,
                mission: mission,
                child: child,
                onApprove: () {
                  Navigator.of(sheetContext).pop();
                  onApprove?.call();
                },
                onReject: () {
                  Navigator.of(sheetContext).pop();
                  onReject?.call();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionApprovalDetails extends StatelessWidget {
  const _MissionApprovalDetails({
    required this.log,
    required this.mission,
    required this.child,
    this.onApprove,
    this.onReject,
  });

  final MissionLog log;
  final Mission? mission;
  final ChildProfile? child;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final missionTitle = mission?.title ?? 'Missão';
    final childName = child?.name ?? 'Criança';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZeniCard(
          child: Row(
            children: [
              Text(mission?.emoji ?? '✅', style: const TextStyle(fontSize: 42)),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      missionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      '$childName enviou essa missão.',
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
        if (mission?.description.isNotEmpty == true) ...[
          const SizedBox(height: ZeniSpacing.lg),
          Text(
            mission!.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
        if (log.note != null && log.note!.isNotEmpty) ...[
          const SizedBox(height: ZeniSpacing.lg),
          ZeniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Observação da criança',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  log.note!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: ZeniSpacing.lg),
        Wrap(
          spacing: ZeniSpacing.sm,
          runSpacing: ZeniSpacing.sm,
          children: [
            const StatusBadge(
              label: 'Aguardando aprovação',
              icon: Icons.hourglass_top_rounded,
              tone: StatusBadgeTone.warning,
            ),
            StatusBadge(
              label: '${log.starsAwarded} estrelas',
              icon: Icons.star_rounded,
              tone: StatusBadgeTone.info,
            ),
            if (mission != null)
              StatusBadge(
                label: mission!.timeGroup.label,
                icon: Icons.schedule_rounded,
                tone: StatusBadgeTone.neutral,
              ),
            if (mission?.requiresPhoto == true)
              const StatusBadge(
                label: 'Foto esperada',
                icon: Icons.photo_camera_rounded,
                tone: StatusBadgeTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: ZeniSpacing.xl),
        Row(
          children: [
            Expanded(
              child: ZeniSecondaryButton(
                label: 'Rejeitar',
                icon: Icons.close_rounded,
                onPressed: onReject,
              ),
            ),
            const SizedBox(width: ZeniSpacing.md),
            Expanded(
              child: ZeniPrimaryButton(
                label: 'Aprovar',
                icon: Icons.check_rounded,
                onPressed: onApprove,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApprovalStatusIcon extends StatelessWidget {
  const _ApprovalStatusIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: ZeniColors.warning.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.hourglass_top_rounded,
        color: ZeniColors.warning,
        size: 24,
      ),
    );
  }
}
