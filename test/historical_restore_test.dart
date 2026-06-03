import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
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
import 'package:zeni/features/sync/data/mappers/remote_historical_restore_mapper.dart';
import 'package:zeni/features/sync/data/models/historical_restore_result.dart';
import 'package:zeni/features/sync/presentation/providers/historical_restore_providers.dart';
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
    ZeniAuthUser? initialUser,
    RemoteFamilySummary? remoteFamily,
    List<RemoteChildSummary> remoteChildren = const <RemoteChildSummary>[],
    List<RemoteMissionSummary> remoteMissions = const <RemoteMissionSummary>[],
    List<RemoteRewardSummary> remoteRewards = const <RemoteRewardSummary>[],
    List<RemoteMissionLogSummary> remoteMissionLogs =
        const <RemoteMissionLogSummary>[],
    List<RemoteRewardRequestSummary> remoteRewardRequests =
        const <RemoteRewardRequestSummary>[],
    List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries =
        const <RemoteStarLedgerEntrySummary>[],
    List<RemoteChildStarBalance> remoteChildBalances =
        const <RemoteChildStarBalance>[],
    bool throwRemoteChildrenRead = false,
  }) {
    final authRepository = _TestAuthRepository(initialUser: initialUser);
    final childrenRepository = _FakeRemoteChildrenRepository(
      children: remoteChildren,
      throwOnRead: throwRemoteChildrenRead,
    );
    final missionsRepository = _FakeRemoteMissionsRepository(
      missions: remoteMissions,
    );
    final rewardsRepository = _FakeRemoteRewardsRepository(
      rewards: remoteRewards,
    );
    final missionLogsRepository = _FakeRemoteMissionLogsRepository(
      missionLogs: remoteMissionLogs,
    );
    final rewardRequestsRepository = _FakeRemoteRewardRequestsRepository(
      requests: remoteRewardRequests,
    );
    final starLedgerRepository = _FakeRemoteStarLedgerRepository(
      entries: remoteStarLedgerEntries,
    );
    final childBalanceRepository = _FakeRemoteChildBalanceRepository(
      balances: remoteChildBalances,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        remoteFamilySummaryProvider.overrideWith((ref) async => remoteFamily),
        remoteChildrenRepositoryProvider.overrideWithValue(childrenRepository),
        remoteMissionsRepositoryProvider.overrideWithValue(missionsRepository),
        remoteRewardsRepositoryProvider.overrideWithValue(rewardsRepository),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          missionLogsRepository,
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          rewardRequestsRepository,
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          starLedgerRepository,
        ),
        remoteChildBalanceRepositoryProvider.overrideWithValue(
          childBalanceRepository,
        ),
      ],
    );

    addTearDown(() async {
      await authRepository.dispose();
      container.dispose();
    });

    return container;
  }

  group('historical restore controller guards', () {
    test('1. does not restore without Supabase', () async {
      seedAppState(_buildLocalCatalogState());
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.supabaseUnavailable);
    });

    test('2. does not restore without login', () async {
      await enableSupabaseForTests();
      seedAppState(_buildLocalCatalogState());
      final container = buildContainer(remoteFamily: _remoteFamily);

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.unauthenticated);
    });

    test('3. does not restore without remote family', () async {
      await enableSupabaseForTests();
      seedAppState(_buildLocalCatalogState());
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: null,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.remoteFamilyMissing);
    });

    test('4. does not restore if main catalogs are not aligned', () async {
      await enableSupabaseForTests();
      seedAppState(_buildLocalCatalogState(missions: const [], rewards: const []));
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.catalogsNotAligned);
    });

    test('5. does not restore if local missionLogs already exist', () async {
      await enableSupabaseForTests();
      seedAppState(
        _buildLocalCatalogState(
          missionLogs: [
            MissionLog(
              id: 'mission-log-local-1',
              missionId: 'mission-local-1',
              childId: 'child-local-1',
              scheduledDate: DateTime(2026, 6, 1),
              status: MissionLogStatus.approved,
              starsAwarded: 10,
              approvedAt: DateTime(2026, 6, 1, 9),
            ),
          ],
        ),
      );
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.localActivityPresent);
    });

    test('6. does not restore if local rewardRequests already exist', () async {
      await enableSupabaseForTests();
      seedAppState(
        _buildLocalCatalogState(
          rewardRequests: [
            RewardRequest(
              id: 'reward-request-local-1',
              rewardId: 'reward-local-1',
              childId: 'child-local-1',
              status: RewardRequestStatus.approved,
              requestedAt: DateTime(2026, 6, 1, 10),
              resolvedAt: DateTime(2026, 6, 1, 11),
            ),
          ],
        ),
      );
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.localActivityPresent);
    });

    test('7. does not restore if local starLedgerEntries already exist', () async {
      await enableSupabaseForTests();
      seedAppState(
        _buildLocalCatalogState(
          starLedgerEntries: [
            StarLedgerEntry(
              id: 'ledger-local-1',
              familyId: 'local-family',
              childId: 'child-local-1',
              amount: 10,
              balanceAfter: 10,
              type: StarLedgerEntryType.earned,
              title: 'Missão local',
              createdAt: DateTime(2026, 6, 1, 9),
            ),
          ],
        ),
      );
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.localActivityPresent);
    });

    test('8. does not restore if any child already has starBalance greater than zero', () async {
      await enableSupabaseForTests();
      seedAppState(_buildLocalCatalogState(child1Balance: 3));
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();

      expect(result.status, HistoricalRestoreResultStatus.localActivityPresent);
    });

    test('22. remote failure does not break the app', () async {
      await enableSupabaseForTests();
      final localState = _buildLocalCatalogState();
      seedAppState(localState);
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
        remoteFamily: _remoteFamily,
        throwRemoteChildrenRead: true,
      );

      final result = await container
          .read(historicalRestoreControllerProvider)
          .restoreHistoryIfSafe();
      final stateAfter = await container.read(zeniAppStateControllerProvider.future);

      expect(result.status, HistoricalRestoreResultStatus.remoteReadFailure);
      expect(stateAfter.missionLogs, isEmpty);
      expect(stateAfter.rewardRequests, isEmpty);
      expect(stateAfter.starLedgerEntries, isEmpty);
      expect(stateAfter.children.map((child) => child.starBalance), [0, 0]);
      expect(stateAfter.children.map((child) => child.streakCount), [7, 4]);
      expect(stateAfter.children.length, localState.children.length);
    });
  });

  group('historical restore mapper guards', () {
    test('9. does not restore if remote child cannot be mapped to local child', () {
      final scenario = _buildSuccessfulRestoreScenario();
      final mapper = const RemoteHistoricalRestoreMapper();

      final result = mapper.map(
        localState: scenario.localState,
        remoteChildren: [
          const RemoteChildSummary(
            id: 'remote-child-1',
            familyId: 'family-remote-1',
            localId: 'missing-child-local-1',
            name: 'Luna',
            avatarKey: '🦊',
          ),
          scenario.remoteChildren[1],
        ],
        remoteMissions: scenario.remoteMissions,
        remoteRewards: scenario.remoteRewards,
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: scenario.remoteChildBalances,
      );

      expect(result.status, HistoricalRestoreResultStatus.catalogsNotAligned);
    });

    test('10. does not restore if remote mission cannot be mapped to local mission', () {
      final scenario = _buildSuccessfulRestoreScenario();
      final mapper = const RemoteHistoricalRestoreMapper();

      final result = mapper.map(
        localState: scenario.localState,
        remoteChildren: scenario.remoteChildren,
        remoteMissions: [
          const RemoteMissionSummary(
            id: 'remote-mission-1',
            familyId: 'family-remote-1',
            childId: 'remote-child-1',
            localId: 'missing-mission-local-1',
            title: 'Arrumar brinquedos',
            stars: 10,
            requiresApproval: false,
            recurrenceType: 'daily',
            recurrenceDays: <int>[],
            isActive: true,
          ),
          scenario.remoteMissions[1],
        ],
        remoteRewards: scenario.remoteRewards,
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: scenario.remoteChildBalances,
      );

      expect(result.status, HistoricalRestoreResultStatus.catalogsNotAligned);
    });

    test('11. does not restore if remote reward cannot be mapped to local reward', () {
      final scenario = _buildSuccessfulRestoreScenario();
      final mapper = const RemoteHistoricalRestoreMapper();

      final result = mapper.map(
        localState: scenario.localState,
        remoteChildren: scenario.remoteChildren,
        remoteMissions: scenario.remoteMissions,
        remoteRewards: [
          const RemoteRewardSummary(
            id: 'remote-reward-1',
            familyId: 'family-remote-1',
            childId: 'remote-child-1',
            localId: 'missing-reward-local-1',
            title: 'Filme em família',
            cost: 4,
            isActive: true,
          ),
          scenario.remoteRewards[1],
        ],
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: scenario.remoteChildBalances,
      );

      expect(result.status, HistoricalRestoreResultStatus.catalogsNotAligned);
    });

    test('12. does not restore if remote ledger diverges from child_star_balances', () {
      final scenario = _buildSuccessfulRestoreScenario();
      final mapper = const RemoteHistoricalRestoreMapper();

      final result = mapper.map(
        localState: scenario.localState,
        remoteChildren: scenario.remoteChildren,
        remoteMissions: scenario.remoteMissions,
        remoteRewards: scenario.remoteRewards,
        remoteMissionLogs: scenario.remoteMissionLogs,
        remoteRewardRequests: scenario.remoteRewardRequests,
        remoteStarLedgerEntries: scenario.remoteStarLedgerEntries,
        remoteChildBalances: [
          scenario.remoteChildBalances[0],
          const RemoteChildStarBalance(
            familyId: 'family-remote-1',
            childId: 'remote-child-2',
            childName: 'Theo',
            creditsTotal: 5,
            debitsTotal: 0,
            derivedBalance: 99,
            ledgerEventsCount: 1,
          ),
        ],
      );

      expect(result.status, HistoricalRestoreResultStatus.unsafeBalanceMismatch);
    });
  });

  group('historical restore success path', () {
    test('13. restores remote missionLogs correctly', () async {
      final run = await _runSuccessfulRestore();

      expect(run.result.isSuccess, isTrue);
      expect(run.result.restoredMissionLogsCount, 2);
      expect(run.state.missionLogs.map((log) => log.id), [
        'mission-log-local-1',
        'mission-log-local-2',
      ]);
      expect(run.state.missionLogs.map((log) => log.missionId), [
        'mission-local-1',
        'mission-local-2',
      ]);
    });

    test('14. restores remote rewardRequests correctly', () async {
      final run = await _runSuccessfulRestore();

      expect(run.result.isSuccess, isTrue);
      expect(run.result.restoredRewardRequestsCount, 1);
      expect(run.state.rewardRequests.single.id, 'reward-request-local-1');
      expect(run.state.rewardRequests.single.rewardId, 'reward-local-1');
      expect(run.state.rewardRequests.single.childId, 'child-local-1');
      expect(run.state.rewardRequests.single.status, RewardRequestStatus.approved);
    });

    test('15. restores remote starLedgerEntries correctly', () async {
      final run = await _runSuccessfulRestore();

      expect(run.result.isSuccess, isTrue);
      expect(run.result.restoredStarLedgerEntriesCount, 3);
      expect(run.state.starLedgerEntries.map((entry) => entry.id), [
        'mission-log-local-1',
        'mission-log-local-2',
        'reward-request-local-1',
      ]);
      expect(run.state.starLedgerEntries.map((entry) => entry.amount), [10, 5, -4]);
      expect(
        run.state.starLedgerEntries.map((entry) => entry.type),
        [
          StarLedgerEntryType.earned,
          StarLedgerEntryType.earned,
          StarLedgerEntryType.spent,
        ],
      );
    });

    test('16. rebuilds balanceAfter locally per child', () async {
      final run = await _runSuccessfulRestore();

      expect(
        run.state.starLedgerEntries.map((entry) => entry.balanceAfter),
        [10, 5, 6],
      );
      expect(run.state.starLedgerEntries[0].childId, 'child-local-1');
      expect(run.state.starLedgerEntries[1].childId, 'child-local-2');
      expect(run.state.starLedgerEntries[2].childId, 'child-local-1');
    });

    test('17. updates local starBalance from the restored ledger', () async {
      final run = await _runSuccessfulRestore();

      expect(run.state.children.map((child) => child.starBalance), [6, 5]);
    });

    test('18. does not alter streak', () async {
      final run = await _runSuccessfulRestore();

      expect(run.state.children.map((child) => child.streakCount), [7, 4]);
    });

    test('19. does not create extra children', () async {
      final run = await _runSuccessfulRestore();

      expect(run.state.children.length, 2);
      expect(run.state.children.map((child) => child.id), [
        'child-local-1',
        'child-local-2',
      ]);
    });

    test('20. does not create extra missions', () async {
      final run = await _runSuccessfulRestore();

      expect(run.state.missions.length, 2);
      expect(run.state.missions.map((mission) => mission.id), [
        'mission-local-1',
        'mission-local-2',
      ]);
    });

    test('21. does not create extra rewards', () async {
      final run = await _runSuccessfulRestore();

      expect(run.state.rewards.length, 2);
      expect(run.state.rewards.map((reward) => reward.id), [
        'reward-local-1',
        'reward-local-2',
      ]);
    });
  });

  group('historical restore apply safety', () {
    test('applyHistoricalRestoreIfSafe revalidates current state and avoids partial application', () async {
      final scenario = _buildSuccessfulRestoreScenario();
      seedAppState(
        _buildLocalCatalogState(
          missionLogs: [
            MissionLog(
              id: 'local-existing-log',
              missionId: 'mission-local-1',
              childId: 'child-local-1',
              scheduledDate: DateTime(2026, 6, 1),
              status: MissionLogStatus.approved,
              starsAwarded: 10,
            ),
          ],
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(zeniAppStateControllerProvider.future);

      final result = await container
          .read(zeniAppStateControllerProvider.notifier)
          .applyHistoricalRestoreIfSafe(scenario.mappedResult.payload!);
      final stateAfter = await container.read(zeniAppStateControllerProvider.future);

      expect(result.status, HistoricalRestoreResultStatus.applyBlocked);
      expect(stateAfter.missionLogs.length, 1);
      expect(stateAfter.missionLogs.single.id, 'local-existing-log');
      expect(stateAfter.rewardRequests, isEmpty);
      expect(stateAfter.starLedgerEntries, isEmpty);
      expect(stateAfter.children.map((child) => child.starBalance), [0, 0]);
    });
  });

  test('23. signOut does not erase restored history', () async {
    final run = await _runSuccessfulRestore();

    final signOutResult = await run.container
        .read(zeniAuthControllerProvider)
        .signOut();
    final stateAfter = await run.container.read(zeniAppStateControllerProvider.future);

    expect(signOutResult.isSuccess, isTrue);
    expect(stateAfter.missionLogs.length, 2);
    expect(stateAfter.rewardRequests.length, 1);
    expect(stateAfter.starLedgerEntries.length, 3);
    expect(stateAfter.children.map((child) => child.starBalance), [6, 5]);
  });
}

const RemoteFamilySummary _remoteFamily = RemoteFamilySummary(
  familyId: 'family-remote-1',
  familyName: 'Minha família',
  role: 'owner',
);

class _SuccessfulRestoreScenario {
  _SuccessfulRestoreScenario({
    required this.localState,
    required this.remoteChildren,
    required this.remoteMissions,
    required this.remoteRewards,
    required this.remoteMissionLogs,
    required this.remoteRewardRequests,
    required this.remoteStarLedgerEntries,
    required this.remoteChildBalances,
    required this.mappedResult,
  });

  final ZeniAppState localState;
  final List<RemoteChildSummary> remoteChildren;
  final List<RemoteMissionSummary> remoteMissions;
  final List<RemoteRewardSummary> remoteRewards;
  final List<RemoteMissionLogSummary> remoteMissionLogs;
  final List<RemoteRewardRequestSummary> remoteRewardRequests;
  final List<RemoteStarLedgerEntrySummary> remoteStarLedgerEntries;
  final List<RemoteChildStarBalance> remoteChildBalances;
  final HistoricalRestoreResult mappedResult;
}

class _SuccessfulRestoreRun {
  _SuccessfulRestoreRun({
    required this.container,
    required this.result,
    required this.state,
  });

  final ProviderContainer container;
  final HistoricalRestoreResult result;
  final ZeniAppState state;
}

Future<_SuccessfulRestoreRun> _runSuccessfulRestore() async {
  await ZeniSupabaseBootstrap.initialize(
    config: const ZeniSupabaseConfig(
      url: 'https://zeni.test.supabase.co',
      anonKey: 'anon-key',
    ),
    initializeOverride: ({required url, required anonKey}) async {},
  );
  final scenario = _buildSuccessfulRestoreScenario();
  SharedPreferences.setMockInitialValues({
    'zeni_app_state_v1': jsonEncode(scenario.localState.toJson()),
  });
  final authRepository = _TestAuthRepository(
    initialUser: const ZeniAuthUser(id: 'user-1', email: 'parent@zeni.app'),
  );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      remoteFamilySummaryProvider.overrideWith((ref) async => _remoteFamily),
      remoteChildrenRepositoryProvider.overrideWithValue(
        _FakeRemoteChildrenRepository(children: scenario.remoteChildren),
      ),
      remoteMissionsRepositoryProvider.overrideWithValue(
        _FakeRemoteMissionsRepository(missions: scenario.remoteMissions),
      ),
      remoteRewardsRepositoryProvider.overrideWithValue(
        _FakeRemoteRewardsRepository(rewards: scenario.remoteRewards),
      ),
      remoteMissionLogsRepositoryProvider.overrideWithValue(
        _FakeRemoteMissionLogsRepository(missionLogs: scenario.remoteMissionLogs),
      ),
      remoteRewardRequestsRepositoryProvider.overrideWithValue(
        _FakeRemoteRewardRequestsRepository(
          requests: scenario.remoteRewardRequests,
        ),
      ),
      remoteStarLedgerRepositoryProvider.overrideWithValue(
        _FakeRemoteStarLedgerRepository(entries: scenario.remoteStarLedgerEntries),
      ),
      remoteChildBalanceRepositoryProvider.overrideWithValue(
        _FakeRemoteChildBalanceRepository(balances: scenario.remoteChildBalances),
      ),
    ],
  );

  final result = await container
      .read(historicalRestoreControllerProvider)
      .restoreHistoryIfSafe();
  final state = await container.read(zeniAppStateControllerProvider.future);

  addTearDown(() async {
    await authRepository.dispose();
    container.dispose();
  });

  return _SuccessfulRestoreRun(container: container, result: result, state: state);
}

