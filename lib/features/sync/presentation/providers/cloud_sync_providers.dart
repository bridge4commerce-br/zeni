import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/family_identity.dart';
import 'family_identity_guard.dart';
import 'device_bootstrap_providers.dart';

import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../balance/presentation/providers/remote_child_balance_providers.dart';
import '../../../balance/presentation/providers/remote_star_ledger_providers.dart';
import '../../../balance/data/repositories/remote_star_ledger_repository.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/repositories/remote_reward_requests_repository.dart';
import '../../../rewards/data/repositories/remote_rewards_repository.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../data/models/device_bootstrap_result.dart';
import '../../data/mappers/remote_incremental_sync_mapper.dart';
import '../../data/models/historical_restore_result.dart';
import '../../../tasks/data/repositories/remote_mission_logs_repository.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../../core/domain/zeni_enums.dart';

class ZeniCloudSyncResult {
  const ZeniCloudSyncResult({required this.status, this.message});

  const ZeniCloudSyncResult.success()
    : this(status: ZeniCloudSyncStatus.success);

  const ZeniCloudSyncResult.noSession(String message)
    : this(status: ZeniCloudSyncStatus.noSession, message: message);

  const ZeniCloudSyncResult.offline(String message)
    : this(status: ZeniCloudSyncStatus.offline, message: message);

  const ZeniCloudSyncResult.failure(String message)
    : this(status: ZeniCloudSyncStatus.error, message: message);

  final ZeniCloudSyncStatus status;
  final String? message;

  bool get isSuccess => status == ZeniCloudSyncStatus.success;
}

