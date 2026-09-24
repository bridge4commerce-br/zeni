import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import 'parent_child_filter_chips.dart';
import 'parent_reward_card.dart';
import 'reward_request_card.dart';

class ParentRewardsTab extends StatefulWidget {
  const ParentRewardsTab({
    super.key,
    required this.activeChildren,
    required this.activeRewards,
    required this.archivedRewards,
    required this.pendingRequests,
    required this.childById,
    required this.rewardById,
    required this.onApproveRewardRequest,
    required this.onRejectRewardRequest,
    required this.onApproveRewardRequestBatch,
    required this.onRejectRewardRequestBatch,
    required this.onEditReward,
    required this.onArchiveReward,
    required this.onRestoreReward,
    this.onRefresh,
  });

  final List<ChildProfile> activeChildren;
  final List<Reward> activeRewards;
  final List<Reward> archivedRewards;
  final List<RewardRequest> pendingRequests;
  final ChildProfile? Function(String childId) childById;
  final Reward? Function(String rewardId) rewardById;
  final ValueChanged<RewardRequest> onApproveRewardRequest;
  final ValueChanged<RewardRequest> onRejectRewardRequest;
  final ValueChanged<List<RewardRequest>> onApproveRewardRequestBatch;
  final ValueChanged<List<RewardRequest>> onRejectRewardRequestBatch;
  final ValueChanged<Reward> onEditReward;
  final ValueChanged<Reward> onArchiveReward;
  final ValueChanged<Reward> onRestoreReward;
  final Future<void> Function()? onRefresh;

  @override
  State<ParentRewardsTab> createState() => _ParentRewardsTabState();
}

class _ParentRewardsTabState extends State<ParentRewardsTab> {
  bool _isSelecting = false;
  bool _showArchivedRewards = false;
  String? _selectedChildId;
  final Set<String> _selectedRequestIds = {};

