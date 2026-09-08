import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../family/presentation/avatar_catalog.dart';

class InitialFamilySetupPage extends ConsumerStatefulWidget {
  const InitialFamilySetupPage({super.key});

  @override
  ConsumerState<InitialFamilySetupPage> createState() =>
      _InitialFamilySetupPageState();
}

class _InitialFamilySetupPageState
    extends ConsumerState<InitialFamilySetupPage> {
  final List<_DraftChild> _children = [];
  bool _isSaving = false;

  Future<void> _addChild({_DraftChild? existing}) async {
    final child = await showModalBottomSheet<_DraftChild>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddChildSheet(initial: existing),
    );
    if (!mounted || child == null) return;
    setState(() {
      if (existing == null) {
        _children.add(child);
      } else {
        _children[_children.indexOf(existing)] = child;
      }
    });
  }

  Future<void> _finish() async {
    if (_children.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(zeniAppStateControllerProvider.notifier);
      for (final child in _children) {
        await controller.completeInitialOnboardingSetup(
          childName: child.name,
          // Kept only while legacy profiles still require the emoji field.
          childEmoji: '⭐',
          childAvatarId: child.avatarId,
          hasCompletedOnboarding: true,
          clearParentPin: false,
          createSuggestedMission: false,
          createSuggestedReward: false,
        );
      }
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        await ZeniErrorPopup.show(
          context,
          title: 'Não foi possível concluir',
          message: 'Tente novamente para salvar as crianças da família.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ZeniScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          0,
          ZeniSpacing.md,
          0,
          ZeniSpacing.xl,
        ),
        child: ZeniPageFrame(
          width: ZeniPageWidth.focus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Voltar',
                onPressed: _isSaving ? null : () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: ZeniSpacing.sm),
              Text('Quem vai usar o Zeni?', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Adicione as crianças da família. Você pode incluir outras agora ou depois.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              if (_children.isEmpty)
                _AddChildInvite(onTap: _isSaving ? null : _addChild)
              else ...[
                for (final child in _children) ...[
                  _ChildDraftCard(
                    child: child,
                    onEdit: _isSaving ? null : () => _addChild(existing: child),
                    onRemove: _isSaving
                        ? null
                        : () => setState(() => _children.remove(child)),
                  ),
                  const SizedBox(height: ZeniSpacing.sm),
                ],
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _addChild,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar outra criança'),
                ),
              ],
              const SizedBox(height: ZeniSpacing.xl),
              ZeniPrimaryButton(
                label: _isSaving ? 'Salvando...' : 'Continuar',
                icon: Icons.arrow_forward_rounded,
                onPressed: _children.isEmpty || _isSaving ? null : _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChildInvite extends StatelessWidget {
  const _AddChildInvite({required this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ZeniCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ZeniSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ZeniColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: ZeniColors.primaryDark),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar criança',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'Nome e avatar levam menos de um minuto.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          const Icon(
            Icons.arrow_forward_rounded,
            color: ZeniColors.primaryDark,
          ),
        ],
      ),
    ),
  );
}

class _ChildDraftCard extends StatelessWidget {
  const _ChildDraftCard({
    required this.child,
    required this.onEdit,
    required this.onRemove,
  });
  final _DraftChild child;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    final avatar = ZeniChildAvatarCatalog.byId(child.avatarId);
    return ZeniCard(
      padding: const EdgeInsets.all(ZeniSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ZeniColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(avatar.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Text(
              child.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet({this.initial});
  final _DraftChild? initial;
  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late String _avatarId =
      widget.initial?.avatarId ?? ZeniChildAvatarCatalog.fallbackId;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      ZeniSpacing.xl,
      ZeniSpacing.xl,
      ZeniSpacing.xl,
      MediaQuery.viewInsetsOf(context).bottom + ZeniSpacing.xl,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionar criança',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: ZeniSpacing.lg),
          _AvatarPicker(
            avatars: ZeniChildAvatarCatalog.all,
            selectedAvatarId: _avatarId,
            onSelected: (avatarId) => setState(() => _avatarId = avatarId),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniTextInput(
            controller: _name,
            label: 'Nome',
            hint: 'Ex.: Luna',
            prefixIcon: Icons.child_care_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          ZeniPrimaryButton(
            label: 'Adicionar',
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    _DraftChild(name: _name.text.trim(), avatarId: _avatarId),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatars,
    required this.selectedAvatarId,
    required this.onSelected,
  });
  final List<ZeniChildAvatar> avatars;
  final String selectedAvatarId;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = ZeniSpacing.sm;
      final itemWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final avatar in avatars)
            Semantics(
              button: true,
              selected: avatar.id == selectedAvatarId,
              child: SizedBox(
                width: itemWidth,
                height: 88,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('avatar-picker-${avatar.id}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelected(avatar.id),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: ZeniColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: avatar.id == selectedAvatarId
                              ? ZeniColors.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: avatar.id == selectedAvatarId ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(ZeniSpacing.sm),
                        child: Image.asset(
                          avatar.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _DraftChild {
  const _DraftChild({required this.name, required this.avatarId});
  final String name;
  final String avatarId;
}
