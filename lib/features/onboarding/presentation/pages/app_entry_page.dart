import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../profile/presentation/pages/profile_choice_page.dart';
import 'canonical_family_gate_page.dart';
import 'family_account_page.dart';
import 'initial_family_setup_page.dart';
import 'onboarding_flow_page.dart';

class AppEntryPage extends ConsumerWidget {
  const AppEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(zeniAppStateControllerProvider);
    final authState = ref.watch(authStateProvider);

    return appState.when(
      loading: () =>
          const ZeniScaffold(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const ZeniScaffold(
        child: Center(child: Text('Não foi possível carregar o app.')),
      ),
      data: (state) {
        if (state.shouldShowOnboarding) {
          return const OnboardingFlowPage();
        }

        if (state.hasUserContent) {
          return const ProfileChoicePage();
        }

        if (!authState.isAuthenticated) {
          return const FamilyAccountPage();
        }

        switch (authState.familyIdentityAccess) {
          case ZeniFamilyIdentityAccess.pending:
            return const CanonicalFamilyGatePage();
          case ZeniFamilyIdentityAccess.blocked:
            return const FamilyAccountPage();
          case ZeniFamilyIdentityAccess.ready:
            return state.family.id == 'local-family'
                ? const CanonicalFamilyGatePage()
                : const InitialFamilySetupPage();
        }
      },
    );
  }
}
