import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/balance/data/models/star_ledger_entry.dart';
import 'package:zeni/features/balance/data/repositories/remote_child_balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/supabase_remote_child_balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/remote_star_ledger_repository.dart';
import 'package:zeni/features/balance/data/repositories/supabase_remote_star_ledger_repository.dart';
import 'package:zeni/features/balance/presentation/providers/remote_child_balance_providers.dart';
import 'package:zeni/features/balance/presentation/providers/remote_star_ledger_providers.dart';
import 'package:zeni/features/auth/data/repositories/apple_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/google_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/family/data/models/family.dart';
import 'package:zeni/features/family/data/models/family_member.dart';
import 'package:zeni/features/family/data/repositories/family_repository.dart';
import 'package:zeni/features/family/data/repositories/remote_children_repository.dart';
import 'package:zeni/features/family/data/repositories/supabase_remote_children_repository.dart';
import 'package:zeni/features/family/presentation/providers/remote_children_providers.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/rewards/data/repositories/remote_reward_requests_repository.dart';
import 'package:zeni/features/rewards/data/repositories/remote_rewards_repository.dart';
import 'package:zeni/features/rewards/data/repositories/supabase_remote_reward_requests_repository.dart';
import 'package:zeni/features/rewards/data/repositories/supabase_remote_rewards_repository.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_reward_requests_providers.dart';
import 'package:zeni/features/rewards/presentation/providers/remote_rewards_providers.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_consistency_providers.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';
import 'package:zeni/features/tasks/data/repositories/remote_mission_logs_repository.dart';
import 'package:zeni/features/tasks/data/repositories/supabase_remote_mission_logs_repository.dart';
import 'package:zeni/features/tasks/data/repositories/remote_missions_repository.dart';
import 'package:zeni/features/tasks/data/repositories/supabase_remote_missions_repository.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_mission_logs_providers.dart';
import 'package:zeni/features/tasks/presentation/providers/remote_missions_providers.dart';
import 'package:zeni/core/providers/zeni_repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZeniSupabaseBootstrap.resetForTests();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ZeniSupabaseBootstrap.resetForTests();
  });

  test('supabase bootstrap skips initialization when env is missing', () async {
    final state = await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(url: '', anonKey: ''),
    );

    expect(state.isConfigured, isFalse);
    expect(state.isInitialized, isFalse);
    expect(ZeniSupabaseBootstrap.client, isNull);
  });

  test('auth repository handles missing supabase without crash', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(authRepositoryProvider);

    expect(repository.currentUser, isNull);
    expect(await repository.authStateChanges().first, isNull);
  });

  test(
    'auth state provider resolves unauthenticated when supabase is absent',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        authStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await container.pump();
      final state = subscription.read();

      expect(state.status, ZeniAuthStatus.unauthenticated);
      expect(state.user, isNull);
    },
  );

  test('sign out is a safe no-op without session', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(zeniAuthControllerProvider).signOut();

    expect(result.isSuccess, isTrue);
  });

  test('auth state provider reacts to sign in and sign out', () async {
    final repository = _TestAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    final states = <ZeniAuthStatus>[];
    final subscription = container.listen(authStateProvider, (_, next) {
      states.add(next.status);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await container.pump();
    expect(subscription.read().status, ZeniAuthStatus.unauthenticated);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    await container.pump();

    expect(subscription.read().status, ZeniAuthStatus.authenticated);
    expect(subscription.read().user?.email, 'responsavel@zeni.app');

    await container.read(zeniAuthControllerProvider).signOut();
    await container.pump();

    expect(subscription.read().status, ZeniAuthStatus.unauthenticated);
    expect(states, contains(ZeniAuthStatus.authenticated));
  });

  test('auth state provider reacts to Google sign in', () async {
    final repository = _TestAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    await container.pump();
    expect(
      container.read(authStateProvider).status,
      ZeniAuthStatus.unauthenticated,
    );

    final result = await container
        .read(zeniAuthControllerProvider)
        .signInWithGoogle();
    await container.pump();

    expect(result.isSuccess, isTrue);
    expect(
      container.read(authStateProvider).status,
      ZeniAuthStatus.authenticated,
    );
    expect(container.read(authStateProvider).user?.email, 'google@zeni.app');
  });

  test('auth state provider reacts to Apple sign in', () async {
    final repository = _TestAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    await container.pump();
    expect(
      container.read(authStateProvider).status,
      ZeniAuthStatus.unauthenticated,
    );

    final result = await container
        .read(zeniAuthControllerProvider)
        .signInWithApple();
    await container.pump();

    expect(result.isSuccess, isTrue);
    expect(
      container.read(authStateProvider).status,
      ZeniAuthStatus.authenticated,
    );
    expect(container.read(authStateProvider).user?.email, 'apple@zeni.app');
  });

  test('google without serverClientId returns controlled error', () async {
    final client = GoogleNativeSignInClient(
      config: const ZeniGoogleSignInConfig(
        serverClientId: '',
        clientId: 'ios-client-id',
      ),
      googleSignIn: GoogleSignIn.instance,
    );

    expect(
      client.signIn,
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.description,
          'description',
          'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
        ),
      ),
    );
  });

  test('google with null idToken returns controlled error', () async {
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: _FakeSupabaseAuthClient(),
      googleSignInClient: const _FakeGoogleSignInClient.failure(
        GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Não foi possível obter o ID token do Google.',
        ),
      ),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Não foi possível obter o ID token do Google.');
  });

  test('google sign in sends idToken and accessToken without nonce', () async {
    final authClient = _FakeSupabaseAuthClient();
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: authClient,
      googleSignInClient: const _FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
          email: 'google@zeni.app',
        ),
      ),
      appleSignInClient: const _FakeAppleSignInClient.success(
        ZeniAppleSignInResult(
          idToken: 'apple-id-token',
          rawNonce: 'apple-raw-nonce',
          email: 'apple@zeni.app',
        ),
      ),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isSuccess, isTrue);
    expect(authClient.lastProvider, OAuthProvider.google);
    expect(authClient.lastIdToken, 'google-id-token');
    expect(authClient.lastAccessToken, 'google-access-token');
    expect(authClient.lastNonce, isNull);
  });

  test('apple sign in keeps sending raw nonce', () async {
    final authClient = _FakeSupabaseAuthClient();
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: authClient,
      googleSignInClient: const _FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ),
      appleSignInClient: const _FakeAppleSignInClient.success(
        ZeniAppleSignInResult(
          idToken: 'apple-id-token',
          rawNonce: 'apple-raw-nonce',
          email: 'apple@zeni.app',
        ),
      ),
    );

    final result = await repository.signInWithApple();

    expect(result.isSuccess, isTrue);
    expect(authClient.lastProvider, OAuthProvider.apple);
    expect(authClient.lastIdToken, 'apple-id-token');
    expect(authClient.lastAccessToken, isNull);
    expect(authClient.lastNonce, 'apple-raw-nonce');
  });

  test('google nonce mismatch error becomes friendly inline failure', () async {
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: _FakeSupabaseAuthClient(
        signInWithIdTokenError: const AuthException(
          'passed nonce and nonce in id_token should either both exist or not',
        ),
      ),
      googleSignInClient: const _FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      'Não foi possível entrar com Google. Tente novamente ou use e-mail.',
    );
  });

  test('google supabase failure becomes controlled inline error', () async {
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: _FakeSupabaseAuthClient(
        signInWithIdTokenError: const AuthException('provider misconfigured'),
      ),
      googleSignInClient: const _FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(idToken: 'google-id-token', accessToken: null),
      ),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      'Não foi possível entrar com Google. Verifique a configuração ou tente e-mail/Apple.',
    );
  });

  test(
    'ensureRemoteFamilyForCurrentUser with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniAccountControllerProvider)
          .ensureRemoteFamilyForCurrentUser();

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Conta remota indisponível neste build.');
    },
  );

  test(
    'auth sign in does not ensure remote family when supabase is unavailable',
    () async {
      final accountRepository = _FakeAccountRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      expect(result.isSuccess, isTrue);
      expect(accountRepository.ensureCalls, 0);
    },
  );

  test(
    'remote family ensure failure is returned in a controlled way',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final accountRepository = _FakeAccountRepository(
        ensureResult: const ZeniEnsureRemoteFamilyResult.failure(
          'Não foi possível preparar a família remota agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniAuthControllerProvider)
          .signInWithGoogle();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível preparar a família remota agora.',
      );
      expect(accountRepository.ensureCalls, 1);
    },
  );

  test(
    'ensureRemoteChildrenForCurrentFamily with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          remoteChildrenRepositoryProvider.overrideWithValue(
            _FakeRemoteChildrenRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniRemoteChildrenControllerProvider)
          .ensureRemoteChildrenForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Crianças remotas indisponíveis neste build.');
    },
  );

  test(
    'user without remote family does not try to sync remote children',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteChildrenRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteChildrenRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteChildrenControllerProvider)
          .ensureRemoteChildrenForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Prepare a família remota antes de sincronizar as crianças.',
      );
      expect(repository.ensureCalls, 0);
    },
  );

  test(
    'remote children ensure failure is returned in a controlled way',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteChildrenRepository(
        ensureResult: const ZeniEnsureRemoteChildrenResult.failure(
          'Não foi possível preparar as crianças na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          familyRepositoryProvider.overrideWithValue(
            _FakeFamilyRepository(
              children: [
                ChildProfile(
                  id: 'child-local-1',
                  familyId: 'local-family',
                  name: 'Luna',
                  emoji: '🦊',
                  starBalance: 0,
                  streakCount: 0,
                  createdAt: DateTime(2026, 5, 28),
                ),
              ],
            ),
          ),
          remoteChildrenRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteChildrenControllerProvider)
          .ensureRemoteChildrenForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível preparar as crianças na nuvem agora.',
      );
      expect(repository.ensureCalls, 1);
    },
  );

  test(
    'user without remote family does not try to sync remote missions',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionsRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteMissionsControllerProvider)
          .ensureRemoteMissionsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Prepare a família remota antes de sincronizar as missões.',
      );
      expect(repository.ensureCalls, 0);
    },
  );

  test(
    'user without remote children gets controlled mission sync failure',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionsRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const <RemoteChildSummary>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteMissionsControllerProvider)
          .ensureRemoteMissionsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Prepare as crianças na nuvem antes de sincronizar as missões.',
      );
      expect(repository.ensureCalls, 0);
    },
  );

  test(
    'ensureRemoteMissionsForCurrentFamily with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          remoteMissionsRepositoryProvider.overrideWithValue(
            _FakeRemoteMissionsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniRemoteMissionsControllerProvider)
          .ensureRemoteMissionsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Missões remotas indisponíveis neste build.');
    },
  );

  test(
    'ensureRemoteRewardsForCurrentFamily with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          remoteRewardsRepositoryProvider.overrideWithValue(
            _FakeRemoteRewardsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniRemoteRewardsControllerProvider)
          .ensureRemoteRewardsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Mimos remotos indisponíveis neste build.');
    },
  );

  test('without remote family rewards sync is not attempted', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteRewardsRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteRewardsRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );

    final result = await container
        .read(zeniRemoteRewardsControllerProvider)
        .ensureRemoteRewardsForCurrentFamily();

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      'Prepare a família remota antes de sincronizar os mimos.',
    );
    expect(repository.ensureCalls, 0);
  });

  test('updating remote family name without auth fails safely', () async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(zeniAccountControllerProvider)
        .updateRemoteFamilyName(familyId: 'family-1', name: 'Família da Luna');

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Conta remota indisponível neste build.');
  });

  test('empty remote family name shows controlled failure', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final accountRepository = _FakeAccountRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(accountRepository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );

    final result = await container
        .read(zeniAccountControllerProvider)
        .updateRemoteFamilyName(familyId: 'family-1', name: '   ');

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Digite um nome para a família.');
    expect(accountRepository.updateCalls, 0);
  });

  test(
    'remote family name update failure is returned in a controlled way',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final accountRepository = _FakeAccountRepository(
        updateResult: const ZeniUpdateRemoteFamilyResult.failure(
          'Não foi possível atualizar a família remota agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniAccountControllerProvider)
          .updateRemoteFamilyName(
            familyId: 'family-1',
            name: 'Família da Luna',
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível atualizar a família remota agora.',
      );
      expect(accountRepository.updateCalls, 1);
    },
  );

  test(
    'local child generates remote payload with family_id and local_id',
    () async {
      final store = _FakeChildrenTableClient();
      final repository = SupabaseRemoteChildrenRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final child = ChildProfile(
        id: 'child-local-1',
        familyId: 'local-family',
        name: 'Luna',
        emoji: '🦊',
        starBalance: 0,
        streakCount: 0,
        createdAt: DateTime(2026, 5, 28),
      );

      final result = await repository.ensureRemoteChildren(
        familyId: 'remote-family-1',
        localChildren: [child],
      );

      expect(result.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.insertedPayloads.single['family_id'], 'remote-family-1');
      expect(store.insertedPayloads.single['local_id'], 'child-local-1');
      expect(store.insertedPayloads.single['name'], 'Luna');
      expect(store.insertedPayloads.single['avatar_key'], '🦊');
    },
  );

  test('repeated ensureRemoteChildren does not duplicate child', () async {
    final store = _FakeChildrenTableClient();
    final repository = SupabaseRemoteChildrenRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final child = ChildProfile(
      id: 'child-local-1',
      familyId: 'local-family',
      name: 'Luna',
      emoji: '🦊',
      starBalance: 0,
      streakCount: 0,
      createdAt: DateTime(2026, 5, 28),
    );

    final first = await repository.ensureRemoteChildren(
      familyId: 'remote-family-1',
      localChildren: [child],
    );
    final second = await repository.ensureRemoteChildren(
      familyId: 'remote-family-1',
      localChildren: [child],
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(store.insertedPayloads, hasLength(1));
    expect(store.updatedPayloads, hasLength(1));
    expect(store.rows, hasLength(1));
  });

  test(
    'local mission generates remote payload with family_id, child_id and local_id',
    () async {
      final store = _FakeMissionsTableClient();
      final repository = SupabaseRemoteMissionsRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final mission = Mission(
        id: 'mission-local-1',
        familyId: 'local-family',
        childId: 'child-local-1',
        title: 'Arrumar brinquedos',
        description: 'Guardar tudo',
        stars: 12,
        recurrence: MissionRecurrence.customDaysOfWeek,
        customDaysOfWeek: const [DateTime.monday, DateTime.wednesday],
        timeGroup: MissionTimeGroup.anytime,
        approvalMode: MissionApprovalMode.parentApproval,
        status: MissionStatus.active,
        createdAt: DateTime(2026, 5, 28),
        updatedAt: DateTime(2026, 5, 28),
      );

      final result = await repository.ensureRemoteMissions(
        familyId: 'remote-family-1',
        localMissions: [mission],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      );

      expect(result.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.insertedPayloads.single['family_id'], 'remote-family-1');
      expect(store.insertedPayloads.single['child_id'], 'remote-child-1');
      expect(store.insertedPayloads.single['local_id'], 'mission-local-1');
      expect(store.insertedPayloads.single['requires_approval'], isTrue);
      expect(
        store.insertedPayloads.single['recurrence_type'],
        'customDaysOfWeek',
      );
      expect(store.insertedPayloads.single['recurrence_days'], [
        DateTime.monday,
        DateTime.wednesday,
      ]);
    },
  );

  test('repeated ensureRemoteMissions does not duplicate mission', () async {
    final store = _FakeMissionsTableClient();
    final repository = SupabaseRemoteMissionsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final mission = Mission(
      id: 'mission-local-1',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Arrumar brinquedos',
      description: 'Guardar tudo',
      stars: 12,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.anytime,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final first = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );
    final second = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(store.insertedPayloads, hasLength(1));
    expect(store.updatedPayloads, hasLength(1));
    expect(store.rows, hasLength(1));
  });

  test(
    'local reward generates remote payload with family_id child_id and local_id',
    () async {
      final store = _FakeRewardsTableClient();
      final repository = SupabaseRemoteRewardsRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final reward = Reward(
        id: 'reward-local-1',
        familyId: 'local-family',
        childId: 'child-local-1',
        title: 'Escolher filme',
        description: 'Vale uma sessão em família',
        cost: 40,
        renewal: RewardRenewal.always,
        createdAt: DateTime(2026, 5, 28),
        updatedAt: DateTime(2026, 5, 28),
      );

      final result = await repository.ensureRemoteRewards(
        familyId: 'remote-family-1',
        localRewards: [reward],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      );

      expect(result.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.insertedPayloads.single['family_id'], 'remote-family-1');
      expect(store.insertedPayloads.single['child_id'], 'remote-child-1');
      expect(store.insertedPayloads.single['local_id'], 'reward-local-1');
      expect(store.insertedPayloads.single['cost'], 40);
    },
  );

  test('repeated ensureRemoteRewards does not duplicate reward', () async {
    final store = _FakeRewardsTableClient();
    final repository = SupabaseRemoteRewardsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final reward = Reward(
      id: 'reward-local-1',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Escolher filme',
      description: 'Vale uma sessão em família',
      cost: 40,
      renewal: RewardRenewal.always,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final first = await repository.ensureRemoteRewards(
      familyId: 'remote-family-1',
      localRewards: [reward],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );
    final second = await repository.ensureRemoteRewards(
      familyId: 'remote-family-1',
      localRewards: [reward.copyWith(description: 'Atualizado')],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(store.insertedPayloads, hasLength(1));
    expect(store.updatedPayloads, hasLength(1));
    expect(store.rows, hasLength(1));
  });

  test('family scoped reward keeps remote child_id null', () async {
    final store = _FakeRewardsTableClient();
    final repository = SupabaseRemoteRewardsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final reward = Reward(
      id: 'reward-local-1',
      familyId: 'local-family',
      title: 'Piquenique em família',
      description: 'Sem vínculo com perfil específico',
      cost: 50,
      renewal: RewardRenewal.always,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final result = await repository.ensureRemoteRewards(
      familyId: 'remote-family-1',
      localRewards: [reward],
      remoteChildIdByLocalChildId: const {},
    );

    expect(result.isSuccess, isTrue);
    expect(store.insertedPayloads.single['child_id'], isNull);
  });

  test(
    'local reward request generates remote payload with family_id child_id reward_id and local_id',
    () async {
      final store = _FakeRewardRequestsTableClient();
      final repository = SupabaseRemoteRewardRequestsRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final request = RewardRequest(
        id: 'request-local-1',
        rewardId: 'reward-local-1',
        childId: 'child-local-1',
        status: RewardRequestStatus.pending,
        requestedAt: DateTime(2026, 5, 28, 16, 20),
        note: 'Quero para hoje',
      );

      final result = await repository.ensureRemoteRewardRequests(
        familyId: 'remote-family-1',
        localRewardRequests: [request],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
        remoteRewardByLocalRewardId: const {
          'reward-local-1': (remoteRewardId: 'remote-reward-1', cost: 40),
        },
      );

      expect(result.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.insertedPayloads.single['family_id'], 'remote-family-1');
      expect(store.insertedPayloads.single['child_id'], 'remote-child-1');
      expect(store.insertedPayloads.single['reward_id'], 'remote-reward-1');
      expect(store.insertedPayloads.single['local_id'], 'request-local-1');
      expect(store.insertedPayloads.single['status'], 'pending');
      expect(store.insertedPayloads.single['stars_spent'], 40);
    },
  );

  test(
    'repeated ensureRemoteRewardRequests does not duplicate request',
    () async {
      final store = _FakeRewardRequestsTableClient();
      final repository = SupabaseRemoteRewardRequestsRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final request = RewardRequest(
        id: 'request-local-1',
        rewardId: 'reward-local-1',
        childId: 'child-local-1',
        status: RewardRequestStatus.approved,
        requestedAt: DateTime(2026, 5, 28, 16, 20),
        resolvedAt: DateTime(2026, 5, 28, 18, 00),
      );

      final first = await repository.ensureRemoteRewardRequests(
        familyId: 'remote-family-1',
        localRewardRequests: [request],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
        remoteRewardByLocalRewardId: const {
          'reward-local-1': (remoteRewardId: 'remote-reward-1', cost: 40),
        },
      );
      final second = await repository.ensureRemoteRewardRequests(
        familyId: 'remote-family-1',
        localRewardRequests: [request.copyWith(note: 'Atualizado')],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
        remoteRewardByLocalRewardId: const {
          'reward-local-1': (remoteRewardId: 'remote-reward-1', cost: 40),
        },
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.updatedPayloads, hasLength(1));
      expect(store.rows, hasLength(1));
    },
  );

  test(
    'local mission log generates remote payload with family_id child_id mission_id and local_id',
    () async {
      final store = _FakeMissionLogsTableClient();
      final repository = SupabaseRemoteMissionLogsRepository(
        client: null,
        tableClient: store,
        currentUserIdOverride: 'user-1',
      );
      final log = MissionLog(
        id: 'log-local-1',
        missionId: 'mission-local-1',
        childId: 'child-local-1',
        scheduledDate: DateTime(2026, 5, 28),
        status: MissionLogStatus.awaitingApproval,
        starsAwarded: 12,
        completedAt: DateTime(2026, 5, 28, 9, 30),
        note: 'Feito com capricho',
      );

      final result = await repository.ensureRemoteMissionLogs(
        familyId: 'remote-family-1',
        localMissionLogs: [log],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
        remoteMissionIdByLocalMissionId: const {
          'mission-local-1': 'remote-mission-1',
        },
      );

      expect(result.isSuccess, isTrue);
      expect(store.insertedPayloads, hasLength(1));
      expect(store.insertedPayloads.single['family_id'], 'remote-family-1');
      expect(store.insertedPayloads.single['child_id'], 'remote-child-1');
      expect(store.insertedPayloads.single['mission_id'], 'remote-mission-1');
      expect(store.insertedPayloads.single['local_id'], 'log-local-1');
      expect(store.insertedPayloads.single['status'], 'awaitingApproval');
      expect(store.insertedPayloads.single['stars_awarded'], 12);
    },
  );

  test('repeated ensureRemoteMissionLogs does not duplicate log', () async {
    final store = _FakeMissionLogsTableClient();
    final repository = SupabaseRemoteMissionLogsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final log = MissionLog(
      id: 'log-local-1',
      missionId: 'mission-local-1',
      childId: 'child-local-1',
      scheduledDate: DateTime(2026, 5, 28),
      status: MissionLogStatus.approved,
      starsAwarded: 10,
      completedAt: DateTime(2026, 5, 28, 9, 30),
      approvedAt: DateTime(2026, 5, 28, 10, 0),
    );

    final first = await repository.ensureRemoteMissionLogs(
      familyId: 'remote-family-1',
      localMissionLogs: [log],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionIdByLocalMissionId: const {
        'mission-local-1': 'remote-mission-1',
      },
    );
    final second = await repository.ensureRemoteMissionLogs(
      familyId: 'remote-family-1',
      localMissionLogs: [log.copyWith(note: 'Atualizado')],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionIdByLocalMissionId: const {
        'mission-local-1': 'remote-mission-1',
      },
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(store.insertedPayloads, hasLength(1));
    expect(store.updatedPayloads, hasLength(1));
    expect(store.rows, hasLength(1));
  });

  test('daily mission recurrence maps correctly', () async {
    final store = _FakeMissionsTableClient();
    final repository = SupabaseRemoteMissionsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final mission = Mission(
      id: 'mission-daily',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Escovar os dentes',
      description: 'Depois do cafe',
      stars: 5,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final result = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(result.isSuccess, isTrue);
    expect(store.insertedPayloads.single['recurrence_type'], 'daily');
    expect(store.insertedPayloads.single['recurrence_days'], isNull);
  });

  test('weekdays mission recurrence maps correctly', () async {
    final store = _FakeMissionsTableClient();
    final repository = SupabaseRemoteMissionsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final mission = Mission(
      id: 'mission-weekdays',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Ler 10 minutos',
      description: 'Antes da escola',
      stars: 5,
      recurrence: MissionRecurrence.weekdays,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final result = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(result.isSuccess, isTrue);
    expect(store.insertedPayloads.single['recurrence_type'], 'weekdays');
    expect(store.insertedPayloads.single['recurrence_days'], isNull);
  });

  test('weekends mission recurrence maps correctly', () async {
    final store = _FakeMissionsTableClient();
    final repository = SupabaseRemoteMissionsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final mission = Mission(
      id: 'mission-weekends',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Ajudar no cafe',
      description: 'Somente fins de semana',
      stars: 7,
      recurrence: MissionRecurrence.weekends,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final result = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(result.isSuccess, isTrue);
    expect(store.insertedPayloads.single['recurrence_type'], 'weekends');
    expect(store.insertedPayloads.single['recurrence_days'], isNull);
  });

  test('once mission recurrence maps correctly', () async {
    final store = _FakeMissionsTableClient();
    final repository = SupabaseRemoteMissionsRepository(
      client: null,
      tableClient: store,
      currentUserIdOverride: 'user-1',
    );
    final mission = Mission(
      id: 'mission-once',
      familyId: 'local-family',
      childId: 'child-local-1',
      title: 'Levar bilhete',
      description: 'Somente hoje',
      stars: 3,
      recurrence: MissionRecurrence.once,
      timeGroup: MissionTimeGroup.anytime,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 28),
      updatedAt: DateTime(2026, 5, 28),
    );

    final result = await repository.ensureRemoteMissions(
      familyId: 'remote-family-1',
      localMissions: [mission],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
    );

    expect(result.isSuccess, isTrue);
    expect(store.insertedPayloads.single['recurrence_type'], 'once');
    expect(store.insertedPayloads.single['recurrence_days'], isNull);
  });

  test(
    'remote missions ensure failure is returned in a controlled way',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionsRepository(
        ensureResult: const ZeniEnsureRemoteMissionsResult.failure(
          'Não foi possível preparar as missões na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          familyRepositoryProvider.overrideWithValue(
            _FakeFamilyRepository(
              children: [
                ChildProfile(
                  id: 'child-local-1',
                  familyId: 'local-family',
                  name: 'Luna',
                  emoji: '🦊',
                  starBalance: 0,
                  streakCount: 0,
                  createdAt: DateTime(2026, 5, 28),
                ),
              ],
            ),
          ),
          remoteMissionsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteMissionsControllerProvider)
          .ensureRemoteMissionsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível preparar as missões na nuvem agora.',
      );
      expect(repository.ensureCalls, 1);
    },
  );

  test('successful remote children sync updates lastChildrenSyncAt', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteChildrenRepository(
      ensureResult:
          const ZeniEnsureRemoteChildrenResult.success(<RemoteChildSummary>[
            RemoteChildSummary(
              id: 'remote-child-1',
              familyId: 'family-1',
              localId: 'child-local-1',
              name: 'Luna',
              avatarKey: '🦊',
            ),
          ]),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        familyRepositoryProvider.overrideWithValue(
          _FakeFamilyRepository(
            children: [
              ChildProfile(
                id: 'child-local-1',
                familyId: 'local-family',
                name: 'Luna',
                emoji: '🦊',
                starBalance: 0,
                streakCount: 0,
                createdAt: DateTime(2026, 5, 28),
              ),
            ],
          ),
        ),
        remoteChildrenRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniRemoteChildrenControllerProvider)
        .ensureRemoteChildrenForCurrentFamily();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isTrue);
    expect(appState.appSettings.lastChildrenSyncAt, isNotNull);
  });

  test(
    'failed remote children sync keeps previous lastChildrenSyncAt',
    () async {
      final previousSyncAt = DateTime(2026, 5, 28, 14, 32);
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                appSettings: AppSettings(lastChildrenSyncAt: previousSyncAt),
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteChildrenRepository(
        ensureResult: const ZeniEnsureRemoteChildrenResult.failure(
          'Não foi possível preparar as crianças na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          familyRepositoryProvider.overrideWithValue(
            _FakeFamilyRepository(
              children: [
                ChildProfile(
                  id: 'child-local-1',
                  familyId: 'local-family',
                  name: 'Luna',
                  emoji: '🦊',
                  starBalance: 0,
                  streakCount: 0,
                  createdAt: DateTime(2026, 5, 28),
                ),
              ],
            ),
          ),
          remoteChildrenRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteChildrenControllerProvider)
          .ensureRemoteChildrenForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(appState.appSettings.lastChildrenSyncAt, previousSyncAt);
    },
  );

  test('successful remote missions sync updates lastMissionsSyncAt', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              missions: [
                Mission(
                  id: 'mission-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Arrumar brinquedos',
                  description: 'Guardar tudo',
                  stars: 12,
                  recurrence: MissionRecurrence.daily,
                  timeGroup: MissionTimeGroup.anytime,
                  approvalMode: MissionApprovalMode.automatic,
                  status: MissionStatus.active,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteMissionsRepository(
      ensureResult:
          const ZeniEnsureRemoteMissionsResult.success(<RemoteMissionSummary>[
            RemoteMissionSummary(
              id: 'remote-mission-1',
              familyId: 'family-1',
              childId: 'remote-child-1',
              localId: 'mission-local-1',
              title: 'Arrumar brinquedos',
              stars: 12,
              requiresApproval: false,
              recurrenceType: 'daily',
              recurrenceDays: <int>[],
              isActive: true,
            ),
          ]),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteMissionsRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
        remoteChildrenProvider.overrideWith(
          (ref) async => const [
            RemoteChildSummary(
              id: 'remote-child-1',
              familyId: 'family-1',
              localId: 'child-local-1',
              name: 'Luna',
              avatarKey: '🦊',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniRemoteMissionsControllerProvider)
        .ensureRemoteMissionsForCurrentFamily();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isTrue);
    expect(appState.appSettings.lastMissionsSyncAt, isNotNull);
  });

  test(
    'failed remote missions sync keeps previous lastMissionsSyncAt',
    () async {
      final previousSyncAt = DateTime(2026, 5, 28, 15, 45);
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                missions: [
                  Mission(
                    id: 'mission-local-1',
                    familyId: 'local-family',
                    childId: 'child-local-1',
                    title: 'Arrumar brinquedos',
                    description: 'Guardar tudo',
                    stars: 12,
                    recurrence: MissionRecurrence.daily,
                    timeGroup: MissionTimeGroup.anytime,
                    approvalMode: MissionApprovalMode.automatic,
                    status: MissionStatus.active,
                    createdAt: DateTime(2026, 5, 28),
                    updatedAt: DateTime(2026, 5, 28),
                  ),
                ],
                appSettings: AppSettings(lastMissionsSyncAt: previousSyncAt),
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionsRepository(
        ensureResult: const ZeniEnsureRemoteMissionsResult.failure(
          'Não foi possível preparar as missões na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteMissionsControllerProvider)
          .ensureRemoteMissionsForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(appState.appSettings.lastMissionsSyncAt, previousSyncAt);
    },
  );

  test('successful remote rewards sync updates lastRewardsSyncAt', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              rewards: [
                Reward(
                  id: 'reward-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Escolher filme',
                  description: 'Vale uma sessão em família',
                  cost: 40,
                  renewal: RewardRenewal.always,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteRewardsRepository(
      ensureResult: const ZeniEnsureRemoteRewardsResult.success(
        <RemoteRewardSummary>[],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteRewardsRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
        remoteChildrenProvider.overrideWith(
          (ref) async => const [
            RemoteChildSummary(
              id: 'remote-child-1',
              familyId: 'family-1',
              localId: 'child-local-1',
              name: 'Luna',
              avatarKey: '🦊',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniRemoteRewardsControllerProvider)
        .ensureRemoteRewardsForCurrentFamily();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isTrue);
    expect(appState.appSettings.lastRewardsSyncAt, isNotNull);
  });

  test('failed remote rewards sync keeps previous lastRewardsSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 15, 55);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              rewards: [
                Reward(
                  id: 'reward-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Escolher filme',
                  description: 'Vale uma sessão em família',
                  cost: 40,
                  renewal: RewardRenewal.always,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
              appSettings: AppSettings(lastRewardsSyncAt: previousSyncAt),
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteRewardsRepository(
      ensureResult: const ZeniEnsureRemoteRewardsResult.failure(
        'Não foi possível preparar os mimos na nuvem agora.',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteRewardsRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
        remoteChildrenProvider.overrideWith(
          (ref) async => const [
            RemoteChildSummary(
              id: 'remote-child-1',
              familyId: 'family-1',
              localId: 'child-local-1',
              name: 'Luna',
              avatarKey: '🦊',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniRemoteRewardsControllerProvider)
        .ensureRemoteRewardsForCurrentFamily();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastRewardsSyncAt, previousSyncAt);
  });

  test(
    'ensureRemoteMissionLogsForCurrentFamily with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          remoteMissionLogsRepositoryProvider.overrideWithValue(
            _FakeRemoteMissionLogsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniRemoteMissionLogsControllerProvider)
          .ensureRemoteMissionLogsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Logs remotos de missão indisponíveis neste build.',
      );
    },
  );

  test(
    'user without remote children or missions gets controlled mission logs sync failure',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionLogsRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionLogsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const <RemoteChildSummary>[],
          ),
          remoteMissionsProvider.overrideWith(
            (ref) async => const <RemoteMissionSummary>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final result = await container
          .read(zeniRemoteMissionLogsControllerProvider)
          .ensureRemoteMissionLogsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Sincronize os dados principais primeiro para preparar as conclusões.',
      );
      expect(repository.ensureCalls, 0);
    },
  );

  test(
    'successful remote mission logs sync updates lastMissionLogsSyncAt',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                missionLogs: [
                  MissionLog(
                    id: 'log-local-1',
                    missionId: 'mission-local-1',
                    childId: 'child-local-1',
                    scheduledDate: DateTime(2026, 5, 28),
                    status: MissionLogStatus.awaitingApproval,
                    starsAwarded: 12,
                    completedAt: DateTime(2026, 5, 28, 9, 30),
                    note: 'Feito com capricho',
                  ),
                ],
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionLogsRepository(
        ensureResult: const ZeniEnsureRemoteMissionLogsResult.success(
          <RemoteMissionLogSummary>[],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionLogsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteMissionsProvider.overrideWith(
            (ref) async => const [
              RemoteMissionSummary(
                id: 'remote-mission-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'mission-local-1',
                title: 'Arrumar brinquedos',
                stars: 12,
                requiresApproval: true,
                recurrenceType: 'daily',
                recurrenceDays: <int>[],
                isActive: true,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteMissionLogsControllerProvider)
          .ensureRemoteMissionLogsForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isTrue);
      expect(appState.appSettings.lastMissionLogsSyncAt, isNotNull);
    },
  );

  test(
    'failed remote mission logs sync keeps previous lastMissionLogsSyncAt',
    () async {
      final previousSyncAt = DateTime(2026, 5, 28, 16, 5);
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                missionLogs: [
                  MissionLog(
                    id: 'log-local-1',
                    missionId: 'mission-local-1',
                    childId: 'child-local-1',
                    scheduledDate: DateTime(2026, 5, 28),
                    status: MissionLogStatus.approved,
                    starsAwarded: 12,
                    completedAt: DateTime(2026, 5, 28, 9, 30),
                    approvedAt: DateTime(2026, 5, 28, 10, 0),
                  ),
                ],
                appSettings: AppSettings(lastMissionLogsSyncAt: previousSyncAt),
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteMissionLogsRepository(
        ensureResult: const ZeniEnsureRemoteMissionLogsResult.failure(
          'Não foi possível preparar as conclusões na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteMissionLogsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteMissionsProvider.overrideWith(
            (ref) async => const [
              RemoteMissionSummary(
                id: 'remote-mission-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'mission-local-1',
                title: 'Arrumar brinquedos',
                stars: 12,
                requiresApproval: true,
                recurrenceType: 'daily',
                recurrenceDays: <int>[],
                isActive: true,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteMissionLogsControllerProvider)
          .ensureRemoteMissionLogsForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(appState.appSettings.lastMissionLogsSyncAt, previousSyncAt);
    },
  );

  test(
    'ensureRemoteRewardRequestsForCurrentFamily with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          remoteRewardRequestsRepositoryProvider.overrideWithValue(
            _FakeRemoteRewardRequestsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(zeniRemoteRewardRequestsControllerProvider)
          .ensureRemoteRewardRequestsForCurrentFamily();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Pedidos remotos de mimos indisponíveis neste build.',
      );
    },
  );

  test('without remote family reward requests sync is not attempted', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final repository = _FakeRemoteRewardRequestsRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(repository),
        remoteFamilySummaryProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );

    final result = await container
        .read(zeniRemoteRewardRequestsControllerProvider)
        .ensureRemoteRewardRequestsForCurrentFamily();

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      'Prepare a família remota antes de sincronizar os pedidos.',
    );
    expect(repository.ensureCalls, 0);
  });

  test(
    'successful remote reward requests sync updates lastRewardRequestsSyncAt',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                rewardRequests: [
                  RewardRequest(
                    id: 'request-local-1',
                    rewardId: 'reward-local-1',
                    childId: 'child-local-1',
                    status: RewardRequestStatus.pending,
                    requestedAt: DateTime(2026, 5, 28, 16, 20),
                  ),
                ],
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteRewardRequestsRepository(
        ensureResult: const ZeniEnsureRemoteRewardRequestsResult.success(
          <RemoteRewardRequestSummary>[],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteRewardRequestsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteRewardsProvider.overrideWith(
            (ref) async => const [
              RemoteRewardSummary(
                id: 'remote-reward-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'reward-local-1',
                title: 'Escolher filme',
                cost: 40,
                isActive: true,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteRewardRequestsControllerProvider)
          .ensureRemoteRewardRequestsForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isTrue);
      expect(appState.appSettings.lastRewardRequestsSyncAt, isNotNull);
    },
  );

  test(
    'failed remote reward requests sync keeps previous lastRewardRequestsSyncAt',
    () async {
      final previousSyncAt = DateTime(2026, 5, 28, 16, 15);
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                rewardRequests: [
                  RewardRequest(
                    id: 'request-local-1',
                    rewardId: 'reward-local-1',
                    childId: 'child-local-1',
                    status: RewardRequestStatus.rejected,
                    requestedAt: DateTime(2026, 5, 28, 16, 20),
                    resolvedAt: DateTime(2026, 5, 28, 18, 00),
                  ),
                ],
                appSettings: AppSettings(
                  lastRewardRequestsSyncAt: previousSyncAt,
                ),
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteRewardRequestsRepository(
        ensureResult: const ZeniEnsureRemoteRewardRequestsResult.failure(
          'Não foi possível preparar os pedidos na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteRewardRequestsRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteRewardsProvider.overrideWith(
            (ref) async => const [
              RemoteRewardSummary(
                id: 'remote-reward-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'reward-local-1',
                title: 'Escolher filme',
                cost: 40,
                isActive: true,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteRewardRequestsControllerProvider)
          .ensureRemoteRewardRequestsForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(appState.appSettings.lastRewardRequestsSyncAt, previousSyncAt);
    },
  );

  test(
    'remote child balance repository reads derived balance safely',
    () async {
      final tableClient = _FakeChildStarBalancesViewClient()
        ..rows.addAll([
          {
            'family_id': 'family-1',
            'child_id': 'remote-child-1',
            'child_name': 'Luna',
            'credits_total': 24,
            'debits_total': 12,
            'derived_balance': 12,
            'ledger_events_count': 4,
            'last_ledger_event_at': '2026-05-28T16:10:00.000Z',
          },
        ]);
      final repository = SupabaseRemoteChildBalanceRepository(
        client: null,
        viewClient: tableClient,
        currentUserIdOverride: 'user-1',
      );

      final balances = await repository.getRemoteChildStarBalances(
        familyId: 'family-1',
      );

      expect(balances, hasLength(1));
      expect(balances.single.childName, 'Luna');
      expect(balances.single.creditsTotal, 24);
      expect(balances.single.debitsTotal, 12);
      expect(balances.single.derivedBalance, 12);
      expect(balances.single.ledgerEventsCount, 4);
    },
  );

  test('remote child balance repository failure does not break app', () async {
    final repository = SupabaseRemoteChildBalanceRepository(
      client: null,
      viewClient: _ThrowingChildStarBalancesViewClient(),
      currentUserIdOverride: 'user-1',
    );

    final balances = await repository.getRemoteChildStarBalances(
      familyId: 'family-1',
    );

    expect(balances, isEmpty);
  });

  test(
    'user without login does not attempt remote child balance lookup',
    () async {
      final fakeRepository = _FakeRemoteChildBalanceRepository();
      final container = ProviderContainer(
        overrides: [
          remoteChildBalanceRepositoryProvider.overrideWithValue(
            fakeRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final balances = await container.read(remoteChildBalancesProvider.future);

      expect(balances, isNull);
      expect(fakeRepository.readCalls, 0);
    },
  );

  test('cloud consistency audit does not run without login', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final authRepository = _TestAuthRepository();
    final fakeRepository = _FakeRemoteChildBalanceRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        remoteChildBalanceRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    addTearDown(() async {
      await authRepository.dispose();
      container.dispose();
    });

    final diagnostic = await container.read(
      cloudConsistencyDiagnosticProvider.future,
    );

    expect(diagnostic, isNull);
    expect(fakeRepository.readCalls, 0);
  });

  test(
    'cloud consistency audit compares local and remote counts safely',
    () async {
      final localState = ZeniAppState.initial().copyWith(
        children: [
          ChildProfile(
            id: 'child-local-1',
            familyId: 'local-family',
            name: 'Luna',
            emoji: '🦊',
            starBalance: 12,
            streakCount: 0,
            createdAt: DateTime(2026, 5, 29, 10),
          ),
        ],
        missions: [
          Mission(
            id: 'mission-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            title: 'Arrumar brinquedos',
            description: 'Guardar tudo no lugar',
            stars: 12,
            recurrence: MissionRecurrence.daily,
            timeGroup: MissionTimeGroup.anytime,
            approvalMode: MissionApprovalMode.automatic,
            status: MissionStatus.active,
            createdAt: DateTime(2026, 5, 29, 10),
            updatedAt: DateTime(2026, 5, 29, 10),
          ),
        ],
        rewards: [
          Reward(
            id: 'reward-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            title: 'Escolher filme',
            description: 'Uma noite especial de cinema',
            cost: 20,
            renewal: RewardRenewal.always,
            isActive: true,
            createdAt: DateTime(2026, 5, 29, 10),
            updatedAt: DateTime(2026, 5, 29, 10),
          ),
        ],
        missionLogs: [
          MissionLog(
            id: 'mission-log-local-1',
            missionId: 'mission-local-1',
            childId: 'child-local-1',
            scheduledDate: DateTime(2026, 5, 29),
            starsAwarded: 12,
            status: MissionLogStatus.approved,
            completedAt: DateTime(2026, 5, 29, 10),
            approvedAt: DateTime(2026, 5, 29, 10, 5),
          ),
        ],
        rewardRequests: [
          RewardRequest(
            id: 'reward-request-local-1',
            childId: 'child-local-1',
            rewardId: 'reward-local-1',
            status: RewardRequestStatus.pending,
            requestedAt: DateTime(2026, 5, 29, 10),
          ),
        ],
        appSettings: const AppSettings(),
      );

      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(localState.toJson()),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );

      final authRepository = _TestAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteMissionsProvider.overrideWith(
            (ref) async => const [
              RemoteMissionSummary(
                id: 'remote-mission-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'mission-local-1',
                title: 'Arrumar brinquedos',
                stars: 12,
                recurrenceType: 'daily',
                recurrenceDays: [],
                requiresApproval: false,
                isActive: true,
              ),
            ],
          ),
          remoteRewardsProvider.overrideWith(
            (ref) async => const [
              RemoteRewardSummary(
                id: 'remote-reward-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'reward-local-1',
                title: 'Escolher filme',
                cost: 20,
                isActive: true,
              ),
            ],
          ),
          remoteMissionLogsProvider.overrideWith(
            (ref) async => [
              RemoteMissionLogSummary(
                id: 'remote-mission-log-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                missionId: 'remote-mission-1',
                localId: 'mission-log-local-1',
                status: 'approved',
                starsAwarded: 12,
                scheduledDate: DateTime(2026, 5, 29),
              ),
            ],
          ),
          remoteRewardRequestsProvider.overrideWith(
            (ref) async => [
              RemoteRewardRequestSummary(
                id: 'remote-reward-request-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                rewardId: 'remote-reward-1',
                localId: 'reward-request-local-1',
                status: 'pending',
                starsSpent: 20,
                requestedAt: DateTime(2026, 5, 29, 10),
              ),
            ],
          ),
          remoteChildBalancesProvider.overrideWith(
            (ref) async => const [
              RemoteChildStarBalance(
                familyId: 'family-1',
                childId: 'remote-child-1',
                childName: 'Luna',
                creditsTotal: 12,
                debitsTotal: 0,
                derivedBalance: 12,
                ledgerEventsCount: 1,
                lastLedgerEventAt: null,
              ),
            ],
          ),
        ],
      );
      addTearDown(() async {
        await authRepository.dispose();
        container.dispose();
      });

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );

      final diagnostic = await container.read(
        cloudConsistencyDiagnosticProvider.future,
      );

      expect(diagnostic, isNotNull);
      expect(diagnostic!.localChildrenCount, 1);
      expect(diagnostic.remoteChildrenCount, 1);
      expect(diagnostic.localMissionsCount, 1);
      expect(diagnostic.remoteMissionsCount, 1);
      expect(diagnostic.localRewardsCount, 1);
      expect(diagnostic.remoteRewardsCount, 1);
      expect(diagnostic.localMissionLogsCount, 1);
      expect(diagnostic.remoteMissionLogsCount, 1);
      expect(diagnostic.localRewardRequestsCount, 1);
      expect(diagnostic.remoteRewardRequestsCount, 1);
      expect(diagnostic.localStarBalance, 12);
      expect(diagnostic.remoteDerivedBalance, 12);
      expect(diagnostic.isAligned, isTrue);
    },
  );

  test(
    'mission credit generates correct star ledger idempotency key',
    () async {
      final tableClient = _FakeStarLedgerTableClient();
      final repository = SupabaseRemoteStarLedgerRepository(
        client: null,
        tableClient: tableClient,
        currentUserIdOverride: 'user-1',
      );

      final result = await repository.ensureRemoteStarLedger(
        familyId: 'family-1',
        localEntries: [
          StarLedgerEntry(
            id: 'ledger-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            amount: 12,
            balanceAfter: 42,
            type: StarLedgerEntryType.earned,
            title: 'Missão concluída',
            description: 'Arrumar brinquedos',
            createdAt: DateTime(2026, 5, 28, 10, 0),
            relatedMissionLogId: 'log-local-1',
          ),
        ],
        remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
        remoteMissionLogIdByLocalMissionLogId: const {
          'log-local-1': 'remote-log-1',
        },
        remoteRewardRequestIdByLocalRewardRequestId: const {},
      );

      expect(result.isSuccess, isTrue);
      expect(
        tableClient.insertedPayloads.single['idempotency_key'],
        'mission_log:log-local-1:earned',
      );
      expect(tableClient.insertedPayloads.single['direction'], 'credit');
      expect(tableClient.insertedPayloads.single['amount'], 12);
      expect(tableClient.insertedPayloads.single['source_type'], 'mission_log');
      expect(tableClient.insertedPayloads.single['source_id'], 'remote-log-1');
    },
  );

  test('reward debit generates correct star ledger idempotency key', () async {
    final tableClient = _FakeStarLedgerTableClient();
    final repository = SupabaseRemoteStarLedgerRepository(
      client: null,
      tableClient: tableClient,
      currentUserIdOverride: 'user-1',
    );

    final result = await repository.ensureRemoteStarLedger(
      familyId: 'family-1',
      localEntries: [
        StarLedgerEntry(
          id: 'ledger-local-2',
          familyId: 'local-family',
          childId: 'child-local-1',
          amount: -40,
          balanceAfter: 10,
          type: StarLedgerEntryType.spent,
          title: 'Pedido de mimo',
          description: 'Escolher filme',
          createdAt: DateTime(2026, 5, 28, 16, 20),
          relatedRewardRequestId: 'request-local-1',
        ),
      ],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionLogIdByLocalMissionLogId: const {},
      remoteRewardRequestIdByLocalRewardRequestId: const {
        'request-local-1': 'remote-request-1',
      },
    );

    expect(result.isSuccess, isTrue);
    expect(
      tableClient.insertedPayloads.single['idempotency_key'],
      'reward_request:request-local-1:spent',
    );
    expect(tableClient.insertedPayloads.single['direction'], 'debit');
    expect(tableClient.insertedPayloads.single['amount'], 40);
    expect(
      tableClient.insertedPayloads.single['source_type'],
      'reward_request',
    );
  });

  test('reward refund generates correct star ledger idempotency key', () async {
    final tableClient = _FakeStarLedgerTableClient();
    final repository = SupabaseRemoteStarLedgerRepository(
      client: null,
      tableClient: tableClient,
      currentUserIdOverride: 'user-1',
    );

    final result = await repository.ensureRemoteStarLedger(
      familyId: 'family-1',
      localEntries: [
        StarLedgerEntry(
          id: 'ledger-local-3',
          familyId: 'local-family',
          childId: 'child-local-1',
          amount: 40,
          balanceAfter: 50,
          type: StarLedgerEntryType.refunded,
          title: 'Estorno de mimo',
          description: 'Pedido rejeitado',
          createdAt: DateTime(2026, 5, 28, 18, 0),
          relatedRewardRequestId: 'request-local-1',
        ),
      ],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionLogIdByLocalMissionLogId: const {},
      remoteRewardRequestIdByLocalRewardRequestId: const {
        'request-local-1': 'remote-request-1',
      },
    );

    expect(result.isSuccess, isTrue);
    expect(
      tableClient.insertedPayloads.single['idempotency_key'],
      'reward_request:request-local-1:refunded',
    );
    expect(tableClient.insertedPayloads.single['direction'], 'credit');
    expect(tableClient.insertedPayloads.single['amount'], 40);
  });

  test('repeated star ledger sync does not duplicate remote entries', () async {
    final tableClient = _FakeStarLedgerTableClient();
    final repository = SupabaseRemoteStarLedgerRepository(
      client: null,
      tableClient: tableClient,
      currentUserIdOverride: 'user-1',
    );
    final localEntry = StarLedgerEntry(
      id: 'ledger-local-1',
      familyId: 'local-family',
      childId: 'child-local-1',
      amount: 12,
      balanceAfter: 42,
      type: StarLedgerEntryType.earned,
      title: 'Missão concluída',
      createdAt: DateTime(2026, 5, 28, 10, 0),
      relatedMissionLogId: 'log-local-1',
    );

    final first = await repository.ensureRemoteStarLedger(
      familyId: 'family-1',
      localEntries: [localEntry],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionLogIdByLocalMissionLogId: const {
        'log-local-1': 'remote-log-1',
      },
      remoteRewardRequestIdByLocalRewardRequestId: const {},
    );
    final second = await repository.ensureRemoteStarLedger(
      familyId: 'family-1',
      localEntries: [localEntry],
      remoteChildIdByLocalChildId: const {'child-local-1': 'remote-child-1'},
      remoteMissionLogIdByLocalMissionLogId: const {
        'log-local-1': 'remote-log-1',
      },
      remoteRewardRequestIdByLocalRewardRequestId: const {},
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(tableClient.rows, hasLength(1));
    expect(tableClient.insertedPayloads, hasLength(1));
    expect(tableClient.updatedPayloads, hasLength(1));
  });

  test(
    'successful remote star ledger sync updates lastStarLedgerSyncAt without altering local balance',
    () async {
      final initialState = ZeniAppState.initial().copyWith(
        children: [
          ChildProfile(
            id: 'child-local-1',
            familyId: 'local-family',
            name: 'Luna',
            emoji: '🦊',
            birthDate: DateTime(2020, 1, 1),
            starBalance: 42,
            streakCount: 0,
            createdAt: DateTime(2026, 5, 28),
          ),
        ],
        starLedgerEntries: [
          StarLedgerEntry(
            id: 'ledger-local-1',
            familyId: 'local-family',
            childId: 'child-local-1',
            amount: 12,
            balanceAfter: 42,
            type: StarLedgerEntryType.earned,
            title: 'Missão concluída',
            createdAt: DateTime(2026, 5, 28, 10, 0),
            relatedMissionLogId: 'log-local-1',
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(initialState.toJson()),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteStarLedgerRepository(
        ensureResult: const ZeniEnsureRemoteStarLedgerResult.success(
          <RemoteStarLedgerEntrySummary>[],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteStarLedgerRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteMissionLogsProvider.overrideWith(
            (ref) async => [
              RemoteMissionLogSummary(
                id: 'remote-log-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                missionId: 'remote-mission-1',
                localId: 'log-local-1',
                status: 'approved',
                starsAwarded: 12,
                scheduledDate: DateTime(2026, 5, 28),
              ),
            ],
          ),
          remoteRewardRequestsProvider.overrideWith(
            (ref) async => const <RemoteRewardRequestSummary>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteStarLedgerControllerProvider)
          .ensureRemoteStarLedgerForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isTrue);
      expect(appState.appSettings.lastStarLedgerSyncAt, isNotNull);
      expect(appState.children.single.starBalance, 42);
    },
  );

  test(
    'failed remote star ledger sync keeps previous lastStarLedgerSyncAt',
    () async {
      final previousSyncAt = DateTime(2026, 5, 28, 16, 20);
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                starLedgerEntries: [
                  StarLedgerEntry(
                    id: 'ledger-local-1',
                    familyId: 'local-family',
                    childId: 'child-local-1',
                    amount: 12,
                    balanceAfter: 42,
                    type: StarLedgerEntryType.earned,
                    title: 'Missão concluída',
                    createdAt: DateTime(2026, 5, 28, 10, 0),
                    relatedMissionLogId: 'log-local-1',
                  ),
                ],
                appSettings: AppSettings(lastStarLedgerSyncAt: previousSyncAt),
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final repository = _FakeRemoteStarLedgerRepository(
        ensureResult: const ZeniEnsureRemoteStarLedgerResult.failure(
          'Não foi possível preparar o histórico de estrelas na nuvem agora.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteStarLedgerRepositoryProvider.overrideWithValue(repository),
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
          remoteChildrenProvider.overrideWith(
            (ref) async => const [
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ],
          ),
          remoteMissionLogsProvider.overrideWith(
            (ref) async => [
              RemoteMissionLogSummary(
                id: 'remote-log-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                missionId: 'remote-mission-1',
                localId: 'log-local-1',
                status: 'approved',
                starsAwarded: 12,
                scheduledDate: DateTime(2026, 5, 28),
              ),
            ],
          ),
          remoteRewardRequestsProvider.overrideWith(
            (ref) async => const <RemoteRewardRequestSummary>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniRemoteStarLedgerControllerProvider)
          .ensureRemoteStarLedgerForCurrentFamily();
      final appState = await container.read(
        zeniAppStateControllerProvider.future,
      );

      expect(result.isSuccess, isFalse);
      expect(appState.appSettings.lastStarLedgerSyncAt, previousSyncAt);
    },
  );

  test(
    'cloud sync runs children before missions, rewards, mission logs, reward requests and star ledger',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(
          ZeniAppState.initial()
              .copyWith(
                missions: [
                  Mission(
                    id: 'mission-local-1',
                    familyId: 'local-family',
                    childId: 'child-local-1',
                    title: 'Arrumar brinquedos',
                    description: 'Guardar tudo',
                    stars: 12,
                    recurrence: MissionRecurrence.daily,
                    timeGroup: MissionTimeGroup.anytime,
                    approvalMode: MissionApprovalMode.automatic,
                    status: MissionStatus.active,
                    createdAt: DateTime(2026, 5, 28),
                    updatedAt: DateTime(2026, 5, 28),
                  ),
                ],
              )
              .toJson(),
        ),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final callOrder = <String>[];
      final childrenRepository = _FakeRemoteChildrenRepository(
        onEnsure: () => callOrder.add('children'),
        ensureResult:
            const ZeniEnsureRemoteChildrenResult.success(<RemoteChildSummary>[
              RemoteChildSummary(
                id: 'remote-child-1',
                familyId: 'family-1',
                localId: 'child-local-1',
                name: 'Luna',
                avatarKey: '🦊',
              ),
            ]),
      );
      final missionsRepository = _FakeRemoteMissionsRepository(
        onEnsure: () => callOrder.add('missions'),
        ensureResult:
            const ZeniEnsureRemoteMissionsResult.success(<RemoteMissionSummary>[
              RemoteMissionSummary(
                id: 'remote-mission-1',
                familyId: 'family-1',
                childId: 'remote-child-1',
                localId: 'mission-local-1',
                title: 'Arrumar brinquedos',
                stars: 12,
                requiresApproval: false,
                recurrenceType: 'daily',
                recurrenceDays: <int>[],
                isActive: true,
              ),
            ]),
      );
      final rewardsRepository = _FakeRemoteRewardsRepository(
        onEnsure: () => callOrder.add('rewards'),
        ensureResult: const ZeniEnsureRemoteRewardsResult.success(
          <RemoteRewardSummary>[],
        ),
      );
      final missionLogsRepository = _FakeRemoteMissionLogsRepository(
        onEnsure: () => callOrder.add('missionLogs'),
        ensureResult: const ZeniEnsureRemoteMissionLogsResult.success(
          <RemoteMissionLogSummary>[],
        ),
      );
      final rewardRequestsRepository = _FakeRemoteRewardRequestsRepository(
        onEnsure: () => callOrder.add('rewardRequests'),
        ensureResult: const ZeniEnsureRemoteRewardRequestsResult.success(
          <RemoteRewardRequestSummary>[],
        ),
      );
      final starLedgerRepository = _FakeRemoteStarLedgerRepository(
        onEnsure: () => callOrder.add('starLedger'),
        ensureResult: const ZeniEnsureRemoteStarLedgerResult.success(
          <RemoteStarLedgerEntrySummary>[],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          remoteChildrenRepositoryProvider.overrideWithValue(
            childrenRepository,
          ),
          remoteMissionsRepositoryProvider.overrideWithValue(
            missionsRepository,
          ),
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
          remoteFamilySummaryProvider.overrideWith(
            (ref) async => const RemoteFamilySummary(
              familyId: 'family-1',
              familyName: 'Minha família',
              role: 'owner',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      final result = await container
          .read(zeniCloudSyncControllerProvider)
          .syncCloudDataNow();

      expect(result.isSuccess, isTrue);
      expect(callOrder, [
        'children',
        'missions',
        'rewards',
        'missionLogs',
        'rewardRequests',
        'starLedger',
      ]);
    },
  );

  test('cloud sync stops before missions when children fail', () async {
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final callOrder = <String>[];
    final childrenRepository = _FakeRemoteChildrenRepository(
      onEnsure: () => callOrder.add('children'),
      ensureResult: const ZeniEnsureRemoteChildrenResult.failure(
        'Não foi possível preparar as crianças na nuvem agora.',
      ),
    );
    final missionsRepository = _FakeRemoteMissionsRepository(
      onEnsure: () => callOrder.add('missions'),
    );
    final rewardsRepository = _FakeRemoteRewardsRepository(
      onEnsure: () => callOrder.add('rewards'),
    );
    final missionLogsRepository = _FakeRemoteMissionLogsRepository(
      onEnsure: () => callOrder.add('missionLogs'),
    );
    final rewardRequestsRepository = _FakeRemoteRewardRequestsRepository(
      onEnsure: () => callOrder.add('rewardRequests'),
    );
    final starLedgerRepository = _FakeRemoteStarLedgerRepository(
      onEnsure: () => callOrder.add('starLedger'),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
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
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();

    expect(result.isSuccess, isFalse);
    expect(callOrder, ['children']);
    expect(missionsRepository.ensureCalls, 0);
    expect(rewardsRepository.ensureCalls, 0);
    expect(missionLogsRepository.ensureCalls, 0);
    expect(rewardRequestsRepository.ensureCalls, 0);
    expect(starLedgerRepository.ensureCalls, 0);
  });

  test('failed cloud sync keeps previous lastFullSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 16, 10);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              appSettings: AppSettings(lastFullSyncAt: previousSyncAt),
              missions: [
                Mission(
                  id: 'mission-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Arrumar brinquedos',
                  description: 'Guardar tudo',
                  stars: 12,
                  recurrence: MissionRecurrence.daily,
                  timeGroup: MissionTimeGroup.anytime,
                  approvalMode: MissionApprovalMode.automatic,
                  status: MissionStatus.active,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.failure(
              'Não foi possível preparar as missões na nuvem agora.',
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardRequestsRepository(),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastFullSyncAt, previousSyncAt);
  });

  test('successful cloud sync updates lastFullSyncAt', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              missions: [
                Mission(
                  id: 'mission-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Arrumar brinquedos',
                  description: 'Guardar tudo',
                  stars: 12,
                  recurrence: MissionRecurrence.daily,
                  timeGroup: MissionTimeGroup.anytime,
                  approvalMode: MissionApprovalMode.automatic,
                  status: MissionStatus.active,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.success(
              <RemoteMissionSummary>[
                RemoteMissionSummary(
                  id: 'remote-mission-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'mission-local-1',
                  title: 'Arrumar brinquedos',
                  stars: 12,
                  requiresApproval: false,
                  recurrenceType: 'daily',
                  recurrenceDays: <int>[],
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(
            ensureResult: const ZeniEnsureRemoteRewardsResult.success(
              <RemoteRewardSummary>[],
            ),
          ),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(
            ensureResult: const ZeniEnsureRemoteMissionLogsResult.success(
              <RemoteMissionLogSummary>[],
            ),
          ),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardRequestsRepository(
            ensureResult: const ZeniEnsureRemoteRewardRequestsResult.success(
              <RemoteRewardRequestSummary>[],
            ),
          ),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(
            ensureResult: const ZeniEnsureRemoteStarLedgerResult.success(
              <RemoteStarLedgerEntrySummary>[],
            ),
          ),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isTrue);
    expect(appState.appSettings.lastFullSyncAt, isNotNull);
  });

  test('failed rewards sync keeps previous lastFullSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 16, 10);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              appSettings: AppSettings(lastFullSyncAt: previousSyncAt),
              rewards: [
                Reward(
                  id: 'reward-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Escolher filme',
                  description: 'Vale uma sessão em família',
                  cost: 40,
                  renewal: RewardRenewal.always,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
              missions: [
                Mission(
                  id: 'mission-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  title: 'Arrumar brinquedos',
                  description: 'Guardar tudo',
                  stars: 12,
                  recurrence: MissionRecurrence.daily,
                  timeGroup: MissionTimeGroup.anytime,
                  approvalMode: MissionApprovalMode.automatic,
                  status: MissionStatus.active,
                  createdAt: DateTime(2026, 5, 28),
                  updatedAt: DateTime(2026, 5, 28),
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.success(
              <RemoteMissionSummary>[
                RemoteMissionSummary(
                  id: 'remote-mission-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'mission-local-1',
                  title: 'Arrumar brinquedos',
                  stars: 12,
                  requiresApproval: false,
                  recurrenceType: 'daily',
                  recurrenceDays: <int>[],
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(
            ensureResult: const ZeniEnsureRemoteRewardsResult.failure(
              'Não foi possível preparar os mimos na nuvem agora.',
            ),
          ),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(
            ensureResult: const ZeniEnsureRemoteMissionLogsResult.success(
              <RemoteMissionLogSummary>[],
            ),
          ),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardRequestsRepository(
            ensureResult: const ZeniEnsureRemoteRewardRequestsResult.success(
              <RemoteRewardRequestSummary>[],
            ),
          ),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(
            ensureResult: const ZeniEnsureRemoteStarLedgerResult.success(
              <RemoteStarLedgerEntrySummary>[],
            ),
          ),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastFullSyncAt, previousSyncAt);
  });

  test('failed mission logs sync keeps previous lastFullSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 16, 10);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(appSettings: AppSettings(lastFullSyncAt: previousSyncAt))
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.success(
              <RemoteMissionSummary>[
                RemoteMissionSummary(
                  id: 'remote-mission-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'mission-local-1',
                  title: 'Arrumar brinquedos',
                  stars: 12,
                  requiresApproval: false,
                  recurrenceType: 'daily',
                  recurrenceDays: <int>[],
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(
            ensureResult: const ZeniEnsureRemoteRewardsResult.success(
              <RemoteRewardSummary>[],
            ),
          ),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(
            ensureResult: const ZeniEnsureRemoteMissionLogsResult.failure(
              'Não foi possível preparar as conclusões na nuvem agora.',
            ),
          ),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastFullSyncAt, previousSyncAt);
  });

  test('failed reward requests sync keeps previous lastFullSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 16, 10);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(appSettings: AppSettings(lastFullSyncAt: previousSyncAt))
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.success(
              <RemoteMissionSummary>[
                RemoteMissionSummary(
                  id: 'remote-mission-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'mission-local-1',
                  title: 'Arrumar brinquedos',
                  stars: 12,
                  requiresApproval: false,
                  recurrenceType: 'daily',
                  recurrenceDays: <int>[],
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(
            ensureResult: const ZeniEnsureRemoteRewardsResult.success(
              <RemoteRewardSummary>[
                RemoteRewardSummary(
                  id: 'remote-reward-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'reward-local-1',
                  title: 'Escolher filme',
                  cost: 40,
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(
            ensureResult: const ZeniEnsureRemoteMissionLogsResult.success(
              <RemoteMissionLogSummary>[],
            ),
          ),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardRequestsRepository(
            ensureResult: const ZeniEnsureRemoteRewardRequestsResult.failure(
              'Não foi possível preparar os pedidos na nuvem agora.',
            ),
          ),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastFullSyncAt, previousSyncAt);
  });

  test('failed star ledger sync keeps previous lastFullSyncAt', () async {
    final previousSyncAt = DateTime(2026, 5, 28, 16, 10);
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(
        ZeniAppState.initial()
            .copyWith(
              appSettings: AppSettings(lastFullSyncAt: previousSyncAt),
              starLedgerEntries: [
                StarLedgerEntry(
                  id: 'ledger-local-1',
                  familyId: 'local-family',
                  childId: 'child-local-1',
                  amount: 12,
                  balanceAfter: 42,
                  type: StarLedgerEntryType.earned,
                  title: 'Missão concluída',
                  createdAt: DateTime(2026, 5, 28, 10, 0),
                  relatedMissionLogId: 'log-local-1',
                ),
              ],
            )
            .toJson(),
      ),
    });
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
        accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        remoteChildrenRepositoryProvider.overrideWithValue(
          _FakeRemoteChildrenRepository(
            ensureResult: const ZeniEnsureRemoteChildrenResult.success(
              <RemoteChildSummary>[
                RemoteChildSummary(
                  id: 'remote-child-1',
                  familyId: 'family-1',
                  localId: 'child-local-1',
                  name: 'Luna',
                  avatarKey: '🦊',
                ),
              ],
            ),
          ),
        ),
        remoteMissionsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionsRepository(
            ensureResult: const ZeniEnsureRemoteMissionsResult.success(
              <RemoteMissionSummary>[
                RemoteMissionSummary(
                  id: 'remote-mission-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'mission-local-1',
                  title: 'Arrumar brinquedos',
                  stars: 12,
                  requiresApproval: false,
                  recurrenceType: 'daily',
                  recurrenceDays: <int>[],
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteRewardsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardsRepository(
            ensureResult: const ZeniEnsureRemoteRewardsResult.success(
              <RemoteRewardSummary>[
                RemoteRewardSummary(
                  id: 'remote-reward-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  localId: 'reward-local-1',
                  title: 'Escolher filme',
                  cost: 40,
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
        remoteMissionLogsRepositoryProvider.overrideWithValue(
          _FakeRemoteMissionLogsRepository(
            ensureResult: ZeniEnsureRemoteMissionLogsResult.success(
              <RemoteMissionLogSummary>[
                RemoteMissionLogSummary(
                  id: 'remote-log-1',
                  familyId: 'family-1',
                  childId: 'remote-child-1',
                  missionId: 'remote-mission-1',
                  localId: 'log-local-1',
                  status: 'approved',
                  starsAwarded: 12,
                  scheduledDate: DateTime(2026, 5, 28),
                ),
              ],
            ),
          ),
        ),
        remoteRewardRequestsRepositoryProvider.overrideWithValue(
          _FakeRemoteRewardRequestsRepository(
            ensureResult: const ZeniEnsureRemoteRewardRequestsResult.success(
              <RemoteRewardRequestSummary>[],
            ),
          ),
        ),
        remoteStarLedgerRepositoryProvider.overrideWithValue(
          _FakeRemoteStarLedgerRepository(
            ensureResult: const ZeniEnsureRemoteStarLedgerResult.failure(
              'Não foi possível preparar o histórico de estrelas na nuvem agora.',
            ),
          ),
        ),
        remoteFamilySummaryProvider.overrideWith(
          (ref) async => const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final result = await container
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow();
    final appState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(result.isSuccess, isFalse);
    expect(appState.appSettings.lastFullSyncAt, previousSyncAt);
  });
}

class _TestAuthRepository implements ZeniAuthRepository {
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
    _currentUser = ZeniAuthUser(id: 'user-1', email: email);
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
    _currentUser = ZeniAuthUser(id: 'user-2', email: email);
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

class _FakeAccountRepository implements ZeniAccountRepository {
  _FakeAccountRepository({
    this.ensureResult = const ZeniEnsureRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    ),
    this.updateResult = const ZeniUpdateRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    ),
  });

  final ZeniEnsureRemoteFamilyResult ensureResult;
  final ZeniUpdateRemoteFamilyResult updateResult;
  int ensureCalls = 0;
  int updateCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    return null;
  }

  @override
  Future<ZeniEnsureRemoteFamilyResult>
  ensureRemoteFamilyForCurrentUser() async {
    ensureCalls += 1;
    return ensureResult;
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  }) async {
    updateCalls += 1;
    return updateResult;
  }
}

class _FakeRemoteChildrenRepository implements RemoteChildrenRepository {
  _FakeRemoteChildrenRepository({
    this.ensureResult = const ZeniEnsureRemoteChildrenResult.success(
      <RemoteChildSummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteChildrenResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    if (ensureResult.isSuccess) {
      return ensureResult.children;
    }
    return const <RemoteChildSummary>[];
  }
}

class _FakeRemoteMissionsRepository implements RemoteMissionsRepository {
  _FakeRemoteMissionsRepository({
    this.ensureResult = const ZeniEnsureRemoteMissionsResult.success(
      <RemoteMissionSummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteMissionsResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async {
    return ensureResult.missions;
  }
}

class _FakeRemoteRewardsRepository implements RemoteRewardsRepository {
  _FakeRemoteRewardsRepository({
    this.ensureResult = const ZeniEnsureRemoteRewardsResult.success(
      <RemoteRewardSummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteRewardsResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async {
    return ensureResult.rewards;
  }
}

class _FakeRemoteRewardRequestsRepository
    implements RemoteRewardRequestsRepository {
  _FakeRemoteRewardRequestsRepository({
    this.ensureResult = const ZeniEnsureRemoteRewardRequestsResult.success(
      <RemoteRewardRequestSummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteRewardRequestsResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List<RewardRequest> localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  }) async {
    return ensureResult.requests;
  }
}

class _FakeRemoteMissionLogsRepository implements RemoteMissionLogsRepository {
  _FakeRemoteMissionLogsRepository({
    this.ensureResult = const ZeniEnsureRemoteMissionLogsResult.success(
      <RemoteMissionLogSummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteMissionLogsResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List<MissionLog> localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async {
    return ensureResult.missionLogs;
  }
}

class _FakeRemoteStarLedgerRepository implements RemoteStarLedgerRepository {
  _FakeRemoteStarLedgerRepository({
    this.ensureResult = const ZeniEnsureRemoteStarLedgerResult.success(
      <RemoteStarLedgerEntrySummary>[],
    ),
    this.onEnsure,
  });

  final ZeniEnsureRemoteStarLedgerResult ensureResult;
  final void Function()? onEnsure;
  int ensureCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List<StarLedgerEntry> localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) async {
    ensureCalls += 1;
    onEnsure?.call();
    return ensureResult;
  }

  @override
  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  }) async {
    return ensureResult.entries;
  }
}

class _FakeRemoteChildBalanceRepository
    implements RemoteChildBalanceRepository {
  _FakeRemoteChildBalanceRepository();
  int readCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  }) async {
    readCalls += 1;
    return const <RemoteChildStarBalance>[];
  }
}

class _FakeFamilyRepository implements FamilyRepository {
  _FakeFamilyRepository({required this.children});

  final List<ChildProfile> children;

  @override
  Future<void> archiveChild(String childId) async {}

  @override
  Future<ChildProfile> createChild({
    required String familyId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ChildProfile?> getChildById(String childId) async {
    for (final child in children) {
      if (child.id == childId) return child;
    }
    return null;
  }

  @override
  Future<List<ChildProfile>> getChildren({bool includeArchived = false}) async {
    return children;
  }

  @override
  Future<Family> getCurrentFamily() async {
    return Family(
      id: 'family-1',
      name: 'Minha família',
      inviteCode: 'ABC123',
      createdAt: DateTime(2026, 5, 28),
    );
  }

  @override
  Future<List<FamilyMember>> getMembers() async => const <FamilyMember>[];

  @override
  Future<void> restoreChild(String childId) async {}

  @override
  Future<ChildProfile?> updateChild({
    required String childId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeChildrenTableClient implements ZeniChildrenTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchChildren({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId && row['local_id'] == localId) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertChild(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateChild({
    required String childId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == childId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeMissionsTableClient implements ZeniMissionsTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMissions({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId && row['local_id'] == localId) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertMission(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-mission-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateMission({
    required String missionId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == missionId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeRewardsTableClient implements ZeniRewardsTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchRewards({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId && row['local_id'] == localId) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertReward(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-reward-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateReward({
    required String rewardId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == rewardId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeMissionLogsTableClient implements ZeniMissionLogsTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMissionLogs({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId && row['local_id'] == localId) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertMissionLog(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-log-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateMissionLog({
    required String missionLogId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == missionLogId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeRewardRequestsTableClient implements ZeniRewardRequestsTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchRewardRequests({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId && row['local_id'] == localId) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertRewardRequest(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-request-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateRewardRequest({
    required String rewardRequestId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == rewardRequestId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeChildStarBalancesViewClient
    implements ZeniChildStarBalancesViewClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchChildStarBalances({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class _ThrowingChildStarBalancesViewClient
    implements ZeniChildStarBalancesViewClient {
  @override
  Future<List<Map<String, dynamic>>> fetchChildStarBalances({
    required String familyId,
  }) {
    throw const PostgrestException(
      message: 'read failed',
      code: '500',
      details: 'details',
      hint: 'hint',
    );
  }
}

class _FakeStarLedgerTableClient implements ZeniStarLedgerTableClient {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> insertedPayloads = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchEntries({
    required String familyId,
  }) async {
    return rows
        .where((row) => row['family_id'] == familyId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndIdempotencyKey({
    required String familyId,
    required String idempotencyKey,
  }) async {
    for (final row in rows) {
      if (row['family_id'] == familyId &&
          row['idempotency_key'] == idempotencyKey) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<void> insertEntry(Map<String, dynamic> payload) async {
    insertedPayloads.add(Map<String, dynamic>.from(payload));
    rows.add({'id': 'remote-ledger-${rows.length + 1}', ...payload});
  }

  @override
  Future<void> updateEntry({
    required String entryId,
    required Map<String, dynamic> payload,
  }) async {
    updatedPayloads.add(Map<String, dynamic>.from(payload));
    final index = rows.indexWhere((row) => row['id'] == entryId);
    if (index >= 0) {
      rows[index] = {...rows[index], ...payload};
    }
  }
}

class _FakeSupabaseAuthClient implements ZeniSupabaseAuthClient {
  _FakeSupabaseAuthClient({this.signInWithIdTokenError});

  final AuthException? signInWithIdTokenError;
  OAuthProvider? lastProvider;
  String? lastIdToken;
  String? lastAccessToken;
  String? lastNonce;
  User? _currentUser;
  Session? _currentSession;
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    lastProvider = provider;
    lastIdToken = idToken;
    lastAccessToken = accessToken;
    lastNonce = nonce;

    if (signInWithIdTokenError != null) {
      throw signInWithIdTokenError!;
    }

    final email = provider == OAuthProvider.google
        ? 'google@zeni.app'
        : 'apple@zeni.app';
    final user = User(
      id: '${provider.name}-user',
      appMetadata: const {},
      userMetadata: null,
      aud: 'authenticated',
      email: email,
      createdAt: '2026-05-28T00:00:00.000Z',
    );
    final session = Session(
      accessToken: 'session-token',
      tokenType: 'bearer',
      user: user,
    );
    _currentUser = user;
    _currentSession = session;
    _controller.add(user);
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _currentSession = null;
    _controller.add(null);
  }
}

class _FakeGoogleSignInClient implements ZeniGoogleSignInClient {
  const _FakeGoogleSignInClient.success(this.result) : error = null;
  const _FakeGoogleSignInClient.failure(this.error) : result = null;

  final ZeniGoogleSignInResult? result;
  final GoogleSignInException? error;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniGoogleSignInResult> signIn() async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeAppleSignInClient implements ZeniAppleSignInClient {
  const _FakeAppleSignInClient.success(this.result);

  final ZeniAppleSignInResult result;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<ZeniAppleSignInResult> signIn() async => result;
}
