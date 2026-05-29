import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
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

class DeviceBootstrapController {
  const DeviceBootstrapController(this._ref);

  final Ref _ref;

  Future<DeviceBootstrapResult> bootstrapFromRemoteFamily() async {
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

      final payload = _ref
          .read(remoteDeviceBootstrapMapperProvider)
          .map(
            remoteFamily: remoteFamily,
            remoteChildren: remoteChildren,
            remoteMissions: remoteMissions,
            remoteRewards: remoteRewards,
            localInviteCode: localState.family.inviteCode,
          );

      final applyResult = await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .applyDeviceBootstrapIfEmpty(payload);
      if (!applyResult.isSuccess) {
        return DeviceBootstrapResult.failure(
          applyResult.message ?? 'Não foi possível restaurar a família agora.',
        );
      }

      _ref.invalidate(remoteFamilySummaryProvider);
      _ref.invalidate(remoteChildrenProvider);
      _ref.invalidate(remoteMissionsProvider);
      _ref.invalidate(remoteRewardsProvider);

      return DeviceBootstrapResult.success(
        restoredChildrenCount: payload.children.length,
        restoredMissionsCount: payload.missions.length,
        restoredRewardsCount: payload.rewards.length,
        message:
            'Família, crianças, missões e mimos foram restaurados. Saldo, histórico e sequência não foram trazidos nesta etapa.',
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
}
