import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import 'parent_mission_typography.dart';

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
    this.embedded = false,
  });

  final MissionLog log;
  final Mission? mission;
  final ChildProfile? child;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final missionTitle = mission?.title ?? 'Missão';
    final childName = child?.name ?? 'Criança';

    if (embedded) {
      return _EmbeddedApprovalRow(
        key: Key('parent-mission-approval-${log.id}'),
        missionTitle: missionTitle,
        missionEmoji: mission?.emoji ?? '✅',
        childName: childName,
        stars: log.starsAwarded,
        isSelectionMode: isSelectionMode,
        isSelected: isSelected,
        onSelectionChanged: onSelectionChanged,
        onTap: () {
          if (isSelectionMode) {
            onSelectionChanged?.call(!isSelected);
            return;
          }
          _openDetails(context);
        },
      );
    }

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
                  style: ParentMissionTypography.missionTitle(
                    context,
                    base: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '$childName · aguardando aprovação',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ParentMissionTypography.metadata(
                    context,
                    color: ZeniColors.mutedText,
                  ),
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
    if (embedded && ZeniAdaptiveModal.usesDialog(context)) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ZeniAdaptiveModalFrame(
            child: _approvalDetailsContainer(dialogContext),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _approvalDetailsContainer(sheetContext),
        );
      },
    );
  }

  Widget _approvalDetailsContainer(BuildContext modalContext) {
    return ZeniModalSheetContainer(
      title: 'Aprovar missão',
      child: _MissionApprovalDetails(
        log: log,
        mission: mission,
        child: child,
        useZeniV2: embedded,
        onApprove: () {
          Navigator.of(modalContext).pop();
          onApprove?.call();
        },
        onReject: () {
          Navigator.of(modalContext).pop();
          onReject?.call();
        },
      ),
    );
  }
}

class _EmbeddedApprovalRow extends StatelessWidget {
  const _EmbeddedApprovalRow({
    super.key,
    required this.missionTitle,
    required this.missionEmoji,
    required this.childName,
    required this.stars,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
  });

  final String missionTitle;
  final String missionEmoji;
  final String childName;
  final int stars;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return Semantics(
      container: true,
      button: true,
      selected: isSelectionMode ? isSelected : null,
      label: '$missionTitle, $childName, $stars estrelas, aguardando aprovação',
      child: Material(
        color: isSelected ? colors.surfaceSubtle : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeniSpacing.spaceCard,
                vertical: ZeniSpacing.spaceControl,
              ),
              child: Row(
                children: [
                  if (isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        onSelectionChanged?.call(value ?? false);
                      },
                    )
                  else
                    SizedBox.square(
                      dimension: 32,
                      child: Center(
                        child: Text(
                          missionEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(missionTitle, style: typography.cardTitle),
                        const SizedBox(height: ZeniSpacing.spaceInlineTight),
                        Text(
                          '$childName · $stars estrelas',
                          style: typography.metadata,
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode) ...[
                    const SizedBox(width: ZeniSpacing.spaceInline),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionApprovalDetails extends StatelessWidget {
  const _MissionApprovalDetails({
    required this.log,
    required this.mission,
    required this.child,
    this.useZeniV2 = false,
    this.onApprove,
    this.onReject,
  });

  final MissionLog log;
  final Mission? mission;
  final ChildProfile? child;
  final bool useZeniV2;
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
            StatusBadge(
              label: useZeniV2 ? 'Aguardando' : 'Aguardando aprovação',
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
        if (useZeniV2)
          Wrap(
            spacing: ZeniSpacing.spaceControl,
            runSpacing: ZeniSpacing.spaceInline,
            children: [
              ZeniButton(
                label: 'Rejeitar',
                icon: Icons.close_rounded,
                role: ZeniButtonRole.secondary,
                mode: ZeniVisualMode.parent,
                fullWidth: false,
                onPressed: onReject,
              ),
              ZeniButton(
                label: 'Aprovar',
                icon: Icons.check_rounded,
                role: ZeniButtonRole.primary,
                mode: ZeniVisualMode.parent,
                fullWidth: false,
                onPressed: onApprove,
              ),
            ],
          )
        else
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
