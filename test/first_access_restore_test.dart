import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/balance/data/models/star_ledger_entry.dart';
import 'package:zeni/features/balance/data/repositories/remote_child_balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/remote_star_ledger_repository.dart';
import 'package:zeni/features/balance/presentation/providers/remote_child_balance_providers.dart';
import 'package:zeni/features/balance/presentation/providers/remote_star_ledger_providers.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/family/data/repositories/remote_children_repository.dart';
import 'package:zeni/features/family/presentation/providers/remote_children_providers.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/rewards/data/repositories/remote_reward_requests_repository.dart';
import 'package:zeni/features/rewards/data/repositories/remote_rewards_repository.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_reward_requests_providers.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_rewards_providers.dart';
import 'package:zeni/features/sync/presentation/providers/first_access_restore_providers.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';
import 'package:zeni/features/tasks/data/repositories/remote_mission_logs_repository.dart';
import 'package:zeni/features/tasks/data/repositories/remote_missions_repository.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_mission_logs_providers.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_missions_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZeniSupabaseBootstrap.resetForTests();
  });

  tearDown(() {
    ZeniSupabaseBootstrap.resetForTests();
  });

  Future<void> enableSupabaseForTests() {
    return ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://zeni.test.supabase.co',
        anonKey: 'anon-key',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
  }

  void seedAppState(ZeniAppState state) {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(state.toJson()),
    });
  }

  ProviderContainer buildContainer({
    required RemoteFamilySummary? remoteFamily,
    required List<RemoteChildSummary> remoteChildren,
    required List<RemoteMissionSummary> remoteMissions,
    required List<RemoteRewardSummary> remoteRewards,
    required List<RemoteMissionLogSummary> remoteMissionLogs,
    required List<RemoteRewardRequestSummary> remoteRewardRequests,
    required List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries,
    required List<RemoteChildStarBalance> remoteChildBalances,
  }) {
    final authRepository = _TestAuthRepository(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        accountRepositoryProvider.overrideWithValue(
          _TestAccountRepository(summary: remoteFamily),
        ),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _TestChildrenRepository(children: remoteChildren),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _TestMissionsRepository(missions: remoteMissions),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _TestRewardsRepository(rewards: remoteRewards),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _TestMissionLogsRepository(logs: remoteMissionLogs),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _TestRewardRequestsRepository(requests: remoteRewardRequests),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _TestStarLedgerRepository(entries: remoteStarLedgerEntries),
        ),
        remoteChildBalanceRepositoryProvider.overrideWithValue(
          _TestChildBalanceRepository(balances: remoteChildBalances),
        ),
      ],
    );
    addTearDown(() async {
      await authRepository.dispose();
      container.dispose();
    });
    return container;
  }

  test(
    'full first access restore rebuilds catalogs history ledger and balances',
    () async {
      await enableSupabaseForTests();
      final scenario = _buildRemoteRestoreScenario();
      final container = buildContainer(
        remoteFamily: scenario.remoteFamily,
        remoteChildren: scenario.remoteChildren,
        remoteMissions: scenario.remoteMissions,
        remoteRewards: scenario.remoteRewards,
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: scenario.remoteChildBalances,
      );

      final result = await container
          .read(firstAccessRestoreControllerProvider)
          .restoreFamilyOnEmptyDevice();
      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(result.status, FirstAccessRestoreResultStatus.success);
      expect(result.message, 'Família restaurada com sucesso neste aparelho.');
      expect(state.family.id, 'remote-family');
      expect(state.children, hasLength(2));
      expect(state.missions, hasLength(2));
      expect(state.rewards, hasLength(2));
      expect(state.missionLogs, hasLength(2));
      expect(state.rewardRequests, hasLength(1));
      expect(state.starLedgerEntries, hasLength(3));
      expect(state.children.map((child) => child.starBalance).toList(), [6, 5]);
    },
  );

  test(
    'remote balance divergence restores catalog only and blocks history safely',
    () async {
      await enableSupabaseForTests();
      final scenario = _buildRemoteRestoreScenario(
        remoteChildBalances: const [
          RemoteChildStarBalance(
            familyId: 'remote-family',
            childId: 'remote-child-1',
            childName: 'Luna',
            creditsTotal: 10,
            debitsTotal: 4,
            derivedBalance: 999,
            ledgerEventsCount: 2,
          ),
          RemoteChildStarBalance(
            familyId: 'remote-family',
            childId: 'remote-child-2',
            childName: 'Theo',
            creditsTotal: 5,
            debitsTotal: 0,
            derivedBalance: 5,
            ledgerEventsCount: 1,
          ),
        ],
      );
      final container = buildContainer(
        remoteFamily: scenario.remoteFamily,
        remoteChildren: scenario.remoteChildren,
        remoteMissions: scenario.remoteMissions,
        remoteRewards: scenario.remoteRewards,
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: scenario.remoteChildBalances,
      );

      final result = await container
          .read(firstAccessRestoreControllerProvider)
          .restoreFamilyOnEmptyDevice();
      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(result.status, FirstAccessRestoreResultStatus.partialSuccess);
      expect(
        result.message,
        'Família restaurada. Não foi possível restaurar histórico e saldo com segurança agora.',
      );
      expect(state.children, hasLength(2));
      expect(state.missions, hasLength(2));
      expect(state.rewards, hasLength(2));
      expect(state.missionLogs, isEmpty);
      expect(state.rewardRequests, isEmpty);
      expect(state.starLedgerEntries, isEmpty);
      expect(state.children.map((child) => child.starBalance).toList(), [0, 0]);
    },
  );

  test('local activity blocks full first access restore', () async {
    await enableSupabaseForTests();
    seedAppState(ZeniAppState.seeded());
    final scenario = _buildRemoteRestoreScenario();
    final container = buildContainer(
      remoteFamily: scenario.remoteFamily,
      remoteChildren: scenario.remoteChildren,
      remoteMissions: scenario.remoteMissions,
      remoteRewards: scenario.remoteRewards,
      remoteMissionLogs: scenario.remoteMissionLogs,
      remoteRewardRequests: scenario.remoteRewardRequests,
      remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
      remoteChildBalances: scenario.remoteChildBalances,
    );

    final before = await container.read(zeniAppStateControllerProvider.future);
    final result = await container
        .read(firstAccessRestoreControllerProvider)
        .restoreFamilyOnEmptyDevice();
    final after = container.read(zeniAppStateControllerProvider).asData!.value;

    expect(result.status, FirstAccessRestoreResultStatus.blocked);
    expect(after.children.length, before.children.length);
    expect(after.missions.length, before.missions.length);
    expect(after.rewards.length, before.rewards.length);
    expect(after.starLedgerEntries.length, before.starLedgerEntries.length);
  });
}

