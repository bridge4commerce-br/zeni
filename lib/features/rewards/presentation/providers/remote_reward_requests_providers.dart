import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../data/repositories/remote_reward_requests_repository.dart';
import '../../data/repositories/remote_rewards_repository.dart';
import '../../data/repositories/supabase_remote_reward_requests_repository.dart';
import 'remote_rewards_providers.dart';

final remoteRewardRequestsRepositoryProvider =
    Provider<RemoteRewardRequestsRepository>((ref) {
      return SupabaseRemoteRewardRequestsRepository(
        client: ZeniSupabaseBootstrap.client,
      );
    });

final remoteRewardRequestsProvider =
    FutureProvider<List<RemoteRewardRequestSummary>?>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable ||
          !authState.isAuthenticated) {
        return null;
      }

      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) return null;

      final remoteChildren = await ref.watch(remoteChildrenProvider.future);
      final remoteRewards = await ref.watch(remoteRewardsProvider.future);
      if (remoteChildren == null ||
          remoteChildren.isEmpty ||
          remoteRewards == null ||
          remoteRewards.isEmpty) {
        return null;
      }

      return ref
          .watch(remoteRewardRequestsRepositoryProvider)
          .getRemoteRewardRequests(familyId: remoteFamily.familyId);
    });

final zeniRemoteRewardRequestsControllerProvider =
    Provider<ZeniRemoteRewardRequestsController>((ref) {
      return ZeniRemoteRewardRequestsController(ref);
    });

class ZeniRemoteRewardRequestsController {
  const ZeniRemoteRewardRequestsController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteRewardRequestsResult>
  ensureRemoteRewardRequestsForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Pedidos remotos de mimos indisponíveis neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Faça login para preparar os pedidos na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Prepare a família remota antes de sincronizar os pedidos.',
      );
    }

    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    final localRewardRequests = appState.rewardRequests;

    final remoteChildren = await _ref.read(remoteChildrenProvider.future);
    if (localRewardRequests.isNotEmpty &&
        (remoteChildren == null || remoteChildren.isEmpty)) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Sincronize os dados principais primeiro para preparar os pedidos.',
      );
    }

    final remoteRewards = await _ref.read(remoteRewardsProvider.future);
    if (localRewardRequests.isNotEmpty &&
        (remoteRewards == null || remoteRewards.isEmpty)) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Sincronize os dados principais primeiro para preparar os pedidos.',
      );
    }

    final availableChildren = remoteChildren ?? const <RemoteChildSummary>[];
    final availableRewards = remoteRewards ?? const <RemoteRewardSummary>[];
    final remoteChildIdByLocalChildId = <String, String>{
      for (final child in availableChildren)
        if (child.localId != null && child.localId!.isNotEmpty)
          child.localId!: child.id,
    };
    final remoteRewardByLocalRewardId =
        <String, ({String remoteRewardId, int cost})>{
          for (final reward in availableRewards)
            if (reward.localId != null && reward.localId!.isNotEmpty)
              reward.localId!: (remoteRewardId: reward.id, cost: reward.cost),
        };
    final result = await _ref
        .read(remoteRewardRequestsRepositoryProvider)
        .ensureRemoteRewardRequests(
          familyId: remoteFamily.familyId,
          localRewardRequests: localRewardRequests,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
          remoteRewardByLocalRewardId: remoteRewardByLocalRewardId,
        );
    if (result.isSuccess) {
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(
              lastRewardRequestsSyncAt: DateTime.now(),
            ),
          );
    }
    _ref.invalidate(remoteRewardRequestsProvider);
    return result;
  }
}
