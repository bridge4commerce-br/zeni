import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/data/repositories/remote_reward_requests_repository.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../tasks/data/repositories/remote_mission_logs_repository.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../data/repositories/remote_star_ledger_repository.dart';
import '../../data/repositories/supabase_remote_star_ledger_repository.dart';

final remoteStarLedgerRepositoryProvider = Provider<RemoteStarLedgerRepository>(
  (ref) {
    return SupabaseRemoteStarLedgerRepository(
      client: ZeniSupabaseBootstrap.client,
    );
  },
);

final remoteStarLedgerProvider =
    FutureProvider<List<RemoteStarLedgerEntrySummary>?>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable ||
          !authState.isAuthenticated) {
        return null;
      }

      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) return null;

      final remoteChildren = await ref.watch(remoteChildrenProvider.future);
      if (remoteChildren == null || remoteChildren.isEmpty) {
        return null;
      }

      return ref
          .watch(remoteStarLedgerRepositoryProvider)
          .getRemoteStarLedgerEntries(familyId: remoteFamily.familyId);
    });

final zeniRemoteStarLedgerControllerProvider =
    Provider<ZeniRemoteStarLedgerController>((ref) {
      return ZeniRemoteStarLedgerController(ref);
    });

class ZeniRemoteStarLedgerController {
  const ZeniRemoteStarLedgerController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteStarLedgerResult>
  ensureRemoteStarLedgerForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Ledger remoto indisponível neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Faça login para preparar o histórico de estrelas na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Prepare a família remota antes de sincronizar o histórico de estrelas.',
      );
    }

    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    final localEntries = appState.starLedgerEntries;

    final remoteChildren = await _ref.read(remoteChildrenProvider.future);
    if (localEntries.isNotEmpty &&
        (remoteChildren == null || remoteChildren.isEmpty)) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Sincronize os dados principais primeiro para preparar o histórico de estrelas.',
      );
    }

    final remoteMissionLogs = await _ref.read(remoteMissionLogsProvider.future);
    final remoteRewardRequests = await _ref.read(
      remoteRewardRequestsProvider.future,
    );
    final availableChildren = remoteChildren ?? const <RemoteChildSummary>[];
    final availableMissionLogs =
        remoteMissionLogs ?? const <RemoteMissionLogSummary>[];
    final availableRewardRequests =
        remoteRewardRequests ?? const <RemoteRewardRequestSummary>[];

    final remoteChildIdByLocalChildId = <String, String>{
      for (final child in availableChildren)
        if (child.localId != null && child.localId!.isNotEmpty)
          child.localId!: child.id,
    };
    final remoteMissionLogIdByLocalMissionLogId = <String, String>{
      for (final log in availableMissionLogs)
        if (log.localId != null && log.localId!.isNotEmpty)
          log.localId!: log.id,
    };
    final remoteRewardRequestIdByLocalRewardRequestId = <String, String>{
      for (final request in availableRewardRequests)
        if (request.localId != null && request.localId!.isNotEmpty)
          request.localId!: request.id,
    };

    final result = await _ref
        .read(remoteStarLedgerRepositoryProvider)
        .ensureRemoteStarLedger(
          familyId: remoteFamily.familyId,
          localEntries: localEntries,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
          remoteMissionLogIdByLocalMissionLogId:
              remoteMissionLogIdByLocalMissionLogId,
          remoteRewardRequestIdByLocalRewardRequestId:
              remoteRewardRequestIdByLocalRewardRequestId,
        );

    if (result.isSuccess) {
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(lastStarLedgerSyncAt: DateTime.now()),
          );
    }

    _ref.invalidate(remoteStarLedgerProvider);
    return result;
  }
}
