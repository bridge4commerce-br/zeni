import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../domain/family_identity.dart';

/// Shared boundary for sync entry points and application of remote responses.
/// The destination is captured, never replaced with a later session's family.
class FamilyIdentityGuard {
  FamilyIdentityGuard(this.ref, {required this.familyId})
    : userId = ref.read(authStateProvider).user?.id;

  final Ref ref;
  final String familyId;
  final String? userId;

  bool get sessionIsCurrent {
    final auth = ref.read(authStateProvider);
    return userId != null && auth.isAuthenticated && auth.user?.id == userId;
  }

  FamilyIdentityStatus? get status {
    final local = ref.read(zeniAppStateControllerProvider).asData?.value;
    return local == null ? null : FamilyIdentity.evaluate(local, familyId);
  }

  bool get canSync => sessionIsCurrent && status == FamilyIdentityStatus.bound;

  bool get canBootstrap {
    final local = ref.read(zeniAppStateControllerProvider).asData?.value;
    return sessionIsCurrent &&
        local != null &&
        FamilyIdentity.isEmptySafe(local) &&
        (status == FamilyIdentityStatus.localUnboundSafe ||
            status == FamilyIdentityStatus.bound);
  }
}
