import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_radius.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../auth/presentation/widgets/auth_account_sheet.dart';
import '../../../sync/presentation/providers/first_access_restore_providers.dart';

class InitialStartChoicePage extends ConsumerStatefulWidget {
  const InitialStartChoicePage({super.key});

  @override
  ConsumerState<InitialStartChoicePage> createState() =>
      _InitialStartChoicePageState();
}

class _InitialStartChoicePageState
    extends ConsumerState<InitialStartChoicePage> {
  bool _isReadyToRestore = false;
  bool _isRestoring = false;
  String? _restoreMessage;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return ZeniScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.lg),
        child: ZeniPageFrame(
          width: ZeniPageWidth.focus,
          child: _isReadyToRestore
              ? _RestoreChoiceContent(
                  isRestoring: _isRestoring,
                  restoreMessage: _restoreMessage,
                  onRestore: _isRestoring ? null : _runRemoteRestore,
                  onStartNewFamily: _isRestoring
                      ? null
                      : () => context.go('/initial-setup'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ZeniBrandLogo(width: 76),
                    const SizedBox(height: ZeniSpacing.xl),
                    Text('Como você quer começar?', style: typography.display),
                    const SizedBox(height: ZeniSpacing.sm),
                    Text(
                      'Escolha uma opção para continuar.',
                      style: typography.body,
                    ),
                    const SizedBox(height: ZeniSpacing.xl),
                    _StartOptionCard(
                      key: const Key('start-path-new-family'),
                      title: 'Criar uma nova família',
                      description: 'Configure sua família e comece.',
                      icon: Icons.family_restroom_rounded,
                      tone: _StartOptionTone.primary,
                      onTap: () => context.push('/family-account'),
                    ),
                    const SizedBox(height: ZeniSpacing.sm),
                    _StartOptionCard(
                      key: const Key('start-path-existing-family'),
                      title: 'Já tenho uma família',
                      description: 'Entre para recuperar seus dados.',
                      icon: Icons.cloud_sync_rounded,
                      tone: _StartOptionTone.secondary,
                      onTap: _startRemoteRestore,
                    ),
                    const SizedBox(height: ZeniSpacing.sm),
                    const _StartOptionCard(
                      key: Key('start-path-child'),
                      title: 'Sou criança',
                      description: 'Entre com acesso do responsável.',
                      icon: Icons.auto_awesome_rounded,
                      tone: _StartOptionTone.child,
                      available: false,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _startRemoteRestore() async {
    setState(() {
      _isReadyToRestore = false;
      _isRestoring = false;
      _restoreMessage =
          'Faça login para continuar. A restauração completa só começa quando você tocar em "Restaurar minha família".';
    });

    final content = AuthAccountSheet(
      isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
      bootstrapState: ZeniSupabaseBootstrap.state,
      showDragHandle: !ZeniAdaptiveModal.usesDialog(context),
    );
    final didAuthenticate = ZeniAdaptiveModal.usesDialog(context)
        ? await showDialog<bool>(
            context: context,
            builder: (_) =>
                Dialog(child: ZeniAdaptiveModalFrame(child: content)),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: content,
            ),
          );

    if (!mounted || didAuthenticate != true) return;
    setState(() {
      _isReadyToRestore = true;
      _isRestoring = false;
      _restoreMessage = null;
    });
  }

  Future<void> _runRemoteRestore() async {
    setState(() {
      _isRestoring = true;
      _restoreMessage = 'Restaurando...';
    });
    final result = await ref
        .read(firstAccessRestoreControllerProvider)
        .restoreFamilyOnEmptyDevice();
    if (!mounted) return;
    setState(() {
      _isRestoring = false;
      _restoreMessage = result.message;
    });
    if (result.status == FirstAccessRestoreResultStatus.success) {
      await ZeniSuccessPopup.show(
        context,
        title: 'Família restaurada',
        message: result.message,
      );
    } else if (result.status == FirstAccessRestoreResultStatus.partialSuccess) {
      await ZeniInfoPopup.show(
        context,
        title: 'Família restaurada',
        message: result.message,
      );
    } else {
      await ZeniErrorPopup.show(
        context,
        title: 'Não foi possível restaurar agora',
        message: result.message,
      );
    }
  }
}

class _RestoreChoiceContent extends StatelessWidget {
  const _RestoreChoiceContent({
    required this.isRestoring,
    required this.restoreMessage,
    required this.onRestore,
    required this.onStartNewFamily,
  });
  final bool isRestoring;
  final String? restoreMessage;
  final VoidCallback? onRestore;
  final VoidCallback? onStartNewFamily;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZeniBrandLogo(width: 86),
        const SizedBox(height: ZeniSpacing.xxxl),
        Text('Sua família está por aqui', style: typography.display),
        const SizedBox(height: ZeniSpacing.sm),
        Text(
          'Sua conta já foi conectada. Agora vamos preparar este aparelho com segurança.',
          style: typography.body,
        ),
        const SizedBox(height: ZeniSpacing.xxl),
        const _ConnectedAccountCard(),
        if (restoreMessage != null) ...[
          const SizedBox(height: ZeniSpacing.lg),
          ZeniSurface(
            role: ZeniSurfaceRole.highlight,
            mode: ZeniVisualMode.parent,
            padding: const EdgeInsets.all(ZeniSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isRestoring ? Icons.sync_rounded : Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: ZeniSpacing.sm),
                Expanded(child: Text(restoreMessage!, style: typography.body)),
              ],
            ),
          ),
        ],
        const SizedBox(height: ZeniSpacing.lg),
        ZeniButton(
          label: isRestoring ? 'Restaurando...' : 'Restaurar minha família',
          icon: Icons.cloud_download_rounded,
          role: ZeniButtonRole.primary,
          mode: ZeniVisualMode.parent,
          onPressed: onRestore,
        ),
        const SizedBox(height: ZeniSpacing.md),
        ZeniButton(
          label: 'Começar nova família neste aparelho',
          icon: Icons.arrow_forward_rounded,
          role: ZeniButtonRole.secondary,
          mode: ZeniVisualMode.parent,
          onPressed: onStartNewFamily,
        ),
      ],
    );
  }
}

