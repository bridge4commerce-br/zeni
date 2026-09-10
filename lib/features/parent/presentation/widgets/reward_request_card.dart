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
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';

class RewardRequestCard extends StatelessWidget {
  const RewardRequestCard({
    super.key,
    required this.request,
    required this.reward,
    required this.child,
    this.onApprove,
    this.onReject,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.embedded = false,
  });

  final RewardRequest request;
  final Reward? reward;
  final ChildProfile? child;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final rewardTitle = reward?.title ?? 'Mimo';
    final childName = child?.name ?? 'Criança';
    final rewardCost = reward?.cost ?? 0;

    if (embedded) {
      return _EmbeddedRewardRequestRow(
        key: Key('parent-reward-request-${request.id}'),
        rewardTitle: rewardTitle,
        rewardEmoji: reward?.emoji ?? '🎁',
        childName: childName,
        rewardCost: rewardCost,
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
            const _RewardRequestStatusIcon(),
            const SizedBox(width: ZeniSpacing.md),
          ],
          Text(reward?.emoji ?? '🎁', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rewardTitle,
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
            '$rewardCost ⭐',
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
            child: _detailsContainer(dialogContext),
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
          child: _detailsContainer(sheetContext),
        );
      },
    );
  }

  Widget _detailsContainer(BuildContext modalContext) =>
      ZeniModalSheetContainer(
        title: 'Pedido de mimo',
        child: SingleChildScrollView(
          child: _RewardRequestDetails(
            request: request,
            reward: reward,
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
        ),
      );
}

class _EmbeddedRewardRequestRow extends StatelessWidget {
  const _EmbeddedRewardRequestRow({
    super.key,
    required this.rewardTitle,
    required this.rewardEmoji,
    required this.childName,
    required this.rewardCost,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
  });

  final String rewardTitle;
  final String rewardEmoji;
  final String childName;
  final int rewardCost;
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
      label:
          '$rewardTitle, $childName, $rewardCost estrelas, aguardando aprovação',
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
                      onChanged: (value) =>
                          onSelectionChanged?.call(value ?? false),
                    )
                  else
                    SizedBox.square(
                      dimension: 32,
                      child: Center(
                        child: Text(
                          rewardEmoji,
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
                        Text(rewardTitle, style: typography.cardTitle),
                        const SizedBox(height: ZeniSpacing.spaceInlineTight),
                        Text(
                          '$childName · $rewardCost estrelas',
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

class _RewardRequestDetails extends StatelessWidget {
  const _RewardRequestDetails({
    required this.request,
    required this.reward,
    required this.child,
    this.useZeniV2 = false,
    this.onApprove,
    this.onReject,
  });

  final RewardRequest request;
  final Reward? reward;
  final ChildProfile? child;
  final bool useZeniV2;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final rewardTitle = reward?.title ?? 'Mimo';
    final childName = child?.name ?? 'Criança';
    final rewardCost = reward?.cost ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZeniCard(
          child: Row(
            children: [
              Text(reward?.emoji ?? '🎁', style: const TextStyle(fontSize: 42)),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rewardTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      '$childName pediu esse mimo.',
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
        if (reward?.description.isNotEmpty == true) ...[
          const SizedBox(height: ZeniSpacing.lg),
          Text(
            reward!.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
        if (request.note != null && request.note!.isNotEmpty) ...[
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
                  request.note!,
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
              label: request.status.label,
              icon: Icons.hourglass_top_rounded,
              tone: StatusBadgeTone.warning,
            ),
            StatusBadge(
              label: '$rewardCost estrelas',
              icon: Icons.star_rounded,
              tone: StatusBadgeTone.info,
            ),
            if (reward != null)
              StatusBadge(
                label: reward!.renewal.label,
                icon: Icons.refresh_rounded,
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

class _RewardRequestStatusIcon extends StatelessWidget {
  const _RewardRequestStatusIcon();

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
