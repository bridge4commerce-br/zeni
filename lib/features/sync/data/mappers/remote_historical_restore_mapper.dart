import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../balance/data/repositories/remote_child_balance_repository.dart';
import '../../../balance/data/repositories/remote_star_ledger_repository.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../rewards/data/repositories/remote_reward_requests_repository.dart';
import '../../../rewards/data/repositories/remote_rewards_repository.dart';
import '../../../sync/data/models/historical_restore_result.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/data/repositories/remote_mission_logs_repository.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';

class RemoteHistoricalRestoreMapper {
  const RemoteHistoricalRestoreMapper();

  HistoricalRestoreResult map({
    required ZeniAppState localState,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required List<RemoteMissionLogSummary> remoteMissionLogs,
    required List<RemoteRewardRequestSummary> remoteRewardRequests,
    required List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries,
    required List<RemoteChildStarBalance> remoteChildBalances,
    DateTime? restoredAt,
  }) {
    final childMapping = _buildChildMapping(
      localChildren: localState.children,
      remoteChildren: remoteChildren,
    );
    if (childMapping == null) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.catalogsNotAligned,
        message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
      );
    }

    final missionMapping = _buildMissionMapping(
      localMissions: localState.missions,
      remoteMissions: remoteMissions,
    );
    if (missionMapping == null) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.catalogsNotAligned,
        message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
      );
    }

    final rewardMapping = _buildRewardMapping(
      localRewards: localState.rewards,
      remoteRewards: remoteRewards,
    );
    if (rewardMapping == null) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.catalogsNotAligned,
        message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
      );
    }

    final missionLogs = <MissionLog>[];
    final missionLogIdByRemoteId = <String, String>{};
    final missionLogIds = <String>{};
    for (final remoteLog in remoteMissionLogs) {
      final localChildId = childMapping[remoteLog.childId];
      final localMissionId = missionMapping[remoteLog.missionId];
      final localLogId = _preferredLocalId(remoteLog.localId, remoteLog.id);
      if (localChildId == null ||
          localMissionId == null ||
          !missionLogIds.add(localLogId)) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.catalogsNotAligned,
          message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
        );
      }

      missionLogs.add(
        MissionLog(
          id: localLogId,
          missionId: localMissionId,
          childId: localChildId,
          scheduledDate: remoteLog.scheduledDate,
          status: _missionLogStatusFromRemote(remoteLog.status),
          starsAwarded: remoteLog.starsAwarded,
          completedAt: remoteLog.completedAt ?? remoteLog.submittedAt,
          approvedAt: remoteLog.approvedAt,
          rejectedAt: remoteLog.rejectedAt,
          photoUrl: remoteLog.photoUrl,
          note: remoteLog.note,
        ),
      );
      missionLogIdByRemoteId[remoteLog.id] = localLogId;
    }

    final rewardRequests = <RewardRequest>[];
    final rewardRequestIdByRemoteId = <String, String>{};
    final rewardRequestIds = <String>{};
    for (final remoteRequest in remoteRewardRequests) {
      final localChildId = childMapping[remoteRequest.childId];
      final localRewardId = rewardMapping[remoteRequest.rewardId];
      final localRequestId = _preferredLocalId(
        remoteRequest.localId,
        remoteRequest.id,
      );
      if (localChildId == null ||
          localRewardId == null ||
          !rewardRequestIds.add(localRequestId)) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.catalogsNotAligned,
          message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
        );
      }

      rewardRequests.add(
        RewardRequest(
          id: localRequestId,
          rewardId: localRewardId,
          childId: localChildId,
          status: _rewardRequestStatusFromRemote(remoteRequest.status),
          requestedAt: remoteRequest.requestedAt ?? DateTime.now(),
          resolvedAt:
              remoteRequest.approvedAt ??
              remoteRequest.rejectedAt ??
              remoteRequest.cancelledAt,
          note: remoteRequest.note,
        ),
      );
      rewardRequestIdByRemoteId[remoteRequest.id] = localRequestId;
    }

    final localFamilyId = localState.family.id;
    final localMissionById = <String, Mission>{
      for (final mission in localState.missions) mission.id: mission,
    };
    final localRewardById = <String, Reward>{
      for (final reward in localState.rewards) reward.id: reward,
    };
    final missionLogById = <String, MissionLog>{
      for (final log in missionLogs) log.id: log,
    };
    final rewardRequestById = <String, RewardRequest>{
      for (final request in rewardRequests) request.id: request,
    };
    final rebuiltEntries = [...remoteStarLedgerEntries]
      ..sort(_compareRemoteLedgerEntries);

    final balancesByChildId = <String, int>{
      for (final child in localState.children) child.id: 0,
    };
    final localLedgerEntries = <StarLedgerEntry>[];
    final ledgerEntryIds = <String>{};

    for (final remoteEntry in rebuiltEntries) {
      final localChildId = childMapping[remoteEntry.childId];
      final localEntryId = _preferredLocalId(
        remoteEntry.sourceLocalId,
        remoteEntry.id,
      );
      if (localChildId == null || !ledgerEntryIds.add(localEntryId)) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.catalogsNotAligned,
          message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
        );
      }

      final entryType = _mapLedgerEntryType(remoteEntry);
      if (entryType == null) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.applyBlocked,
          message: 'Não foi possível restaurar o histórico agora.',
        );
      }

      final signedAmount = _signedAmount(remoteEntry);
      final nextBalance = (balancesByChildId[localChildId] ?? 0) + signedAmount;
      balancesByChildId[localChildId] = nextBalance;

      final localMissionLogId = remoteEntry.sourceType == 'mission_log'
          ? _resolveRelatedId(
              remoteId: remoteEntry.sourceId,
              remoteLocalId: remoteEntry.sourceLocalId,
              remoteToLocalMap: missionLogIdByRemoteId,
              existingIds: missionLogIds,
            )
          : null;
      final localRewardRequestId = remoteEntry.sourceType == 'reward_request'
          ? _resolveRelatedId(
              remoteId: remoteEntry.sourceId,
              remoteLocalId: remoteEntry.sourceLocalId,
              remoteToLocalMap: rewardRequestIdByRemoteId,
              existingIds: rewardRequestIds,
            )
          : null;

      if ((remoteEntry.sourceType == 'mission_log' && localMissionLogId == null) ||
          (remoteEntry.sourceType == 'reward_request' &&
              localRewardRequestId == null)) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.catalogsNotAligned,
          message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
        );
      }

      localLedgerEntries.add(
        StarLedgerEntry(
          id: localEntryId,
          familyId: localFamilyId,
          childId: localChildId,
          amount: signedAmount,
          balanceAfter: nextBalance,
          type: entryType,
          title: _buildLedgerTitle(
            entryType: entryType,
            remoteEntry: remoteEntry,
            localMissionById: localMissionById,
            localRewardById: localRewardById,
            missionLogById: missionLogById,
            rewardRequestById: rewardRequestById,
            localMissionLogId: localMissionLogId,
            localRewardRequestId: localRewardRequestId,
          ),
          description: remoteEntry.reason,
          createdAt: remoteEntry.occurredAt,
          relatedMissionLogId: localMissionLogId,
          relatedRewardRequestId: localRewardRequestId,
        ),
      );
    }

    final remoteBalanceByLocalChildId = <String, int>{};
    for (final remoteBalance in remoteChildBalances) {
      final localChildId = childMapping[remoteBalance.childId];
      if (localChildId == null) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.catalogsNotAligned,
          message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
        );
      }
      remoteBalanceByLocalChildId[localChildId] = remoteBalance.derivedBalance;
    }

    if (remoteBalanceByLocalChildId.length != localState.children.length) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.unsafeBalanceMismatch,
        message: 'Não foi possível restaurar o histórico com segurança. O saldo da nuvem não confere com os eventos.',
      );
    }

    for (final child in localState.children) {
      final rebuiltBalance = balancesByChildId[child.id] ?? 0;
      if (remoteBalanceByLocalChildId[child.id] != rebuiltBalance) {
        return const HistoricalRestoreResult.failure(
          status: HistoricalRestoreResultStatus.unsafeBalanceMismatch,
          message: 'Não foi possível restaurar o histórico com segurança. O saldo da nuvem não confere com os eventos.',
        );
      }
    }

    final rebuiltChildren = [
      for (final child in localState.children)
        child.copyWith(starBalance: balancesByChildId[child.id] ?? 0),
    ];

    return HistoricalRestoreResult.success(
      payload: HistoricalRestorePayload(
        missionLogs: missionLogs,
        rewardRequests: rewardRequests,
        starLedgerEntries: localLedgerEntries,
        rebuiltChildren: rebuiltChildren,
        restoredAt: restoredAt ?? DateTime.now(),
      ),
    );
  }

  Map<String, String>? _buildChildMapping({
    required List<ChildProfile> localChildren,
    required List<RemoteChildSummary> remoteChildren,
  }) {
    if (localChildren.isEmpty || remoteChildren.length != localChildren.length) {
      return null;
    }

    final localIds = localChildren.map((child) => child.id).toSet();
    final mapping = <String, String>{};
    final usedLocalIds = <String>{};
    for (final remoteChild in remoteChildren) {
      final localId = _preferredLocalId(remoteChild.localId, remoteChild.id);
      if (!localIds.contains(localId) || !usedLocalIds.add(localId)) {
        return null;
      }
      mapping[remoteChild.id] = localId;
    }

    return usedLocalIds.length == localIds.length ? mapping : null;
  }

  Map<String, String>? _buildMissionMapping({
    required List<Mission> localMissions,
    required List<RemoteMissionSummary> remoteMissions,
  }) {
    final localIds = localMissions.map((mission) => mission.id).toSet();
    if (remoteMissions.length != localIds.length) {
      return null;
    }

    final mapping = <String, String>{};
    final usedLocalIds = <String>{};
    for (final remoteMission in remoteMissions) {
      final localId = _preferredLocalId(remoteMission.localId, remoteMission.id);
      if (!localIds.contains(localId) || !usedLocalIds.add(localId)) {
        return null;
      }
      mapping[remoteMission.id] = localId;
    }

    return usedLocalIds.length == localIds.length ? mapping : null;
  }

  Map<String, String>? _buildRewardMapping({
    required List<Reward> localRewards,
    required List<RemoteRewardSummary> remoteRewards,
  }) {
    final localIds = localRewards.map((reward) => reward.id).toSet();
    if (remoteRewards.length != localIds.length) {
      return null;
    }

    final mapping = <String, String>{};
    final usedLocalIds = <String>{};
    for (final remoteReward in remoteRewards) {
      final localId = _preferredLocalId(remoteReward.localId, remoteReward.id);
      if (!localIds.contains(localId) || !usedLocalIds.add(localId)) {
        return null;
      }
      mapping[remoteReward.id] = localId;
    }

    return usedLocalIds.length == localIds.length ? mapping : null;
  }

  String _preferredLocalId(String? localId, String remoteId) {
    final trimmed = localId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return remoteId;
  }

  MissionLogStatus _missionLogStatusFromRemote(String rawStatus) {
    return switch (rawStatus) {
      'awaitingApproval' => MissionLogStatus.awaitingApproval,
      'approved' => MissionLogStatus.approved,
      'rejected' => MissionLogStatus.rejected,
      'skipped' => MissionLogStatus.skipped,
      _ => MissionLogStatus.pending,
    };
  }

  RewardRequestStatus _rewardRequestStatusFromRemote(String rawStatus) {
    return switch (rawStatus) {
      'approved' => RewardRequestStatus.approved,
      'rejected' => RewardRequestStatus.rejected,
      'delivered' => RewardRequestStatus.delivered,
      'cancelled' => RewardRequestStatus.cancelled,
      _ => RewardRequestStatus.pending,
    };
  }

  int _compareRemoteLedgerEntries(
    RemoteStarLedgerEntrySummary a,
    RemoteStarLedgerEntrySummary b,
  ) {
    final byOccurredAt = a.occurredAt.compareTo(b.occurredAt);
    if (byOccurredAt != 0) {
      return byOccurredAt;
    }

    final aCreatedAt = a.createdAt ?? a.occurredAt;
    final bCreatedAt = b.createdAt ?? b.occurredAt;
    final byCreatedAt = aCreatedAt.compareTo(bCreatedAt);
    if (byCreatedAt != 0) {
      return byCreatedAt;
    }

    return a.id.compareTo(b.id);
  }

  StarLedgerEntryType? _mapLedgerEntryType(
    RemoteStarLedgerEntrySummary entry,
  ) {
    if (entry.sourceType == 'mission_log' && entry.direction == 'credit') {
      return StarLedgerEntryType.earned;
    }

    if (entry.sourceType == 'reward_request' && entry.direction == 'debit') {
      return StarLedgerEntryType.spent;
    }

    if (entry.sourceType == 'reward_request' && entry.direction == 'credit') {
      return StarLedgerEntryType.refunded;
    }

    if (entry.sourceType == 'manual_adjustment') {
      return StarLedgerEntryType.adjusted;
    }

    return null;
  }

  int _signedAmount(RemoteStarLedgerEntrySummary entry) {
    final absoluteAmount = entry.amount.abs();
    return entry.direction == 'debit' ? -absoluteAmount : absoluteAmount;
  }

  String? _resolveRelatedId({
    required String? remoteId,
    required String? remoteLocalId,
    required Map<String, String> remoteToLocalMap,
    required Set<String> existingIds,
  }) {
    if (remoteId != null && remoteToLocalMap.containsKey(remoteId)) {
      return remoteToLocalMap[remoteId];
    }

    final fallbackLocalId = remoteLocalId?.trim();
    if (fallbackLocalId != null &&
        fallbackLocalId.isNotEmpty &&
        existingIds.contains(fallbackLocalId)) {
      return fallbackLocalId;
    }

    return null;
  }

  String _buildLedgerTitle({
    required StarLedgerEntryType entryType,
    required RemoteStarLedgerEntrySummary remoteEntry,
    required Map<String, Mission> localMissionById,
    required Map<String, Reward> localRewardById,
    required Map<String, MissionLog> missionLogById,
    required Map<String, RewardRequest> rewardRequestById,
    required String? localMissionLogId,
    required String? localRewardRequestId,
  }) {
    if (localMissionLogId != null) {
      final log = missionLogById[localMissionLogId];
      final mission = log == null ? null : localMissionById[log.missionId];
      return mission?.title ?? 'Missão restaurada';
    }

    if (localRewardRequestId != null) {
      final request = rewardRequestById[localRewardRequestId];
      final reward = request == null ? null : localRewardById[request.rewardId];
      if (entryType == StarLedgerEntryType.refunded) {
        return reward == null ? 'Reembolso restaurado' : 'Reembolso: ${reward.title}';
      }
      return reward?.title ?? 'Mimo restaurado';
    }

    return remoteEntry.reason?.trim().isNotEmpty == true
        ? remoteEntry.reason!.trim()
        : 'Ajuste manual';
  }
}
