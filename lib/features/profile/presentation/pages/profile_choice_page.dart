import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../auth/local/parent_biometric_auth.dart';
import '../../../auth/presentation/widgets/parent_pin_dialog.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/presentation/avatar_catalog.dart';

class ProfileChoicePage extends ConsumerStatefulWidget {
  const ProfileChoicePage({super.key});

  @override
  ConsumerState<ProfileChoicePage> createState() => _ProfileChoicePageState();
}

class _ProfileChoicePageState extends ConsumerState<ProfileChoicePage> {
  _ProfileChoiceData _buildData(ZeniAppState appState) {
    final activeChildren = appState.children
        .where((child) => child.isActive)
        .toList();
    if (kDebugMode) {
      final childIds = activeChildren.map((child) => child.id).join(', ');
      debugPrint(
        '[ProfileChoice] family=${appState.family.id} '
        'activeChildren=${activeChildren.length} ids=[$childIds]',
      );
      if (activeChildren.isEmpty) {
        debugPrint(
          '[ProfileChoice] No active child profiles available. '
          'children=${appState.children.length}, missions=${appState.missions.length}, rewards=${appState.rewards.length}',
        );
      }
    }

    return _ProfileChoiceData(children: activeChildren);
  }

  Future<void> _openParentMode(ZeniAppState appState) async {
    final settings = appState.appSettings;

    if (!settings.hasParentPin) {
      context.go('/parent');
      return;
    }

    if (settings.parentBiometricsEnabled) {
      final biometricResult = await ref
          .read(parentBiometricAuthProvider)
          .authenticate();
      if (!mounted) return;

      if (biometricResult.isAuthenticated) {
        context.go('/parent');
        return;
      }

      if (biometricResult.status == ParentBiometricAuthStatus.unavailable &&
          biometricResult.message != null) {
        await ZeniInfoPopup.show(
          context,
          title: 'Biometria indisponível',
          message: biometricResult.message!,
        );
        if (!mounted) return;
      }
    }

    final enteredPin = await showDialog<String>(
      context: context,
      builder: (context) => const ParentPinDialog.verify(),
    );
    if (!mounted || enteredPin == null) return;

    if (settings.matchesParentPin(enteredPin)) {
      context.go('/parent');
      return;
    }

    await ZeniErrorPopup.show(
      context,
      title: 'PIN incorreto',
      message: 'O PIN informado não confere. Tente novamente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(zeniAppStateControllerProvider);

    return ZeniScaffold(
      child: appState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar os perfis.')),
        data: (data) => _ProfileChoiceContent(
          data: _buildData(data),
          onOpenParent: () => _openParentMode(data),
        ),
      ),
    );
  }
}

class _ProfileChoiceContent extends StatelessWidget {
  const _ProfileChoiceContent({required this.data, required this.onOpenParent});

  final _ProfileChoiceData data;
  final VoidCallback onOpenParent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ZeniSpacing.xl,
        ZeniSpacing.lg,
        ZeniSpacing.xl,
        ZeniSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZeniBrandLogo(width: 88),
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Quem vai usar o Zeni agora?',
                style: textTheme.displayLarge,
              ),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Escolha um perfil para continuar.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              _ParentAccessButton(onTap: onOpenParent),
              const SizedBox(height: ZeniSpacing.xl),
              Text('Crianças', style: textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.md),
              _ChildProfilesGrid(children: data.children),
              const SizedBox(height: ZeniSpacing.lg),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ZeniInfoPopup.show(
                      context,
                      title: 'Código da família',
                      message: 'Este recurso estará disponível em breve.',
                    );
                  },
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Entrar com código da família'),
                  style: TextButton.styleFrom(
                    foregroundColor: ZeniColors.primaryDark,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZeniSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildProfilesGrid extends StatelessWidget {
  const _ChildProfilesGrid({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = ZeniSpacing.sm;
      final useTwoColumns = constraints.maxWidth >= 440;
      final itemWidth = useTwoColumns
          ? (constraints.maxWidth - gap) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(
              width: itemWidth,
              child: _ChildProfileCard(child: child),
            ),
        ],
      );
    },
  );
}

class _ParentAccessButton extends StatelessWidget {
  const _ParentAccessButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.md,
            vertical: ZeniSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: ZeniColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ZeniColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: ZeniColors.primaryDark),
              const SizedBox(width: ZeniSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrar como responsável',
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      'Gerencie sua família.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeniSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: ZeniColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final avatar = ZeniChildAvatarCatalog.byId(child.avatarId);
    return ZeniCard(
      key: Key('profile-child-${child.id}'),
      onTap: () {
        context.go('/child/${child.id}');
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ZeniColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(avatar.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: textTheme.titleLarge),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${child.streakCount} dias de sequência',
                  style: textTheme.bodyMedium?.copyWith(
                    color: ZeniColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          ZeniBalancePill(stars: child.starBalance),
        ],
      ),
    );
  }
}

class _ProfileChoiceData {
  const _ProfileChoiceData({required this.children});

  final List<ChildProfile> children;
}
