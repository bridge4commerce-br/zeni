import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../tasks/data/models/mission.dart';
import '../../data/models/smart_mission_template.dart';
import '../../data/models/smart_routine_template.dart';
import '../../data/models/smart_suggestion.dart';
import '../../data/repositories/asset_smart_content_repository.dart';
import '../../domain/family_smart_preferences.dart';
import '../../domain/smart_suggestion_enums.dart';
import '../../domain/smart_suggestion_service.dart';

class SmartSuggestionsPage extends StatefulWidget {
  const SmartSuggestionsPage({
    super.key,
    required this.children,
    required this.activeMissions,
    required this.onSelectMission,
  });

  final List<ChildProfile> children;
  final List<Mission> activeMissions;
  final Future<void> Function(SmartMissionTemplate mission, ChildProfile child)
  onSelectMission;

  @override
  State<SmartSuggestionsPage> createState() => _SmartSuggestionsPageState();
}

class _SmartSuggestionsPageState extends State<SmartSuggestionsPage> {
  final _repository = AssetSmartContentRepository();
  String? _selectedChildId;
  Future<_SmartContentData>? _contentFuture;
  String? _contentKey;

  ChildProfile? get _child => widget.children.isEmpty
      ? null
      : widget.children.firstWhere(
          (child) => child.id == _selectedChildId,
          orElse: () => widget.children.first,
        );

  @override
  Widget build(BuildContext context) {
    final child = _child;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final contentKey = '$locale:${child?.id}';
    if (child != null && contentKey != _contentKey) {
      _contentKey = contentKey;
      _contentFuture = _load(child, locale);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sugestões para sua família')),
      body: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: child == null
            ? const Center(
                child: Text('Adicione uma criança para ver sugestões.'),
              )
            : FutureBuilder<_SmartContentData>(
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: ZeniSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sugestões para sua família',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: ZeniSpacing.sm),
                        Text(
                          'Escolha uma ideia e ajuste do jeito que funciona para vocês.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ZeniColors.mutedText),
                        ),
                        if (widget.children.length > 1) ...[
                          const SizedBox(height: ZeniSpacing.lg),
                          DropdownButton<String>(
                            key: const Key('smart-content-child-selector'),
                            value: child.id,
                            isExpanded: true,
                            onChanged: (id) =>
                                setState(() => _selectedChildId = id),
                            items: [
                              for (final item in widget.children)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: ZeniSpacing.xl),
                        Text(
                          'Missões sugeridas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: ZeniSpacing.md),
                        for (final suggestion in data.suggestions) ...[
                          ZeniCard(
                            onTap: () async => widget.onSelectMission(
                              suggestion.mission,
                              child,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(suggestion.mission.title),
                              subtitle: Text(
                                '${_friendlyDomain(suggestion.mission.domain)} · ${suggestion.mission.description}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                          const SizedBox(height: ZeniSpacing.sm),
                        ],
                        const SizedBox(height: ZeniSpacing.xl),
                        Text(
                          'Rotinas prontas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: ZeniSpacing.md),
                        for (final routine in data.routines.take(4)) ...[
                          ZeniCard(
                            onTap: () => _showRoutine(routine, data.missions),
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
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<_SmartContentData> _load(ChildProfile child, String locale) async {
    final missions = await _repository.getMissions(locale);
    final routines = await _repository.getRoutines(locale);
    final suggestions = await SmartSuggestionService(_repository).suggest(
      child: child,
      goal: SmartSuggestionGoal.routine,
      preferences: const FamilySmartPreferences(),
      activeMissions: widget.activeMissions,
      history: const [],
      localeTag: locale,
    );
    return _SmartContentData(
      missions: missions,
      routines: routines,
      suggestions: suggestions.whereType<SmartMissionSuggestion>().toList(),
    );
  }

  Future<void> _showRoutine(
    SmartRoutineTemplate routine,
    List<SmartMissionTemplate> missions,
  ) {
    final steps = routine.steps
        .map((id) => missions.where((mission) => mission.id == id).firstOrNull)
        .whereType<SmartMissionTemplate>()
        .toList();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(routine.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(routine.description),
              const SizedBox(height: ZeniSpacing.md),
              for (final mission in steps) Text('• ${mission.title}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _friendlyDomain(String domain) => switch (domain) {
    'self_care' => 'Autocuidado',
    'study' => 'Estudos',
    'home_participation' => 'Casa',
    _ => 'Dia a dia',
  };
}

class _SmartContentData {
  const _SmartContentData({
    required this.missions,
    required this.routines,
    required this.suggestions,
  });
  final List<SmartMissionTemplate> missions;
  final List<SmartRoutineTemplate> routines;
  final List<SmartMissionSuggestion> suggestions;
}
