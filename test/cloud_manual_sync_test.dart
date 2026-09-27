import 'dart:async';
import 'dart:convert';

import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/features/sync/domain/family_identity.dart';
import 'package:zeni/features/sync/presentation/providers/device_bootstrap_providers.dart';
import 'package:zeni/features/sync/presentation/providers/historical_restore_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/balance/data/repositories/remote_child_balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/remote_star_ledger_repository.dart';
import 'package:zeni/features/balance/data/models/star_ledger_entry.dart';
import 'package:zeni/features/balance/presentation/providers/remote_child_balance_providers.dart';
import 'package:zeni/features/balance/presentation/providers/remote_star_ledger_providers.dart';
import 'package:zeni/features/family/data/repositories/remote_children_repository.dart';
import 'package:zeni/features/family/presentation/providers/remote_children_providers.dart';
import 'package:zeni/features/rewards/data/repositories/remote_reward_requests_repository.dart';
import 'package:zeni/features/rewards/data/repositories/remote_rewards_repository.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_reward_requests_providers.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_rewards_providers.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';
import 'package:zeni/features/tasks/data/repositories/remote_mission_logs_repository.dart';
import 'package:zeni/features/tasks/data/repositories/remote_missions_repository.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';
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

  familyIdentityTests();

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
      expect(state.rewards.map((reward) => reward.childId).toList()..sort(), [
        'child-local-1',
        'child-local-2',
      ]);
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
    required String displayName,
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
    required String displayName,
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

class _TestAccountRepository extends ZeniAccountRepository {
  const _TestAccountRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    return const ZeniResolveCurrentFamilyResult.found(
      summary: RemoteFamilySummary(
        familyId: 'family-remote-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
      userId: 'test-user',
      membershipId: 'membership-test',
    );
  }