enum ZeniCloudSyncStatus { success, noSession, offline, error, familyMismatch }

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
  ZeniCloudSyncController(this._ref);

  final Ref _ref;
  Future<ZeniCloudSyncResult>? _inFlightSync;

  Future<ZeniCloudSyncResult> syncNowManually() async {
    return _runSingleFlight(() async {
      _debugLog('Manual sync started');
      if (!ZeniSupabaseBootstrap.state.isAvailable) {
        return const ZeniCloudSyncResult.failure(
          'Não foi possível sincronizar agora. Tente novamente em instantes.',
        );
      }

      final authState = _ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        return const ZeniCloudSyncResult.noSession(
          'Entre na conta para sincronizar com a nuvem.',
        );
      }

      final result = await _performSync();
      if (!result.isSuccess) {
        return result;
      }

      return const ZeniCloudSyncResult(
        status: ZeniCloudSyncStatus.success,
        message: 'Dados sincronizados neste aparelho.',
      );
    });
  }

  Future<ZeniCloudSyncResult> syncCloudDataNow() async {
    return _runSingleFlight(_performSync);
  }

  Future<ZeniCloudSyncResult> _performSync() async {
    _debugLog('Cloud sync started');
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniCloudSyncResult.failure(
        'Sincronização na nuvem indisponível neste build.',
      );
    }

    await _ref.read(zeniAppStateControllerProvider.future);
    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniCloudSyncResult.noSession(
        'Faça login para sincronizar seus dados.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniCloudSyncResult.failure(
        'Prepare a família remota antes de sincronizar.',
      );
    }

    await _ref.read(zeniAppStateControllerProvider.future);
    final identity = FamilyIdentityGuard(_ref, familyId: remoteFamily.familyId);
    if (identity.userId != authState.user?.id) return _identityBlocked;
    if (identity.status == FamilyIdentityStatus.localUnboundSafe &&
        identity.canBootstrap) {
      final bootstrap = await _ref
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      if (!bootstrap.isSuccess) {
        return ZeniCloudSyncResult.failure(
          bootstrap.message ?? 'Falha na recuperação.',
        );
      }
    }
    if (!identity.canSync) return _identityBlocked;

    final childrenResult = await _ref
        .read(zeniRemoteChildrenControllerProvider)
        .ensureRemoteChildrenForCurrentFamily();
    if (!childrenResult.isSuccess) {
      _debugLog('Children sync failed: ${childrenResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final missionsResult = await _ref
        .read(zeniRemoteMissionsControllerProvider)
        .ensureRemoteMissionsForCurrentFamily();
    if (!missionsResult.isSuccess) {
      _debugLog('Missions sync failed: ${missionsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final rewardsResult = await _ref
        .read(zeniRemoteRewardsControllerProvider)
        .ensureRemoteRewardsForCurrentFamily();
    if (!rewardsResult.isSuccess) {
      _debugLog('Rewards sync failed: ${rewardsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final missionLogsResult = await _ref
        .read(zeniRemoteMissionLogsControllerProvider)
        .ensureRemoteMissionLogsForCurrentFamily();
    if (!missionLogsResult.isSuccess) {
      _debugLog('Mission logs sync failed: ${missionLogsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final rewardRequestsResult = await _ref
        .read(zeniRemoteRewardRequestsControllerProvider)
        .ensureRemoteRewardRequestsForCurrentFamily();
    if (!rewardRequestsResult.isSuccess) {
      _debugLog('Reward requests sync failed: ${rewardRequestsResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final starLedgerResult = await _ref
        .read(zeniRemoteStarLedgerControllerProvider)
        .ensureRemoteStarLedgerForCurrentFamily();
    if (!starLedgerResult.isSuccess) {
      _debugLog('Star ledger sync failed: ${starLedgerResult.message}');
      return const ZeniCloudSyncResult.failure(
        'Não foi possível sincronizar agora. Tente novamente.',
      );
    }

    if (!identity.canSync) return _identityBlocked;
    final pullResult = await _pullRemoteChanges(
      identity: identity,
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
    if (!identity.canSync) return _identityBlocked;
    await _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(
          appState.appSettings.copyWith(lastFullSyncAt: DateTime.now()),
        );
    _debugLog('Cloud sync finished successfully');
    return const ZeniCloudSyncResult.success();
  }

  Future<HistoricalRestoreResult> _pullRemoteChanges({
    required FamilyIdentityGuard identity,
    required String remoteFamilyId,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required List<RemoteMissionLogSummary> remoteMissionLogs,
    required List<RemoteRewardRequestSummary> remoteRewardRequests,
    required List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries,
  }) async {
    _debugLog(
      'Pulling remote changes: children=${remoteChildren.length}, '
      'missions=${remoteMissions.length}, rewards=${remoteRewards.length}, '
      'missionLogs=${remoteMissionLogs.length}, '
      'rewardRequests=${remoteRewardRequests.length}, '
      'starLedgerEntries=${remoteStarLedgerEntries.length}',
    );
    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    if (!identity.canSync) return _identityPullBlocked;
    final catalogPayload = _buildRemoteCatalogPayload(
      localState: localState,
      remoteFamily: remoteFamilyId,
      remoteChildren: remoteChildren,
      remoteMissions: remoteMissions,
      remoteRewards: remoteRewards,
    );
    await _ref
        .read(zeniAppStateControllerProvider.notifier)
        .applyRemoteCatalogSnapshot(catalogPayload);

    final syncedState = await _ref.read(zeniAppStateControllerProvider.future);
    final remoteChildBalances = await _ref
        .read(remoteChildBalanceRepositoryProvider)
        .getRemoteChildStarBalances(familyId: remoteFamilyId);
    if (!identity.canSync) return _identityPullBlocked;
    final mappedResult = _ref
        .read(remoteIncrementalSyncMapperProvider)
        .map(
          localState: syncedState,
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
      _debugLog(
        'Remote snapshot applied: missionLogs=${mappedResult.payload!.missionLogs.length}, '
        'rewardRequests=${mappedResult.payload!.rewardRequests.length}, '
        'starLedgerEntries=${mappedResult.payload!.starLedgerEntries.length}',
      );
      _ref.invalidate(remoteMissionLogsProvider);
      _ref.invalidate(remoteRewardRequestsProvider);
      _ref.invalidate(remoteStarLedgerProvider);
      _ref.invalidate(remoteChildBalancesProvider);
    }
    return applyResult;
  }

  DeviceBootstrapPayload _buildRemoteCatalogPayload({
    required ZeniAppState localState,
    required String remoteFamily,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
  }) {
    final now = DateTime.now();
    final existingChildrenById = <String, ChildProfile>{
      for (final child in localState.children) child.id: child,
    };
    final childIdByRemoteId = <String, String>{};

    final children = [
      for (final remoteChild in remoteChildren)
        (() {
          final localChildId = _preferredLocalId(
            remoteChild.localId,
            remoteChild.id,
          );
          childIdByRemoteId[remoteChild.id] = localChildId;
          final existingChild = existingChildrenById[localChildId];
          if (existingChild != null) {
            return existingChild.copyWith(
              familyId: localState.family.id,
              name: remoteChild.name,
              birthDate: remoteChild.birthDate,
              isActive: !remoteChild.isArchived,
            );
          }

          return ChildProfile(
            id: localChildId,
            familyId: localState.family.id,
            name: remoteChild.name,
            emoji: _mapEmoji(remoteChild.avatarKey, '🦊'),
            avatarUrl: null,
            birthDate: remoteChild.birthDate,
            starBalance: 0,
            streakCount: 0,
            ttsEnabled: false,
            isActive: !remoteChild.isArchived,
            createdAt: now,
          );
        })(),
    ];

    final existingMissionsById = <String, Mission>{
      for (final mission in localState.missions) mission.id: mission,
    };
    final missions = [
      for (final remoteMission in remoteMissions)
        (() {
          final localMissionId = _preferredLocalId(
            remoteMission.localId,
            remoteMission.id,
          );
          final localChildId =
              childIdByRemoteId[remoteMission.childId] ?? remoteMission.childId;
          final recurrence = missionRecurrenceFromStorage(
            remoteMission.recurrenceType,
          );
          final existingMission = existingMissionsById[localMissionId];
          if (existingMission != null) {
            return existingMission.copyWith(
              familyId: localState.family.id,
              childId: localChildId,
              title: remoteMission.title,
              stars: remoteMission.stars,
              recurrence: recurrence,
              customDaysOfWeek: recurrence == MissionRecurrence.customDaysOfWeek
                  ? remoteMission.recurrenceDays
                  : const <int>[],
              approvalMode: remoteMission.requiresApproval
                  ? MissionApprovalMode.parentApproval
                  : MissionApprovalMode.automatic,
              status:
                  remoteMission.archivedAt != null || !remoteMission.isActive
                  ? MissionStatus.archived
                  : MissionStatus.active,
              updatedAt: now,
            );
          }

          return Mission(
            id: localMissionId,
            familyId: localState.family.id,
            childId: localChildId,
            title: remoteMission.title,
            description: 'Missão restaurada da nuvem.',
            emoji: '✅',
            stars: remoteMission.stars,
            recurrence: recurrence,
            customDaysOfWeek: recurrence == MissionRecurrence.customDaysOfWeek
                ? remoteMission.recurrenceDays
                : const <int>[],
            timeGroup: MissionTimeGroup.anytime,
            approvalMode: remoteMission.requiresApproval
                ? MissionApprovalMode.parentApproval
                : MissionApprovalMode.automatic,
            status: remoteMission.archivedAt != null || !remoteMission.isActive
                ? MissionStatus.archived
                : MissionStatus.active,
            requiresPhoto: false,
            createdAt: now,
            updatedAt: now,
          );
        })(),
    ];

    final existingRewardsById = <String, Reward>{
      for (final reward in localState.rewards) reward.id: reward,
    };
    final rewards = [
      for (final remoteReward in remoteRewards)
        (() {
          final localRewardId = _preferredLocalId(
            remoteReward.localId,
            remoteReward.id,
          );
          final localChildId = remoteReward.childId == null
              ? null
              : childIdByRemoteId[remoteReward.childId!];
          final existingReward = existingRewardsById[localRewardId];
          if (existingReward != null) {
            return existingReward.copyWith(
              familyId: localState.family.id,
              childId: localChildId,
              title: remoteReward.title,
              cost: remoteReward.cost,
              isActive:
                  remoteReward.archivedAt == null && remoteReward.isActive,
              updatedAt: now,
            );
          }

          return Reward(
            id: localRewardId,
            familyId: localState.family.id,
            childId: localChildId,
            title: remoteReward.title,
            description: 'Mimo restaurado da nuvem.',
            emoji: _mapEmoji(remoteReward.imageKey, '🎁'),
            cost: remoteReward.cost,
            renewal: RewardRenewal.always,
            isActive: remoteReward.archivedAt == null && remoteReward.isActive,
            createdAt: now,
            updatedAt: now,
          );
        })(),
    ];

    return DeviceBootstrapPayload(
      family: localState.family.copyWith(
        name: localState.family.name,
        id: remoteFamily,
      ),
      children: children,
      missions: missions,
      rewards: rewards,
    );
  }

  String _preferredLocalId(String? localId, String remoteId) {
    final trimmed = localId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }

    return remoteId;
  }

  String _mapEmoji(String? rawValue, String fallback) {
    final trimmed = rawValue?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }

    return trimmed;
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniCloudSync] $message');
  }

  Future<ZeniCloudSyncResult> _runSingleFlight(
    Future<ZeniCloudSyncResult> Function() action,
  ) {
    final inFlightSync = _inFlightSync;
    if (inFlightSync != null) {
      _debugLog('Reusing in-flight sync');
      return inFlightSync;
    }

    final future = action().whenComplete(() {
      _inFlightSync = null;
    });
    _inFlightSync = future;
    return future;
  }

  static const _identityBlocked = ZeniCloudSyncResult(
    status: ZeniCloudSyncStatus.familyMismatch,
    message: familyIdentityBlockedMessage,
  );

  static const _identityPullBlocked = HistoricalRestoreResult.failure(
    status: HistoricalRestoreResultStatus.applyBlocked,
    message: familyIdentityBlockedMessage,
  );
}
