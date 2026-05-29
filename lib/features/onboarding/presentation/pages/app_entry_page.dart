import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../profile/presentation/pages/profile_choice_page.dart';
import 'onboarding_flow_page.dart';

class AppEntryPage extends ConsumerWidget {
  const AppEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(zeniAppStateControllerProvider);

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

        return const ProfileChoicePage();
      },
    );
  }
}
