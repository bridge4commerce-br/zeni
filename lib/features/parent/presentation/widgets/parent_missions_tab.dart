import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_choice_chip.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../smart_content/presentation/pages/smart_suggestions_page.dart';
import '../../../smart_content/data/repositories/smart_content_repository.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import 'mission_approval_card.dart';
import 'parent_child_filter_chips.dart';
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
    required this.onConfirmSuggestedMissions,
    this.onDiscoveringChanged,
    this.smartContentRepository,
    this.onRefresh,
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
  final Future<SmartBatchCreationResult> Function(
    List<SmartBatchMissionDraft>,
    List<ChildProfile>,
  )
  onConfirmSuggestedMissions;
  final ValueChanged<bool>? onDiscoveringChanged;
  final SmartContentRepository? smartContentRepository;
  final Future<void> Function()? onRefresh;

  @override
  State<ParentMissionsTab> createState() => _ParentMissionsTabState();
}

class _ParentMissionsTabState extends State<ParentMissionsTab> {
  bool _isSelecting = false;
  bool _showArchivedMissions = false;
  bool _isDiscovering = false;
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
    if (_isDiscovering) return _buildDiscovery(context);
    final windowClass = ZeniResponsive.windowClass(context);
    final awaitingLogs = _filteredAwaitingLogs();
    final missions = _filteredActiveMissions();
    final archivedMissions = _filteredArchivedMissions();
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final usesSplitLayout =
        awaitingLogs.isNotEmpty &&
        (windowClass == ZeniWindowClass.large ||
            (windowClass == ZeniWindowClass.expanded && isLandscape));

    final pendingSection = _PendingMissionsSection(
      logs: awaitingLogs,
      missionById: widget.missionById,
      childById: widget.childById,
      isSelecting: _isSelecting,
      selectedLogIds: _selectedLogIds,
      onToggleSelectionMode: _toggleSelectionMode,
      onSelectAll: _selectAll,
      onSelectionChanged: _changeLogSelection,
      onApprove: widget.onApproveMission,
      onReject: widget.onRejectMission,
      onApproveSelected: _approveSelected,
      onRejectSelected: _rejectSelected,
    );
    final catalogSection = _MissionCatalogSection(
      missions: missions,
      archivedMissions: archivedMissions,
      childById: widget.childById,
      showArchivedMissions: _showArchivedMissions,
      onEditMission: widget.onEditMission,
      onArchiveMission: widget.onArchiveMission,
      onRestoreMission: widget.onRestoreMission,
      onToggleArchived: _toggleArchivedMissions,
    );

    final body = usesSplitLayout
        ? Row(
            key: const Key('parent-missions-split-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: pendingSection),
              const SizedBox(width: ZeniSpacing.spaceGroup),
              Expanded(flex: 3, child: catalogSection),
            ],
          )
        : Column(
            key: const Key('parent-missions-single-layout'),
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
            _ParentMissionsContextHeader(
              isDiscovering: false,
              onContextChanged: _changeContext,
              children: widget.activeChildren,
              selectedChildId: _selectedChildId,
              onChildChanged: _changeSelectedChild,
            ),
            const SizedBox(height: ZeniSpacing.spaceSection),
            body,
          ],
        ),
      ),
    );

    if (widget.onRefresh == null) return content;
    return RefreshIndicator(onRefresh: widget.onRefresh!, child: content);
  }

  Widget _buildDiscovery(BuildContext context) => SmartSuggestionsContent(
    children: widget.activeChildren,
    activeMissions: widget.activeMissions,
    onConfirmBatch: widget.onConfirmSuggestedMissions,
    repository: widget.smartContentRepository,
    embedded: true,
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ParentMissionsContextHeader(
          isDiscovering: true,
          onContextChanged: _changeContext,
          children: widget.activeChildren,
          selectedChildId: _selectedChildId,
          onChildChanged: _changeSelectedChild,
        ),
        const SizedBox(height: ZeniSpacing.spaceControl),
        Text(
          'Escolha missões e rotinas para revisar antes de adicionar.',
          style: ZeniTypography.of(context).body,
        ),
      ],
    ),
  );

  void _changeContext(bool discovering) {
    if (_isDiscovering == discovering) return;
    setState(() => _isDiscovering = discovering);
    widget.onDiscoveringChanged?.call(discovering);
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

  void _toggleArchivedMissions() {
    setState(() {
      _showArchivedMissions = !_showArchivedMissions;
    });
  }

  void _changeLogSelection(String logId, bool selected) {
    setState(() {
      if (selected) {
        _selectedLogIds.add(logId);
      } else {
        _selectedLogIds.remove(logId);
      }
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

class _ParentMissionsHeader extends StatelessWidget {
  const _ParentMissionsHeader();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      key: const Key('parent-missions-page-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Missões', style: typography.pageTitle),
        const SizedBox(height: ZeniSpacing.spaceInline),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Aprove, organize e acompanhe as missões da família.',
            style: typography.body,
          ),
        ),
      ],
    );
  }
}

