import '../models/reward.dart';

class RemoteRewardSummary {
  const RemoteRewardSummary({
    required this.id,
    required this.familyId,
    required this.localId,
    required this.title,
    required this.cost,
    required this.isActive,
    this.childId,
    this.imageKey,
    this.archivedAt,
  });

  final String id;
  final String familyId;
  final String? childId;
  final String? localId;
  final String title;
  final int cost;
  final String? imageKey;
  final bool isActive;
  final DateTime? archivedAt;
}

class ZeniEnsureRemoteRewardsResult {
  const ZeniEnsureRemoteRewardsResult({
    required this.isSuccess,
    this.rewards = const <RemoteRewardSummary>[],
    this.message,
  });

  const ZeniEnsureRemoteRewardsResult.success(List<RemoteRewardSummary> rewards)
    : this(isSuccess: true, rewards: rewards);

  const ZeniEnsureRemoteRewardsResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteRewardSummary> rewards;
  final String? message;
}

abstract class RemoteRewardsRepository {
  bool get isConfigured;

  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  });

  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  });
}
