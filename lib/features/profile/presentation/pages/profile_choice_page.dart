import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
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
    final typography = ZeniTypography.of(context);
    final windowClass = ZeniResponsive.windowClass(context);
    final usesTabletLayout = windowClass != ZeniWindowClass.compact;

    final parentSection = _ParentSection(
      onOpenParent: onOpenParent,
      showHeading: usesTabletLayout,
    );
    final childrenSection = _ChildrenSection(children: data.children);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceGroup,
        bottom: ZeniSpacing.spaceCanvas + MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZeniBrandLogo(width: 88),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            Text('Quem vai usar o Zeni agora?', style: typography.pageTitle),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(
              'Escolha um perfil para continuar.',
              style: typography.body.copyWith(
                color: context.zeniColors.textSecondary,
              ),
            ),
            const SizedBox(height: ZeniSpacing.spaceSection),
            if (usesTabletLayout)
              Column(
                key: const Key('profile-choice-tablet-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  parentSection,
                  const SizedBox(height: ZeniSpacing.spaceSection),
                  childrenSection,
                ],
              )
            else
              Column(
                key: const Key('profile-choice-single-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  parentSection,
                  const SizedBox(height: ZeniSpacing.spaceSection),
                  childrenSection,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ParentSection extends StatelessWidget {
  const _ParentSection({required this.onOpenParent, required this.showHeading});

  final VoidCallback onOpenParent;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return Column(
      key: const Key('profile-choice-parent-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          Text('Responsável', style: typography.sectionTitle),
          const SizedBox(height: ZeniSpacing.spaceCard),
        ],
        _ParentAccessButton(onTap: onOpenParent),
      ],
    );
  }
}

class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return Column(
      key: const Key('profile-choice-children-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crianças', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceCard),
        _ChildProfilesGrid(children: children),
      ],
    );
  }
}

class _ChildProfilesGrid extends StatelessWidget {
  const _ChildProfilesGrid({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = ZeniSpacing.spaceCard;
        final availableWidth = constraints.maxWidth;
        final columns = ZeniAdaptiveGrid.columnsForWidth(
          availableWidth: availableWidth + spacing,
          windowClass: ZeniResponsive.windowClass(context),
          minItemWidth: 250 + spacing,
        );
        final itemWidth = (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          key: const Key('profile-choice-child-grid'),
          spacing: spacing,
          runSpacing: spacing,
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
}

class _ParentAccessButton extends StatelessWidget {
  const _ParentAccessButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return ZeniSurface(
      role: ZeniSurfaceRole.interactive,
      mode: ZeniVisualMode.parent,
      backgroundColor: colors.surfaceSubtle,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: ZeniTouchTargets.minimum,
            height: ZeniTouchTargets.minimum,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.shield_outlined, color: colors.actionPrimary),
          ),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrar como responsável', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text('Gerencie sua família.', style: typography.metadata),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Icon(Icons.chevron_right_rounded, color: colors.actionPrimary),
        ],
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final avatar = ZeniChildAvatarCatalog.byId(child.avatarId);

    return ZeniSurface(
      key: Key('profile-child-${child.id}'),
      role: ZeniSurfaceRole.interactive,
      mode: ZeniVisualMode.kids,
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      onTap: () => context.go('/child/${child.id}'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usesStackedMetadata = constraints.maxWidth < 300;

          if (usesStackedMetadata) {
            return _StackedChildProfileContent(child: child, avatar: avatar);
          }

          return _InlineChildProfileContent(child: child, avatar: avatar);
        },
      ),
    );
  }
}

class _InlineChildProfileContent extends StatelessWidget {
  const _InlineChildProfileContent({required this.child, required this.avatar});

  final ChildProfile child;
  final ZeniChildAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return Row(
      children: [
        _ChildAvatar(avatar: avatar),
        const SizedBox(width: ZeniSpacing.spaceControl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.name, style: typography.cardTitle),
              const SizedBox(height: ZeniSpacing.spaceInlineTight),
              Text(
                '${child.streakCount} dias de sequência',
                style: typography.metadata,
              ),
            ],
          ),
        ),
        const SizedBox(width: ZeniSpacing.spaceControl),
        ZeniBalancePill(stars: child.starBalance),
      ],
    );
  }
}

class _StackedChildProfileContent extends StatelessWidget {
  const _StackedChildProfileContent({
    required this.child,
    required this.avatar,
  });

  final ChildProfile child;
  final ZeniChildAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ChildAvatar(avatar: avatar),
            const SizedBox(width: ZeniSpacing.spaceControl),
            Expanded(child: Text(child.name, style: typography.cardTitle)),
          ],
        ),
        const SizedBox(height: ZeniSpacing.spaceCard),
        Row(
          children: [
            Expanded(
              child: Text(
                '${child.streakCount} dias de sequência',
                style: typography.metadata,
              ),
            ),
            const SizedBox(width: ZeniSpacing.spaceControl),
            ZeniBalancePill(stars: child.starBalance),
          ],
        ),
      ],
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.avatar});

  final ZeniChildAvatar avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ZeniTouchTargets.childPriority,
      height: ZeniTouchTargets.childPriority,
      decoration: BoxDecoration(
        color: context.zeniColors.surfaceSubtle,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(avatar.assetPath, fit: BoxFit.contain),
    );
  }
}

class _ProfileChoiceData {
  const _ProfileChoiceData({required this.children});

  final List<ChildProfile> children;
}
