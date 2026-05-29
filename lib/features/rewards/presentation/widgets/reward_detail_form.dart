import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/counter_stepper.dart';
import '../../../../core/widgets/inputs/zeni_multiline_input.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../family/data/models/child_profile.dart';
import '../../data/models/reward.dart';

class RewardFormResult {
  const RewardFormResult({
    required this.title,
    required this.description,
    required this.emoji,
    required this.cost,
    required this.renewal,
    this.childId,
  });

  final String title;
  final String description;
  final String emoji;
  final int cost;
  final RewardRenewal renewal;
  final String? childId;
}

class RewardDetailForm extends StatefulWidget {
  const RewardDetailForm({
    super.key,
    required this.children,
    this.initialReward,
  });

  final List<ChildProfile> children;
  final Reward? initialReward;

  @override
  State<RewardDetailForm> createState() => _RewardDetailFormState();
}

class _RewardDetailFormState extends State<RewardDetailForm> {
  static const _emojiOptions = [
    '🎁',
    '🍦',
    '🎬',
    '🎮',
    '🧸',
    '🍕',
    '🛝',
    '🏆',
    '📺',
    '🧁',
    '🍫',
    '🎨',
    '⚽',
    '🎧',
    '🦄',
    '⭐',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedEmoji;
  int _cost = 40;
  RewardRenewal _renewal = RewardRenewal.weekly;
  String? _childId;

  bool get _isEditing => widget.initialReward != null;

  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    final reward = widget.initialReward;
    _selectedEmoji = reward?.emoji ?? _emojiOptions.first;

    if (!_emojiOptions.contains(_selectedEmoji)) {
      _selectedEmoji = _emojiOptions.first;
    }

    if (reward != null) {
      _titleController.text = reward.title;
      _descriptionController.text = reward.description;
      _cost = reward.cost;
      _renewal = reward.renewal;
      _childId = reward.childId;
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
      title: _isEditing ? 'Editar mimo' : 'Criar mimo',
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
                label: 'Nome do mimo',
                hint: 'Ex.: Escolher o filme',
                prefixIcon: Icons.card_giftcard_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniMultilineInput(
                controller: _descriptionController,
                label: 'Descrição',
                hint: 'Explique a recompensa combinada com a família',
                maxLength: 140,
              ),
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Emoji do mimo',
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
                label: 'Custo do mimo',
                subtitle: 'Quantidade de estrelas necessárias',
                value: _cost,
                min: 5,
                max: 500,
                step: 5,
                suffix: '⭐',
                onChanged: (value) {
                  setState(() {
                    _cost = value;
                  });
                },
              ),
              const SizedBox(height: ZeniSpacing.xl),
              Text(
                'Disponível para',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniOptionRow(
                title: 'Todas as crianças',
                subtitle: 'Qualquer criança da família pode pedir',
                selected: _childId == null,
                leading: const Icon(
                  Icons.family_restroom_rounded,
                  color: ZeniColors.primaryDark,
                ),
                onTap: () {
                  setState(() {
                    _childId = null;
                  });
                },
              ),
              const SizedBox(height: ZeniSpacing.sm),
              for (final child in widget.children) ...[
                ZeniOptionRow(
                  title: child.name,
                  subtitle: 'Disponível apenas para este perfil',
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
              Text('Renovação', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.md),
              for (final renewal in RewardRenewal.values) ...[
                ZeniOptionRow(
                  title: renewal.label,
                  selected: _renewal == renewal,
                  onTap: () {
                    setState(() {
                      _renewal = renewal;
                    });
                  },
                ),
                const SizedBox(height: ZeniSpacing.sm),
              ],
              const SizedBox(height: ZeniSpacing.xl),
              Text(
                _isEditing
                    ? 'As alterações serão aplicadas localmente por enquanto.'
                    : 'O mimo será criado localmente por enquanto.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniPrimaryButton(
                label: _isEditing ? 'Salvar mimo' : 'Criar mimo',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
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
      RewardFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _selectedEmoji,
        cost: _cost,
        renewal: _renewal,
        childId: _childId,
      ),
    );
  }
}