  @override
  void didUpdateWidget(covariant ParentRewardsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    final availableIds = _filteredPendingRequests()
        .map((request) => request.id)
        .toSet();
    _selectedRequestIds.removeWhere((id) => !availableIds.contains(id));

    if (_selectedRequestIds.isEmpty && _filteredPendingRequests().isEmpty) {
      _isSelecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowClass = ZeniResponsive.windowClass(context);
    final pendingRequests = _filteredPendingRequests();
    final rewards = _filteredActiveRewards();
    final archivedRewards = _filteredArchivedRewards();
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final usesSplitLayout =
        pendingRequests.isNotEmpty &&
        (windowClass == ZeniWindowClass.large ||
            (windowClass == ZeniWindowClass.expanded && isLandscape));

    final pendingSection = _PendingRewardsSection(
      requests: pendingRequests,
      childById: widget.childById,
      rewardById: widget.rewardById,
      isSelecting: _isSelecting,
      selectedRequestIds: _selectedRequestIds,
      onToggleSelectionMode: _toggleSelectionMode,
      onSelectAll: _selectAll,
      onSelectionChanged: (requestId, selected) {
        setState(() {
          if (selected) {
            _selectedRequestIds.add(requestId);
          } else {
            _selectedRequestIds.remove(requestId);
          }
        });
      },
      onApprove: widget.onApproveRewardRequest,
      onReject: widget.onRejectRewardRequest,
      onApproveSelected: _approveSelected,
      onRejectSelected: _rejectSelected,
    );
    final catalogSection = _RewardCatalogSection(
      rewards: rewards,
      archivedRewards: archivedRewards,
      showArchivedRewards: _showArchivedRewards,
      onEditReward: widget.onEditReward,
      onArchiveReward: widget.onArchiveReward,
      onRestoreReward: widget.onRestoreReward,
      onToggleArchived: () =>
          setState(() => _showArchivedRewards = !_showArchivedRewards),
    );
    final body = usesSplitLayout
        ? Row(
            key: const Key('parent-rewards-split-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: pendingSection),
              const SizedBox(width: ZeniSpacing.spaceGroup),
              Expanded(flex: 3, child: catalogSection),
            ],
          )
        : Column(
            key: const Key('parent-rewards-single-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pendingSection,
              const SizedBox(height: ZeniSpacing.spaceSection),
              catalogSection,
            ],
          );

    final content = SingleChildScrollView(
      physics: widget.onRefresh == null
          ? null
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceSection,
        bottom:
            ZeniSpacing.spaceCanvas +
            ZeniSpacing.spaceGroup +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ParentRewardsHeader(),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            ParentChildFilterChips(
              children: widget.activeChildren,
              selectedChildId: _selectedChildId,
              onChanged: _changeSelectedChild,
              useZeniV2: true,
            ),
            const SizedBox(height: ZeniSpacing.spaceSection),
            body,
          ],
        ),
      ),
    );

    if (widget.onRefresh == null) {
      return content;
    }

    return RefreshIndicator(onRefresh: widget.onRefresh!, child: content);
  }

  List<RewardRequest> _filteredPendingRequests() {
    return widget.pendingRequests.where((request) {
      final child = widget.childById(request.childId);
      if (child?.isActive != true) return false;

      return _selectedChildId == null || request.childId == _selectedChildId;
    }).toList();
  }

  List<Reward> _filteredActiveRewards() {
    return widget.activeRewards.where((reward) {
      if (reward.childId == null) return true;

      final child = widget.childById(reward.childId!);
      if (child?.isActive != true) return false;

      return _selectedChildId == null || reward.childId == _selectedChildId;
    }).toList();
  }

  List<Reward> _filteredArchivedRewards() {
    return widget.archivedRewards.where((reward) {
      if (reward.childId == null) return true;

      final child = widget.childById(reward.childId!);
      if (child?.isActive != true) return false;

      return _selectedChildId == null || reward.childId == _selectedChildId;
    }).toList();
  }

  void _changeSelectedChild(String? childId) {
    setState(() {
      _selectedChildId = childId;
      _selectedRequestIds.clear();
      _isSelecting = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedRequestIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      final allIds = _filteredPendingRequests()
          .map((request) => request.id)
          .toSet();

      if (_selectedRequestIds.length == allIds.length) {
        _selectedRequestIds.clear();
      } else {
        _selectedRequestIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  List<RewardRequest> _selectedRequests() {
    return _filteredPendingRequests()
        .where((request) => _selectedRequestIds.contains(request.id))
        .toList();
  }

  void _approveSelected() {
    final requests = _selectedRequests();
    if (requests.isEmpty) return;

    widget.onApproveRewardRequestBatch(requests);

    setState(() {
      _selectedRequestIds.clear();
      _isSelecting = false;
    });
  }

  void _rejectSelected() {
    final requests = _selectedRequests();
    if (requests.isEmpty) return;

    widget.onRejectRewardRequestBatch(requests);

    setState(() {
      _selectedRequestIds.clear();
      _isSelecting = false;
    });
  }
}

class _ParentRewardsHeader extends StatelessWidget {
  const _ParentRewardsHeader();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mimos', style: typography.pageTitle),
        const SizedBox(height: ZeniSpacing.spaceInline),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Filtre por criança para acompanhar pedidos e recompensas.',
            style: typography.body,
          ),
        ),
      ],
    );
  }
}

class _PendingRewardsSection extends StatelessWidget {
  const _PendingRewardsSection({
    required this.requests,
    required this.childById,
    required this.rewardById,
    required this.isSelecting,
    required this.selectedRequestIds,
    required this.onToggleSelectionMode,
    required this.onSelectAll,
    required this.onSelectionChanged,
    required this.onApprove,
    required this.onReject,
    required this.onApproveSelected,
    required this.onRejectSelected,
  });

