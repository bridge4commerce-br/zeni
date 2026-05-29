import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../data/repositories/supabase_account_repository.dart';
import '../../data/repositories/zeni_account_repository.dart';
import 'zeni_auth_providers.dart';

final accountRepositoryProvider = Provider<ZeniAccountRepository>((ref) {
  return SupabaseAccountRepository(client: ZeniSupabaseBootstrap.client);
});

final remoteFamilySummaryProvider = FutureProvider<RemoteFamilySummary?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  if (!ZeniSupabaseBootstrap.state.isAvailable || !authState.isAuthenticated) {
    return null;
  }

  return ref.watch(accountRepositoryProvider).getCurrentRemoteFamilySummary();
});

final zeniAccountControllerProvider = Provider<ZeniAccountController>((ref) {
  return ZeniAccountController(ref);
});

class ZeniAccountController {
  const ZeniAccountController(this._ref);

  final Ref _ref;

  Future<ZeniEnsureRemoteFamilyResult> ensureRemoteFamilyForCurrentUser() async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Faça login para preparar a família remota.',
      );
    }

    final result = await _ref
        .read(accountRepositoryProvider)
        .ensureRemoteFamilyForCurrentUser();
    _ref.invalidate(remoteFamilySummaryProvider);
    return result;
  }

  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
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
        .updateRemoteFamilyName(familyId: familyId, name: name);
    _ref.invalidate(remoteFamilySummaryProvider);
    return result;
  }
}
