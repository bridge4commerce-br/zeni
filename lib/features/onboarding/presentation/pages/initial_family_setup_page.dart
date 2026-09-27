import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../family/presentation/avatar_catalog.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';

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
    final content = _AddChildSheet(initial: existing);
    final child = ZeniAdaptiveModal.usesDialog(context)
        ? await showDialog<_DraftChild>(
            context: context,
            builder: (_) =>
                Dialog(child: ZeniAdaptiveModalFrame(child: content)),
          )
        : await showModalBottomSheet<_DraftChild>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => content,
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
    final authState = ref.read(authStateProvider);
    final localState = await ref.read(zeniAppStateControllerProvider.future);
    if (!authState.isAuthenticated ||
        authState.familyIdentityAccess != ZeniFamilyIdentityAccess.ready ||
        localState.family.id == 'local-family') {
      if (!mounted) return;
      await ZeniErrorPopup.show(
        context,
        title: 'Conta necessária',
        message:
            'Entre com a conta do responsável antes de configurar a família.',
      );
      if (mounted) context.go('/');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(zeniAppStateControllerProvider.notifier);
      for (final child in _children) {
        await controller.completeInitialOnboardingSetup(
          childName: child.name,
          // Kept only while legacy profiles still require the emoji field.
          childEmoji: '⭐',
          childAvatarId: child.avatarId,
          childBirthDate: child.birthDate,
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
    final typography = ZeniTypography.of(context);
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
              Text('Quem vai usar o Zeni?', style: typography.display),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Adicione as crianças da família. Você pode incluir outras agora ou depois.',
                style: typography.body,
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
                ZeniButton(
                  label: 'Adicionar outra criança',
                  icon: Icons.add_rounded,
                  role: ZeniButtonRole.secondary,
                  mode: ZeniVisualMode.parent,
                  onPressed: _isSaving ? null : _addChild,
                ),
              ],
              const SizedBox(height: ZeniSpacing.xl),
              ZeniButton(
                label: _isSaving ? 'Salvando...' : 'Continuar',
                icon: Icons.arrow_forward_rounded,
                role: ZeniButtonRole.primary,
                mode: ZeniVisualMode.parent,
                loading: _isSaving,
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
    child: ZeniSurface(
      role: ZeniSurfaceRole.interactive,
      mode: ZeniVisualMode.parent,
      onTap: onTap,
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar criança',
                  style: ZeniTypography.of(context).cardTitle,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'Nome e avatar levam menos de um minuto.',
                  style: ZeniTypography.of(context).metadata,
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          Icon(
            Icons.arrow_forward_rounded,
            color: Theme.of(context).colorScheme.primary,
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
    return ZeniSurface(
      role: ZeniSurfaceRole.grouped,
      mode: ZeniVisualMode.parent,
      padding: const EdgeInsets.all(ZeniSpacing.spaceControl),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(avatar.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Text(
              child.name,
              style: ZeniTypography.of(context).cardTitle,
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
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.initial?.birthDate;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 8),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (date != null) setState(() => _birthDate = date);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
            style: ZeniTypography.of(context).sectionTitle,
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniTextInput(
            controller: _name,
            label: 'Nome',
            hint: 'Ex.: Luna',
            prefixIcon: Icons.child_care_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          Text(
            'Data de nascimento (opcional)',
            style: ZeniTypography.of(context).cardTitle,
          ),
          const SizedBox(height: ZeniSpacing.spaceControl),
          OutlinedButton.icon(
            icon: const Icon(Icons.cake_rounded),
            label: Text(
              _birthDate == null
                  ? 'Adicionar data de nascimento'
                  : _formatDate(_birthDate!),
            ),
            onPressed: _pickBirthDate,
          ),
          const SizedBox(height: ZeniSpacing.lg),
          Text(
            'Escolha um avatar',
            style: ZeniTypography.of(context).cardTitle,
          ),
          const SizedBox(height: ZeniSpacing.spaceControl),
          _AvatarPicker(
            avatars: ZeniChildAvatarCatalog.all,
            selectedAvatarId: _avatarId,
            onSelected: (avatarId) => setState(() => _avatarId = avatarId),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          ZeniButton(
            label: 'Adicionar',
            role: ZeniButtonRole.primary,
            mode: ZeniVisualMode.parent,
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    _DraftChild(
                      name: _name.text.trim(),
                      avatarId: _avatarId,
                      birthDate: _birthDate,
                    ),
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
  const _DraftChild({
    required this.name,
    required this.avatarId,
    this.birthDate,
  });
  final String name;
  final String avatarId;
  final DateTime? birthDate;
}
