import '../../../core/domain/zeni_enums.dart';
import '../../../core/state/zeni_app_state.dart';
import '../../rewards/data/models/reward_request.dart';
import '../../tasks/data/models/mission_log.dart';

class PendingSyncNotice {
  const PendingSyncNotice({required this.title, required this.message});

  final String title;
  final String message;
}

class PendingSyncNotificationPlan {
  const PendingSyncNotificationPlan({
    required this.currentPendingMissionLogIds,
    required this.currentPendingRewardRequestIds,
    required this.notices,
  });

  final Set<String> currentPendingMissionLogIds;
  final Set<String> currentPendingRewardRequestIds;
  final List<PendingSyncNotice> notices;
}

PendingSyncNotificationPlan buildPendingSyncNotificationPlan({
  required ZeniAppState previousState,
  required ZeniAppState currentState,
}) {
  final previousPendingMissionLogIds = previousState.missionLogs
      .where((log) => log.status == MissionLogStatus.awaitingApproval)
      .map((log) => log.id)
      .toSet();
  final currentPendingMissionLogs = currentState.missionLogs
      .where((log) => log.status == MissionLogStatus.awaitingApproval)
      .toList();
  final currentPendingMissionLogIds = currentPendingMissionLogs
      .map((log) => log.id)
      .toSet();
  final newPendingMissionLogs = currentPendingMissionLogs
      .where((log) => !previousPendingMissionLogIds.contains(log.id))
      .toList();

  final previousPendingRewardRequestIds = previousState.rewardRequests
      .where((request) => request.status == RewardRequestStatus.pending)
      .map((request) => request.id)
      .toSet();
  final currentPendingRewardRequests = currentState.rewardRequests
      .where((request) => request.status == RewardRequestStatus.pending)
      .toList();
  final currentPendingRewardRequestIds = currentPendingRewardRequests
      .map((request) => request.id)
      .toSet();
  final newPendingRewardRequests = currentPendingRewardRequests
      .where((request) => !previousPendingRewardRequestIds.contains(request.id))
      .toList();

  final childNamesById = {
    for (final child in currentState.children) child.id: child.name,
  };
  final notices = <PendingSyncNotice>[
    if (newPendingMissionLogs.isNotEmpty)
      PendingSyncNotice(
        title: 'Nova missão para aprovar',
        message: _missionMessage(
          childNamesById: childNamesById,
          newPendingMissionLogs: newPendingMissionLogs,
        ),
      ),
    if (newPendingRewardRequests.isNotEmpty)
      PendingSyncNotice(
        title: 'Novo pedido de mimo',
        message: _rewardMessage(
          childNamesById: childNamesById,
          newPendingRewardRequests: newPendingRewardRequests,
        ),
      ),
  ];

  return PendingSyncNotificationPlan(
    currentPendingMissionLogIds: currentPendingMissionLogIds,
    currentPendingRewardRequestIds: currentPendingRewardRequestIds,
    notices: notices,
  );
}

String _missionMessage({
  required Map<String, String> childNamesById,
  required List<MissionLog> newPendingMissionLogs,
}) {
  if (newPendingMissionLogs.length == 1) {
    final childName =
        childNamesById[newPendingMissionLogs.single.childId] ?? 'Uma criança';
    return '$childName enviou uma missão para aprovação.';
  }

  return 'Há novas missões aguardando aprovação.';
}

String _rewardMessage({
  required Map<String, String> childNamesById,
  required List<RewardRequest> newPendingRewardRequests,
}) {
  if (newPendingRewardRequests.length == 1) {
    final childName =
        childNamesById[newPendingRewardRequests.single.childId] ??
        'Uma criança';
    return '$childName pediu um mimo.';
  }

  return 'Há novos pedidos de mimo aguardando resposta.';
}
