// ignore_for_file: curly_braces_in_flow_control_structures, prefer_final_fields

import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../data/models/smart_mission_template.dart';
import '../../data/models/smart_routine_template.dart';
import '../../data/models/smart_suggestion.dart';
import '../../data/repositories/asset_smart_content_repository.dart';
import '../../data/repositories/smart_content_repository.dart';
import '../../domain/family_smart_preferences.dart';
import '../../domain/smart_suggestion_enums.dart';
import '../../domain/smart_suggestion_service.dart';

class SmartBatchMissionDraft {
  const SmartBatchMissionDraft({
    required this.templateId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.stars,
    required this.recurrence,
    required this.customDaysOfWeek,
    required this.timeGroup,
    required this.approvalMode,
  });
  factory SmartBatchMissionDraft.fromTemplate(SmartMissionTemplate template) =>
      SmartBatchMissionDraft(
        templateId: template.id,
        title: template.title,
        description: template.description,
        emoji: '✅',
        stars: template.suggestedStars > 0 ? template.suggestedStars : 10,
        recurrence: template.suggestedRecurrence ?? MissionRecurrence.once,
        customDaysOfWeek: const [],
        timeGroup: template.suggestedTimeGroup ?? MissionTimeGroup.anytime,
        approvalMode: template.requiresApprovalByDefault
            ? MissionApprovalMode.parentApproval
            : MissionApprovalMode.automatic,
      );
  final String templateId, title, description, emoji;
  final int stars;
  final MissionRecurrence recurrence;
  final List<int> customDaysOfWeek;
  final MissionTimeGroup timeGroup;
  final MissionApprovalMode approvalMode;
  SmartBatchMissionDraft withForm(TaskFormResult form) =>
      SmartBatchMissionDraft(
        templateId: templateId,
        title: form.title,
        description: form.description,
        emoji: form.emoji,
        stars: form.stars,
        recurrence: form.recurrence,
        customDaysOfWeek: form.customDaysOfWeek,
        timeGroup: form.timeGroup,
        approvalMode: form.approvalMode,
      );
}

class SmartBatchCreationResult {
  const SmartBatchCreationResult({
    required this.created,
    required this.skipped,
  });
  final int created, skipped;
}

class SmartSuggestionsPage extends StatefulWidget {
  const SmartSuggestionsPage({
    super.key,
    required this.children,
    required this.activeMissions,
    required this.onConfirmBatch,
    this.repository,
  });
  final List<ChildProfile> children;
  final List<Mission> activeMissions;
  final Future<SmartBatchCreationResult> Function(
    List<SmartBatchMissionDraft>,
    List<ChildProfile>,
  )
  onConfirmBatch;
  final SmartContentRepository? repository;
  @override
  State<SmartSuggestionsPage> createState() => _SmartSuggestionsPageState();
}

class _SmartSuggestionsPageState extends State<SmartSuggestionsPage> {
  late final SmartContentRepository _repository =
      widget.repository ?? AssetSmartContentRepository();
  final _selectedChildren = <String>{};
  final _selectedMissions = <String>{};
  final _recipientSectionKey = GlobalKey();
  bool _showChildSelectionError = false;
  Future<_Data>? _future;
  String? _locale;
  @override
  void initState() {
    super.initState();
    if (widget.children.length == 1)
      _selectedChildren.add(widget.children.first.id);
  }

