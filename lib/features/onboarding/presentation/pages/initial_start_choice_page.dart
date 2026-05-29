import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../auth/presentation/widgets/auth_account_sheet.dart';
import '../../../sync/presentation/providers/device_bootstrap_providers.dart';

class InitialStartChoicePage extends ConsumerStatefulWidget {
  const InitialStartChoicePage({super.key});

  @override
  ConsumerState<InitialStartChoicePage> createState() =>
      _InitialStartChoicePageState();
}

class _InitialStartChoicePageState
    extends ConsumerState<InitialStartChoicePage> {
  bool _isRestoring = false;
  bool _restorationFailed = false;
  String? _restoreMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniScaffold(
      appBar: const ZeniTopBar(
        title: 'Zeni',
        subtitle: 'Escolha como deseja começar',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ZeniSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como você quer começar?', style: textTheme.displayLarge),
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              'Você pode montar uma nova família agora ou aguardar a restauração da nuvem na próxima etapa.',
              style: textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            _ChoiceCard(
              title: 'Começar nova família',
              subtitle:
                  'Cadastre uma criança, crie missões e escolha os primeiros mimos.',
              icon: Icons.family_restroom_rounded,
              onTap: () {
                context.go('/initial-setup');
              },
            ),
            const SizedBox(height: ZeniSpacing.md),
            _ChoiceCard(
              title: 'Já tenho conta',
              subtitle:
                  'Entre com sua conta para restaurar família, crianças, missões e mimos salvos na nuvem.',
              icon: Icons.cloud_sync_rounded,
              onTap: _startRemoteRestore,
            ),
            if (_restoreMessage != null) ...[
              const SizedBox(height: ZeniSpacing.lg),
              ZeniCard(
                padding: const EdgeInsets.all(ZeniSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _restorationFailed
                          ? Icons.error_outline_rounded
                          : _isRestoring
                          ? Icons.sync_rounded
                          : Icons.info_outline_rounded,
                      color: _restorationFailed
                          ? Theme.of(context).colorScheme.error
                          : ZeniColors.primaryDark,
                    ),
                    const SizedBox(width: ZeniSpacing.sm),
                    Expanded(
                      child: Text(
                        _restoreMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _restorationFailed
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            ZeniPrimaryButton(
              label: 'Começar nova família',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                context.go('/initial-setup');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRemoteRestore() async {
    setState(() {
      _isRestoring = false;
      _restorationFailed = false;
      _restoreMessage =
          'Vamos restaurar a estrutura da sua família. Saldo, histórico e sequência não serão trazidos nesta etapa.';
    });

    final didAuthenticate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AuthAccountSheet(
            isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
          ),
        );
      },
    );

    if (!mounted || didAuthenticate != true) return;

    setState(() {
      _isRestoring = true;
      _restorationFailed = false;
      _restoreMessage =
          'Restaurando família, crianças, missões e mimos salvos na nuvem...';
    });

    final result = await ref
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();
    if (!mounted) return;

    setState(() {
      _isRestoring = false;
      _restorationFailed = !result.isSuccess;
      _restoreMessage = result.message;
    });
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x1A16A34A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: ZeniColors.primaryDark),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleLarge),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: ZeniColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: ZeniColors.primary),
        ],
      ),
    );
  }
}
