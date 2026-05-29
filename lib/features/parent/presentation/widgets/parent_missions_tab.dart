import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import 'mission_approval_card.dart';
import 'parent_child_filter_chips.dart';
import 'parent_empty_state_card.dart';
import 'parent_mission_card.dart';

class ParentMissionsTab extends StatefulWidget {
  const ParentMissionsTab({
    super.key,
    required this.activeChildren,
    required this.activeMissions,
    required this.archivedMissions,
    required this.awaitingLogs,
    required this.childById,
    required this.missionById,
    required this.onApproveMission,
    required this.onRejectMission,
    required this.onApproveMissionBatch,
    required this.onRejectMissionBatch,
    required this.onEditMission,
    required this.onArchiveMission,
    required this.onRestoreMission,
  });

  final List<ChildProfile> activeChildren;
  final List<Mission> activeMissions;
  final List<Mission> archivedMissions;
  final List<MissionLog> awaitingLogs;
  final ChildProfile? Function(String childId) childById;
  final Mission? Function(String missionId) missionById;
  final ValueChanged<MissionLog> onApproveMission;
  final ValueChanged<MissionLog> onRejectMission;
  final ValueChanged<List<MissionLog>> onApproveMissionBatch;
  final ValueChanged<List<MissionLog>> onRejectMissionBatch;
  final ValueChanged<Mission> onEditMission;
  final ValueChanged<Mission> onArchiveMission;
  final ValueChanged<Mission> onRestoreMission;

  @override
  State<ParentMissionsTab> createState() => _ParentMissionsTabState();
}

class _ParentMissionsTabState extends State<ParentMissionsTab> {
  bool _isSelecting = false;
  bool _showArchivedMissions = false;
  String? _selectedChildId;
  final Set<String> _selectedLogIds = {};

  @override
  void didUpdateWidget(covariant ParentMissionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    final availableIds = _filteredAwaitingLogs().map((log) => log.id).toSet();
    _selectedLogIds.removeWhere((id) => !availableIds.contains(id));

    if (_selectedLogIds.isEmpty && _filteredAwaitingLogs().isEmpty) {
      _isSelecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaitingLogs = _filteredAwaitingLogs();
    final missions = _filteredActiveMissions();
    final archivedMissions = _filteredArchivedMissions();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Missões', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Filtre por criança para aprovar e acompanhar as missões.',
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
                  'Aprovações pendentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (awaitingLogs.isNotEmpty)
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
          if (_isSelecting && awaitingLogs.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Selecionar todos'),
                ),
                const SizedBox(width: ZeniSpacing.sm),
                Text(
                  '${_selectedLogIds.length} selecionadas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ],
          const SizedBox(height: ZeniSpacing.md),
          if (awaitingLogs.isEmpty)
            const ParentEmptyStateCard(
              emoji: '✨',
              title: 'Nada pendente',
              message:
                  'Quando uma criança enviar uma missão, ela aparecerá aqui.',
            )
          else
            for (final log in awaitingLogs) ...[
              MissionApprovalCard(
                log: log,
                mission: widget.missionById(log.missionId),
                child: widget.childById(log.childId),
                isSelectionMode: _isSelecting,
                isSelected: _selectedLogIds.contains(log.id),
                onSelectionChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLogIds.add(log.id);
                    } else {
                      _selectedLogIds.remove(log.id);
                    }
                  });
                },
                onReject: () => widget.onRejectMission(log),
                onApprove: () => widget.onApproveMission(log),
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          if (_isSelecting && _selectedLogIds.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.md),
            _MissionBatchActionBar(
              selectedCount: _selectedLogIds.length,
              onRejectSelected: _rejectSelected,
              onApproveSelected: _approveSelected,
            ),
          ],
          const SizedBox(height: ZeniSpacing.xl),
          Text('Missões ativas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          if (missions.isEmpty)
            const ParentEmptyStateCard(
              emoji: '✅',
              title: 'Nenhuma missão',
              message: 'Essa criança ainda não tem missões cadastradas.',
            )
          else
            for (final mission in missions) ...[
              ParentMissionCard(
                mission: mission,
                child: widget.childById(mission.childId),
                onEdit: () => widget.onEditMission(mission),
                onDelete: () => widget.onArchiveMission(mission),
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          const SizedBox(height: ZeniSpacing.xl),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _showArchivedMissions = !_showArchivedMissions;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Missões arquivadas (${archivedMissions.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    _showArchivedMissions
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: ZeniColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
          if (_showArchivedMissions) ...[
            const SizedBox(height: ZeniSpacing.md),
            if (archivedMissions.isEmpty)
              const ParentEmptyStateCard(
                emoji: '🗂️',
                title: 'Nenhuma missão arquivada',
                message: 'As missões arquivadas aparecerão aqui.',
              )
            else
              for (final mission in archivedMissions) ...[
                _ArchivedMissionCard(
                  mission: mission,
                  child: widget.childById(mission.childId),
                  onRestore: () => widget.onRestoreMission(mission),
                ),
                const SizedBox(height: ZeniSpacing.md),
              ],
          ],
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  List<MissionLog> _filteredAwaitingLogs() {
    return widget.awaitingLogs.where((log) {
      final child = widget.childById(log.childId);
      if (child?.isActive != true) return false;

      return _selectedChildId == null || log.childId == _selectedChildId;
    }).toList();
  }

  List<Mission> _filteredActiveMissions() {
    return widget.activeMissions.where((mission) {
      final child = widget.childById(mission.childId);
      if (child?.isActive != true) return false;

      return _selectedChildId == null || mission.childId == _selectedChildId;
    }).toList();
  }

  List<Mission> _filteredArchivedMissions() {
    return widget.archivedMissions.where((mission) {
      return _selectedChildId == null || mission.childId == _selectedChildId;
    }).toList();
  }

  void _changeSelectedChild(String? childId) {
    setState(() {
      _selectedChildId = childId;
      _selectedLogIds.clear();
      _isSelecting = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedLogIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      final allIds = _filteredAwaitingLogs().map((log) => log.id).toSet();

      if (_selectedLogIds.length == allIds.length) {
        _selectedLogIds.clear();
      } else {
        _selectedLogIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  List<MissionLog> _selectedLogs() {
    return _filteredAwaitingLogs()
        .where((log) => _selectedLogIds.contains(log.id))
        .toList();
  }

  void _approveSelected() {
    final logs = _selectedLogs();
    if (logs.isEmpty) return;

    widget.onApproveMissionBatch(logs);

    setState(() {
      _selectedLogIds.clear();
      _isSelecting = false;
    });
  }

  void _rejectSelected() {
    final logs = _selectedLogs();
    if (logs.isEmpty) return;

    widget.onRejectMissionBatch(logs);

    setState(() {
      _selectedLogIds.clear();
      _isSelecting = false;
    });
  }
}

class _MissionBatchActionBar extends StatelessWidget {
  const _MissionBatchActionBar({
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
              '$selectedCount selecionadas',
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

class _ArchivedMissionCard extends StatelessWidget {
  const _ArchivedMissionCard({
    required this.mission,
    required this.child,
    required this.onRestore,
  });

  final Mission mission;
  final ChildProfile? child;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(mission.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${child?.name ?? 'Criança'} · ${mission.stars} estrelas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
                const SizedBox(height: ZeniSpacing.sm),
                const StatusBadge(
                  label: 'Arquivada',
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