class _ParentMissionsContextHeader extends StatelessWidget {
  const _ParentMissionsContextHeader({
    required this.isDiscovering,
    required this.onContextChanged,
    required this.children,
    required this.selectedChildId,
    required this.onChildChanged,
  });

  final bool isDiscovering;
  final ValueChanged<bool> onContextChanged;
  final List<ChildProfile> children;
  final String? selectedChildId;
  final ValueChanged<String?> onChildChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('parent-missions-context-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ParentMissionsHeader(),
        const SizedBox(height: ZeniSpacing.spaceControl),
        SizedBox(
          width: double.infinity,
          child: _MissionContextSelector(
            isDiscovering: isDiscovering,
            onChanged: onContextChanged,
          ),
        ),
        if (!isDiscovering) ...[
          const SizedBox(height: ZeniSpacing.spaceControl),
          SizedBox(
            width: double.infinity,
            child: ParentChildFilterChips(
              children: children,
              selectedChildId: selectedChildId,
              onChanged: onChildChanged,
              useZeniV2: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingMissionsSection extends StatelessWidget {
  const _PendingMissionsSection({
    required this.logs,
    required this.missionById,
    required this.childById,
    required this.isSelecting,
    required this.selectedLogIds,
    required this.onToggleSelectionMode,
    required this.onSelectAll,
    required this.onSelectionChanged,
    required this.onApprove,
    required this.onReject,
    required this.onApproveSelected,
    required this.onRejectSelected,
  });

  final List<MissionLog> logs;
  final Mission? Function(String missionId) missionById;
  final ChildProfile? Function(String childId) childById;
  final bool isSelecting;
  final Set<String> selectedLogIds;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onSelectAll;
  final void Function(String logId, bool selected) onSelectionChanged;
  final ValueChanged<MissionLog> onApprove;
  final ValueChanged<MissionLog> onReject;
  final VoidCallback onApproveSelected;
  final VoidCallback onRejectSelected;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      key: const Key('parent-missions-pending-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aprovações pendentes', style: typography.sectionTitle),
                  if (logs.isNotEmpty) ...[
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      '${logs.length} ${logs.length == 1 ? 'missão aguarda' : 'missões aguardam'} sua decisão.',
                      style: typography.metadata,
                    ),
                  ],
                ],
              ),
            ),
            if (logs.isNotEmpty) ...[
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
          height: logs.isEmpty
              ? ZeniSpacing.spaceInline
              : ZeniSpacing.spaceCard,
        ),
        if (logs.isEmpty)
          const _PendingMissionsEmptyNotice()
        else
          ZeniSurface(
            key: const Key('parent-missions-pending-list'),
            role: ZeniSurfaceRole.highlight,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (isSelecting) ...[
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
                          label: 'Selecionar todas',
                          role: ZeniButtonRole.tertiary,
                          mode: ZeniVisualMode.parent,
                          fullWidth: false,
                          onPressed: onSelectAll,
                        ),
                        Text(
                          '${selectedLogIds.length} selecionadas',
                          style: typography.metadata,
                        ),
                      ],
                    ),
                  ),
                  const _MissionDivider(),
                ],
                for (var index = 0; index < logs.length; index++) ...[
                  MissionApprovalCard(
                    log: logs[index],
                    mission: missionById(logs[index].missionId),
                    child: childById(logs[index].childId),
                    isSelectionMode: isSelecting,
                    isSelected: selectedLogIds.contains(logs[index].id),
                    embedded: true,
                    onSelectionChanged: (selected) =>
                        onSelectionChanged(logs[index].id, selected),
                    onReject: () => onReject(logs[index]),
                    onApprove: () => onApprove(logs[index]),
                  ),
                  if (index < logs.length - 1) const _MissionDivider(),
                ],
                if (isSelecting && selectedLogIds.isNotEmpty) ...[
                  const _MissionDivider(),
                  _MissionBatchActionBar(
                    selectedCount: selectedLogIds.length,
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

class _PendingMissionsEmptyNotice extends StatelessWidget {
  const _PendingMissionsEmptyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Semantics(
      label: 'Aprovações pendentes: nada pendente agora',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: colors.actionPrimary,
              ),
              const SizedBox(width: ZeniSpacing.spaceInline),
              Text('Nada pendente agora', style: typography.bodyEmphasis),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCatalogSection extends StatelessWidget {
  const _MissionCatalogSection({
    required this.missions,
    required this.archivedMissions,
    required this.childById,
    required this.showArchivedMissions,
    required this.onEditMission,
    required this.onArchiveMission,
    required this.onRestoreMission,
    required this.onToggleArchived,
  });

  final List<Mission> missions;
  final List<Mission> archivedMissions;
  final ChildProfile? Function(String childId) childById;
  final bool showArchivedMissions;
  final ValueChanged<Mission> onEditMission;
  final ValueChanged<Mission> onArchiveMission;
  final ValueChanged<Mission> onRestoreMission;
  final VoidCallback onToggleArchived;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('parent-missions-catalog-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActiveMissionsSection(
          missions: missions,
          childById: childById,
          onEditMission: onEditMission,
          onArchiveMission: onArchiveMission,
        ),
        _ArchivedMissionsSection(
          missions: archivedMissions,
          childById: childById,
          isExpanded: showArchivedMissions,
          onToggle: onToggleArchived,
          onRestoreMission: onRestoreMission,
        ),
      ],
    );
  }
}

