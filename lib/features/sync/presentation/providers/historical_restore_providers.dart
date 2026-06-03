import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../balance/presentation/providers/remote_child_balance_providers.dart';
import '../../../balance/presentation/providers/remote_star_ledger_providers.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../data/mappers/remote_historical_restore_mapper.dart';
import '../../data/models/historical_restore_result.dart';

final remoteHistoricalRestoreMapperProvider =
    Provider<RemoteHistoricalRestoreMapper>(
      (ref) => const RemoteHistoricalRestoreMapper(),
    );

final historicalRestoreActionStateProvider =
    FutureProvider<HistoricalRestoreActionState>((ref) async {
      final authState = ref.watch(authStateProvider);
      final appState = await ref.watch(zeniAppStateControllerProvider.future);
      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);

      final hasCatalogs = appState.children.isNotEmpty &&
          (appState.missions.isNotEmpty || appState.rewards.isNotEmpty);
      final hasEmptyHistory = appState.missionLogs.isEmpty &&
          appState.rewardRequests.isEmpty &&
          appState.starLedgerEntries.isEmpty;
      final hasZeroBalances = appState.children.every(
        (child) => child.starBalance == 0,
      );
      final isVisible = authState.isAuthenticated &&
          remoteFamily != null &&
          hasCatalogs &&
          hasEmptyHistory;

      return HistoricalRestoreActionState(
        isVisible: isVisible,
        isEnabled: isVisible && hasZeroBalances,
      );
    });

final historicalRestoreControllerProvider =
    Provider<HistoricalRestoreController>((ref) {
      return HistoricalRestoreController(ref);
    });

class HistoricalRestoreController {
  const HistoricalRestoreController(this._ref);

  final Ref _ref;

  Future<HistoricalRestoreResult> restoreHistoryIfSafe() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.supabaseUnavailable,
        message: 'Não foi possível restaurar o histórico agora.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.unauthenticated,
        message: 'Faça login para restaurar o histórico neste aparelho.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.remoteFamilyMissing,
        message: 'Nenhuma família remota preparada foi encontrada.',
      );
    }

    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    if (!_hasSafeLocalRestoreBase(localState)) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.localActivityPresent,
        message:
            'Este aparelho já possui atividade local. Para evitar duplicidade de estrelas, o histórico não será restaurado automaticamente.',
      );
    }

    if (!_hasAlignedLocalCatalogBase(localState)) {
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.catalogsNotAligned,
        message: 'Sincronize crianças, missões e mimos antes de restaurar o histórico.',
      );
    }

    try {
      final remoteChildren = await _ref
          .read(remoteChildrenRepositoryProvider)
          .getRemoteChildren(familyId: remoteFamily.familyId);
      final remoteMissions = await _ref
          .read(remoteMissionsRepositoryProvider)
          .getRemoteMissions(familyId: remoteFamily.familyId);
      final remoteRewards = await _ref
          .read(remoteRewardsRepositoryProvider)
          .getRemoteRewards(familyId: remoteFamily.familyId);
      final remoteMissionLogs = await _ref
          .read(remoteMissionLogsRepositoryProvider)
          .getRemoteMissionLogs(familyId: remoteFamily.familyId);
      final remoteRewardRequests = await _ref
          .read(remoteRewardRequestsRepositoryProvider)
          .getRemoteRewardRequests(familyId: remoteFamily.familyId);
      final remoteStarLedgerEntries = await _ref
          .read(remoteStarLedgerRepositoryProvider)
          .getRemoteStarLedgerEntries(familyId: remoteFamily.familyId);
      final remoteChildBalances = await _ref
          .read(remoteChildBalanceRepositoryProvider)
          .getRemoteChildStarBalances(familyId: remoteFamily.familyId);

      final mappedResult = _ref
          .read(remoteHistoricalRestoreMapperProvider)
          .map(
            localState: localState,
            remoteChildren: remoteChildren,
            remoteMissions: remoteMissions,
            remoteRewards: remoteRewards,
            remoteMissionLogs: remoteMissionLogs,
            remoteRewardRequests: remoteRewardRequests,
            remoteStarLedgerEntries: remoteStarLedgerEntries,
            remoteChildBalances: remoteChildBalances,
          );
      if (!mappedResult.isSuccess) {
        return mappedResult;
      }

      final applyResult = await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .applyHistoricalRestoreIfSafe(mappedResult.payload!);
      if (!applyResult.isSuccess) {
        return applyResult;
      }

      _ref.invalidate(remoteMissionLogsProvider);
      _ref.invalidate(remoteRewardRequestsProvider);
      _ref.invalidate(remoteStarLedgerProvider);
      _ref.invalidate(remoteChildBalancesProvider);
      _ref.invalidate(historicalRestoreActionStateProvider);
      return applyResult;
    } catch (error) {
      _debugLog('restoreHistoryIfSafe unexpected error: $error');
      return const HistoricalRestoreResult.failure(
        status: HistoricalRestoreResultStatus.remoteReadFailure,
        message: 'Não foi possível restaurar o histórico agora.',
      );
    }
  }

  bool _hasAlignedLocalCatalogBase(dynamic localState) {
    return localState.children.isNotEmpty &&
        (localState.missions.isNotEmpty || localState.rewards.isNotEmpty);
  }

  bool _hasSafeLocalRestoreBase(dynamic localState) {
    return localState.missionLogs.isEmpty &&
        localState.rewardRequests.isEmpty &&
        localState.starLedgerEntries.isEmpty &&
        localState.children.every((child) => child.starBalance == 0);
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[HistoricalRestore] $message');
  }
}
