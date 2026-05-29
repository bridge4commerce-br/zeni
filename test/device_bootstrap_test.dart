import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/family/data/repositories/remote_children_repository.dart';
import 'package:zeni/features/family/presentation/providers/remote_children_providers.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/repositories/remote_rewards_repository.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_rewards_providers.dart';
import 'package:zeni/features/sync/presentation/providers/device_bootstrap_providers.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/repositories/remote_missions_repository.dart';
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

  ProviderContainer buildContainer({
    ZeniAuthUser? initialUser,
    RemoteFamilySummary? remoteFamily,
    List<RemoteChildSummary> remoteChildren = const <RemoteChildSummary>[],
    List<RemoteMissionSummary> remoteMissions = const <RemoteMissionSummary>[],
    List<RemoteRewardSummary> remoteRewards = const <RemoteRewardSummary>[],
    bool throwChildrenRead = false,
  }) {
    final authRepository = _TestBootstrapAuthRepository(
      initialUser: initialUser,
    );
    final accountRepository = _TestBootstrapAccountRepository(
      summary: remoteFamily,
    );
    final childrenRepository = throwChildrenRead
        ? const _ThrowingRemoteChildrenRepository()
        : _TestBootstrapChildrenRepository(children: remoteChildren);
    final missionsRepository = _TestBootstrapMissionsRepository(
      missions: remoteMissions,
    );
    final rewardsRepository = _TestBootstrapRewardsRepository(
      rewards: remoteRewards,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        accountRepositoryProvider.overrideWithValue(accountRepository),
        remoteChildrenRepositoryProvider.overrideWithValue(childrenRepository),
        remoteMissionsRepositoryProvider.overrideWithValue(missionsRepository),
        remoteRewardsRepositoryProvider.overrideWithValue(rewardsRepository),
      ],
    );
    addTearDown(() async {
      await authRepository.dispose();
      container.dispose();
    });
    return container;
  }

  test('bootstrap does not run without Supabase available', () async {
    final container = buildContainer(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
    );

    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Restauração na nuvem indisponível neste build.');
  });

  test('bootstrap does not run without authenticated user', () async {
    await enableSupabaseForTests();
    final container = buildContainer();

    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      'Faça login para restaurar a família neste aparelho.',
    );
  });

  test('bootstrap does not run without remote family', () async {
    await enableSupabaseForTests();
    final container = buildContainer(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
      remoteFamily: null,
    );

    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Nenhuma família remota preparada foi encontrada.');
  });

  test('bootstrap does not overwrite existing local state', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
    });
    await enableSupabaseForTests();
    final container = buildContainer(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
      remoteFamily: const RemoteFamilySummary(
        familyId: 'remote-family',
        familyName: 'Família Remota',
        role: 'owner',
      ),
    );

    final before = await container.read(zeniAppStateControllerProvider.future);
    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();
    final after = container.read(zeniAppStateControllerProvider).asData!.value;

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Este aparelho já possui dados locais.');
    expect(after.children.length, before.children.length);
    expect(after.missions.length, before.missions.length);
    expect(after.rewards.length, before.rewards.length);
  });

  test(
    'bootstrap on empty state restores family children missions and rewards',
    () async {
      await enableSupabaseForTests();
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
        remoteFamily: const RemoteFamilySummary(
          familyId: 'remote-family',
          familyName: 'Família Remota',
          role: 'owner',
        ),
        remoteChildren: const [
          RemoteChildSummary(
            id: 'remote-child-1',
            familyId: 'remote-family',
            localId: 'local-child-1',
            name: 'Luna',
            avatarKey: '🦊',
          ),
        ],
        remoteMissions: const [
          RemoteMissionSummary(
            id: 'remote-mission-1',
            familyId: 'remote-family',
            childId: 'remote-child-1',
            localId: 'local-mission-1',
            title: 'Arrumar a cama',
            stars: 10,
            requiresApproval: true,
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
            localId: 'local-reward-1',
            title: 'Escolher o filme',
            cost: 40,
            imageKey: '🎬',
            isActive: true,
          ),
        ],
      );

      final result = await container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(result.isSuccess, isTrue);
      expect(result.restoredChildrenCount, 1);
      expect(result.restoredMissionsCount, 1);
      expect(result.restoredRewardsCount, 1);
      expect(state.family.id, 'remote-family');
      expect(state.family.name, 'Família Remota');
      expect(state.children, hasLength(1));
      expect(state.missions, hasLength(1));
      expect(state.rewards, hasLength(1));
      expect(state.children.single.id, 'local-child-1');
      expect(state.missions.single.id, 'local-mission-1');
      expect(state.rewards.single.id, 'local-reward-1');
    },
  );

  test(
    'bootstrap does not create extra onboarding child or import saldo and history',
    () async {
      await enableSupabaseForTests();
      final container = buildContainer(
        initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
        remoteFamily: const RemoteFamilySummary(
          familyId: 'remote-family',
          familyName: 'Família Remota',
          role: 'owner',
        ),
        remoteChildren: const [
          RemoteChildSummary(
            id: 'remote-child-1',
            familyId: 'remote-family',
            localId: null,
            name: 'Theo',
            avatarKey: '🐼',
          ),
        ],
      );

      final result = await container
          .read(deviceBootstrapControllerProvider)
          .bootstrapFromRemoteFamily();
      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(result.isSuccess, isTrue);
      expect(state.children, hasLength(1));
      expect(state.children.single.name, 'Theo');
      expect(state.children.single.starBalance, 0);
      expect(state.children.single.streakCount, 0);
      expect(state.starLedgerEntries, isEmpty);
      expect(state.missionLogs, isEmpty);
      expect(state.rewardRequests, isEmpty);
    },
  );

  test('bootstrap failure on remote read does not break the app', () async {
    await enableSupabaseForTests();
    final container = buildContainer(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
      remoteFamily: const RemoteFamilySummary(
        familyId: 'remote-family',
        familyName: 'Família Remota',
        role: 'owner',
      ),
      throwChildrenRead: true,
    );

    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();
    final state = container.read(zeniAppStateControllerProvider).asData!.value;

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Não foi possível restaurar a família agora.');
    expect(state.children, isEmpty);
    expect(state.missions, isEmpty);
    expect(state.rewards, isEmpty);
  });

  test('successful bootstrap marks onboarding as completed', () async {
    await enableSupabaseForTests();
    final container = buildContainer(
      initialUser: const ZeniAuthUser(id: 'user-1', email: 'a@b.com'),
      remoteFamily: const RemoteFamilySummary(
        familyId: 'remote-family',
        familyName: 'Família Remota',
        role: 'owner',
      ),
    );

    final result = await container
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();
    final state = container.read(zeniAppStateControllerProvider).asData!.value;

    expect(result.isSuccess, isTrue);
    expect(state.appSettings.hasCompletedOnboarding, isTrue);
  });
}

