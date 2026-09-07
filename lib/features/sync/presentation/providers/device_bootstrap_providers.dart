import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/data/repositories/remote_children_repository.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/data/repositories/remote_rewards_repository.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../data/mappers/remote_device_bootstrap_mapper.dart';
import '../../data/models/device_bootstrap_result.dart';

final remoteDeviceBootstrapMapperProvider =
    Provider<RemoteDeviceBootstrapMapper>(
      (ref) => const RemoteDeviceBootstrapMapper(),
    );

final deviceBootstrapControllerProvider = Provider<DeviceBootstrapController>((
  ref,
) {
  return DeviceBootstrapController(ref);
});

final deviceBootstrapActionStateProvider =
    FutureProvider<DeviceBootstrapActionState>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
        return const DeviceBootstrapActionState(
          isVisible: false,
          showAction: false,
          isEnabled: false,
          message: null,
        );
      }

      final localState = await ref.watch(zeniAppStateControllerProvider.future);
      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) {
        return const DeviceBootstrapActionState(
          isVisible: false,
          showAction: false,
          isEnabled: false,
          message: null,
        );
      }

      if (localState.hasUserContent) {
        return const DeviceBootstrapActionState(
          isVisible: true,
          showAction: true,
          isEnabled: false,
          message: 'Este aparelho já possui dados locais.',
        );
      }

      final remoteChildren =
          await ref.watch(remoteChildrenProvider.future) ??
          const [];
      final remoteMissions =
          await ref.watch(remoteMissionsProvider.future) ??
          const <RemoteMissionSummary>[];
      final remoteRewards =
          await ref.watch(remoteRewardsProvider.future) ??
          const [];
      final hasRemoteCatalogData =
          remoteChildren.isNotEmpty ||
          remoteMissions.isNotEmpty ||
          remoteRewards.isNotEmpty;

      if (!hasRemoteCatalogData) {
        return const DeviceBootstrapActionState(
          isVisible: false,
          showAction: false,
          isEnabled: false,
          message: null,
        );
      }

      return const DeviceBootstrapActionState(
        isVisible: true,
        showAction: true,
        isEnabled: true,
        message:
            'Restaure família, crianças, missões e mimos da nuvem neste aparelho. Saldo, histórico e sequência não serão trazidos nesta etapa.',
      );
    });

class DeviceBootstrapActionState {
  const DeviceBootstrapActionState({
    required this.isVisible,
    required this.showAction,
    required this.isEnabled,
    required this.message,
  });

  final bool isVisible;
  final bool showAction;
  final bool isEnabled;
  final String? message;
}

class DeviceBootstrapController {
  const DeviceBootstrapController(this._ref);

  final Ref _ref;

  Future<DeviceBootstrapResult> bootstrapFromRemoteFamily() async {
    _debugLog('Bootstrap from remote family started');
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const DeviceBootstrapResult.failure(
        'Restauração na nuvem indisponível neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const DeviceBootstrapResult.failure(
        'Faça login para restaurar a família neste aparelho.',
      );
    }

    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    if (localState.hasUserContent) {
      return const DeviceBootstrapResult.failure(
        'Este aparelho já possui dados locais.',
      );
    }