class _RemoteRestoreScenario {
  const _RemoteRestoreScenario({
    required this.remoteFamily,
    required this.remoteChildren,
    required this.remoteMissions,
    required this.remoteRewards,
    required this.remoteMissionLogs,
    required this.remoteRewardRequests,
    required this.remoteStarLedgerEntries,
    required this.remoteChildBalances,
  });

  final RemoteFamilySummary remoteFamily;
  final List<RemoteChildSummary> remoteChildren;
  final List<RemoteMissionSummary> remoteMissions;
  final List<RemoteRewardSummary> remoteRewards;
  final List<RemoteMissionLogSummary> remoteMissionLogs;
  final List<RemoteRewardRequestSummary> remoteRewardRequests;
  final List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries;
  final List<RemoteChildStarBalance> remoteChildBalances;
}

_RemoteRestoreScenario _buildRemoteRestoreScenario({
  List<RemoteChildStarBalance>? remoteChildBalances,
}) {
  return _RemoteRestoreScenario(
    remoteFamily: const RemoteFamilySummary(
      familyId: 'remote-family',
      familyName: 'Família Remota',
      role: 'owner',
    ),
    remoteChildren: const [
      RemoteChildSummary(
        id: 'remote-child-1',
        familyId: 'remote-family',
        localId: 'child-local-1',
        name: 'Luna',
        avatarKey: '🦊',
      ),
      RemoteChildSummary(
        id: 'remote-child-2',
        familyId: 'remote-family',
        localId: 'child-local-2',
        name: 'Theo',
        avatarKey: '🐼',
      ),
    ],
    remoteMissions: const [
      RemoteMissionSummary(
        id: 'remote-mission-1',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        localId: 'mission-local-1',
        title: 'Arrumar brinquedos',
        stars: 10,
        requiresApproval: false,
        recurrenceType: 'daily',
        recurrenceDays: <int>[],
        isActive: true,
      ),
      RemoteMissionSummary(
        id: 'remote-mission-2',
        familyId: 'remote-family',
        childId: 'remote-child-2',
        localId: 'mission-local-2',
        title: 'Ler por 15 minutos',
        stars: 5,
        requiresApproval: false,
        recurrenceType: 'daily',
        recurrenceDays: <int>[],
        isActive: true,
      ),
    ],
    remoteRewards: const [
      RemoteRewardSummary(
        id: 'remote-reward-1',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        localId: 'reward-local-1',
        title: 'Filme em família',
        cost: 4,
        imageKey: '🎬',
        isActive: true,
      ),
      RemoteRewardSummary(
        id: 'remote-reward-2',
        familyId: 'remote-family',
        childId: 'remote-child-2',
        localId: 'reward-local-2',
        title: 'Escolher sobremesa',
        cost: 6,
        imageKey: '🍨',
        isActive: true,
      ),
    ],
    remoteMissionLogs: [
      RemoteMissionLogSummary(
        id: 'remote-mission-log-1',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        missionId: 'remote-mission-1',
        localId: 'mission-log-local-1',
        status: 'approved',
        starsAwarded: 10,
        scheduledDate: DateTime(2026, 6, 1),
        completedAt: DateTime(2026, 6, 1, 8),
        approvedAt: DateTime(2026, 6, 1, 9),
      ),
      RemoteMissionLogSummary(
        id: 'remote-mission-log-2',
        familyId: 'remote-family',
        childId: 'remote-child-2',
        missionId: 'remote-mission-2',
        localId: 'mission-log-local-2',
        status: 'approved',
        starsAwarded: 5,
        scheduledDate: DateTime(2026, 6, 1),
        completedAt: DateTime(2026, 6, 1, 9, 30),
        approvedAt: DateTime(2026, 6, 1, 9, 45),
      ),
    ],
    remoteRewardRequests: [
      RemoteRewardRequestSummary(
        id: 'remote-reward-request-1',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        rewardId: 'remote-reward-1',
        localId: 'reward-request-local-1',
        status: 'approved',
        starsSpent: 4,
        requestedAt: DateTime(2026, 6, 1, 10),
        approvedAt: DateTime(2026, 6, 1, 10, 30),
      ),
    ],
    remoteStarLedgerEntries: [
      RemoteStarLedgerEntrySummary(
        id: 'remote-ledger-1',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        sourceType: 'mission_log',
        sourceId: 'remote-mission-log-1',
        sourceLocalId: 'mission-log-local-1',
        idempotencyKey: 'restore-1',
        direction: 'credit',
        amount: 10,
        occurredAt: DateTime(2026, 6, 1, 9),
        createdAt: DateTime(2026, 6, 1, 9),
        reason: 'Conclusão restaurada',
      ),
      RemoteStarLedgerEntrySummary(
        id: 'remote-ledger-2',
        familyId: 'remote-family',
        childId: 'remote-child-2',
        sourceType: 'mission_log',
        sourceId: 'remote-mission-log-2',
        sourceLocalId: 'mission-log-local-2',
        idempotencyKey: 'restore-2',
        direction: 'credit',
        amount: 5,
        occurredAt: DateTime(2026, 6, 1, 9, 45),
        createdAt: DateTime(2026, 6, 1, 9, 45),
        reason: 'Conclusão restaurada',
      ),
      RemoteStarLedgerEntrySummary(
        id: 'remote-ledger-3',
        familyId: 'remote-family',
        childId: 'remote-child-1',
        sourceType: 'reward_request',
        sourceId: 'remote-reward-request-1',
        sourceLocalId: 'reward-request-local-1',
        idempotencyKey: 'restore-3',
        direction: 'debit',
        amount: 4,
        occurredAt: DateTime(2026, 6, 1, 10, 30),
        createdAt: DateTime(2026, 6, 1, 10, 30),
        reason: 'Resgate restaurado',
      ),
    ],
    remoteChildBalances:
        remoteChildBalances ??
        const [
          RemoteChildStarBalance(
            familyId: 'remote-family',
            childId: 'remote-child-1',
            childName: 'Luna',
            creditsTotal: 10,
            debitsTotal: 4,
            derivedBalance: 6,
            ledgerEventsCount: 2,
          ),
          RemoteChildStarBalance(
            familyId: 'remote-family',
            childId: 'remote-child-2',
            childName: 'Theo',
            creditsTotal: 5,
            debitsTotal: 0,
            derivedBalance: 5,
            ledgerEventsCount: 1,
          ),
        ],
  );
}