class _ConnectedAccountCard extends StatelessWidget {
  const _ConnectedAccountCard();
  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return ZeniSurface(
      role: ZeniSurfaceRole.grouped,
      mode: ZeniVisualMode.parent,
      padding: const EdgeInsets.all(ZeniSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conta conectada', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'Encontramos dados salvos na nuvem. Vamos trazer sua família para este aparelho.',
                  style: typography.metadata,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _StartOptionTone { primary, secondary, child }

class _StartOptionCard extends StatelessWidget {
  const _StartOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    this.onTap,
    this.available = true,
  });
  final String title;
  final String description;
  final IconData icon;
  final _StartOptionTone tone;
  final VoidCallback? onTap;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = _StartOptionPalette.of(context, tone);
    return ZeniSurface(
      role: ZeniSurfaceRole.interactive,
      mode: ZeniVisualMode.parent,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 124),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: ZeniRadius.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(ZeniSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.iconBackground,
                          borderRadius: BorderRadius.circular(ZeniRadius.md),
                        ),
                        child: Icon(icon, color: palette.iconColor),
                      ),
                      const SizedBox(height: ZeniSpacing.md),
                      Text(title, style: textTheme.titleLarge),
                      const SizedBox(height: ZeniSpacing.xs),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ZeniSpacing.sm),
                SizedBox(
                  width: 68,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: available
                        ? Icon(
                            Icons.arrow_forward_rounded,
                            color: palette.iconColor,
                          )
                        : _UnavailableBadge(color: palette.iconColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: ZeniSpacing.sm,
      vertical: ZeniSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(ZeniRadius.pill),
    ),
    child: Text(
      'Em breve',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StartOptionPalette {
  const _StartOptionPalette({
    required this.background,
    required this.iconBackground,
    required this.iconColor,
  });
  final Color background;
  final Color iconBackground;
  final Color iconColor;
  factory _StartOptionPalette.of(BuildContext context, _StartOptionTone tone) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (tone) {
      _StartOptionTone.primary => _StartOptionPalette(
        background: ZeniColors.primary.withValues(alpha: dark ? 0.2 : 0.12),
        iconBackground: ZeniColors.primary.withValues(
          alpha: dark ? 0.28 : 0.18,
        ),
        iconColor: dark ? ZeniColors.primaryLight : ZeniColors.primaryDark,
      ),
      _StartOptionTone.secondary => _StartOptionPalette(
        background: Theme.of(context).colorScheme.surface,
        iconBackground: ZeniColors.sky.withValues(alpha: dark ? 0.22 : 0.14),
        iconColor: dark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
      ),
      _StartOptionTone.child => _StartOptionPalette(
        background: ZeniColors.purple.withValues(alpha: dark ? 0.18 : 0.1),
        iconBackground: ZeniColors.purple.withValues(alpha: dark ? 0.28 : 0.16),
        iconColor: dark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
      ),
    };
  }
}
