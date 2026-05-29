import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../data/repositories/remote_rewards_repository.dart';
import '../../data/repositories/supabase_remote_rewards_repository.dart';

final remoteRewardsRepositoryProvider = Provider<RemoteRewardsRepository>((
  ref,
) {
  return SupabaseRemoteRewardsRepository(client: ZeniSupabaseBootstrap.client);
});

final remoteRewardsProvider = FutureProvider<List<RemoteRewardSummary>?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
    return null;
  }

  final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
  if (remoteFamily == null) return null;

  return ref
      .watch(remoteRewardsRepositoryProvider)
      .getRemoteRewards(familyId: remoteFamily.familyId);
});

final zeniRemoteRewardsControllerProvider =
    Provider<ZeniRemoteRewardsController>((ref) {
      return ZeniRemoteRewardsController(ref);
    });

class ZeniRemoteRewardsController {
  const ZeniRemoteRewardsController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteRewardsResult>
  ensureRemoteRewardsForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Mimos remotos indisponíveis neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Faça login para preparar os mimos na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Prepare a família remota antes de sincronizar os mimos.',
      );
    }

    final remoteChildren = await _ref.read(remoteChildrenProvider.future);
    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    final hasChildScopedRewards = appState.rewards.any(
      (reward) => reward.childId != null,
    );

    if (hasChildScopedRewards &&
        (remoteChildren == null || remoteChildren.isEmpty)) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Sincronize os dados principais primeiro para preparar os mimos.',
      );
    }

    final availableChildren = remoteChildren ?? const <RemoteChildSummary>[];
    final remoteChildIdByLocalChildId = <String, String>{
      for (final child in availableChildren)
        if (child.localId != null && child.localId!.isNotEmpty)
          child.localId!: child.id,
    };

    final result = await _ref
        .read(remoteRewardsRepositoryProvider)
        .ensureRemoteRewards(
          familyId: remoteFamily.familyId,
          localRewards: appState.rewards,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
        );
    if (result.isSuccess) {
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(lastRewardsSyncAt: DateTime.now()),
          );
    }
    _ref.invalidate(remoteRewardsProvider);
    return result;
  }
}
