import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/balance/data/repositories/remote_child_balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/remote_star_ledger_repository.dart';
import 'package:zeni/features/balance/presentation/providers/remote_child_balance_providers.dart';
import 'package:zeni/features/balance/presentation/providers/remote_star_ledger_providers.dart';
import 'package:zeni/features/family/data/repositories/remote_children_repository.dart';
import 'package:zeni/features/family/presentation/providers/remote_children_providers.dart';
import 'package:zeni/features/rewards/data/repositories/remote_reward_requests_repository.dart';
import 'package:zeni/features/rewards/data/repositories/remote_rewards_repository.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_reward_requests_providers.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_rewards_providers.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';
import 'package:zeni/features/tasks/data/repositories/remote_mission_logs_repository.dart';
import 'package:zeni/features/tasks/data/repositories/remote_missions_repository.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_mission_logs_providers.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_missions_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZeniSupabaseBootstrap.resetForTests();
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://zeni.test.supabase.co',
        anonKey: 'anon-key',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
  });

  tearDown(() {
    ZeniSupabaseBootstrap.resetForTests();
  });

  test(
    'manual sync without login returns noSession and keeps local state intact',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _UnauthenticatedTestAuthRepository(),
          ),
          accountRepositoryProvider.overrideWithValue(
            const _TestAccountRepository(),
          ),
          remoteChildrenRepositoryProvider.overrideWithValue(
            const _TestRemoteChildrenRepository(),
          ),
          remoteMissionsRepositoryProvider.overrideWithValue(
            const _TestRemoteMissionsRepository(),
          ),
          remoteRewardsRepositoryProvider.overrideWithValue(
            const _TestRemoteRewardsRepository(),
          ),
          remoteMissionLogsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteMissionLogsRepository(),
          ),
          remoteRewardRequestsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteRewardRequestsRepository(),
          ),
          remoteStarLedgerRepositoryProvider.overrideWithValue(
            const _EmptyRemoteStarLedgerRepository(),
          ),
          remoteChildBalanceRepositoryProvider.overrideWithValue(
            const _EmptyRemoteChildBalanceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, ZeniCloudSyncStatus.noSession);
      expect(result.message, 'Entre na conta para sincronizar com a nuvem.');
      expect(appState.children, isEmpty);
      expect(appState.missions, isEmpty);
      expect(appState.rewards, isEmpty);
    },
  );

  test(
    'manual sync on a clean device restores children missions and rewards without duplication',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(
            const _TestAccountRepository(),
          ),
          remoteChildrenRepositoryProvider.overrideWithValue(
            const _TestRemoteChildrenRepository(),
          ),
          remoteMissionsRepositoryProvider.overrideWithValue(
            const _TestRemoteMissionsRepository(),
          ),
          remoteRewardsRepositoryProvider.overrideWithValue(
            const _TestRemoteRewardsRepository(),
          ),
          remoteMissionLogsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteMissionLogsRepository(),
          ),
          remoteRewardRequestsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteRewardRequestsRepository(),
          ),
          remoteStarLedgerRepositoryProvider.overrideWithValue(
            const _EmptyRemoteStarLedgerRepository(),
          ),
          remoteChildBalanceRepositoryProvider.overrideWithValue(
            const _EmptyRemoteChildBalanceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(authStateProvider.notifier)
          .setAuthenticated(
            const ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
          );

      final firstResult = await container
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      final firstState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(firstResult.isSuccess, isTrue);
      expect(firstResult.message, 'Dados sincronizados neste aparelho.');
      expect(firstState.children, hasLength(1));
      expect(firstState.missions, hasLength(1));
      expect(firstState.rewards, hasLength(1));
      expect(firstState.children.single.id, 'child-local-1');
      expect(firstState.missions.single.childId, 'child-local-1');
      expect(firstState.rewards.single.childId, 'child-local-1');

      final secondResult = await container
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      final secondState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(secondResult.isSuccess, isTrue);
      expect(secondState.children, hasLength(1));
      expect(secondState.missions, hasLength(1));
      expect(secondState.rewards, hasLength(1));
    },
  );

  test(
    'manual sync repeated three times on clean device keeps restored catalogs deduplicated',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(
            const _TestAccountRepository(),
          ),
          remoteChildrenRepositoryProvider.overrideWithValue(
            const _TwoChildrenRemoteChildrenRepository(),
          ),
          remoteMissionsRepositoryProvider.overrideWithValue(
            const _TwoChildrenRemoteMissionsRepository(),
          ),
          remoteRewardsRepositoryProvider.overrideWithValue(
            const _TwoChildrenRemoteRewardsRepository(),
          ),
          remoteMissionLogsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteMissionLogsRepository(),
          ),
          remoteRewardRequestsRepositoryProvider.overrideWithValue(
            const _EmptyRemoteRewardRequestsRepository(),
          ),
          remoteStarLedgerRepositoryProvider.overrideWithValue(
            const _EmptyRemoteStarLedgerRepository(),
          ),
          remoteChildBalanceRepositoryProvider.overrideWithValue(
            const _EmptyRemoteChildBalanceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(authStateProvider.notifier)
          .setAuthenticated(
            const ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
          );

      await container.read(zeniCloudSyncControllerProvider).syncNowManually();
      await container.read(zeniCloudSyncControllerProvider).syncNowManually();
      await container.read(zeniCloudSyncControllerProvider).syncNowManually();

      final state = await container.read(zeniAppStateControllerProvider.future);

      expect(state.children, hasLength(2));
      expect(state.missions, hasLength(2));
      expect(state.rewards, hasLength(2));
      expect(state.children.map((child) => child.id).toSet(), {
        'child-local-1',
        'child-local-2',
      });
      expect(
        state.missions.map((mission) => mission.childId).toList()..sort(),
        ['child-local-1', 'child-local-2'],
      );
      expect(
        state.rewards.map((reward) => reward.childId).toList()..sort(),
        ['child-local-1', 'child-local-2'],
      );
    },
  );
}

