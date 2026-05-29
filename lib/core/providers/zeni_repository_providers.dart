import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/balance/data/repositories/balance_repository.dart';
import '../../features/balance/data/repositories/mock_balance_repository.dart';
import '../../features/family/data/repositories/family_repository.dart';
import '../../features/family/data/repositories/mock_family_repository.dart';
import '../../features/rewards/data/repositories/mock_reward_repository.dart';
import '../../features/rewards/data/repositories/reward_repository.dart';
import '../../features/tasks/data/repositories/mission_repository.dart';
import '../../features/tasks/data/repositories/mock_mission_repository.dart';

final _localFamilyRepositoryProvider = Provider<MockFamilyRepository>((ref) {
  return MockFamilyRepository(ref);
});

final _localMissionRepositoryProvider = Provider<MockMissionRepository>((ref) {
  return MockMissionRepository(ref);
});

final _localRewardRepositoryProvider = Provider<MockRewardRepository>((ref) {
  return MockRewardRepository(ref);
});

final _localBalanceRepositoryProvider = Provider<MockBalanceRepository>((ref) {
  return MockBalanceRepository(ref);
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return ref.watch(_localFamilyRepositoryProvider);
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return ref.watch(_localMissionRepositoryProvider);
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return ref.watch(_localRewardRepositoryProvider);
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return ref.watch(_localBalanceRepositoryProvider);
});

final mockFamilyRepositoryProvider = _localFamilyRepositoryProvider;
final mockMissionRepositoryProvider = _localMissionRepositoryProvider;
final mockRewardRepositoryProvider = _localRewardRepositoryProvider;
final mockBalanceRepositoryProvider = _localBalanceRepositoryProvider;
