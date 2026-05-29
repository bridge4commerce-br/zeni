import '../../../family/data/models/child_profile.dart';
import '../../../family/data/models/family.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../tasks/data/models/mission.dart';

class DeviceBootstrapPayload {
  const DeviceBootstrapPayload({
    required this.family,
    required this.children,
    required this.missions,
    required this.rewards,
  });

  final Family family;
  final List<ChildProfile> children;
  final List<Mission> missions;
  final List<Reward> rewards;
}

class DeviceBootstrapApplyResult {
  const DeviceBootstrapApplyResult({required this.isSuccess, this.message});

  const DeviceBootstrapApplyResult.success() : this(isSuccess: true);

  const DeviceBootstrapApplyResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
}

class DeviceBootstrapResult {
  const DeviceBootstrapResult({
    required this.isSuccess,
    this.message,
    this.restoredChildrenCount = 0,
    this.restoredMissionsCount = 0,
    this.restoredRewardsCount = 0,
  });

  const DeviceBootstrapResult.success({
    required int restoredChildrenCount,
    required int restoredMissionsCount,
    required int restoredRewardsCount,
    String? message,
  }) : this(
         isSuccess: true,
         message: message,
         restoredChildrenCount: restoredChildrenCount,
         restoredMissionsCount: restoredMissionsCount,
         restoredRewardsCount: restoredRewardsCount,
       );

  const DeviceBootstrapResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
  final int restoredChildrenCount;
  final int restoredMissionsCount;
  final int restoredRewardsCount;
}
