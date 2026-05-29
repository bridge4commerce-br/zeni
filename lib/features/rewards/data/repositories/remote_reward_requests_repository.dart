import '../models/reward_request.dart';

class RemoteRewardRequestSummary {
  const RemoteRewardRequestSummary({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.rewardId,
    required this.localId,
    required this.status,
    required this.starsSpent,
    this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.note,
    this.rejectionReason,
  });

  final String id;
  final String familyId;
  final String childId;
  final String rewardId;
  final String? localId;
  final String status;
  final int starsSpent;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final String? note;
  final String? rejectionReason;
}

class ZeniEnsureRemoteRewardRequestsResult {
  const ZeniEnsureRemoteRewardRequestsResult({
    required this.isSuccess,
    this.requests = const <RemoteRewardRequestSummary>[],
    this.message,
  });

  const ZeniEnsureRemoteRewardRequestsResult.success(
    List<RemoteRewardRequestSummary> requests,
  ) : this(isSuccess: true, requests: requests);

  const ZeniEnsureRemoteRewardRequestsResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteRewardRequestSummary> requests;
  final String? message;
}

abstract class RemoteRewardRequestsRepository {
  bool get isConfigured;

  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  });

  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List<RewardRequest> localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  });
}
