import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../auth/presentation/widgets/auth_account_sheet.dart';

class FamilyAccountPage extends ConsumerWidget {
  const FamilyAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          0,
          ZeniSpacing.md,
          0,
          ZeniSpacing.xxxl,
        ),
        child: ZeniPageFrame(
          width: ZeniPageWidth.focus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: const Key('family-account-back'),
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Voltar',
              ),
              const SizedBox(height: ZeniSpacing.sm),
              const ZeniBrandLogo(width: 76),
              const SizedBox(height: ZeniSpacing.xl),
              Text(
                'Guarde as conquistas da sua família',
                style: textTheme.displayLarge,
              ),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Crie uma conta grátis para recuperar seus dados e usar o Zeni em outros aparelhos.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                '✓ O Zeni continua funcionando offline.',
                style: textTheme.bodyMedium?.copyWith(
                  color: ZeniColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniPrimaryButton(
                label: 'Criar conta grátis',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _openAccountSheet(
                  context,
                  preferredEmailAction: AuthEmailAction.signUp,
                ),
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Já tenho conta',
                icon: Icons.login_rounded,
                onPressed: () => _openAccountSheet(
                  context,
                  preferredEmailAction: AuthEmailAction.signIn,
                ),
              ),
              const SizedBox(height: ZeniSpacing.md),
              Center(
                child: TextButton(
                  key: const Key('family-account-local-only'),
                  onPressed: () => context.go('/initial-setup'),
                  child: const Text('Continuar sem conta'),
                ),
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Center(
                child: Text(
                  'Você pode criar uma conta depois.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAccountSheet(
    BuildContext context, {
    required AuthEmailAction preferredEmailAction,
  }) async {
    final didAuthenticate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AuthAccountSheet(
          isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
          bootstrapState: ZeniSupabaseBootstrap.state,
          preferredEmailAction: preferredEmailAction,
        ),
      ),
    );

    if (context.mounted && didAuthenticate == true) {
      context.go('/initial-setup');
    }
  }
}