    try {
      final remoteFamily = await _ref.read(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) {
        return const DeviceBootstrapResult.failure(
          'Nenhuma família remota preparada foi encontrada.',
        );
      }

      final remoteChildren = await _ref
          .read(remoteChildrenRepositoryProvider)
          .getRemoteChildren(familyId: remoteFamily.familyId);
      final remoteMissions = remoteChildren.isEmpty
          ? const <RemoteMissionSummary>[]
          : await _ref
                .read(remoteMissionsRepositoryProvider)
                .getRemoteMissions(familyId: remoteFamily.familyId);
      final remoteRewards = await _ref
          .read(remoteRewardsRepositoryProvider)
          .getRemoteRewards(familyId: remoteFamily.familyId);

      _debugLog(
        'Remote catalog fetched: children=${remoteChildren.length}, '
        'missions=${remoteMissions.length}, rewards=${remoteRewards.length}',
      );

      final hasRemoteCatalogData =
          remoteChildren.isNotEmpty ||
          remoteMissions.isNotEmpty ||
          remoteRewards.isNotEmpty;
      if (!hasRemoteCatalogData) {
        _debugLog('Bootstrap aborted: remote catalog is empty');
        return const DeviceBootstrapResult.failure(
          'Nenhum dado remoto foi encontrado para restaurar.',
        );
      }

      final payload = _ref
          .read(remoteDeviceBootstrapMapperProvider)
          .map(
            remoteFamily: remoteFamily,
            remoteChildren: remoteChildren,
            remoteMissions: remoteMissions,
            remoteRewards: remoteRewards,
            localInviteCode: localState.family.inviteCode,
          );
      _debugBootstrapMappings(
        remoteChildren: remoteChildren,
        remoteMissions: remoteMissions,
        remoteRewards: remoteRewards,
        payload: payload,
      );

      final applyResult = await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .applyDeviceBootstrapIfEmpty(payload);
      if (!applyResult.isSuccess) {
        return DeviceBootstrapResult.failure(
          applyResult.message ?? 'Não foi possível restaurar a família agora.',
        );
      }

      _debugLog(
        'Bootstrap applied locally: children=${payload.children.length}, '
        'missions=${payload.missions.length}, rewards=${payload.rewards.length}',
      );

      _ref.invalidate(remoteFamilySummaryProvider);
      _ref.invalidate(remoteChildrenProvider);
      _ref.invalidate(remoteMissionsProvider);
      _ref.invalidate(remoteRewardsProvider);

      return DeviceBootstrapResult.success(
        restoredChildrenCount: payload.children.length,
        restoredMissionsCount: payload.missions.length,
        restoredRewardsCount: payload.rewards.length,
        message:
            'Dados principais restaurados neste aparelho. Você já pode escolher um perfil para continuar.',
      );
    } catch (error) {
      _debugLog('bootstrapFromRemoteFamily unexpected error: $error');
      return const DeviceBootstrapResult.failure(
        'Não foi possível restaurar a família agora.',
      );
    }
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[DeviceBootstrap] $message');
  }

  void _debugBootstrapMappings({
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required DeviceBootstrapPayload payload,
  }) {
    if (!kDebugMode) return;

    for (var index = 0; index < remoteChildren.length; index += 1) {
      final remoteChild = remoteChildren[index];
      final localChild = payload.children[index];
      _debugLog('Child mapping: remote=${remoteChild.id} -> local=${localChild.id}');
    }

    final localChildIdByRemoteChildId = <String, String>{
      for (var index = 0; index < remoteChildren.length; index += 1)
        remoteChildren[index].id: payload.children[index].id,
    };
    final localMissionById = {
      for (final mission in payload.missions) mission.id: mission,
    };
    final localRewardById = {
      for (final reward in payload.rewards) reward.id: reward,
    };

    for (final remoteMission in remoteMissions) {
      final localMissionId = remoteMission.localId ?? remoteMission.id;
      final localMission = localMissionById[localMissionId];
      _debugLog(
        'Mission mapping: remote=${remoteMission.id} -> local=$localMissionId '
        '(child remote=${remoteMission.childId} -> local=${localChildIdByRemoteChildId[remoteMission.childId] ?? 'missing'}) '
        'resolvedChild=${localMission?.childId ?? 'missing'}',
      );
    }

    for (final remoteReward in remoteRewards) {
      final localRewardId = remoteReward.localId ?? remoteReward.id;
      final localReward = localRewardById[localRewardId];
      _debugLog(
        'Reward mapping: remote=${remoteReward.id} -> local=$localRewardId '
        '(child remote=${remoteReward.childId ?? 'global'} -> local=${remoteReward.childId == null ? 'global' : (localChildIdByRemoteChildId[remoteReward.childId!] ?? 'missing')}) '
        'resolvedChild=${localReward?.childId ?? 'global'}',
      );
    }
  }
}
