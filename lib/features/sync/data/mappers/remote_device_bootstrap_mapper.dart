import '../../../../core/domain/zeni_enums.dart';
import '../../../auth/data/repositories/zeni_account_repository.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/models/family.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/repositories/remote_rewards_repository.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';
import '../models/device_bootstrap_result.dart';

class RemoteDeviceBootstrapMapper {
  const RemoteDeviceBootstrapMapper();

  static const String fallbackChildEmoji = '🦊';
  static const String fallbackMissionEmoji = '✅';
  static const String fallbackRewardEmoji = '🎁';

  DeviceBootstrapPayload map({
    required RemoteFamilySummary remoteFamily,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required String localInviteCode,
    DateTime? importedAt,
  }) {
    final now = importedAt ?? DateTime.now();
    final family = Family(
      id: remoteFamily.familyId,
      name: remoteFamily.familyName,
      inviteCode: localInviteCode,
      createdAt: now,
    );

    final children = [
      for (final child in remoteChildren)
        ChildProfile(
          id: _preferLocalId(child.localId, child.id),
          familyId: family.id,
          name: child.name,
          emoji: _mapEmoji(child.avatarKey, fallbackChildEmoji),
          avatarUrl: null,
          birthDate: child.birthDate,
          starBalance: 0,
          streakCount: 0,
          ttsEnabled: false,
          isActive: !child.isArchived,
          createdAt: now,
        ),
    ];

    final localChildIdByRemoteChildId = <String, String>{
      for (var index = 0; index < remoteChildren.length; index += 1)
        remoteChildren[index].id: children[index].id,
    };

    final missions = [
      for (final mission in remoteMissions)
        Mission(
          id: _preferLocalId(mission.localId, mission.id),
          familyId: family.id,
          childId:
              localChildIdByRemoteChildId[mission.childId] ?? mission.childId,
          title: mission.title,
          description: 'Missão restaurada da nuvem.',
          emoji: fallbackMissionEmoji,
          stars: mission.stars,
          recurrence: missionRecurrenceFromStorage(mission.recurrenceType),
          customDaysOfWeek:
              missionRecurrenceFromStorage(mission.recurrenceType) ==
                  MissionRecurrence.customDaysOfWeek
              ? mission.recurrenceDays
              : const <int>[],
          timeGroup: MissionTimeGroup.anytime,
          approvalMode: mission.requiresApproval
              ? MissionApprovalMode.parentApproval
              : MissionApprovalMode.automatic,
          status: mission.archivedAt != null || !mission.isActive
              ? MissionStatus.archived
              : MissionStatus.active,
          requiresPhoto: false,
          createdAt: now,
          updatedAt: now,
        ),
    ];

    final rewards = [
      for (final reward in remoteRewards)
        Reward(
          id: _preferLocalId(reward.localId, reward.id),
          familyId: family.id,
          childId: reward.childId == null
              ? null
              : localChildIdByRemoteChildId[reward.childId!],
          title: reward.title,
          description: 'Mimo restaurado da nuvem.',
          emoji: _mapEmoji(reward.imageKey, fallbackRewardEmoji),
          cost: reward.cost,
          renewal: RewardRenewal.always,
          isActive: reward.archivedAt == null && reward.isActive,
          createdAt: now,
          updatedAt: now,
        ),
    ];

    return DeviceBootstrapPayload(
      family: family,
      children: children,
      missions: missions,
      rewards: rewards,
    );
  }

  String _preferLocalId(String? localId, String remoteId) {
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
}
