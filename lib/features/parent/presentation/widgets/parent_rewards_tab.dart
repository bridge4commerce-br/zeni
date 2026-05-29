import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import 'parent_child_filter_chips.dart';
import 'parent_empty_state_card.dart';
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
    final pendingRequests = _filteredPendingRequests();
    final rewards = _filteredActiveRewards();
    final archivedRewards = _filteredArchivedRewards();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mimos', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Filtre por criança para acompanhar pedidos e recompensas.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ParentChildFilterChips(
            children: widget.activeChildren,
            selectedChildId: _selectedChildId,
            onChanged: _changeSelectedChild,
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedidos pendentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (pendingRequests.isNotEmpty)
                TextButton.icon(
                  onPressed: _toggleSelectionMode,
                  icon: Icon(
                    _isSelecting
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                  ),
                  label: Text(_isSelecting ? 'Cancelar' : 'Selecionar'),
                ),
            ],
          ),
          if (_isSelecting && pendingRequests.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Selecionar todos'),
                ),
                const SizedBox(width: ZeniSpacing.sm),
                Text(
                  '${_selectedRequestIds.length} selecionados',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ],
          const SizedBox(height: ZeniSpacing.md),
          if (pendingRequests.isEmpty)
            const ParentEmptyStateCard(
              emoji: '🎁',
              title: 'Nenhum pedido por enquanto',
              message: 'Quando uma criança pedir um mimo, ele aparecerá aqui.',
            )
          else
            for (final request in pendingRequests) ...[
              RewardRequestCard(
                request: request,
                reward: widget.rewardById(request.rewardId),
                child: widget.childById(request.childId),
                isSelectionMode: _isSelecting,
                isSelected: _selectedRequestIds.contains(request.id),
                onSelectionChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedRequestIds.add(request.id);
                    } else {
                      _selectedRequestIds.remove(request.id);
                    }
                  });
                },
                onReject: () => widget.onRejectRewardRequest(request),
                onApprove: () => widget.onApproveRewardRequest(request),
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          if (_isSelecting && _selectedRequestIds.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.md),
            _RewardBatchActionBar(
              selectedCount: _selectedRequestIds.length,
              onRejectSelected: _rejectSelected,
              onApproveSelected: _approveSelected,
            ),
          ],
          const SizedBox(height: ZeniSpacing.xl),
          Text(
            'Catálogo de mimos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ZeniSpacing.md),
          if (rewards.isEmpty)
            const ParentEmptyStateCard(
              emoji: '🎁',
              title: 'Nenhum mimo',
              message: 'Essa criança ainda não tem mimos disponíveis.',
            )
          else
            for (final reward in rewards) ...[
              ParentRewardCard(
                reward: reward,
                onEdit: () => widget.onEditReward(reward),
                onDelete: () => widget.onArchiveReward(reward),
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          const SizedBox(height: ZeniSpacing.xl),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _showArchivedRewards = !_showArchivedRewards;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mimos arquivados (${archivedRewards.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    _showArchivedRewards
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: ZeniColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
          if (_showArchivedRewards) ...[
            const SizedBox(height: ZeniSpacing.md),
            if (archivedRewards.isEmpty)
              const ParentEmptyStateCard(
                emoji: '🗂️',
                title: 'Nenhum mimo arquivado',
                message: 'Os mimos arquivados aparecerão aqui.',
              )
            else
              for (final reward in archivedRewards) ...[
                _ArchivedRewardCard(
                  reward: reward,
                  onRestore: () => widget.onRestoreReward(reward),
                ),
                const SizedBox(height: ZeniSpacing.md),
              ],
          ],
          const SizedBox(height: 96),
        ],
      ),
    );
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: ZeniColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ZeniSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$selectedCount selecionados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ZeniSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejectSelected,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Rejeitar'),
                  ),
                ),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApproveSelected,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return ZeniCard(
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${reward.cost} estrelas · ${reward.renewal.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
                const SizedBox(height: ZeniSpacing.sm),
                const StatusBadge(
                  label: 'Arquivado',
                  icon: Icons.archive_outlined,
                  tone: StatusBadgeTone.neutral,
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
}