  final List<RewardRequest> requests;
  final ChildProfile? Function(String childId) childById;
  final Reward? Function(String rewardId) rewardById;
  final bool isSelecting;
  final Set<String> selectedRequestIds;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onSelectAll;
  final void Function(String requestId, bool selected) onSelectionChanged;
  final ValueChanged<RewardRequest> onApprove;
  final ValueChanged<RewardRequest> onReject;
  final VoidCallback onApproveSelected;
  final VoidCallback onRejectSelected;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      key: const Key('parent-rewards-pending-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedidos pendentes', style: typography.sectionTitle),
                  if (requests.isNotEmpty) ...[
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      '${requests.length} ${requests.length == 1 ? 'pedido aguarda' : 'pedidos aguardam'} sua decisão.',
                      style: typography.metadata,
                    ),
                  ],
                ],
              ),
            ),
            if (requests.isNotEmpty) ...[
              const SizedBox(width: ZeniSpacing.spaceInline),
              ZeniButton(
                label: isSelecting ? 'Cancelar' : 'Selecionar',
                icon: isSelecting
                    ? Icons.close_rounded
                    : Icons.checklist_rounded,
                role: ZeniButtonRole.tertiary,
                mode: ZeniVisualMode.parent,
                fullWidth: false,
                onPressed: onToggleSelectionMode,
              ),
            ],
          ],
        ),
        SizedBox(
          height: requests.isEmpty
              ? ZeniSpacing.spaceInline
              : ZeniSpacing.spaceCard,
        ),
        if (requests.isEmpty)
          const _RewardEmptyState(
            icon: Icons.hourglass_empty_rounded,
            title: 'Nada pendente agora',
            message: 'Quando uma criança pedir um mimo, ele aparecerá aqui.',
            compact: true,
          )
        else
          ZeniSurface(
            key: const Key('parent-rewards-pending-list'),
            role: ZeniSurfaceRole.highlight,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ZeniSpacing.spaceCard,
                      ZeniSpacing.spaceInline,
                      ZeniSpacing.spaceCard,
                      ZeniSpacing.spaceInline,
                    ),
                    child: Wrap(
                      spacing: ZeniSpacing.spaceControl,
                      runSpacing: ZeniSpacing.spaceInline,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ZeniButton(
                          label: 'Selecionar todos',
                          role: ZeniButtonRole.tertiary,
                          mode: ZeniVisualMode.parent,
                          fullWidth: false,
                          onPressed: onSelectAll,
                        ),
                        Text(
                          '${selectedRequestIds.length} selecionados',
                          style: typography.metadata,
                        ),
                      ],
                    ),
                  ),
                for (var index = 0; index < requests.length; index++) ...[
                  RewardRequestCard(
                    request: requests[index],
                    reward: rewardById(requests[index].rewardId),
                    child: childById(requests[index].childId),
                    embedded: true,
                    isSelectionMode: isSelecting,
                    isSelected: selectedRequestIds.contains(requests[index].id),
                    onSelectionChanged: (selected) =>
                        onSelectionChanged(requests[index].id, selected),
                    onApprove: () => onApprove(requests[index]),
                    onReject: () => onReject(requests[index]),
                  ),
                  if (index < requests.length - 1) const _RewardDivider(),
                ],
                if (isSelecting && selectedRequestIds.isNotEmpty) ...[
                  const _RewardDivider(),
                  _RewardBatchActionBar(
                    selectedCount: selectedRequestIds.length,
                    onRejectSelected: onRejectSelected,
                    onApproveSelected: onApproveSelected,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RewardCatalogSection extends StatelessWidget {
  const _RewardCatalogSection({
    required this.rewards,
    required this.archivedRewards,
    required this.showArchivedRewards,
    required this.onEditReward,
    required this.onArchiveReward,
    required this.onRestoreReward,
    required this.onToggleArchived,
  });

  final List<Reward> rewards;
  final List<Reward> archivedRewards;
  final bool showArchivedRewards;
  final ValueChanged<Reward> onEditReward;
  final ValueChanged<Reward> onArchiveReward;
  final ValueChanged<Reward> onRestoreReward;
  final VoidCallback onToggleArchived;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Column(
      key: const Key('parent-rewards-catalog-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catálogo de mimos', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceInlineTight),
        Text(
          '${rewards.length} ${rewards.length == 1 ? 'mimo ativo' : 'mimos ativos'}',
          style: typography.metadata,
        ),
        const SizedBox(height: ZeniSpacing.spaceCard),
        if (rewards.isEmpty)
          const _RewardEmptyState(
            icon: Icons.card_giftcard_outlined,
            title: 'Nenhum mimo',
            message: 'Essa criança ainda não tem mimos disponíveis.',
          )
        else
          ZeniSurface(
            key: const Key('parent-rewards-active-list'),
            role: ZeniSurfaceRole.grouped,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < rewards.length; index++) ...[
                  ParentRewardCard(
                    reward: rewards[index],
                    onEdit: () => onEditReward(rewards[index]),
                    onDelete: () => onArchiveReward(rewards[index]),
                  ),
                  if (index < rewards.length - 1) const _RewardDivider(),
                ],
              ],
            ),
          ),
        const SizedBox(height: ZeniSpacing.spaceSection),
        Semantics(
          button: true,
          expanded: showArchivedRewards,
          child: InkWell(
            key: const Key('parent-rewards-archived-toggle'),
            onTap: onToggleArchived,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mimos arquivados (${archivedRewards.length})',
                      style: typography.cardTitle,
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceInline),
                  Icon(
                    showArchivedRewards
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colors.actionPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showArchivedRewards) ...[
          const SizedBox(height: ZeniSpacing.spaceCard),
          if (archivedRewards.isEmpty)
            const _RewardEmptyState(
              icon: Icons.archive_outlined,
              title: 'Nenhum mimo arquivado',
              message: 'Os mimos arquivados aparecerão aqui.',
            )
          else
            ZeniSurface(
              key: const Key('parent-rewards-archived-list'),
              role: ZeniSurfaceRole.grouped,
              mode: ZeniVisualMode.parent,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < archivedRewards.length;
                    index++
                  ) ...[
                    _ArchivedRewardCard(
                      reward: archivedRewards[index],
                      onRestore: () => onRestoreReward(archivedRewards[index]),
                    ),
                    if (index < archivedRewards.length - 1)
                      const _RewardDivider(),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _RewardEmptyState extends StatelessWidget {
  const _RewardEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return ZeniSurface(
      role: ZeniSurfaceRole.plain,
      mode: ZeniVisualMode.parent,
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.cardTitle),
                if (!compact) ...[
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(message, style: typography.metadata),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBatchActionBar extends StatelessWidget {
  const _RewardBatchActionBar({
    required this.selectedCount,
    required this.onRejectSelected,
    required this.onApproveSelected,
  });

  final int selectedCount;
  final VoidCallback onRejectSelected;
  final VoidCallback onApproveSelected;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Padding(
      key: const Key('parent-rewards-batch-actions'),
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      child: Wrap(
        spacing: ZeniSpacing.spaceControl,
        runSpacing: ZeniSpacing.spaceInline,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$selectedCount selecionados', style: typography.bodyEmphasis),
          ZeniButton(
            label: 'Rejeitar',
            icon: Icons.close_rounded,
            role: ZeniButtonRole.secondary,
            mode: ZeniVisualMode.parent,
            fullWidth: false,
            onPressed: onRejectSelected,
          ),
          ZeniButton(
            label: 'Aprovar',
            icon: Icons.check_rounded,
            role: ZeniButtonRole.primary,
            mode: ZeniVisualMode.parent,
            fullWidth: false,
            onPressed: onApproveSelected,
          ),
        ],
      ),
    );
  }
}

class _ArchivedRewardCard extends StatelessWidget {
  const _ArchivedRewardCard({required this.reward, required this.onRestore});

  final Reward reward;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Semantics(
      container: true,
      label: '${reward.title}, ${reward.cost} estrelas, arquivado',
      child: Padding(
        key: Key('parent-archived-reward-${reward.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.spaceCard,
          vertical: ZeniSpacing.spaceControl,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: Center(
                child: Text(reward.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.title, style: typography.cardTitle),
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(
                    '${reward.cost} estrelas · ${reward.renewal.label}',
                    style: typography.metadata,
                  ),
                  const SizedBox(height: ZeniSpacing.spaceInline),
                  const StatusBadge(
                    label: 'Arquivado',
                    icon: Icons.archive_outlined,
                    tone: StatusBadgeTone.neutral,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            IconButton(
              tooltip: 'Restaurar mimo',
              onPressed: onRestore,
              color: colors.actionPrimary,
              icon: const Icon(Icons.restore_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardDivider extends StatelessWidget {
  const _RewardDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: ZeniSpacing.spaceCard,
    endIndent: ZeniSpacing.spaceCard,
    color: context.zeniColors.borderSubtle,
  );
}
