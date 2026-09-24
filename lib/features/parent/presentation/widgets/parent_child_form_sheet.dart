import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../family/presentation/avatar_catalog.dart';

class ParentChildFormResult {
  const ParentChildFormResult({
    required this.name,
    required this.emoji,
    required this.ttsEnabled,
    this.avatarId,
    this.birthDate,
  });

  final String name;
  final String emoji;
  final bool ttsEnabled;
  final String? avatarId;
  final DateTime? birthDate;
}

class ParentChildFormSheet extends StatefulWidget {
  const ParentChildFormSheet({
    super.key,
    this.initialName,
    this.initialEmoji,
    this.initialBirthDate,
    this.initialTtsEnabled = false,
    this.initialAvatarId,
    this.title = 'Adicionar criança',
    this.submitLabel = 'Adicionar criança',
    this.showDragHandle = true,
  });

  final String? initialName;
  final String? initialEmoji;
  final DateTime? initialBirthDate;
  final bool initialTtsEnabled;
  final String? initialAvatarId;
  final String title;
  final String submitLabel;
  final bool showDragHandle;

  @override
  State<ParentChildFormSheet> createState() => _ParentChildFormSheetState();
}

class _ParentChildFormSheetState extends State<ParentChildFormSheet> {
  final _nameController = TextEditingController();

  late String _selectedEmoji;
  late String? _selectedAvatarId;
  late bool _ttsEnabled;
  DateTime? _birthDate;

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.initialName ?? '';
    _selectedEmoji = widget.initialEmoji ?? '⭐';
    _selectedAvatarId =
        widget.initialAvatarId ??
        (widget.initialName == null ? ZeniChildAvatarCatalog.fallbackId : null);
    _ttsEnabled = widget.initialTtsEnabled;
    _birthDate = widget.initialBirthDate;
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
      showDragHandle: widget.showDragHandle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha um nome, data de nascimento e avatar.',
              style: ZeniTypography.of(context).body,
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
              'Data de nascimento (opcional)',
              style: ZeniTypography.of(context).cardTitle,
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
            Text(
              'Escolha um avatar',
              style: ZeniTypography.of(context).cardTitle,
            ),
            const SizedBox(height: ZeniSpacing.md),
            Wrap(
              spacing: ZeniSpacing.sm,
              runSpacing: ZeniSpacing.sm,
              children: [
                for (final avatar in ZeniChildAvatarCatalog.all)
                  ChoiceChip(
                    label: Image.asset(avatar.assetPath, width: 40, height: 40),
                    selected: _selectedAvatarId == avatar.id,
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .12),
                    side: BorderSide(
                      color: _selectedAvatarId == avatar.id
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: _selectedAvatarId == avatar.id ? 2 : 1,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedAvatarId = avatar.id;
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
        avatarId: _selectedAvatarId,
        ttsEnabled: _ttsEnabled,
        birthDate: _birthDate,
      ),
    );
  }
}
