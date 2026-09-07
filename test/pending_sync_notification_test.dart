import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/sync/domain/pending_sync_notification.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';

void main() {
  test('buildPendingSyncNotificationPlan reports only newly pulled pendencies', () {
    final beforeState = ZeniAppState.initial().copyWith(
      children: [_child('child-1', 'Pedro')],
      missionLogs: [
        MissionLog(
          id: 'existing-log',
          missionId: 'mission-1',
          childId: 'child-1',
          scheduledDate: DateTime(2026, 7, 7),
          status: MissionLogStatus.awaitingApproval,
          starsAwarded: 5,
        ),
      ],
    );
    final afterState = beforeState.copyWith(
      missionLogs: [
        MissionLog(
          id: 'new-log',
          missionId: 'mission-2',
          childId: 'child-1',
          scheduledDate: DateTime(2026, 7, 7),
          status: MissionLogStatus.awaitingApproval,
          starsAwarded: 8,
        ),
        ...beforeState.missionLogs,
      ],
      rewardRequests: [
        RewardRequest(
          id: 'new-request',
          rewardId: 'reward-1',
          childId: 'child-1',
          status: RewardRequestStatus.pending,
          requestedAt: DateTime(2026, 7, 7, 10),
        ),
      ],
    );

    final plan = buildPendingSyncNotificationPlan(
      previousState: beforeState,
      currentState: afterState,
    );

    expect(plan.currentPendingMissionLogIds, {'existing-log', 'new-log'});
    expect(plan.currentPendingRewardRequestIds, {'new-request'});
    expect(plan.notices, hasLength(2));
    expect(plan.notices.first.title, 'Nova missão para aprovar');
    expect(
      plan.notices.first.message,
      'Pedro enviou uma missão para aprovação.',
    );
    expect(plan.notices.last.title, 'Novo pedido de mimo');
    expect(plan.notices.last.message, 'Pedro pediu um mimo.');
  });

  test('buildPendingSyncNotificationPlan does not duplicate notices for existing pendencies', () {
    final state = ZeniAppState.initial().copyWith(
      children: [_child('child-1', 'Pedro')],
      missionLogs: [
        MissionLog(
          id: 'existing-log',
          missionId: 'mission-1',
          childId: 'child-1',
          scheduledDate: DateTime(2026, 7, 7),
          status: MissionLogStatus.awaitingApproval,
          starsAwarded: 5,
        ),
      ],
      rewardRequests: [
        RewardRequest(
          id: 'existing-request',
          rewardId: 'reward-1',
          childId: 'child-1',
          status: RewardRequestStatus.pending,
          requestedAt: DateTime(2026, 7, 7, 10),
        ),
      ],
    );

    final plan = buildPendingSyncNotificationPlan(
      previousState: state,
      currentState: state,
    );

    expect(plan.currentPendingMissionLogIds, {'existing-log'});
    expect(plan.currentPendingRewardRequestIds, {'existing-request'});
    expect(plan.notices, isEmpty);
  });
}

ChildProfile _child(String id, String name) {
  return ChildProfile(
    id: id,
    familyId: 'family-1',
    name: name,
    emoji: '🦁',
    starBalance: 0,
    streakCount: 0,
    createdAt: DateTime(2026, 7, 7),
  );
}