  @override
  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    return const ZeniCreateInitialFamilyResult.alreadyExists(
      summary: RemoteFamilySummary(
        familyId: 'family-remote-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
      userId: 'test-user',
      membershipId: 'membership-test',
    );
  }

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

void familyIdentityTests() {
  ZeniAppState boundState() {
    final initial = ZeniAppState.initial();
    return initial.copyWith(
      family: initial.family.copyWith(id: 'family-remote-1'),
      familyMembers: [
        for (final member in initial.familyMembers)
          member.copyWith(familyId: 'family-remote-1'),
      ],
    );
  }

  ZeniAppState coherentGraphState() {
    final state = boundState();
    final seed = ZeniAppState.seeded();
    final child = seed.children.first.copyWith(
      familyId: 'family-remote-1',
      starBalance: 0,
    );
    final mission = seed.missions.first.copyWith(
      familyId: 'family-remote-1',
      childId: child.id,
    );
    final reward = seed.rewards.first.copyWith(
      familyId: 'family-remote-1',
      childId: child.id,
    );
    final missionLog = MissionLog(
      id: 'mission-log-1',
      missionId: mission.id,
      childId: child.id,
      scheduledDate: DateTime(2026, 1, 1),
      status: MissionLogStatus.approved,
      starsAwarded: mission.stars,
    );
    final rewardRequest = RewardRequest(
      id: 'reward-request-1',
      rewardId: reward.id,
      childId: child.id,
      status: RewardRequestStatus.approved,
      requestedAt: DateTime(2026, 1, 1),
    );
    final ledgerEntry = StarLedgerEntry(
      id: 'ledger-1',
      familyId: 'family-remote-1',
      childId: child.id,
      amount: mission.stars,
      balanceAfter: mission.stars,
      type: StarLedgerEntryType.earned,
      title: 'Missão aprovada',
      createdAt: DateTime(2026, 1, 1),
      relatedMissionLogId: missionLog.id,
      relatedRewardRequestId: rewardRequest.id,
    );
    return state.copyWith(
      children: [child],
      missions: [mission],
      missionLogs: [missionLog],
      rewards: [reward],
      rewardRequests: [rewardRequest],
      starLedgerEntries: [ledgerEntry],
    );
  }

  Future<
    ({
      ProviderContainer container,
      _MutableIdentityAuth auth,
      _IdentityAccount account,
      _IdentityChildren children,
      _IdentityMissionLogs missionLogs,
    })
  >
  setup(ZeniAppState state, {String familyId = 'family-remote-1'}) async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(state.toJson()),
    });
    final auth = _MutableIdentityAuth();
    final account = _IdentityAccount()..familyId = familyId;
    final children = _IdentityChildren();
    final missionLogs = _IdentityMissionLogs();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accountRepositoryProvider.overrideWithValue(account),
        remoteChildrenRepositoryProvider.overrideWithValue(children),
        remoteMissionsRepositoryProvider.overrideWithValue(
          const _TestRemoteMissionsRepository(),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          const _TestRemoteRewardsRepository(),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(missionLogs),
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
    addTearDown(() {
      container.dispose();
      auth.events.close();
    });
    await container.read(zeniAppStateControllerProvider.future);
    container.read(authStateProvider);
    return (
      container: container,
      auth: auth,
      account: account,
      children: children,
      missionLogs: missionLogs,
    );
  }

  test(
    'identity classifies all four states without inferring binding from login',
    () {
      final empty = ZeniAppState.initial();
      expect(
        FamilyIdentity.evaluate(empty, 'family-remote-1'),
        FamilyIdentityStatus.localUnboundSafe,
      );
      expect(
        FamilyIdentity.evaluate(boundState(), 'family-remote-1'),
        FamilyIdentityStatus.bound,
      );
      expect(
        FamilyIdentity.evaluate(boundState(), 'family-B'),
        FamilyIdentityStatus.sessionMismatch,
      );
      expect(
        FamilyIdentity.evaluate(
          empty.copyWith(children: ZeniAppState.seeded().children),
          'family-remote-1',
        ),
        FamilyIdentityStatus.legacyUnboundWithData,
      );
    },
  );

  test('identity rejects mission log with unknown child', () {
    final state = coherentGraphState();
    final broken = state.copyWith(
      missionLogs: [state.missionLogs.single.copyWith(childId: 'missing')],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects mission log with unknown mission', () {
    final state = coherentGraphState();
    final broken = state.copyWith(
      missionLogs: [state.missionLogs.single.copyWith(missionId: 'missing')],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects reward request with unknown child', () {
    final state = coherentGraphState();
    final broken = state.copyWith(
      rewardRequests: [
        state.rewardRequests.single.copyWith(childId: 'missing'),
      ],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects reward request with unknown reward', () {
    final state = coherentGraphState();
    final broken = state.copyWith(
      rewardRequests: [
        state.rewardRequests.single.copyWith(rewardId: 'missing'),
      ],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects ledger entry with unknown child', () {
    final state = coherentGraphState();
    final entry = state.starLedgerEntries.single;
    final broken = state.copyWith(
      starLedgerEntries: [
        StarLedgerEntry(
          id: entry.id,
          familyId: entry.familyId,
          childId: 'missing',
          amount: entry.amount,
          balanceAfter: entry.balanceAfter,
          type: entry.type,
          title: entry.title,
          createdAt: entry.createdAt,
          relatedMissionLogId: entry.relatedMissionLogId,
          relatedRewardRequestId: entry.relatedRewardRequestId,
        ),
      ],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects ledger entry with unknown mission log', () {
    final state = coherentGraphState();
    final entry = state.starLedgerEntries.single;
    final broken = state.copyWith(
      starLedgerEntries: [
        StarLedgerEntry(
          id: entry.id,
          familyId: entry.familyId,
          childId: entry.childId,
          amount: entry.amount,
          balanceAfter: entry.balanceAfter,
          type: entry.type,
          title: entry.title,
          createdAt: entry.createdAt,
          relatedMissionLogId: 'missing',
          relatedRewardRequestId: entry.relatedRewardRequestId,
        ),
      ],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('identity rejects ledger entry with unknown reward request', () {
    final state = coherentGraphState();
    final entry = state.starLedgerEntries.single;
    final broken = state.copyWith(
      starLedgerEntries: [
        StarLedgerEntry(
          id: entry.id,
          familyId: entry.familyId,
          childId: entry.childId,
          amount: entry.amount,
          balanceAfter: entry.balanceAfter,
          type: entry.type,
          title: entry.title,
          createdAt: entry.createdAt,
          relatedMissionLogId: entry.relatedMissionLogId,
          relatedRewardRequestId: 'missing',
        ),
      ],
    );
    expect(
      FamilyIdentity.evaluate(broken, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
  });

  test('login with found family does not create another family', () async {
    final h = await setup(boundState());
    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
    expect(result.isSuccess, isTrue);
    expect(h.container.read(authStateProvider).isAuthenticated, isTrue);
    expect(
      h.container.read(authStateProvider).familyIdentityAccess,
      ZeniFamilyIdentityAccess.ready,
    );
    expect(h.account.resolveCalls, 1);
    expect(h.account.createCalls, 0);
    expect(h.account.ensureCalls, 0);
  });

  test('Google name initializes the profile on first login', () async {
    final h = await setup(boundState());
    h.account.profile = null;

    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithGoogle();

    expect(result.isSuccess, isTrue);
    expect(h.account.profile?.displayName, 'Nome do Google');
    expect(h.account.profileInitializationCalls, 1);
  });

  test('Google login does not overwrite an existing profile name', () async {
    final h = await setup(boundState());
    h.account.profile = const ZeniAccountProfile(
      userId: 'user-B',
      displayName: 'Nome escolhido no Zeni',
      email: 'b@zeni.app',
    );

    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithGoogle();

    expect(result.isSuccess, isTrue);
    expect(h.account.profile?.displayName, 'Nome escolhido no Zeni');
    expect(h.account.profileInitializationCalls, 1);
  });

  test('login not found with empty safe base creates initial family', () async {
    final h = await setup(ZeniAppState.initial());
    h.account.hasRemoteFamily = false;
    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
    expect(result.isSuccess, isTrue);
    expect(h.account.resolveCalls, 1);
    expect(h.account.createCalls, 1);
    expect(h.account.ensureCalls, 0);
    final localState = await h.container.read(
      zeniAppStateControllerProvider.future,
    );
    expect(localState.family.id, 'family-remote-1');
    expect(
      h.container.read(authStateProvider).familyIdentityAccess,
      ZeniFamilyIdentityAccess.ready,
    );
  });

  test('create initial family accepts already exists after retry', () async {
    final h = await setup(ZeniAppState.initial());
    h.account.hasRemoteFamily = false;
    h.account.createStatus = ZeniCreateInitialFamilyStatus.alreadyExists;
    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
    expect(result.isSuccess, isTrue);
    expect(h.account.resolveCalls, 1);
    expect(h.account.createCalls, 1);
  });

  for (final blockedStatus in [
    ZeniResolveCurrentFamilyStatus.ambiguous,
    ZeniResolveCurrentFamilyStatus.inconsistent,
  ]) {
    test('login $blockedStatus blocks cloud identity without create', () async {
      final h = await setup(ZeniAppState.initial());
      h.account.forcedResolveStatus = blockedStatus;
      final result = await h.container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
      expect(result.isSuccess, isFalse);
      expect(h.container.read(authStateProvider).isAuthenticated, isTrue);
      expect(
        result.message,
        blockedStatus == ZeniResolveCurrentFamilyStatus.ambiguous
            ? canonicalFamilyAmbiguousMessage
            : canonicalFamilyInconsistentMessage,
      );
      expect(h.account.createCalls, 0);
      final syncResult = await h.container
          .read(zeniCloudSyncControllerProvider)
          .syncCloudDataNow();
      expect(syncResult.isSuccess, isFalse);
      expect(h.children.pushes, 0);
      expect(h.children.reads, 0);
    });
  }

  test('session disappearing after resolve prevents creation', () async {
    final h = await setup(ZeniAppState.initial());
    h.account.hasRemoteFamily = false;
    h.account.beforeResolveReturn = h.auth.signOut;
    final result = await h.container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
    expect(result.isSuccess, isFalse);
    expect(result.message, canonicalFamilySessionChangedMessage);
    expect(h.account.createCalls, 0);
  });

  test('concurrent login preparation creates the family once', () async {
    final h = await setup(ZeniAppState.initial());
    h.account.hasRemoteFamily = false;
    h.account.createStarted = Completer<void>();
    h.account.createGate = Completer<void>();
    final controller = h.container.read(zeniAuthControllerProvider);
    final first = controller.signInWithEmailPassword(
      email: 'b@zeni.app',
      password: 'test',
    );
    await h.account.createStarted!.future;
    final second = controller.signInWithEmailPassword(
      email: 'b@zeni.app',
      password: 'test',
    );
    h.account.createGate!.complete();
    final results = await Future.wait([first, second]);
    expect(results.every((result) => result.isSuccess), isTrue);
    expect(h.account.resolveCalls, 1);
    expect(h.account.createCalls, 1);
  });

  test(
    'login preserves unbound local data and does not ensure a family',
    () async {
      final local = ZeniAppState.seeded().copyWith(
        family: ZeniAppState.initial().family,
      );
      final h = await setup(local);
      h.account.hasRemoteFamily = false;
      final before = jsonEncode(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).toJson(),
      );
      final result = await h.container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
      expect(result.isSuccess, isFalse);
      expect(result.issue, ZeniAuthIssue.localFamilyConflict);
      expect(result.message, localFamilyConflictMessage);
      expect(h.container.read(authStateProvider).isAuthenticated, isTrue);
      expect(
        h.container.read(authStateProvider).familyIdentityAccess,
        ZeniFamilyIdentityAccess.blocked,
      );
      expect(h.auth.currentUser, isNotNull);
      expect(h.account.createCalls, 0);
      expect(h.account.ensureCalls, 0);
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );

      await h.container.read(zeniAuthControllerProvider).signOut();
      final signedOutState = h.container.read(authStateProvider);
      expect(signedOutState.isAuthenticated, isFalse);
      expect(signedOutState.user, isNull);
      expect(
        signedOutState.familyIdentityAccess,
        ZeniFamilyIdentityAccess.pending,
      );
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );
    },
  );

  test(
    'bootstrap action is disabled on mismatch without reading remote catalogs',
    () async {
      final h = await setup(boundState(), familyId: 'family-B');
      final action = await h.container.read(
        deviceBootstrapActionStateProvider.future,
      );
      expect(action.isVisible, isFalse);
      expect(action.showAction, isFalse);
      expect(action.isEnabled, isFalse);
      expect(action.message, familyIdentityBlockedMessage);
      expect(h.children.reads, 0);
    },
  );

  test(
    'bootstrap action is hidden for an unsafe unbound base without catalog reads',
    () async {
      final local = ZeniAppState.seeded().copyWith(
        family: ZeniAppState.initial().family,
      );
      final h = await setup(local);
      final action = await h.container.read(
        deviceBootstrapActionStateProvider.future,
      );
      expect(action.isVisible, isFalse);
      expect(action.showAction, isFalse);
      expect(action.isEnabled, isFalse);
      expect(h.children.reads, 0);
    },
  );

  test(
    'historical restore action is disabled on mismatch before history reads',
    () async {
      final h = await setup(coherentGraphState(), familyId: 'family-B');
      final action = await h.container.read(
        historicalRestoreActionStateProvider.future,
      );
      expect(action.isVisible, isFalse);
      expect(action.showAction, isFalse);
      expect(action.isEnabled, isFalse);
      expect(action.message, familyIdentityBlockedMessage);
      expect(h.missionLogs.reads, 0);
    },
  );

  test('bound A plus session A permits sync', () async {
    final h = await setup(boundState());
    final result = await h.container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    expect(result.isSuccess, isTrue);
    expect(h.children.pushes, 1);
  });

  test(
    'mismatch blocks push and pull and preserves persisted state byte for byte',
    () async {
      final h = await setup(boundState(), familyId: 'family-B');
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString('zeni_app_state_v1');
      final result = await h.container
          .read(zeniCloudSyncControllerProvider)
          .syncCloudDataNow();
      expect(result.status, ZeniCloudSyncStatus.familyMismatch);
      expect(h.children.pushes, 0);
      expect(h.children.reads, 0);
      expect(prefs.getString('zeni_app_state_v1'), before);
      expect(h.account.ensureCalls, 0);
    },
  );

  test(
    'manual retries cannot bypass mismatch or create a remote family',
    () async {
      final h = await setup(boundState(), familyId: 'family-B');
      for (var retry = 0; retry < 3; retry++) {
        final result = await h.container
            .read(zeniCloudSyncControllerProvider)
            .syncNowManually();
        expect(result.status, ZeniCloudSyncStatus.familyMismatch);
      }
      expect(h.children.pushes, 0);
      expect(h.children.reads, 0);
      expect(h.account.ensureCalls, 0);
    },
  );

  test(
    'local data without binding cannot attach to the first session',
    () async {
      final local = ZeniAppState.seeded().copyWith(
        family: ZeniAppState.initial().family,
      );
      final h = await setup(local);
      final before = jsonEncode(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).toJson(),
      );
      final result = await h.container
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      expect(result.status, ZeniCloudSyncStatus.familyMismatch);
      expect(h.children.pushes, 0);
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );
    },
  );

  test(
    'logout preserves binding and login to B cannot reassociate A',
    () async {
      final h = await setup(boundState());
      final before = jsonEncode(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).toJson(),
      );
      await h.container.read(zeniAuthControllerProvider).signOut();
      expect(h.container.read(authStateProvider).isAuthenticated, isFalse);
      expect(
        (await h.container
                .read(zeniCloudSyncControllerProvider)
                .syncCloudDataNow())
            .status,
        ZeniCloudSyncStatus.noSession,
      );
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );
      h.account.familyId = 'family-B';
      final resolveCallsBeforeLogin = h.account.resolveCalls;
      final loginResult = await h.container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(email: 'b@zeni.app', password: 'test');
      expect(loginResult.issue, ZeniAuthIssue.localFamilyConflict);
      expect(h.account.resolveCalls, resolveCallsBeforeLogin + 1);
      expect(h.container.read(authStateProvider).isAuthenticated, isTrue);
      expect(
        h.container.read(authStateProvider).isFamilyIdentityBlocked,
        isTrue,
      );
      expect(h.auth.currentUser, isNotNull);
      final result = await h.container
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      expect(result.status, ZeniCloudSyncStatus.familyMismatch);
      expect(h.children.pushes, 0);
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );
    },
  );

  test(
    'empty local base becomes bound only after safe bootstrap and persists restart',
    () async {
      final h = await setup(ZeniAppState.initial());
      final result = await h.container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      expect(result.isSuccess, isTrue);
      final state = await h.container.read(
        zeniAppStateControllerProvider.future,
      );
      expect(
        FamilyIdentity.evaluate(state, 'family-remote-1'),
        FamilyIdentityStatus.bound,
      );
      final prefs = await SharedPreferences.getInstance();
      final restored = ZeniAppState.fromJson(
        jsonDecode(prefs.getString('zeni_app_state_v1')!)
            as Map<String, dynamic>,
      );
      expect(restored.family.id, 'family-remote-1');
      expect(h.children.pushes, 0);
    },
  );

  test(
    'bootstrap cannot replace an empty but already bound A with B',
    () async {
      final h = await setup(boundState(), familyId: 'family-B');
      final result = await h.container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      expect(result.isSuccess, isFalse);
      expect(h.children.reads, 0);
      expect(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).family.id,
        'family-remote-1',
      );
    },
  );

  test('history without catalog is not an empty safe unbound base', () async {
    final local = ZeniAppState.initial().copyWith(
      missionLogs: ZeniAppState.seeded().missionLogs,
    );
    expect(local.missionLogs, isNotEmpty);
    final h = await setup(local);
    expect(
      FamilyIdentity.evaluate(local, 'family-remote-1'),
      FamilyIdentityStatus.legacyUnboundWithData,
    );
    expect(
      (await h.container
              .read(deviceBootstrapControllerProvider)
              .bootstrapFromRemoteFamily())
          .isSuccess,
      isFalse,
    );
    expect(h.children.reads, 0);
  });

  test(
    'direct domain push entry points also use the shared identity guard',
    () async {
      final h = await setup(boundState(), familyId: 'family-B');
      expect(
        (await h.container
                .read(zeniRemoteChildrenControllerProvider)
                .ensureRemoteChildrenForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(
        (await h.container
                .read(zeniRemoteMissionsControllerProvider)
                .ensureRemoteMissionsForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(
        (await h.container
                .read(zeniRemoteRewardsControllerProvider)
                .ensureRemoteRewardsForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(
        (await h.container
                .read(zeniRemoteMissionLogsControllerProvider)
                .ensureRemoteMissionLogsForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(
        (await h.container
                .read(zeniRemoteRewardRequestsControllerProvider)
                .ensureRemoteRewardRequestsForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(
        (await h.container
                .read(zeniRemoteStarLedgerControllerProvider)
                .ensureRemoteStarLedgerForCurrentFamily())
            .isSuccess,
        isFalse,
      );
      expect(h.children.pushes, 0);
    },
  );

  test(
    'account change while bootstrap reads cannot apply the stale snapshot',
    () async {
      final h = await setup(ZeniAppState.initial());
      final started = Completer<void>();
      final resume = Completer<void>();
      h.children.beforeRead = () async {
        started.complete();
        await resume.future;
      };
      final pending = h.container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      await started.future;
      await h.container.read(zeniAuthControllerProvider).signOut();
      resume.complete();
      expect((await pending).isSuccess, isFalse);
      expect(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).family.id,
        'local-family',
      );
      expect(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).children,
        isEmpty,
      );
    },
  );

  test('account change during push cannot continue into pull', () async {
    final h = await setup(boundState());
    h.children.afterPush = () async {
      await h.container.read(zeniAuthControllerProvider).signOut();
    };
    expect(
      (await h.container
              .read(zeniCloudSyncControllerProvider)
              .syncCloudDataNow())
          .isSuccess,
      isFalse,
    );
    expect(
      (await h.container.read(zeniAppStateControllerProvider.future)).children,
      isEmpty,
    );
    expect(
      (await h.container.read(zeniAppStateControllerProvider.future)).family.id,
      'family-remote-1',
    );
  });

  test(
    'historical restore rejects another family without replacing local catalogs',
    () async {
      final h = await setup(ZeniAppState.initial());
      await h.container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      final before = jsonEncode(
        (await h.container.read(
          zeniAppStateControllerProvider.future,
        )).toJson(),
      );
      h.account.familyId = 'family-B';
      h.container.invalidate(remoteFamilySummaryProvider);
      final result = await h.container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();
      expect(result.isSuccess, isFalse);
      expect(
        jsonEncode(
          (await h.container.read(
            zeniAppStateControllerProvider.future,
          )).toJson(),
        ),
        before,
      );
    },
  );
}

class _MutableIdentityAuth extends _TestAuthRepository {
  ZeniAuthUser? user = const ZeniAuthUser(id: 'user-A', email: 'a@zeni.app');
  final events = StreamController<ZeniAuthUser?>.broadcast();
  @override
  ZeniAuthUser? get currentUser => user;
  @override
  Stream<ZeniAuthUser?> authStateChanges() => events.stream;
  @override
  Future<ZeniAuthOperationResult> signOut() async {
    user = null;
    events.add(null);
    return const ZeniAuthOperationResult.success();
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    user = ZeniAuthUser(id: 'user-B', email: email);
    events.add(user);
    return ZeniAuthOperationResult.success(user: user);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    user = const ZeniAuthUser(
      id: 'user-B',
      email: 'b@zeni.app',
      displayName: 'Nome do Google',
    );
    events.add(user);
    return ZeniAuthOperationResult.success(user: user);
  }
}

class _IdentityAccount extends _TestAccountRepository {
  String familyId = 'family-remote-1';
  bool hasRemoteFamily = true;
  ZeniResolveCurrentFamilyStatus? forcedResolveStatus;
  ZeniCreateInitialFamilyStatus createStatus =
      ZeniCreateInitialFamilyStatus.created;
  Future<void> Function()? beforeResolveReturn;
  Completer<void>? createStarted;
  Completer<void>? createGate;
  int resolveCalls = 0;
  int createCalls = 0;
  int ensureCalls = 0;
  int profileInitializationCalls = 0;
  ZeniAccountProfile? profile;

  @override
  Future<ZeniAccountProfile?> getCurrentAccountProfile() async => profile;

  @override
  Future<ZeniUpdateAccountProfileResult> initializeCurrentAccountProfile({
    String? suggestedDisplayName,
  }) async {
    profileInitializationCalls++;
    final existing = profile;
    if (existing != null) {
      return ZeniUpdateAccountProfileResult.success(existing);
    }
    final created = ZeniAccountProfile(
      userId: 'user-B',
      displayName: suggestedDisplayName?.trim() ?? '',
      email: 'b@zeni.app',
    );
    profile = created;
    return ZeniUpdateAccountProfileResult.success(created);
  }

  RemoteFamilySummary get _summary => RemoteFamilySummary(
    familyId: familyId,
    familyName: 'Família',
    role: 'owner',
  );

  @override
  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    resolveCalls++;
    await beforeResolveReturn?.call();
    final status = forcedResolveStatus;
    if (status == ZeniResolveCurrentFamilyStatus.ambiguous) {
      return const ZeniResolveCurrentFamilyResult.ambiguous(
        userId: 'user-B',
        reason: 'multiple_memberships',
      );
    }
    if (status == ZeniResolveCurrentFamilyStatus.inconsistent) {
      return const ZeniResolveCurrentFamilyResult.inconsistent(
        userId: 'user-B',
        reason: 'invalid_membership_or_owner',
      );
    }
    if (!hasRemoteFamily || status == ZeniResolveCurrentFamilyStatus.notFound) {
      return const ZeniResolveCurrentFamilyResult.notFound(userId: 'user-B');
    }
    return ZeniResolveCurrentFamilyResult.found(
      summary: _summary,
      userId: 'user-B',
      membershipId: 'membership-B',
    );
  }

  @override
  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    createCalls++;
    createStarted?.complete();
    await createGate?.future;
    hasRemoteFamily = true;
    return switch (createStatus) {
      ZeniCreateInitialFamilyStatus.created =>
        ZeniCreateInitialFamilyResult.created(
          summary: _summary,
          userId: 'user-B',
          membershipId: 'membership-B',
        ),
      ZeniCreateInitialFamilyStatus.alreadyExists =>
        ZeniCreateInitialFamilyResult.alreadyExists(
          summary: _summary,
          userId: 'user-B',
          membershipId: 'membership-B',
        ),
      ZeniCreateInitialFamilyStatus.ambiguous =>
        const ZeniCreateInitialFamilyResult.ambiguous(
          userId: 'user-B',
          reason: 'multiple_memberships',
        ),
      ZeniCreateInitialFamilyStatus.inconsistent =>
        const ZeniCreateInitialFamilyResult.inconsistent(
          userId: 'user-B',
          reason: 'invalid_membership_or_owner',
        ),
      ZeniCreateInitialFamilyStatus.failure =>
        const ZeniCreateInitialFamilyResult.failure('create failed'),
    };
  }

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    if (!hasRemoteFamily) return null;
    return _summary;
  }

  @override
  Future<ZeniEnsureRemoteFamilyResult>
  ensureRemoteFamilyForCurrentUser() async {
    ensureCalls++;
    hasRemoteFamily = true;
    return ZeniEnsureRemoteFamilyResult.success(
      (await getCurrentRemoteFamilySummary())!,
    );
  }
}

class _IdentityChildren extends _TestRemoteChildrenRepository {
  int pushes = 0;
  int reads = 0;
  Future<void> Function()? beforeRead;
  Future<void> Function()? afterPush;
  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    reads++;
    await beforeRead?.call();
    return super.getRemoteChildren(familyId: familyId);
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List localChildren,
  }) async {
    pushes++;
    await afterPush?.call();
    return ZeniEnsureRemoteChildrenResult.success(
      await super.getRemoteChildren(familyId: familyId),
    );
  }
}

class _IdentityMissionLogs extends _EmptyRemoteMissionLogsRepository {
  int reads = 0;

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async {
    reads++;
    return super.getRemoteMissionLogs(familyId: familyId);
  }
}