class _ActiveMissionsSection extends StatelessWidget {
  const _ActiveMissionsSection({
    required this.missions,
    required this.childById,
    required this.onEditMission,
    required this.onArchiveMission,
  });

  final List<Mission> missions;
  final ChildProfile? Function(String childId) childById;
  final ValueChanged<Mission> onEditMission;
  final ValueChanged<Mission> onArchiveMission;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Missões ativas', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceInlineTight),
        Text(
          '${missions.length} ${missions.length == 1 ? 'missão ativa' : 'missões ativas'}',
          style: typography.metadata,
        ),
        const SizedBox(height: ZeniSpacing.spaceCard),
        if (missions.isEmpty)
          const _MissionEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Nenhuma missão',
            message: 'Essa criança ainda não tem missões cadastradas.',
          )
        else
          ZeniSurface(
            key: const Key('parent-missions-active-list'),
            role: ZeniSurfaceRole.grouped,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < missions.length; index++) ...[
                  ParentMissionCard(
                    mission: missions[index],
                    child: childById(missions[index].childId),
                    onEdit: () => onEditMission(missions[index]),
                    onDelete: () => onArchiveMission(missions[index]),
                  ),
                  if (index < missions.length - 1) const _MissionDivider(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MissionContextSelector extends StatelessWidget {
  const _MissionContextSelector({
    required this.isDiscovering,
    required this.onChanged,
  });

  final bool isDiscovering;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact =
        ZeniResponsive.windowClass(context) == ZeniWindowClass.compact;
    final family = ZeniChoiceChip(
      key: const Key('parent-missions-mode-family'),
      label: 'Missões da família',
      selected: !isDiscovering,
      onSelected: (_) => onChanged(false),
      mode: ZeniVisualMode.parent,
    );
    final suggestions = ZeniChoiceChip(
      key: const Key('parent-missions-mode-suggestions'),
      label: 'Sugestões',
      selected: isDiscovering,
      onSelected: (_) => onChanged(true),
      mode: ZeniVisualMode.parent,
      icon: isCompact ? null : const Icon(Icons.auto_awesome_rounded),
    );

    if (isCompact) {
      return SingleChildScrollView(
        key: const Key('parent-missions-context-selector'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            family,
            const SizedBox(width: ZeniSpacing.spaceInline),
            suggestions,
          ],
        ),
      );
    }

    return Row(
      key: const Key('parent-missions-context-selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        family,
        const SizedBox(width: ZeniSpacing.spaceInline),
        suggestions,
      ],
    );
  }
}

