import '../../features/balance/data/models/star_ledger_entry.dart';
import '../../features/family/data/models/child_profile.dart';
import '../../features/family/data/models/family.dart';
import '../../features/family/data/models/family_member.dart';
import '../../features/rewards/data/models/reward.dart';
import '../../features/rewards/data/models/reward_request.dart';
import '../../features/settings/data/models/app_settings.dart';
import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/mission_log.dart';
import '../domain/zeni_enums.dart';
import '../mock/zeni_mock_data.dart';

class ZeniAppState {
  const ZeniAppState({
    required this.family,
    required this.children,
    required this.familyMembers,
    required this.missions,
    required this.missionLogs,
    required this.rewards,
    required this.rewardRequests,
    required this.starLedgerEntries,
    required this.appSettings,
  });

  factory ZeniAppState.seeded() {
    return ZeniAppState(
      family: ZeniMockData.family,
      children: List<ChildProfile>.from(ZeniMockData.children),
      familyMembers: List<FamilyMember>.from(ZeniMockData.members),
      missions: List<Mission>.from(ZeniMockData.missions),
      missionLogs: List<MissionLog>.from(ZeniMockData.missionLogs),
      rewards: List<Reward>.from(ZeniMockData.rewards),
      rewardRequests: List<RewardRequest>.from(ZeniMockData.rewardRequests),
      starLedgerEntries: List<StarLedgerEntry>.from(ZeniMockData.ledgerEntries),
      appSettings: const AppSettings(),
    );
  }

  factory ZeniAppState.initial() {
    final now = DateTime.now();

    return ZeniAppState(
      family: Family(
        id: 'local-family',
        name: 'Minha família',
        inviteCode: 'ZENI00',
        createdAt: now,
      ),
      children: const <ChildProfile>[],
      familyMembers: [
        FamilyMember(
          id: 'local-parent',
          familyId: 'local-family',
          name: 'Responsável',
          role: ZeniUserRole.parent,
          isOwner: true,
          createdAt: now,
        ),
      ],
      missions: const <Mission>[],
      missionLogs: const <MissionLog>[],
      rewards: const <Reward>[],
      rewardRequests: const <RewardRequest>[],
      starLedgerEntries: const <StarLedgerEntry>[],
      appSettings: const AppSettings(),
    );
  }

  final Family family;
  final List<ChildProfile> children;
  final List<FamilyMember> familyMembers;
  final List<Mission> missions;
  final List<MissionLog> missionLogs;
  final List<Reward> rewards;
  final List<RewardRequest> rewardRequests;
  final List<StarLedgerEntry> starLedgerEntries;
  final AppSettings appSettings;

  bool get hasUserContent =>
      children.isNotEmpty || missions.isNotEmpty || rewards.isNotEmpty;

  bool get shouldShowOnboarding =>
      !appSettings.hasCompletedOnboarding && !hasUserContent;

  ChildProfile? childById(String childId) {
    for (final child in children) {
      if (child.id == childId) {
        return child;
      }
    }

    return null;
  }

  Mission? missionById(String missionId) {
    for (final mission in missions) {
      if (mission.id == missionId) {
        return mission;
      }
    }

    return null;
  }

  Reward? rewardById(String rewardId) {
    for (final reward in rewards) {
      if (reward.id == rewardId) {
        return reward;
      }
    }

    return null;
  }

  ZeniAppState copyWith({
    Family? family,
    List<ChildProfile>? children,
    List<FamilyMember>? familyMembers,
    List<Mission>? missions,
    List<MissionLog>? missionLogs,
    List<Reward>? rewards,
    List<RewardRequest>? rewardRequests,
    List<StarLedgerEntry>? starLedgerEntries,
    AppSettings? appSettings,
  }) {
    return ZeniAppState(
      family: family ?? this.family,
      children: children ?? this.children,
      familyMembers: familyMembers ?? this.familyMembers,
      missions: missions ?? this.missions,
      missionLogs: missionLogs ?? this.missionLogs,
      rewards: rewards ?? this.rewards,
      rewardRequests: rewardRequests ?? this.rewardRequests,
      starLedgerEntries: starLedgerEntries ?? this.starLedgerEntries,
      appSettings: appSettings ?? this.appSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family.toJson(),
      'children': children.map((child) => child.toJson()).toList(),
      'familyMembers': familyMembers.map((member) => member.toJson()).toList(),
      'missions': missions.map((mission) => mission.toJson()).toList(),
      'missionLogs': missionLogs.map((log) => log.toJson()).toList(),
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'rewardRequests': rewardRequests
          .map((request) => request.toJson())
          .toList(),
      'starLedgerEntries': starLedgerEntries
          .map((entry) => entry.toJson())
          .toList(),
      'appSettings': appSettings.toJson(),
    };
  }

  factory ZeniAppState.fromJson(Map<String, dynamic> json) {
    return ZeniAppState(
      family: Family.fromJson(json['family'] as Map<String, dynamic>),
      children: (json['children'] as List<dynamic>)
          .map((item) => ChildProfile.fromJson(item as Map<String, dynamic>))
          .toList(),
      familyMembers: (json['familyMembers'] as List<dynamic>)
          .map((item) => FamilyMember.fromJson(item as Map<String, dynamic>))
          .toList(),
      missions: (json['missions'] as List<dynamic>)
          .map((item) => Mission.fromJson(item as Map<String, dynamic>))
          .toList(),
      missionLogs: (json['missionLogs'] as List<dynamic>)
          .map((item) => MissionLog.fromJson(item as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List<dynamic>)
          .map((item) => Reward.fromJson(item as Map<String, dynamic>))
          .toList(),
      rewardRequests: (json['rewardRequests'] as List<dynamic>)
          .map((item) => RewardRequest.fromJson(item as Map<String, dynamic>))
          .toList(),
      starLedgerEntries: (json['starLedgerEntries'] as List<dynamic>)
          .map((item) => StarLedgerEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      appSettings: AppSettings.fromJson(
        json['appSettings'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}
