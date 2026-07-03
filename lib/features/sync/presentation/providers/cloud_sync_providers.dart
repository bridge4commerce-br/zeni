import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../balance/presentation/providers/remote_child_balance_providers.dart';
import '../../../balance/presentation/providers/remote_star_ledger_providers.dart';
import '../../../balance/data/repositories/remote_star_ledger_repository.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/data/repositories/remote_reward_requests_repository.dart';
import '../../../rewards/data/repositories/remote_rewards_repository.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../data/mappers/remote_incremental_sync_mapper.dart';
import '../../data/models/historical_restore_result.dart';
import '../../../tasks/data/repositories/remote_mission_logs_repository.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';

class ZeniCloudSyncResult {
  const ZeniCloudSyncResult({required this.isSuccess, this.message});

  const ZeniCloudSyncResult.success() : this(isSuccess: true);

  const ZeniCloudSyncResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
}

final zeniCloudSyncControllerProvider = Provider<ZeniCloudSyncController>((
  ref,
) {
  return ZeniCloudSyncController(ref);
});

final remoteIncrementalSyncMapperProvider =
    Provider<RemoteIncrementalSyncMapper>(
      (ref) => const RemoteIncrementalSyncMapper(),
    );

class ZeniCloudSyncController {
  const ZeniCloudSyncController(this._ref);

  final Ref _ref;

  Future<ZeniCloudSyncResult> syncCloudDataNow() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniCloudSyncResult.failure(
        'Sincronização na nuvem indisponível neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniCloudSyncResult.failure(
        'Faça login para sincronizar seus dados.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniCloudSyncResult.failure(
        'Prepare a família remota antes de sincronizar.',
      );
    }

    final childrenResult = await _ref
        .read(zeniRemoteChildrenControllerProvider)
        .ensureRemoteChildrenForCurrentFamily();
    if (!childrenResult.isSuccess) {
      _debugLog('Children sync failed: ${childrenResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final missionsResult = await _ref
        .read(zeniRemoteMissionsControllerProvider)
        .ensureRemoteMissionsForCurrentFamily();
    if (!missionsResult.isSuccess) {
      _debugLog('Missions sync failed: ${missionsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final rewardsResult = await _ref
        .read(zeniRemoteRewardsControllerProvider)
        .ensureRemoteRewardsForCurrentFamily();
    if (!rewardsResult.isSuccess) {
      _debugLog('Rewards sync failed: ${rewardsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final missionLogsResult = await _ref
        .read(zeniRemoteMissionLogsControllerProvider)
        .ensureRemoteMissionLogsForCurrentFamily();
    if (!missionLogsResult.isSuccess) {
      _debugLog('Mission logs sync failed: ${missionLogsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final rewardRequestsResult = await _ref
        .read(zeniRemoteRewardRequestsControllerProvider)
        .ensureRemoteRewardRequestsForCurrentFamily();
    if (!rewardRequestsResult.isSuccess) {
      _debugLog('Reward requests sync failed: ${rewardRequestsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final starLedgerResult = await _ref
        .read(zeniRemoteStarLedgerControllerProvider)
        .ensureRemoteStarLedgerForCurrentFamily();
    if (!starLedgerResult.isSuccess) {
      _debugLog('Star ledger sync failed: ${starLedgerResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    final pullResult = await _pullRemoteChanges(
      remoteFamilyId: remoteFamily.familyId,
      remoteChildren: childrenResult.children,
      remoteMissions: missionsResult.missions,
      remoteRewards: rewardsResult.rewards,
      remoteMissionLogs: missionLogsResult.missionLogs,
      remoteRewardRequests: rewardRequestsResult.requests,
      remoteStarLedgerEntries: starLedgerResult.entries,
    );
    if (!pullResult.isSuccess) {
      _debugLog('Remote pull sync failed: ${pullResult.message}');
      return ZeniCloudSyncResult.failure(pullResult.message);
    }

    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    await _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(
          appState.appSettings.copyWith(lastFullSyncAt: DateTime.now()),
        );
    return const ZeniCloudSyncResult.success();
  }

  Future<HistoricalRestoreResult> _pullRemoteChanges({
    required String remoteFamilyId,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required List<RemoteMissionLogSummary> remoteMissionLogs,
    required List<RemoteRewardRequestSummary> remoteRewardRequests,
    required List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries,
  }) async {
    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    final remoteChildBalances = await _ref
        .read(remoteChildBalanceRepositoryProvider)
        .getRemoteChildStarBalances(familyId: remoteFamilyId);
    final mappedResult = _ref
        .read(remoteIncrementalSyncMapperProvider)
        .map(
          localState: localState,
          remoteChildren: remoteChildren,
          remoteMissions: remoteMissions,
          remoteRewards: remoteRewards,
          remoteMissionLogs: remoteMissionLogs,
          remoteRewardRequests: remoteRewardRequests,
          remoteStarLedgerEntries: remoteStarLedgerEntries,
          remoteChildBalances: remoteChildBalances,
        );
    if (!mappedResult.isSuccess) {
      return mappedResult;
    }

    final applyResult = await _ref
        .read(zeniAppStateControllerProvider.notifier)
        .applyRemoteSyncSnapshot(mappedResult.payload!);
    if (applyResult.isSuccess) {
      _ref.invalidate(remoteMissionLogsProvider);
      _ref.invalidate(remoteRewardRequestsProvider);
      _ref.invalidate(remoteStarLedgerProvider);
      _ref.invalidate(remoteChildBalancesProvider);
    }
    return applyResult;
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniCloudSync] $message');
  }
}