class _TestAuthRepository implements ZeniAuthRepository {
  _TestAuthRepository({ZeniAuthUser? initialUser}) : _currentUser = initialUser;

  final StreamController<ZeniAuthUser?> _controller =
      StreamController<ZeniAuthUser?>.broadcast();
  ZeniAuthUser? _currentUser;

  @override
  bool get isGoogleSignInAvailable => true;

  @override
  bool get isAppleSignInAvailable => true;

  @override
  ZeniAuthUser? get currentUser => _currentUser;

  @override
  Stream<ZeniAuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = ZeniAuthUser(id: 'signed-in', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _currentUser = ZeniAuthUser(
      id: 'signed-up',
      email: email,
      displayName: displayName,
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const ZeniAuthOperationResult.success();
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    return const ZeniAuthOperationResult.success();
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    return const ZeniAuthOperationResult.success();
  }

  Future<void> dispose() => _controller.close();
}

class _TestAccountRepository extends ZeniAccountRepository {
  const _TestAccountRepository({required this.summary});

  final RemoteFamilySummary? summary;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    final value = summary;
    return value == null
        ? const ZeniResolveCurrentFamilyResult.notFound(userId: 'test-user')
        : ZeniResolveCurrentFamilyResult.found(
            summary: value,
            userId: 'test-user',
            membershipId: 'membership-test',
          );
  }

