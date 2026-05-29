import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/counter_stepper.dart';
import '../../../../core/widgets/inputs/zeni_multiline_input.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../family/data/models/child_profile.dart';
import '../../data/models/mission.dart';

class TaskFormResult {
  const TaskFormResult({
    required this.childId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.stars,
    required this.recurrence,
    required this.customDaysOfWeek,
    required this.timeGroup,
    required this.approvalMode,
    required this.requiresPhoto,
  });

  final String childId;
  final String title;
  final String description;
  final String emoji;
  final int stars;
  final MissionRecurrence recurrence;
  final List<int> customDaysOfWeek;
  final MissionTimeGroup timeGroup;
  final MissionApprovalMode approvalMode;
  final bool requiresPhoto;
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, required this.children, this.initialMission});

  final List<ChildProfile> children;
  final Mission? initialMission;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  static const _emojiOptions = [
    '🛏️',
    '🧹',
    '📚',
    '🦷',
    '🧼',
    '🧸',
    '🐶',
    '🍽️',
    '🧺',
    '🎒',
    '✏️',
    '🚿',
    '🧽',
    '🧦',
    '🌱',
    '⭐',
    '✅',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  static const _weekDays = <(int, String)>[
    (DateTime.monday, 'Seg'),
    (DateTime.tuesday, 'Ter'),
    (DateTime.wednesday, 'Qua'),
    (DateTime.thursday, 'Qui'),
    (DateTime.friday, 'Sex'),
    (DateTime.saturday, 'Sab'),
    (DateTime.sunday, 'Dom'),
  ];

  late String _childId;
  late String _selectedEmoji;
  int _stars = 10;
  MissionRecurrence _recurrence = MissionRecurrence.daily;
  Set<int> _customDaysOfWeek = <int>{};
  MissionTimeGroup _timeGroup = MissionTimeGroup.morning;
  MissionApprovalMode _approvalMode = MissionApprovalMode.parentApproval;
  bool _requiresPhoto = false;

  bool get _isEditing => widget.initialMission != null;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      widget.children.isNotEmpty &&
      (_recurrence != MissionRecurrence.customDaysOfWeek ||
          _customDaysOfWeek.isNotEmpty);

  @override
  void initState() {
    super.initState();

    final mission = widget.initialMission;
    _childId = mission?.childId ?? widget.children.first.id;
    _selectedEmoji = mission?.emoji ?? _emojiOptions.first;

    if (!_emojiOptions.contains(_selectedEmoji)) {
      _selectedEmoji = _emojiOptions.first;
    }

    if (mission != null) {
      _titleController.text = mission.title;
      _descriptionController.text = mission.description;
      _stars = mission.stars;
      _recurrence = mission.recurrence;
      _customDaysOfWeek = mission.effectiveCustomDaysOfWeek.toSet();
      _timeGroup = mission.timeGroup;
      _approvalMode = mission.approvalMode;
      _requiresPhoto = mission.requiresPhoto;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: _isEditing ? 'Editar missão' : 'Criar missão',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZeniTextInput(
                controller: _titleController,
                label: 'Nome da missão',
                hint: 'Ex.: Arrumar a cama',
                prefixIcon: Icons.check_circle_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniMultilineInput(
                controller: _descriptionController,
                label: 'Descrição',
                hint: 'Explique a missão de forma simples',
                maxLength: 140,
              ),
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Emoji da missão',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ZeniSpacing.md),
              Wrap(
                spacing: ZeniSpacing.sm,
                runSpacing: ZeniSpacing.sm,
                children: [
                  for (final emoji in _emojiOptions)
                    ChoiceChip(
                      label: Text(emoji, style: const TextStyle(fontSize: 22)),
                      selected: _selectedEmoji == emoji,
                      onSelected: (_) {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: ZeniSpacing.lg),
              CounterStepper(
                label: 'Valor da missão',
                subtitle: 'Quantidade de estrelas ao concluir',
                value: _stars,
                min: 1,
                max: 100,
                step: 5,
                suffix: '⭐',
                onChanged: (value) {
                  setState(() {
                    _stars = value;
                  });
                },
              ),
              const SizedBox(height: ZeniSpacing.xl),
              Text('Criança', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.md),
              for (final child in widget.children) ...[
                ZeniOptionRow(
                  title: child.name,
                  subtitle:
                      '${child.starBalance} estrelas · ${child.streakCount} dias de sequência',
                  selected: _childId == child.id,
                  leading: Text(
                    child.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  onTap: () {
                    setState(() {
                      _childId = child.id;
                    });
                  },
                ),
                const SizedBox(height: ZeniSpacing.sm),
              ],
              const SizedBox(height: ZeniSpacing.lg),
              Text('Horário', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.md),
              for (final group in MissionTimeGroup.values) ...[
                ZeniOptionRow(
                  title: '${group.emoji} ${group.label}',
                  selected: _timeGroup == group,
                  onTap: () {
                    setState(() {
                      _timeGroup = group;
                    });
                  },
                ),
                const SizedBox(height: ZeniSpacing.sm),
              ],
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Recorrência',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ZeniSpacing.md),
              for (final recurrence in MissionRecurrence.values) ...[
                ZeniOptionRow(
                  title: recurrence.label,
                  selected: _recurrence == recurrence,
                  onTap: () {
                    setState(() {
                      _recurrence = recurrence;
                    });
                  },
                ),
                const SizedBox(height: ZeniSpacing.sm),
              ],
              if (_recurrence == MissionRecurrence.customDaysOfWeek) ...[
                const SizedBox(height: ZeniSpacing.sm),
                Text(
                  'Selecione os dias',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.sm),
                Wrap(
                  spacing: ZeniSpacing.sm,
                  runSpacing: ZeniSpacing.sm,
                  children: [
                    for (final (weekday, label) in _weekDays)
                      FilterChip(
                        label: Text(label),
                        selected: _customDaysOfWeek.contains(weekday),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _customDaysOfWeek.add(weekday);
                            } else {
                              _customDaysOfWeek.remove(weekday);
                            }
                          });
                        },
                      ),
                  ],
                ),
                if (_customDaysOfWeek.isEmpty) ...[
                  const SizedBox(height: ZeniSpacing.sm),
                  Text(
                    'Escolha pelo menos um dia para a recorrência personalizada.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: ZeniColors.error),
                  ),
                ],
              ],
              const SizedBox(height: ZeniSpacing.lg),
              Text('Aprovação', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.md),
              for (final mode in MissionApprovalMode.values) ...[
                ZeniOptionRow(
                  title: mode.label,
                  subtitle: mode == MissionApprovalMode.parentApproval
                      ? 'Responsável aprova antes de liberar estrelas'
                      : 'Estrelas entram assim que a criança concluir',
                  selected: _approvalMode == mode,
                  onTap: () {
                    setState(() {
                      _approvalMode = mode;
                    });
                  },
                ),
                const SizedBox(height: ZeniSpacing.sm),
              ],
              const SizedBox(height: ZeniSpacing.lg),
              ZeniSwitch(
                title: 'Pedir foto',
                subtitle: 'A criança poderá anexar foto ao concluir',
                icon: Icons.photo_camera_rounded,
                value: _requiresPhoto,
                onChanged: (value) {
                  setState(() {
                    _requiresPhoto = value;
                  });
                },
              ),
              const SizedBox(height: ZeniSpacing.xl),
              Text(
                _isEditing
                    ? 'As alterações serão aplicadas localmente por enquanto.'
                    : 'A missão será criada localmente por enquanto.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniPrimaryButton(
                label: _isEditing ? 'Salvar missão' : 'Criar missão',
                icon: _isEditing ? Icons.save_rounded : Icons.add_task_rounded,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Cancelar',
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      TaskFormResult(
        childId: _childId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _selectedEmoji,
        stars: _stars,
        recurrence: _recurrence,
        customDaysOfWeek: _customDaysOfWeek.toList()..sort(),
        timeGroup: _timeGroup,
        approvalMode: _approvalMode,
        requiresPhoto: _requiresPhoto,
      ),
    );
  }
}
