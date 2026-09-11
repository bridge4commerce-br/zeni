import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_rewards_tab.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/child/presentation/widgets/child_missions_tab.dart';
import 'package:zeni/features/child/presentation/widgets/child_rewards_tab.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_missions_tab.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';

void main() {
  testWidgets(
    'child missions pull-to-refresh calls the shared refresh action',
    (tester) async {
      var refreshCalls = 0;
      final mission = Mission(
        id: 'mission-1',
        familyId: 'family-1',
        childId: 'child-1',
        title: 'Arrumar a cama',
        description: 'Organizar tudo antes do cafe.',
        stars: 5,
        recurrence: MissionRecurrence.daily,
        timeGroup: MissionTimeGroup.morning,
        approvalMode: MissionApprovalMode.automatic,
        status: MissionStatus.active,
        createdAt: DateTime(2026, 7, 3),
        updatedAt: DateTime(2026, 7, 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChildMissionsTab(
              missions: [mission],
              logForMission: (missionId) => null,
              missionAnchorKeyFor: (missionId) => GlobalKey(),
              onCompleteMission: (mission, log, sourceKey, {note}) {},
              onCancelMissionSubmission: (mission, log) {},
              onUndoMissionCompletion: (mission, log) {},
              onListenToMissionDetails: (mission, log) {},
              onStopMissionSpeech: () async {},
              canListenToMission: false,
              onRefresh: () async {
                refreshCalls += 1;
              },
            ),
          ),
        ),
      );

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalls, 1);
    },
  );

  testWidgets('child rewards pull-to-refresh calls the shared refresh action', (
    tester,
  ) async {
    var refreshCalls = 0;
    final reward = Reward(
      id: 'reward-1',
      familyId: 'family-1',
      childId: 'child-1',
      title: 'Escolher o filme',
      description: 'Uma noite especial.',
      cost: 20,
      renewal: RewardRenewal.always,
      createdAt: DateTime(2026, 7, 3),
      updatedAt: DateTime(2026, 7, 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChildRewardsTab(
            childBalance: 30,
            rewards: [reward],
            pendingRewardRequests: const [],
            rewardById: (rewardId) => rewardId == reward.id ? reward : null,
            onRedeemReward: (_) {},
            onListenToReward: (_) {},
            onListenToRewardDetails: (reward, request) {},
            canListenToReward: false,
            onRefresh: () async {
              refreshCalls += 1;
            },
          ),
        ),
      ),
    );

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCalls, 1);
  });

  testWidgets(
    'parent missions pull-to-refresh calls the shared refresh action',
    (tester) async {
      var refreshCalls = 0;
      final child = ChildProfile(
        id: 'child-1',
        familyId: 'family-1',
        name: 'Pedro',
        emoji: '🦁',
        starBalance: 0,
        streakCount: 0,
        createdAt: DateTime(2026, 7, 3),
      );
      final mission = Mission(
        id: 'mission-1',
        familyId: 'family-1',
        childId: 'child-1',
        title: 'Arrumar a cama',
        description: 'Organizar tudo antes do cafe.',
        stars: 5,
        recurrence: MissionRecurrence.daily,
        timeGroup: MissionTimeGroup.morning,
        approvalMode: MissionApprovalMode.parentApproval,
        status: MissionStatus.active,
        createdAt: DateTime(2026, 7, 3),
        updatedAt: DateTime(2026, 7, 3),
      );
      final log = MissionLog(
        id: 'log-1',
        missionId: 'mission-1',
        childId: 'child-1',
        scheduledDate: DateTime(2026, 7, 3),
        status: MissionLogStatus.awaitingApproval,
        starsAwarded: 5,
        completedAt: DateTime(2026, 7, 3, 8),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParentMissionsTab(
              activeChildren: [child],
              activeMissions: [mission],
              archivedMissions: const [],
              awaitingLogs: [log],
              childById: (childId) => childId == child.id ? child : null,
              missionById: (missionId) =>
                  missionId == mission.id ? mission : null,
              onApproveMission: (_) {},
              onRejectMission: (_) {},
              onApproveMissionBatch: (_) {},
              onRejectMissionBatch: (_) {},
              onEditMission: (_) {},
              onArchiveMission: (_) {},
              onRestoreMission: (_) {},
              onOpenSuggestions: () {},
              onRefresh: () async {
                refreshCalls += 1;
              },
            ),
          ),
        ),
      );

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalls, 1);
    },
  );

  testWidgets(
    'parent rewards pull-to-refresh calls the shared refresh action',
    (tester) async {
      var refreshCalls = 0;
      final child = ChildProfile(
        id: 'child-1',
        familyId: 'family-1',
        name: 'Pedro',
        emoji: '🦁',
        starBalance: 0,
        streakCount: 0,
        createdAt: DateTime(2026, 7, 3),
      );
      final reward = Reward(
        id: 'reward-1',
        familyId: 'family-1',
        childId: 'child-1',
        title: 'Escolher o filme',
        description: 'Uma noite especial.',
        cost: 20,
        renewal: RewardRenewal.always,
        createdAt: DateTime(2026, 7, 3),
        updatedAt: DateTime(2026, 7, 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParentRewardsTab(
              activeChildren: [child],
              activeRewards: [reward],
              archivedRewards: const [],
              pendingRequests: const <RewardRequest>[],
              childById: (childId) => childId == child.id ? child : null,
              rewardById: (rewardId) => rewardId == reward.id ? reward : null,
              onApproveRewardRequest: (_) {},
              onRejectRewardRequest: (_) {},
              onApproveRewardRequestBatch: (_) {},
              onRejectRewardRequestBatch: (_) {},
              onEditReward: (_) {},
              onArchiveReward: (_) {},
              onRestoreReward: (_) {},
              onRefresh: () async {
                refreshCalls += 1;
              },
            ),
          ),
        ),
      );

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalls, 1);
    },
  );
}
