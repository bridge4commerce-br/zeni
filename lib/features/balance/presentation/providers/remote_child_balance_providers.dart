import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../data/repositories/remote_child_balance_repository.dart';
import '../../data/repositories/supabase_remote_child_balance_repository.dart';

final remoteChildBalanceRepositoryProvider =
    Provider<RemoteChildBalanceRepository>((ref) {
      return SupabaseRemoteChildBalanceRepository(
        client: ZeniSupabaseBootstrap.client,
      );
    });

final remoteChildBalancesProvider =
    FutureProvider<List<RemoteChildStarBalance>?>((ref) async {
      final authState = ref.watch(authStateProvider);
      if (!ZeniSupabaseBootstrap.state.isAvailable ||
          !authState.isAuthenticated) {
        return null;
      }

      final remoteFamily = await ref.watch(remoteFamilySummaryProvider.future);
      if (remoteFamily == null) return null;

      return ref
          .watch(remoteChildBalanceRepositoryProvider)
          .getRemoteChildStarBalances(familyId: remoteFamily.familyId);
    });