class _ArchivedMissionsSection extends StatelessWidget {
  const _ArchivedMissionsSection({
    required this.missions,
    required this.childById,
    required this.isExpanded,
    required this.onToggle,
    required this.onRestoreMission,
  });

  final List<Mission> missions;
  final ChildProfile? Function(String childId) childById;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<Mission> onRestoreMission;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: isExpanded,
          child: InkWell(
            key: const Key('parent-missions-archived-toggle'),
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Missões arquivadas (${missions.length})',
                      style: typography.cardTitle,
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceInline),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colors.actionPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: ZeniSpacing.spaceCard),
          if (missions.isEmpty)
            const _MissionEmptyState(
              icon: Icons.archive_outlined,
              title: 'Nenhuma missão arquivada',
              message: 'As missões arquivadas aparecerão aqui.',
            )
          else
            ZeniSurface(
              key: const Key('parent-missions-archived-list'),
              role: ZeniSurfaceRole.grouped,
              mode: ZeniVisualMode.parent,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < missions.length; index++) ...[
                    _ArchivedMissionRow(
                      mission: missions[index],
                      child: childById(missions[index].childId),
                      onRestore: () => onRestoreMission(missions[index]),
                    ),
                    if (index < missions.length - 1) const _MissionDivider(),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ArchivedMissionRow extends StatelessWidget {
  const _ArchivedMissionRow({
    required this.mission,
    required this.child,
    required this.onRestore,
  });

  final Mission mission;
  final ChildProfile? child;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Semantics(
      container: true,
      label:
          '${mission.title}, ${child?.name ?? 'Criança'}, ${mission.stars} estrelas, arquivada',
      child: Padding(
        key: Key('parent-archived-mission-${mission.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.spaceCard,
          vertical: ZeniSpacing.spaceControl,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 32,
              child: Center(
                child: Text(
                  mission.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mission.title, style: typography.cardTitle),
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(
                    '${child?.name ?? 'Criança'} · ${mission.stars} estrelas',
                    style: typography.metadata,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            IconButton(
              tooltip: 'Restaurar missão',
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
    final typography = ZeniTypography.of(context);
    return Padding(
      key: const Key('parent-missions-batch-actions'),
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$selectedCount selecionadas', style: typography.bodyEmphasis),
          const SizedBox(height: ZeniSpacing.spaceControl),
          Wrap(
            spacing: ZeniSpacing.spaceControl,
            runSpacing: ZeniSpacing.spaceInline,
            children: [
              ZeniButton(
                label: 'Rejeitar',
                icon: Icons.close_rounded,
                role: ZeniButtonRole.destructive,
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
        ],
      ),
    );
  }
}

class _MissionEmptyState extends StatelessWidget {
  const _MissionEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeniSpacing.spaceCard,
        vertical: ZeniSpacing.spaceGroup,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textSecondary),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text(message, style: typography.metadata),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionDivider extends StatelessWidget {
  const _MissionDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: ZeniSpacing.spaceCard,
    endIndent: ZeniSpacing.spaceCard,
    color: context.zeniColors.borderSubtle,
  );
}
