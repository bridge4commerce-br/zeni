import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../data/repositories/remote_missions_repository.dart';
import '../../data/repositories/supabase_remote_missions_repository.dart';

final remoteMissionsRepositoryProvider = Provider<RemoteMissionsRepository>((ref) {
  return SupabaseRemoteMissionsRepository(client: ZeniSupabaseBootstrap.client);
});

final remoteMissionsProvider = FutureProvider<List<RemoteMissionSummary>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
    return null;
  }

  final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
  if (remoteFamily == null) return null;

  final remoteChildren = await ref.watch(remoteChildrenProvider.future);
  if (remoteChildren == null || remoteChildren.isEmpty) {
    return null;
  }

  return ref
      .watch(remoteMissionsRepositoryProvider)
      .getRemoteMissions(familyId: remoteFamily.familyId);
});

final zeniRemoteMissionsControllerProvider = Provider<ZeniRemoteMissionsController>((ref) {
  return ZeniRemoteMissionsController(ref);
});

class ZeniRemoteMissionsController {
  const ZeniRemoteMissionsController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissionsForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Missões remotas indisponíveis neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Faça login para preparar as missões na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Prepare a família remota antes de sincronizar as missões.',
      );
    }

    final remoteChildren = await _ref.read(remoteChildrenProvider.future);
    if (remoteChildren == null || remoteChildren.isEmpty) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Prepare as crianças na nuvem antes de sincronizar as missões.',
      );
    }

    final remoteChildIdByLocalChildId = <String, String>{
      for (final child in remoteChildren)
        if (child.localId != null && child.localId!.isNotEmpty)
          child.localId!: child.id,
    };

    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    final result = await _ref
        .read(remoteMissionsRepositoryProvider)
        .ensureRemoteMissions(
          familyId: remoteFamily.familyId,
          localMissions: appState.missions,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
        );
    if (result.isSuccess) {
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(lastMissionsSyncAt: DateTime.now()),
          );
    }
    _ref.invalidate(remoteMissionsProvider);
    return result;
  }
}
