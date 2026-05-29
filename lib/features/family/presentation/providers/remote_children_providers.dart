import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/zeni_repository_providers.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../data/repositories/remote_children_repository.dart';
import '../../data/repositories/supabase_remote_children_repository.dart';

final remoteChildrenRepositoryProvider = Provider<RemoteChildrenRepository>((
  ref,
) {
  return SupabaseRemoteChildrenRepository(client: ZeniSupabaseBootstrap.client);
});

final remoteChildrenProvider = FutureProvider<List<RemoteChildSummary>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
    return null;
  }

  final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
  if (remoteFamily == null) return null;

  return ref
      .watch(remoteChildrenRepositoryProvider)
      .getRemoteChildren(familyId: remoteFamily.familyId);
});

final zeniRemoteChildrenControllerProvider = Provider<ZeniRemoteChildrenController>((ref) {
  return ZeniRemoteChildrenController(ref);
});

class ZeniRemoteChildrenController {
  const ZeniRemoteChildrenController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildrenForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Crianças remotas indisponíveis neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Faça login para preparar as crianças na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Prepare a família remota antes de sincronizar as crianças.',
      );
    }

    final localChildren = await _ref
        .read(familyRepositoryProvider)
        .getChildren(includeArchived: true);
    final result = await _ref
        .read(remoteChildrenRepositoryProvider)
        .ensureRemoteChildren(
          familyId: remoteFamily.familyId,
          localChildren: localChildren,
        );
    if (result.isSuccess) {
      final appState = await _ref.read(zeniAppStateControllerProvider.future);
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(lastChildrenSyncAt: DateTime.now()),
          );
    }
    _ref.invalidate(remoteChildrenProvider);
    return result;
  }
}
