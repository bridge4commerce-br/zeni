import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../data/repositories/remote_mission_logs_repository.dart';
import '../../data/repositories/supabase_remote_mission_logs_repository.dart';
import 'remote_missions_providers.dart';

final remoteMissionLogsRepositoryProvider =
    Provider<RemoteMissionLogsRepository>((ref) {
      return SupabaseRemoteMissionLogsRepository(
        client: ZeniSupabaseBootstrap.client,
      );
    });

final remoteMissionLogsProvider =
    FutureProvider<List<RemoteMissionLogSummary>?>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable ||
          !authState.isAuthenticated) {
        return null;
      }

      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) return null;

      final remoteChildren = await ref.watch(remoteChildrenProvider.future);
      final remoteMissions = await ref.watch(remoteMissionsProvider.future);
      if (remoteChildren == null ||
          remoteChildren.isEmpty ||
          remoteMissions == null ||
          remoteMissions.isEmpty) {
        return null;
      }

      return ref
          .watch(remoteMissionLogsRepositoryProvider)
          .getRemoteMissionLogs(familyId: remoteFamily.familyId);
    });

final zeniRemoteMissionLogsControllerProvider =
    Provider<ZeniRemoteMissionLogsController>((ref) {
      return ZeniRemoteMissionLogsController(ref);
    });

class ZeniRemoteMissionLogsController {
  const ZeniRemoteMissionLogsController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteMissionLogsResult>
  ensureRemoteMissionLogsForCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Logs remotos de missão indisponíveis neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Faça login para preparar as conclusões na nuvem.',
      );
    }

    final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
    if (remoteFamily == null) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Prepare a família remota antes de sincronizar as conclusões.',
      );
    }

    final remoteChildren = await _ref.read(remoteChildrenProvider.future);
    if (remoteChildren == null || remoteChildren.isEmpty) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Sincronize os dados principais primeiro para preparar as conclusões.',
      );
    }

    final remoteMissions = await _ref.read(remoteMissionsProvider.future);
    if (remoteMissions == null || remoteMissions.isEmpty) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Sincronize os dados principais primeiro para preparar as conclusões.',
      );
    }

    final remoteChildIdByLocalChildId = <String, String>{
      for (final child in remoteChildren)
        if (child.localId != null && child.localId!.isNotEmpty)
          child.localId!: child.id,
    };
    final remoteMissionIdByLocalMissionId = <String, String>{
      for (final mission in remoteMissions)
        if (mission.localId != null && mission.localId!.isNotEmpty)
          mission.localId!: mission.id,
    };

    final appState = await _ref.read(zeniAppStateControllerProvider.future);
    final result = await _ref
        .read(remoteMissionLogsRepositoryProvider)
        .ensureRemoteMissionLogs(
          familyId: remoteFamily.familyId,
          localMissionLogs: appState.missionLogs,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
          remoteMissionIdByLocalMissionId: remoteMissionIdByLocalMissionId,
        );
    if (result.isSuccess) {
      await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(
            appState.appSettings.copyWith(
              lastMissionLogsSyncAt: DateTime.now(),
            ),
          );
    }
    _ref.invalidate(remoteMissionLogsProvider);
    return result;
  }
}
