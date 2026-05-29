import '../../../../core/domain/zeni_enums.dart';
import '../models/reward.dart';
import '../models/reward_request.dart';

abstract class RewardRepository {
  Future<List<Reward>> getRewardsForFamily(String familyId);

  Future<List<Reward>> getRewardsForChild(String childId);

  Future<List<RewardRequest>> getPendingRequests();

  Future<List<RewardRequest>> getRequestsForChild(String childId);

  Future<Reward> createReward({
    required String familyId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  });

  Future<Reward?> updateReward({
    required String rewardId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  });

  Future<Reward?> archiveReward(String rewardId);

  Future<Reward?> restoreReward(String rewardId);

  Future<void> requestReward({required String childId, required Reward reward});

  Future<void> approveRewardRequest(String requestId);

  Future<void> rejectRewardRequest(String requestId);
}
