import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../auth/presentation/widgets/auth_account_sheet.dart';

class FamilyAccountPage extends ConsumerWidget {
  const FamilyAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = ZeniTypography.of(context);

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
                style: typography.display,
              ),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Entre ou crie sua conta para identificar sua família com segurança em todos os aparelhos.',
                style: typography.body,
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniSurface(
                role: ZeniSurfaceRole.highlight,
                mode: ZeniVisualMode.parent,
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt_rounded),
                    const SizedBox(width: ZeniSpacing.spaceInline),
                    Expanded(
                      child: Text(
                        'O Zeni continua funcionando offline.',
                        style: typography.metadata,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniButton(
                label: 'Criar conta grátis',
                icon: Icons.person_add_alt_1_rounded,
                role: ZeniButtonRole.primary,
                mode: ZeniVisualMode.parent,
                onPressed: () => _openAccountSheet(
                  context,
                  preferredEmailAction: AuthEmailAction.signUp,
                ),
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniButton(
                label: 'Já tenho conta',
                icon: Icons.login_rounded,
                role: ZeniButtonRole.secondary,
                mode: ZeniVisualMode.parent,
                onPressed: () => _openAccountSheet(
                  context,
                  preferredEmailAction: AuthEmailAction.signIn,
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
    final content = AuthAccountSheet(
      isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
      bootstrapState: ZeniSupabaseBootstrap.state,
      preferredEmailAction: preferredEmailAction,
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

    if (context.mounted && didAuthenticate == true) {
      context.go('/');
    }
  }
}
