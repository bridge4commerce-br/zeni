import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../models/reward.dart';
import '../models/reward_request.dart';
import 'reward_repository.dart';

class MockRewardRepository implements RewardRepository {
  MockRewardRepository(this._ref);

  final Ref _ref;

  @override
  Future<List<Reward>> getRewardsForFamily(String familyId) async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).rewards
        .where((reward) => reward.familyId == familyId && reward.isActive)
        .toList();
  }

  @override
  Future<List<Reward>> getRewardsForChild(String childId) async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).rewards
        .where(
          (reward) =>
              reward.isActive &&
              (reward.childId == null || reward.childId == childId),
        )
        .toList();
  }

  @override
  Future<List<RewardRequest>> getPendingRequests() async {
    return (await _ref.read(zeniAppStateControllerProvider.future))
        .rewardRequests
        .where((request) => request.status == RewardRequestStatus.pending)
        .toList();
  }

  @override
  Future<List<RewardRequest>> getRequestsForChild(String childId) async {
    return (await _ref.read(
      zeniAppStateControllerProvider.future,
    )).rewardRequests.where((request) => request.childId == childId).toList();
  }

  @override
  Future<Reward> createReward({
    required String familyId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .createReward(
          familyId: familyId,
          childId: childId,
          title: title,
          description: description,
          emoji: emoji,
          cost: cost,
          renewal: renewal,
        );
  }

  @override
  Future<Reward?> updateReward({
    required String rewardId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateReward(
          rewardId: rewardId,
          childId: childId,
          title: title,
          description: description,
          emoji: emoji,
          cost: cost,
          renewal: renewal,
        );
  }

  @override
  Future<Reward?> archiveReward(String rewardId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .archiveReward(rewardId);
  }

  @override
  Future<Reward?> restoreReward(String rewardId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .restoreReward(rewardId);
  }

  @override
  Future<void> requestReward({
    required String childId,
    required Reward reward,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .requestReward(childId: childId, reward: reward);
  }

  @override
  Future<void> approveRewardRequest(String requestId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .approveRewardRequest(requestId);
  }

  @override
  Future<void> rejectRewardRequest(String requestId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .rejectRewardRequest(requestId);
  }
}