  @override
  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    final value = summary;
    return value == null
        ? const ZeniCreateInitialFamilyResult.failure('indisponível')
        : ZeniCreateInitialFamilyResult.alreadyExists(
            summary: value,
            userId: 'test-user',
            membershipId: 'membership-test',
          );
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async => summary;

  @override
  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() {
    throw UnimplementedError();
  }
}

class _TestChildrenRepository implements RemoteChildrenRepository {
  const _TestChildrenRepository({required this.children});

  final List<RemoteChildSummary> children;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async => children;

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  }) {
    throw UnimplementedError();
  }
}

class _TestMissionsRepository implements RemoteMissionsRepository {
  const _TestMissionsRepository({required this.missions});

  final List<RemoteMissionSummary> missions;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async => missions;

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) {
    throw UnimplementedError();
  }
}

class _TestRewardsRepository implements RemoteRewardsRepository {
  const _TestRewardsRepository({required this.rewards});

  final List<RemoteRewardSummary> rewards;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async => rewards;

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) {
    throw UnimplementedError();
  }
}

class _TestMissionLogsRepository implements RemoteMissionLogsRepository {
  const _TestMissionLogsRepository({required this.logs});

  final List<RemoteMissionLogSummary> logs;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async => logs;

  @override
  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List<MissionLog> localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  }) {
    throw UnimplementedError();
  }
}

class _TestRewardRequestsRepository implements RemoteRewardRequestsRepository {
  const _TestRewardRequestsRepository({required this.requests});

  final List<RemoteRewardRequestSummary> requests;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  }) async => requests;

  @override
  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List<RewardRequest> localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  }) {
    throw UnimplementedError();
  }
}

class _TestStarLedgerRepository implements RemoteStarLedgerRepository {
  const _TestStarLedgerRepository({required this.entries});

  final List<RemoteStarLedgerEntrySummary> entries;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  }) async => entries;

  @override
  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List<StarLedgerEntry> localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) {
    throw UnimplementedError();
  }
}

class _TestChildBalanceRepository implements RemoteChildBalanceRepository {
  const _TestChildBalanceRepository({required this.balances});

  final List<RemoteChildStarBalance> balances;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  }) async => balances;
}
