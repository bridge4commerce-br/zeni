import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../auth/local/parent_biometric_auth.dart';
import '../../../auth/presentation/widgets/parent_pin_dialog.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/models/family.dart';

class ProfileChoicePage extends ConsumerStatefulWidget {
  const ProfileChoicePage({super.key});

  @override
  ConsumerState<ProfileChoicePage> createState() => _ProfileChoicePageState();
}

class _ProfileChoicePageState extends ConsumerState<ProfileChoicePage> {
  _ProfileChoiceData _buildData(ZeniAppState appState) {
    return _ProfileChoiceData(
      family: appState.family,
      children: appState.children.where((child) => child.isActive).toList(),
    );
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
      appBar: const ZeniTopBar(
        title: 'ZeniKids',
        subtitle: 'Escolha como deseja entrar',
      ),
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
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quem está usando o ZeniKids?', style: textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            data.family.name,
            style: textTheme.titleLarge?.copyWith(
              color: ZeniColors.primaryDark,
            ),
          ),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Cada criança vê suas missões, estrelas e mimos. Responsáveis gerenciam a família.',
            style: textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Text('Crianças', style: textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          for (final child in data.children) ...[
            _ChildProfileCard(child: child),
            const SizedBox(height: ZeniSpacing.md),
          ],
          const SizedBox(height: ZeniSpacing.lg),
          Text('Responsável', style: textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          ZeniCard(
            onTap: onOpenParent,
            child: Row(
              children: [
                const ZeniAvatar(
                  label: 'Responsável',
                  emoji: '👨‍👩‍👧',
                  size: 64,
                  backgroundColor: Color(0x1A22C55E),
                ),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrar como responsável',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: ZeniSpacing.xs),
                      Text(
                        'Criar missões, aprovar conquistas e configurar mimos.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: ZeniColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ZeniColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          ZeniPrimaryButton(
            label: 'Entrar com código da família',
            icon: Icons.qr_code_rounded,
            onPressed: () {
              ZeniInfoPopup.show(
                context,
                title: 'Código da família',
                message:
                    'O convite por código será implementado no fluxo de auth.',
              );
            },
          ),
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
    final textTheme = Theme.of(context).textTheme;

    return ZeniCard(
      onTap: () {
        context.go('/child/${child.id}');
      },
      child: Row(
        children: [
          ZeniAvatar(label: child.name, emoji: child.emoji, size: 64),
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
  const _ProfileChoiceData({required this.family, required this.children});

  final Family family;
  final List<ChildProfile> children;
}
