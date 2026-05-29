import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../balance/data/repositories/remote_child_balance_repository.dart';
import '../../../balance/presentation/providers/remote_child_balance_providers.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../data/models/cloud_consistency_diagnostic.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';

final cloudConsistencyDiagnosticProvider =
    FutureProvider<CloudConsistencyDiagnostic?>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable ||
          !authState.isAuthenticated) {
        return null;
      }

      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) return null;

      final appState = await ref.watch(zeniAppStateControllerProvider.future);
      final remoteChildren = await ref.watch(remoteChildrenProvider.future);
      final remoteMissions = await ref.watch(remoteMissionsProvider.future);
      final remoteRewards = await ref.watch(remoteRewardsProvider.future);
      final remoteMissionLogs = await ref.watch(
        remoteMissionLogsProvider.future,
      );
      final remoteRewardRequests = await ref.watch(
        remoteRewardRequestsProvider.future,
      );
      final remoteChildBalances = await ref.watch(
        remoteChildBalancesProvider.future,
      );

      final childBalanceDiagnostics = _buildChildBalanceDiagnostics(
        localChildren: appState.children,
        remoteChildren: remoteChildren ?? const [],
        remoteBalances: remoteChildBalances ?? const [],
      );
      final warnings = <String>[
        if (appState.children.length != (remoteChildren?.length ?? 0))
          'A quantidade de crianças locais e remotas é diferente.',
        if (appState.missions.length != (remoteMissions?.length ?? 0))
          'A quantidade de missões locais e remotas é diferente.',
        if (appState.rewards.length != (remoteRewards?.length ?? 0))
          'A quantidade de mimos locais e remotos é diferente.',
        if (appState.missionLogs.length != (remoteMissionLogs?.length ?? 0))
          'A quantidade de conclusões locais e remotas é diferente.',
        if (appState.rewardRequests.length !=
            (remoteRewardRequests?.length ?? 0))
          'A quantidade de pedidos locais e remotos é diferente.',
      ];

      return CloudConsistencyDiagnostic(
        localChildrenCount: appState.children.length,
        remoteChildrenCount: remoteChildren?.length ?? 0,
        localMissionsCount: appState.missions.length,
        remoteMissionsCount: remoteMissions?.length ?? 0,
        localRewardsCount: appState.rewards.length,
        remoteRewardsCount: remoteRewards?.length ?? 0,
        localMissionLogsCount: appState.missionLogs.length,
        remoteMissionLogsCount: remoteMissionLogs?.length ?? 0,
        localRewardRequestsCount: appState.rewardRequests.length,
        remoteRewardRequestsCount: remoteRewardRequests?.length ?? 0,
        localStarBalance: appState.children.fold<int>(
          0,
          (sum, child) => sum + child.starBalance,
        ),
        remoteDerivedBalance: (remoteChildBalances ?? const []).fold<int>(
          0,
          (sum, item) => sum + item.derivedBalance,
        ),
        childBalanceDiagnostics: childBalanceDiagnostics,
        warnings: warnings,
      );
    });

List<ChildBalanceDiagnostic> _buildChildBalanceDiagnostics({
  required List<ChildProfile> localChildren,
  required List<RemoteChildSummary> remoteChildren,
  required List<RemoteChildStarBalance> remoteBalances,
}) {
  final localChildById = <String, ChildProfile>{
    for (final child in localChildren) child.id: child,
  };
  final localChildIdByRemoteChildId = <String, String>{
    for (final child in remoteChildren)
      if (child.localId != null && child.localId!.isNotEmpty)
        child.id: child.localId!,
  };

  return [
    for (final remoteBalance in remoteBalances)
      if (localChildIdByRemoteChildId.containsKey(remoteBalance.childId) &&
          localChildById.containsKey(
            localChildIdByRemoteChildId[remoteBalance.childId],
          ))
        ChildBalanceDiagnostic(
          childName:
              localChildById[localChildIdByRemoteChildId[remoteBalance
                      .childId]]!
                  .name,
          localBalance:
              localChildById[localChildIdByRemoteChildId[remoteBalance
                      .childId]]!
                  .starBalance,
          remoteBalance: remoteBalance.derivedBalance,
          ledgerEventsCount: remoteBalance.ledgerEventsCount,
        ),
  ];
}