class _TestAuthRepository implements ZeniAuthRepository {
  @override
  bool get isGoogleSignInAvailable => true;

  @override
  bool get isAppleSignInAvailable => true;

  @override
  ZeniAuthUser? get currentUser =>
      const ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app');

  @override
  Stream<ZeniAuthUser?> authStateChanges() async* {
    yield currentUser;
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => ZeniAuthOperationResult.success(user: currentUser);

  @override
  Future<ZeniAuthOperationResult> signOut() async =>
      const ZeniAuthOperationResult.success();

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async => ZeniAuthOperationResult.success(user: currentUser);

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async =>
      ZeniAuthOperationResult.success(user: currentUser);

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async =>
      ZeniAuthOperationResult.success(user: currentUser);
}

class _UnauthenticatedTestAuthRepository implements ZeniAuthRepository {
  @override
  bool get isGoogleSignInAvailable => true;

  @override
  bool get isAppleSignInAvailable => true;

  @override
  ZeniAuthUser? get currentUser => null;

  @override
  Stream<ZeniAuthUser?> authStateChanges() async* {
    yield null;
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const ZeniAuthOperationResult.failure('indisponível');

  @override
  Future<ZeniAuthOperationResult> signOut() async =>
      const ZeniAuthOperationResult.success();

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async => const ZeniAuthOperationResult.failure('indisponível');

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async =>
      const ZeniAuthOperationResult.failure('indisponível');

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async =>
      const ZeniAuthOperationResult.failure('indisponível');
}

class _TestAccountRepository implements ZeniAccountRepository {
  const _TestAccountRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    return const RemoteFamilySummary(
      familyId: 'family-remote-1',
      familyName: 'Minha família',
      role: 'owner',
    );
  }

  @override
  Future<ZeniEnsureRemoteFamilyResult>
  ensureRemoteFamilyForCurrentUser() async {
    return const ZeniEnsureRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: 'family-remote-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    );
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  }) async {
    return ZeniUpdateRemoteFamilyResult.success(
      RemoteFamilySummary(familyId: familyId, familyName: name, role: 'owner'),
    );
  }

  @override
  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() async {
    return const ZeniDeleteAccountResult.success();
  }
}

class _TestRemoteChildrenRepository implements RemoteChildrenRepository {
  const _TestRemoteChildrenRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    return const [
      RemoteChildSummary(
        id: 'remote-child-1',
        familyId: 'family-remote-1',
        localId: 'child-local-1',
        name: 'Pedro',
        avatarKey: '🦁',
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List localChildren,
  }) async {
    return ZeniEnsureRemoteChildrenResult.success(
      await getRemoteChildren(familyId: familyId),
    );
  }
}

