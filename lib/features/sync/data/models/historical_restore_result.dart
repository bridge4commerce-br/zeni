import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../tasks/data/models/mission_log.dart';

enum HistoricalRestoreResultStatus {
  success,
  supabaseUnavailable,
  unauthenticated,
  remoteFamilyMissing,
  catalogsNotAligned,
  localActivityPresent,
  unsafeBalanceMismatch,
  remoteReadFailure,
  applyBlocked,
}

class HistoricalRestorePayload {
  const HistoricalRestorePayload({
    required this.missionLogs,
    required this.rewardRequests,
    required this.starLedgerEntries,
    required this.rebuiltChildren,
    required this.restoredAt,
  });

  final List<MissionLog> missionLogs;
  final List<RewardRequest> rewardRequests;
  final List<StarLedgerEntry> starLedgerEntries;
  final List<ChildProfile> rebuiltChildren;
  final DateTime restoredAt;
}

class HistoricalRestoreResult {
  const HistoricalRestoreResult({
    required this.status,
    required this.message,
    this.payload,
    this.restoredMissionLogsCount = 0,
    this.restoredRewardRequestsCount = 0,
    this.restoredStarLedgerEntriesCount = 0,
  });

  HistoricalRestoreResult.success({
    required HistoricalRestorePayload payload,
  }) : this(
         status: HistoricalRestoreResultStatus.success,
         message:
             'Histórico restaurado neste aparelho. O saldo foi reconstruído com segurança a partir dos eventos da nuvem.',
         payload: payload,
         restoredMissionLogsCount: payload.missionLogs.length,
         restoredRewardRequestsCount: payload.rewardRequests.length,
         restoredStarLedgerEntriesCount: payload.starLedgerEntries.length,
       );

  const HistoricalRestoreResult.failure({
    required HistoricalRestoreResultStatus status,
    required String message,
  }) : this(status: status, message: message);

  final HistoricalRestoreResultStatus status;
  final String message;
  final HistoricalRestorePayload? payload;
  final int restoredMissionLogsCount;
  final int restoredRewardRequestsCount;
  final int restoredStarLedgerEntriesCount;

  bool get isSuccess => status == HistoricalRestoreResultStatus.success;
}

class HistoricalRestoreActionState {
  const HistoricalRestoreActionState({
    required this.isVisible,
    required this.showAction,
    required this.isEnabled,
    required this.message,
  });

  final bool isVisible;
  final bool showAction;
  final bool isEnabled;
  final String? message;
}
