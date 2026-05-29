import 'package:go_router/go_router.dart';

import '../features/child/presentation/pages/child_shell_page.dart';
import '../features/onboarding/presentation/pages/app_entry_page.dart';
import '../features/onboarding/presentation/pages/initial_family_setup_page.dart';
import '../features/onboarding/presentation/pages/onboarding_flow_page.dart';
import '../features/onboarding/presentation/pages/onboarding_preview_page.dart';
import '../features/parent/presentation/pages/parent_shell_page.dart';

GoRouter createZeniRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppEntryPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowPage(),
      ),
      GoRoute(
        path: '/initial-setup',
        builder: (context, state) => const InitialFamilySetupPage(),
      ),
      GoRoute(
        path: '/child/:childId',
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;

          return ChildShellPage(childId: childId);
        },
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentShellPage(),
      ),
      GoRoute(
        path: '/dev/components',
        builder: (context, state) => const OnboardingPreviewPage(),
      ),
    ],
  );
}