_SuccessfulRestoreScenario _buildSuccessfulRestoreScenario() {
  final localState = _buildLocalCatalogState();
  final remoteChildren = const [
    RemoteChildSummary(
      id: 'remote-child-1',
      familyId: 'family-remote-1',
      localId: 'child-local-1',
      name: 'Luna',
      avatarKey: '🦊',
    ),
    RemoteChildSummary(
      id: 'remote-child-2',
      familyId: 'family-remote-1',
      localId: 'child-local-2',
      name: 'Theo',
      avatarKey: '🐼',
    ),
  ];
  final remoteMissions = const [
    RemoteMissionSummary(
      id: 'remote-mission-1',
      familyId: 'family-remote-1',
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
      familyId: 'family-remote-1',
      childId: 'remote-child-2',
      localId: 'mission-local-2',
      title: 'Ler por 15 minutos',
      stars: 5,
      requiresApproval: false,
      recurrenceType: 'daily',
      recurrenceDays: <int>[],
      isActive: true,
    ),
  ];
  final remoteRewards = const [
    RemoteRewardSummary(
      id: 'remote-reward-1',
      familyId: 'family-remote-1',
      childId: 'remote-child-1',
      localId: 'reward-local-1',
      title: 'Filme em família',
      cost: 4,
      isActive: true,
    ),
    RemoteRewardSummary(
      id: 'remote-reward-2',
      familyId: 'family-remote-1',
      childId: 'remote-child-2',
      localId: 'reward-local-2',
      title: 'Escolher sobremesa',
      cost: 6,
      isActive: true,
    ),
  ];
  final remoteMissionLogs = [
    RemoteMissionLogSummary(
      id: 'remote-mission-log-1',
      familyId: 'family-remote-1',
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
      familyId: 'family-remote-1',
      childId: 'remote-child-2',
      missionId: 'remote-mission-2',
      localId: 'mission-log-local-2',
      status: 'approved',
      starsAwarded: 5,
      scheduledDate: DateTime(2026, 6, 1),
      completedAt: DateTime(2026, 6, 1, 9, 30),
      approvedAt: DateTime(2026, 6, 1, 9, 45),
    ),
  ];
  final remoteRewardRequests = [
    RemoteRewardRequestSummary(
      id: 'remote-reward-request-1',
      familyId: 'family-remote-1',
      childId: 'remote-child-1',
      rewardId: 'remote-reward-1',
      localId: 'reward-request-local-1',
      status: 'approved',
      starsSpent: 4,
      requestedAt: DateTime(2026, 6, 1, 10),
      approvedAt: DateTime(2026, 6, 1, 10, 30),
      note: 'Tudo certo',
    ),
  ];
  final remoteStarLedgerEntries = [
    RemoteStarLedgerEntrySummary(
      id: 'remote-ledger-1',
      familyId: 'family-remote-1',
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
      familyId: 'family-remote-1',
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
      familyId: 'family-remote-1',
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
  ];
  final remoteChildBalances = const [
    RemoteChildStarBalance(
      familyId: 'family-remote-1',
      childId: 'remote-child-1',
      childName: 'Luna',
      creditsTotal: 10,
      debitsTotal: 4,
      derivedBalance: 6,
      ledgerEventsCount: 2,
    ),
    RemoteChildStarBalance(
      familyId: 'family-remote-1',
      childId: 'remote-child-2',
      childName: 'Theo',
      creditsTotal: 5,
      debitsTotal: 0,
      derivedBalance: 5,
      ledgerEventsCount: 1,
    ),
  ];
  final mappedResult = const RemoteHistoricalRestoreMapper().map(
    localState: localState,
    remoteChildren: remoteChildren,
    remoteMissions: remoteMissions,
    remoteRewards: remoteRewards,
    remoteMissionLogs: remoteMissionLogs,
    remoteRewardRequests: remoteRewardRequests,
    remoteStarLedgerEntries: remoteStarLedgerEntries,
    remoteChildBalances: remoteChildBalances,
    restoredAt: DateTime(2026, 6, 2, 12),
  );

  return _SuccessfulRestoreScenario(
    localState: localState,
    remoteChildren: remoteChildren,
    remoteMissions: remoteMissions,
    remoteRewards: remoteRewards,
    remoteMissionLogs: remoteMissionLogs,
    remoteRewardRequests: remoteRewardRequests,
    remoteStarLedgerEntries: remoteStarLedgerEntries,
    remoteChildBalances: remoteChildBalances,
    mappedResult: mappedResult,
  );
}

ZeniAppState _buildLocalCatalogState({
  List<Mission>? missions,
  List<Reward>? rewards,
  List<MissionLog> missionLogs = const [],
  List<RewardRequest> rewardRequests = const [],
  List<StarLedgerEntry> starLedgerEntries = const [],
  int child1Balance = 0,
  int child2Balance = 0,
}) {
  final initial = ZeniAppState.initial();
  final createdAt = DateTime(2026, 5, 20);

  return initial.copyWith(
    children: [
      ChildProfile(
        id: 'child-local-1',
        familyId: 'local-family',
        name: 'Luna',
        emoji: '🦊',
        starBalance: child1Balance,
        streakCount: 7,
        createdAt: createdAt,
      ),
      ChildProfile(
        id: 'child-local-2',
        familyId: 'local-family',
        name: 'Theo',
        emoji: '🐼',
        starBalance: child2Balance,
        streakCount: 4,
        createdAt: createdAt,
      ),
    ],
    missions: missions ??
        [
          Mission(
            id: 'mission-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            title: 'Arrumar brinquedos',
            description: 'Guardar tudo',
            stars: 10,
            recurrence: MissionRecurrence.daily,
            timeGroup: MissionTimeGroup.anytime,
            approvalMode: MissionApprovalMode.automatic,
            status: MissionStatus.active,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
          Mission(
            id: 'mission-local-2',
            familyId: 'local-family',
            childId: 'child-local-2',
            title: 'Ler por 15 minutos',
            description: 'Ler junto com a família',
            stars: 5,
            recurrence: MissionRecurrence.daily,
            timeGroup: MissionTimeGroup.anytime,
            approvalMode: MissionApprovalMode.automatic,
            status: MissionStatus.active,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ],
    rewards: rewards ??
        [
          Reward(
            id: 'reward-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            title: 'Filme em família',
            description: 'Escolher o filme da noite',
            cost: 4,
            renewal: RewardRenewal.always,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
          Reward(
            id: 'reward-local-2',
            familyId: 'local-family',
            childId: 'child-local-2',
            title: 'Escolher sobremesa',
            description: 'Vale sobremesa especial',
            cost: 6,
            renewal: RewardRenewal.always,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ],
    missionLogs: missionLogs,
    rewardRequests: rewardRequests,
    starLedgerEntries: starLedgerEntries,
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
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    _currentUser = const ZeniAuthUser(
      id: 'google-user',
      email: 'google@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    _currentUser = const ZeniAuthUser(
      id: 'apple-user',
      email: 'apple@zeni.app',
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
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = ZeniAuthUser(id: 'signed-up', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  Future<void> dispose() => _controller.close();
}

class _FakeRemoteChildrenRepository implements RemoteChildrenRepository {
  const _FakeRemoteChildrenRepository({
    required this.children,
    this.throwOnRead = false,
  });

  final List<RemoteChildSummary> children;
  final bool throwOnRead;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    if (throwOnRead) {
      throw Exception('boom');
    }
    return children;
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  }) async {
    return ZeniEnsureRemoteChildrenResult.success(children);
  }
}

class _FakeRemoteMissionsRepository implements RemoteMissionsRepository {
  const _FakeRemoteMissionsRepository({required this.missions});

  final List<RemoteMissionSummary> missions;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async {
    return missions;
  }

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteMissionsResult.success(missions);
  }
}

class _FakeRemoteRewardsRepository implements RemoteRewardsRepository {
  const _FakeRemoteRewardsRepository({required this.rewards});

  final List<RemoteRewardSummary> rewards;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async {
    return rewards;
  }

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    return ZeniEnsureRemoteRewardsResult.success(rewards);
  }
}

class _FakeRemoteMissionLogsRepository implements RemoteMissionLogsRepository {
  const _FakeRemoteMissionLogsRepository({required this.missionLogs});

  final List<RemoteMissionLogSummary> missionLogs;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async {
    return missionLogs;
  }

  @override
  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List<MissionLog> localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  }) async {
    return ZeniEnsureRemoteMissionLogsResult.success(missionLogs);
  }
}

class _FakeRemoteRewardRequestsRepository
    implements RemoteRewardRequestsRepository {
  const _FakeRemoteRewardRequestsRepository({required this.requests});

  final List<RemoteRewardRequestSummary> requests;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  }) async {
    return requests;
  }

  @override
  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List<RewardRequest> localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  }) async {
    return ZeniEnsureRemoteRewardRequestsResult.success(requests);
  }
}

class _FakeRemoteStarLedgerRepository implements RemoteStarLedgerRepository {
  const _FakeRemoteStarLedgerRepository({required this.entries});

  final List<RemoteStarLedgerEntrySummary> entries;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  }) async {
    return entries;
  }

  @override
  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List<StarLedgerEntry> localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) async {
    return ZeniEnsureRemoteStarLedgerResult.success(entries);
  }
}

class _FakeRemoteChildBalanceRepository
    implements RemoteChildBalanceRepository {
  const _FakeRemoteChildBalanceRepository({required this.balances});

  final List<RemoteChildStarBalance> balances;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  }) async {
    return balances;
  }
}
