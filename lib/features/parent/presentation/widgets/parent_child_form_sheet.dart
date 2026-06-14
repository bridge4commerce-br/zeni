import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';

class ParentChildFormResult {
  const ParentChildFormResult({
    required this.name,
    required this.emoji,
    required this.ttsEnabled,
    this.birthDate,
  });

  final String name;
  final String emoji;
  final bool ttsEnabled;
  final DateTime? birthDate;
}

class ParentChildFormSheet extends StatefulWidget {
  const ParentChildFormSheet({
    super.key,
    this.initialName,
    this.initialEmoji,
    this.initialBirthDate,
    this.initialTtsEnabled = false,
    this.title = 'Adicionar criança',
    this.submitLabel = 'Adicionar criança',
  });

  final String? initialName;
  final String? initialEmoji;
  final DateTime? initialBirthDate;
  final bool initialTtsEnabled;
  final String title;
  final String submitLabel;

  @override
  State<ParentChildFormSheet> createState() => _ParentChildFormSheetState();
}

class _ParentChildFormSheetState extends State<ParentChildFormSheet> {
  static const _emojiOptions = [
    '🌟',
    '🚀',
    '🦁',
    '🦊',
    '🐼',
    '🐵',
    '🐯',
    '🐰',
    '🐸',
    '🦄',
    '⚽',
    '🎨',
    '🎮',
    '📚',
    '🎧',
    '🌈',
    '⭐',
  ];

  final _nameController = TextEditingController();

  late String _selectedEmoji;
  late bool _ttsEnabled;
  DateTime? _birthDate;

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.initialName ?? '';
    _selectedEmoji = widget.initialEmoji ?? _emojiOptions.first;
    _ttsEnabled = widget.initialTtsEnabled;
    _birthDate = widget.initialBirthDate;

    if (!_emojiOptions.contains(_selectedEmoji)) {
      _selectedEmoji = _emojiOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: widget.title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha um nome, avatar e data de nascimento.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nome da criança',
                hintText: 'Ex.: Luna',
                prefixIcon: Icon(Icons.child_care_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            Text(
              'Data de nascimento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.cake_rounded),
              label: Text(
                _birthDate == null
                    ? 'Adicionar data de nascimento'
                    : _formatDate(_birthDate!),
              ),
              onPressed: _pickBirthDate,
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniSwitch(
              title: 'Leitura em voz alta neste perfil',
              subtitle:
                  'Quando o app usar a configuração por criança, ${_nameController.text.trim().isEmpty ? 'este perfil' : _nameController.text.trim()} poderá ouvir missões e mimos.',
              icon: Icons.record_voice_over_rounded,
              value: _ttsEnabled,
              onChanged: (value) {
                setState(() {
                  _ttsEnabled = value;
                });
              },
            ),
            const SizedBox(height: ZeniSpacing.md),
            Text(
              'Escolha um avatar',
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
            const SizedBox(height: ZeniSpacing.xl),
            ZeniPrimaryButton(
              label: widget.submitLabel,
              icon: Icons.check_rounded,
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
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );

    if (selectedDate == null) return;

    setState(() {
      _birthDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  void _submit() {
    Navigator.of(context).pop(
      ParentChildFormResult(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        ttsEnabled: _ttsEnabled,
        birthDate: _birthDate,
      ),
    );
  }
}