  List<ChildProfile> get _children => widget.children
      .where((child) => _selectedChildren.contains(child.id))
      .toList();
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_future == null || _locale != locale) {
      _locale = locale;
      _future = _load(locale);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sugestões para sua família')),
      body: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: FutureBuilder<_Data>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sugestões para sua família',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: ZeniSpacing.sm),
                  Text(
                    'Escolha missões e revise tudo antes de adicionar.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                  if (widget.children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: ZeniSpacing.xl),
                      child: Text('Adicione uma criança para ver sugestões.'),
                    )
                  else ...[
                    if (widget.children.length > 1) ...[
                      const SizedBox(height: ZeniSpacing.xl),
                      Text(
                        'Para quem?',
                        key: _recipientSectionKey,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (final child in widget.children)
                        CheckboxListTile(
                          key: Key('smart-content-child-${child.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(child.name),
                          value: _selectedChildren.contains(child.id),
                          onChanged: (value) => setState(() {
                            if (value ?? false)
                              _selectedChildren.add(child.id);
                            else
                              _selectedChildren.remove(child.id);
                            if (_selectedChildren.isNotEmpty) {
                              _showChildSelectionError = false;
                            }
                          }),
                        ),
                      if (_showChildSelectionError)
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            margin: const EdgeInsets.only(top: ZeniSpacing.xs),
                            padding: const EdgeInsets.all(ZeniSpacing.md),
                            decoration: BoxDecoration(
                              color: ZeniColors.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Escolha pelo menos uma criança para usar esta rotina.',
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: ZeniSpacing.xl),
                    Text(
                      'Missões sugeridas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = ZeniAdaptiveGrid.columnsForWidth(
                          availableWidth: constraints.maxWidth,
                          windowClass: ZeniResponsive.windowClass(context),
                          minItemWidth: 280,
                        );
                        final itemWidth =
                            (constraints.maxWidth -
                                (columns - 1) * ZeniSpacing.sm) /
                            columns;
                        return Wrap(
                          spacing: ZeniSpacing.sm,
                          runSpacing: ZeniSpacing.sm,
                          children: [
                            for (final suggestion in data.suggestions)
                              SizedBox(
                                width: itemWidth,
                                child: _MissionChoice(
                                  mission: suggestion.mission,
                                  selected: _selectedMissions.contains(
                                    suggestion.mission.id,
                                  ),
                                  onTap: () => setState(() {
                                    if (!_selectedMissions.add(
                                      suggestion.mission.id,
                                    ))
                                      _selectedMissions.remove(
                                        suggestion.mission.id,
                                      );
                                  }),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: ZeniSpacing.xl),
                    Text(
                      'Rotinas prontas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    for (final routine in data.routines.take(4)) ...[
                      ZeniCard(
                        onTap: () => _routine(routine, data.missions),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(routine.title),
                          subtitle: Text(
                            '${routine.description}\n${routine.steps.length} missões',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      ),
                      const SizedBox(height: ZeniSpacing.sm),
                    ],
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _AllRoutinesPage(
                            routines: data.routines,
                            missions: data.missions,
                            onSelect: _routine,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.view_list_rounded),
                      label: const Text('Ver todas as rotinas'),
                    ),
                    const SizedBox(height: ZeniSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ZeniPrimaryButton(
                        label: 'Revisar ${_selectedMissions.length} missões',
                        icon: Icons.fact_check_rounded,
                        onPressed:
                            _selectedMissions.isEmpty || _children.isEmpty
                            ? null
                            : () => _review(data.missions),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_Data> _load(String locale) async {
    final missions = await _repository.getMissions(locale);
    final routines = await _repository.getRoutines(locale);
    final suggestions = widget.children.isEmpty
        ? const <SmartMissionSuggestion>[]
        : (await SmartSuggestionService(_repository).suggest(
            child: widget.children.first,
            goal: SmartSuggestionGoal.routine,
            preferences: const FamilySmartPreferences(),
            activeMissions: widget.activeMissions,
            history: const [],
            localeTag: locale,
          )).whereType<SmartMissionSuggestion>().toList();
    return _Data(missions, routines, suggestions);
  }

  Future<void> _routine(
    SmartRoutineTemplate routine,
    List<SmartMissionTemplate> missions,
  ) async {
    final steps = [
      for (final id in routine.steps)
        ...missions.where((mission) => mission.id == id),
    ];
    final chosen = steps.map((mission) => mission.id).toSet();
    final use = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(routine.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(routine.description),
                const SizedBox(height: ZeniSpacing.md),
                for (final mission in steps)
                  CheckboxListTile(
                    title: Text(mission.title),
                    subtitle: Text(
                      '⭐ ${SmartBatchMissionDraft.fromTemplate(mission).stars} · ${SmartBatchMissionDraft.fromTemplate(mission).timeGroup.label} · ${SmartBatchMissionDraft.fromTemplate(mission).recurrence.label}',
                    ),
                    value: chosen.contains(mission.id),
                    onChanged: (value) => update(() {
                      if (value ?? false)
                        chosen.add(mission.id);
                      else
                        chosen.remove(mission.id);
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: chosen.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Usar esta rotina'),
            ),
          ],
        ),
      ),
    );
    if (use == true && mounted) {
      setState(() {
        _selectedMissions.addAll(chosen);
      });
      if (_children.isNotEmpty) {
        _review(missions);
      } else {
        setState(() => _showChildSelectionError = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _recipientSectionKey.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(
              target,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: 0.15,
            );
          }
        });
      }
    }
  }

  Future<void> _review(List<SmartMissionTemplate> all) async {
    if (_children.isEmpty) return;
    final byId = {for (final mission in all) mission.id: mission};
    final drafts = [
      for (final id in _selectedMissions)
        if (byId[id] != null) SmartBatchMissionDraft.fromTemplate(byId[id]!),
    ];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReviewPage(
          children: _children,
          drafts: drafts,
          active: widget.activeMissions,
          confirm: widget.onConfirmBatch,
        ),
      ),
    );
  }
}

class _AllRoutinesPage extends StatelessWidget {
  const _AllRoutinesPage({
    required this.routines,
    required this.missions,
    required this.onSelect,
  });
  final List<SmartRoutineTemplate> routines;
  final List<SmartMissionTemplate> missions;
  final Future<void> Function(SmartRoutineTemplate, List<SmartMissionTemplate>)
  onSelect;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Todas as rotinas')),
    body: ZeniPageFrame(
      width: ZeniPageWidth.main,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.xl),
        itemCount: routines.length,
        separatorBuilder: (_, _) => const SizedBox(height: ZeniSpacing.sm),
        itemBuilder: (context, index) {
          final routine = routines[index];
          return ZeniCard(
            onTap: () => onSelect(routine, missions),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(routine.title),
              subtitle: Text(
                '${routine.description}\n${routine.steps.length} missões',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      ),
    ),
  );
}

class _MissionChoice extends StatelessWidget {
  const _MissionChoice({
    required this.mission,
    required this.selected,
    required this.onTap,
  });
  final SmartMissionTemplate mission;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ZeniCard(
    onTap: onTap,
    child: Row(
      children: [
        Checkbox(
          key: Key('smart-content-mission-${mission.id}'),
          value: selected,
          onChanged: (_) => onTap(),
        ),
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
                mission.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReviewPage extends StatefulWidget {
  const _ReviewPage({
    required this.children,
    required this.drafts,
    required this.active,
    required this.confirm,
  });
  final List<ChildProfile> children;
  final List<SmartBatchMissionDraft> drafts;
  final List<Mission> active;
  final Future<SmartBatchCreationResult> Function(
    List<SmartBatchMissionDraft>,
    List<ChildProfile>,
  )
  confirm;
  @override
  State<_ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<_ReviewPage> {
  late List<SmartBatchMissionDraft> _drafts = [...widget.drafts];
  bool _saving = false;
  bool _duplicate(SmartBatchMissionDraft draft, ChildProfile child) =>
      widget.active.any(
        (mission) =>
            mission.isActive &&
            mission.childId == child.id &&
            mission.title.trim().toLowerCase() ==
                draft.title.trim().toLowerCase(),
      );
  @override
  Widget build(BuildContext context) {
    final skipped = _drafts.fold(
      0,
      (sum, draft) =>
          sum +
          widget.children.where((child) => _duplicate(draft, child)).length,
    );
    final created = _drafts.length * widget.children.length - skipped;
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar missões')),
      body: SingleChildScrollView(
        key: const Key('smart-content-review-scroll'),
        padding: const EdgeInsets.only(
          top: ZeniSpacing.md,
          bottom: ZeniSpacing.xl,
        ),
        child: ZeniPageFrame(
          width: ZeniPageWidth.main,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.children.isEmpty)
                const Text(
                  'Selecione pelo menos uma criança antes de revisar as missões.',
                )
              else ...[
                Text(
                  'Para: ${widget.children.map((child) => child.name).join(', ')}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ZeniSpacing.lg),
                for (var i = 0; i < _drafts.length; i++) ...[
                  _ReviewCard(
                    draft: _drafts[i],
                    duplicate: widget.children.any(
                      (child) => _duplicate(_drafts[i], child),
                    ),
                    onEdit: () => _edit(i),
                  ),
                  const SizedBox(height: ZeniSpacing.sm),
                ],
                if (skipped > 0)
                  Text(
                    '$skipped missões já ativas serão ignoradas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                const SizedBox(height: ZeniSpacing.xl),
                Text(
                  '${_drafts.length} missões × ${widget.children.length} crianças',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('$created missões serão adicionadas'),
                const SizedBox(height: ZeniSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ZeniPrimaryButton(
                    label: 'Adicionar $created missões',
                    icon: Icons.add_task_rounded,
                    onPressed: _saving || created == 0 ? null : _confirm,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(int index) async {
    final draft = _drafts[index];
    final result = await _taskForm(context, widget.children, draft);
    if (result != null && mounted)
      setState(() => _drafts[index] = draft.withForm(result));
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final result = await widget.confirm(_drafts, widget.children);
    if (!mounted) return;
    ZeniSuccessPopup.show(
      context,
      title: 'Missões adicionadas!',
      message:
          '${result.created} missões adicionadas${result.skipped > 0 ? ' · ${result.skipped} já existiam' : ''}.',
    );
    Navigator.pop(context);
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.draft,
    required this.duplicate,
    required this.onEdit,
  });
  final SmartBatchMissionDraft draft;
  final bool duplicate;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => ZeniCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(draft.title),
      subtitle: Text(
        '⭐ ${draft.stars} · ${draft.timeGroup.label} · ${draft.recurrence.label} · ${draft.approvalMode.label}${duplicate ? '\nJá existe para uma criança selecionada' : ''}',
      ),
      isThreeLine: duplicate,
      trailing: TextButton(onPressed: onEdit, child: const Text('Editar')),
    ),
  );
}

Future<TaskFormResult?> _taskForm(
  BuildContext context,
  List<ChildProfile> children,
  SmartBatchMissionDraft draft,
) {
  final form = TaskFormSheet(
    children: children,
    initialValues: TaskFormInitialValues(
      childId: children.first.id,
      title: draft.title,
      description: draft.description,
      emoji: draft.emoji,
      stars: draft.stars,
      approvalMode: draft.approvalMode,
      recurrence: draft.recurrence,
      customDaysOfWeek: draft.customDaysOfWeek,
      timeGroup: draft.timeGroup,
    ),
  );
  if (ZeniAdaptiveModal.usesDialog(context))
    return showDialog<TaskFormResult>(
      context: context,
      builder: (_) => Dialog(child: ZeniAdaptiveModalFrame(child: form)),
    );
  return showModalBottomSheet<TaskFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: form,
    ),
  );
}

class _Data {
  const _Data(this.missions, this.routines, this.suggestions);
  final List<SmartMissionTemplate> missions;
  final List<SmartRoutineTemplate> routines;
  final List<SmartMissionSuggestion> suggestions;
}