class _TestRemoteMissionsRepository implements RemoteMissionsRepository {
  const _TestRemoteMissionsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async {
    return const [
      RemoteMissionSummary(
        id: 'remote-mission-1',
        familyId: 'family-remote-1',
        childId: 'remote-child-1',
        localId: 'mission-local-1',
        title: 'Escovar os dentes',
        stars: 5,
        requiresApproval: false,
        recurrenceType: 'daily',
        recurrenceDays: <int>[],
        isActive: true,
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteMissionsResult.success(
      await getRemoteMissions(familyId: familyId),
    );
  }
}

class _TwoChildrenRemoteChildrenRepository implements RemoteChildrenRepository {
  const _TwoChildrenRemoteChildrenRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    return const [
      RemoteChildSummary(
        id: 'remote-child-1',
        familyId: 'family-remote-1',
        localId: 'child-local-1',
        name: 'Pedro',
        avatarKey: '🦁',
      ),
      RemoteChildSummary(
        id: 'remote-child-2',
        familyId: 'family-remote-1',
        localId: 'child-local-2',
        name: 'Luna',
        avatarKey: '🦊',
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List localChildren,
  }) async {
    return ZeniEnsureRemoteChildrenResult.success(
      await getRemoteChildren(familyId: familyId),
    );
  }
}

class _TwoChildrenRemoteMissionsRepository implements RemoteMissionsRepository {
  const _TwoChildrenRemoteMissionsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async {
    return const [
      RemoteMissionSummary(
        id: 'remote-mission-1',
        familyId: 'family-remote-1',
        childId: 'remote-child-1',
        localId: 'mission-local-1',
        title: 'Escovar os dentes',
        stars: 5,
        requiresApproval: false,
        recurrenceType: 'daily',
        recurrenceDays: <int>[],
        isActive: true,
      ),
      RemoteMissionSummary(
        id: 'remote-mission-2',
        familyId: 'family-remote-1',
        childId: 'remote-child-2',
        localId: 'mission-local-2',
        title: 'Guardar brinquedos',
        stars: 7,
        requiresApproval: true,
        recurrenceType: 'daily',
        recurrenceDays: <int>[],
        isActive: true,
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteMissionsResult.success(
      await getRemoteMissions(familyId: familyId),
    );
  }
}

class _TwoChildrenRemoteRewardsRepository implements RemoteRewardsRepository {
  const _TwoChildrenRemoteRewardsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async {
    return const [
      RemoteRewardSummary(
        id: 'remote-reward-1',
        familyId: 'family-remote-1',
        childId: 'remote-child-1',
        localId: 'reward-local-1',
        title: 'Escolher sobremesa',
        cost: 20,
        imageKey: '🍨',
        isActive: true,
      ),
      RemoteRewardSummary(
        id: 'remote-reward-2',
        familyId: 'family-remote-1',
        childId: 'remote-child-2',
        localId: 'reward-local-2',
        title: 'Cinema em casa',
        cost: 25,
        imageKey: '🎬',
        isActive: true,
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteRewardsResult.success(
      await getRemoteRewards(familyId: familyId),
    );
  }
}

class _TestRemoteRewardsRepository implements RemoteRewardsRepository {
  const _TestRemoteRewardsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async {
    return const [
      RemoteRewardSummary(
        id: 'remote-reward-1',
        familyId: 'family-remote-1',
        childId: 'remote-child-1',
        localId: 'reward-local-1',
        title: 'Escolher o filme',
        cost: 20,
        isActive: true,
      ),
    ];
  }

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteRewardsResult.success(
      await getRemoteRewards(familyId: familyId),
    );
  }
}

class _EmptyRemoteMissionLogsRepository implements RemoteMissionLogsRepository {
  const _EmptyRemoteMissionLogsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async => const [];

  @override
  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  }) async => const ZeniEnsureRemoteMissionLogsResult.success([]);
}

class _EmptyRemoteRewardRequestsRepository
    implements RemoteRewardRequestsRepository {
  const _EmptyRemoteRewardRequestsRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  }) async => const [];

  @override
  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  }) async => const ZeniEnsureRemoteRewardRequestsResult.success([]);
}

class _EmptyRemoteStarLedgerRepository implements RemoteStarLedgerRepository {
  const _EmptyRemoteStarLedgerRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  }) async => const [];

  @override
  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) async => const ZeniEnsureRemoteStarLedgerResult.success([]);
}

class _EmptyRemoteChildBalanceRepository
    implements RemoteChildBalanceRepository {
  const _EmptyRemoteChildBalanceRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  }) async => const [];
}
