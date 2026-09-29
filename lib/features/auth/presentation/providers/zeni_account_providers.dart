import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../data/repositories/supabase_account_repository.dart';
import '../../data/repositories/zeni_account_repository.dart';
import 'zeni_auth_providers.dart';

final accountRepositoryProvider = Provider<ZeniAccountRepository>((ref) {
  return SupabaseAccountRepository(client: ZeniSupabaseBootstrap.client);
});

final remoteFamilyResolutionProvider =
    FutureProvider<ZeniResolveCurrentFamilyResult>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable) {
        return const ZeniResolveCurrentFamilyResult.failure(
          'Conta remota indisponível neste build.',
        );
      }
      if (!authState.isAuthenticated) {
        return const ZeniResolveCurrentFamilyResult.failure(
          'Faça login para identificar a família remota.',
        );
      }

      return ref.watch(accountRepositoryProvider).resolveCurrentFamily();
    });

final remoteFamilySummaryProvider = FutureProvider<RemoteFamilySummary?>((
  ref,
) async {
  final resolution = await ref.watch(remoteFamilyResolutionProvider.future);
  return resolution.status == ZeniResolveCurrentFamilyStatus.found
      ? resolution.summary
      : null;
});

final currentAccountProfileProvider = FutureProvider<ZeniAccountProfile?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
    return null;
  }
  return ref.watch(accountRepositoryProvider).getCurrentAccountProfile();
});

final zeniAccountControllerProvider = Provider<ZeniAccountController>((ref) {
  return ZeniAccountController(ref);
});

class ZeniAccountController {
  const ZeniAccountController(this._ref);

  final Ref _ref;

  Future<ZeniUpdateAccountProfileResult> initializeCurrentAccountProfile({
    String? suggestedDisplayName,
  }) async {
    final result = await _ref
        .read(accountRepositoryProvider)
        .initializeCurrentAccountProfile(
          suggestedDisplayName: suggestedDisplayName,
        );
    _ref.invalidate(currentAccountProfileProvider);
    return result;
  }

  Future<ZeniUpdateAccountProfileResult> updateCurrentAccountDisplayName({
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      return const ZeniUpdateAccountProfileResult.failure('Informe seu nome.');
    }
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Conecte-se à internet para atualizar seu nome.',
      );
    }
    if (!_ref.read(authStateProvider).isAuthenticated) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Faça login para editar seu nome.',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .updateCurrentAccountDisplayName(displayName: trimmedName);
    _ref.invalidate(currentAccountProfileProvider);
    return result;
  }

  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniResolveCurrentFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    if (!_ref.read(authStateProvider).isAuthenticated) {
      return const ZeniResolveCurrentFamilyResult.failure(
        'Faça login para identificar a família remota.',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .resolveCurrentFamily();
    _ref.invalidate(remoteFamilyResolutionProvider);
    _ref.invalidate(remoteFamilySummaryProvider);
    return result;
  }

  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniCreateInitialFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    if (!_ref.read(authStateProvider).isAuthenticated) {
      return const ZeniCreateInitialFamilyResult.failure(
        'Faça login para criar a família remota.',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .createInitialFamily();
    _ref.invalidate(remoteFamilyResolutionProvider);
    _ref.invalidate(remoteFamilySummaryProvider);
    return result;
  }

  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Digite um nome para a família.',
      );
    }

    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Faça login para editar a família remota.',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .updateRemoteFamilyName(name: name);
    final summary = result.summary;
    if (!result.isSuccess || summary == null) {
      return result;
    }

    bool wasPersisted;
    try {
      wasPersisted = await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateFamilyNameIfMatches(
            familyId: summary.familyId,
            name: summary.familyName,
          );
    } catch (_) {
      wasPersisted = false;
    }
    if (!wasPersisted) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'O nome foi atualizado na nuvem, mas não pôde ser salvo neste aparelho.',
      );
    }

    _ref.invalidate(remoteFamilyResolutionProvider);
    _ref.invalidate(remoteFamilySummaryProvider);
    return result;
  }

  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniDeleteAccountResult.failure(
        message: 'Conta remota indisponível neste build.',
        errorCode: 'not_available',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniDeleteAccountResult.failure(
        message: 'Faça login para excluir conta e dados da nuvem.',
        errorCode: 'not_authenticated',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .deleteAccountAndRemoteFamily();
    if (!result.isSuccess) {
      return result;
    }

    final signOutResult = await _ref.read(zeniAuthControllerProvider).signOut();
    if (!signOutResult.isSuccess) {
      _ref.read(authStateProvider.notifier).setSignedOut();
      _ref.invalidate(remoteFamilyResolutionProvider);
      _ref.invalidate(remoteFamilySummaryProvider);
      _ref.invalidate(remoteChildrenProvider);
      _ref.invalidate(remoteMissionsProvider);
      _ref.invalidate(remoteRewardsProvider);
      _ref.invalidate(remoteMissionLogsProvider);
      _ref.invalidate(remoteRewardRequestsProvider);
    }

    return ZeniDeleteAccountResult.success(
      familyId: result.familyId,
      message: result.message,
    );
  }
}