class _TestBootstrapAuthRepository implements ZeniAuthRepository {
  _TestBootstrapAuthRepository({ZeniAuthUser? initialUser})
    : _currentUser = initialUser;

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

  Future<void> dispose() => _controller.close();
}

class _TestBootstrapAccountRepository implements ZeniAccountRepository {
  const _TestBootstrapAccountRepository({required this.summary});

  final RemoteFamilySummary? summary;

  @override
  bool get isConfigured => true;

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async => summary;

  @override
  Future<ZeniEnsureRemoteFamilyResult>
  ensureRemoteFamilyForCurrentUser() async {
    if (summary == null) {
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Nenhuma família remota preparada foi encontrada.',
      );
    }

    return ZeniEnsureRemoteFamilyResult.success(summary!);
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  }) async {
    if (summary == null) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Nenhuma família remota preparada foi encontrada.',
      );
    }

    return ZeniUpdateRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: familyId,
        familyName: name,
        role: summary!.role,
        email: summary!.email,
      ),
    );
  }
}

class _TestBootstrapChildrenRepository implements RemoteChildrenRepository {
  const _TestBootstrapChildrenRepository({required this.children});

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
  }) async => ZeniEnsureRemoteChildrenResult.success(children);
}

class _ThrowingRemoteChildrenRepository implements RemoteChildrenRepository {
  const _ThrowingRemoteChildrenRepository();

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) {
    throw Exception('boom');
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  }) {
    throw UnimplementedError();
  }
}

class _TestBootstrapMissionsRepository implements RemoteMissionsRepository {
  const _TestBootstrapMissionsRepository({required this.missions});

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
  }) async => ZeniEnsureRemoteMissionsResult.success(missions);
}

class _TestBootstrapRewardsRepository implements RemoteRewardsRepository {
  const _TestBootstrapRewardsRepository({required this.rewards});

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
  }) async => ZeniEnsureRemoteRewardsResult.success(rewards);
}
