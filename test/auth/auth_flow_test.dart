import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/apple_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/google_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import '../support/auth_test_fakes.dart';

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
    'auth repository returns build without cloud message when unconfigured',
    () async {
      final repository = SupabaseAuthRepository(client: null);

      final result = await repository.signInWithEmailPassword(
        email: 'responsavel@zeni.app',
        password: '123456',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'A conexão com a nuvem não foi incluída neste build.',
      );
    },
  );

  test(
    'auth repository returns initialization failure message when bootstrap failed',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://zeni.test.supabase.co',
          anonKey: 'anon-key',
        ),
        initializeOverride: ({required url, required anonKey}) async {
          throw Exception('boom');
        },
      );

      final repository = SupabaseAuthRepository(client: null);
      final result = await repository.signInWithEmailPassword(
        email: 'responsavel@zeni.app',
        password: '123456',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'A conexão com a nuvem falhou ao iniciar. Tente reinstalar ou contate o suporte.',
      );
    },
  );

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

  test('clearing local device data works without Supabase or login', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(zeniAppStateControllerProvider.future);

    await container
        .read(zeniAppStateControllerProvider.notifier)
        .clearLocalDeviceData();

    final resetState = await container.read(
      zeniAppStateControllerProvider.future,
    );

    expect(resetState.children, isEmpty);
    expect(resetState.missions, isEmpty);
    expect(resetState.rewards, isEmpty);
    expect(resetState.missionLogs, isEmpty);
    expect(resetState.rewardRequests, isEmpty);
    expect(resetState.starLedgerEntries, isEmpty);
    expect(resetState.appSettings.hasCompletedOnboarding, isFalse);
  });

  test(
    'clearing local device data does not call sign out or depend on auth',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
      });

      final repository = TestAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        await repository.dispose();
        container.dispose();
      });

      await container
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: 'responsavel@zeni.app',
            password: '123456',
          );
      await container.read(zeniAppStateControllerProvider.future);
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

      await container
          .read(zeniAppStateControllerProvider.notifier)
          .clearLocalDeviceData();

      expect(repository.signOutCalls, 0);
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
    },
  );

  test('auth state provider reacts to sign in and sign out', () async {
    final repository = TestAuthRepository();
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

  test('sign out clears a ready family identity session', () async {
    final repository = TestAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    await container
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: 'responsavel@zeni.app',
          password: '123456',
        );
    final user = container.read(authStateProvider).user!;
    container.read(authStateProvider.notifier).setFamilyIdentityReady(user);
    expect(
      container.read(authStateProvider).familyIdentityAccess,
      ZeniFamilyIdentityAccess.ready,
    );

    await container.read(zeniAuthControllerProvider).signOut();
    await container.pump();

    final state = container.read(authStateProvider);
    expect(state.status, ZeniAuthStatus.unauthenticated);
    expect(state.user, isNull);
    expect(state.familyIdentityAccess, ZeniFamilyIdentityAccess.pending);
  });

  test('auth state provider reacts to Google sign in', () async {
    final repository = TestAuthRepository();
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
    final repository = TestAuthRepository();
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
      authClient: FakeSupabaseAuthClient(),
      googleSignInClient: const FakeGoogleSignInClient.failure(
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
    final authClient = FakeSupabaseAuthClient();
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: authClient,
      googleSignInClient: const FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
          email: 'google@zeni.app',
        ),
      ),
      appleSignInClient: const FakeAppleSignInClient.success(
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
    final authClient = FakeSupabaseAuthClient();
    final repository = SupabaseAuthRepository(
      client: null,
      authClient: authClient,
      googleSignInClient: const FakeGoogleSignInClient.success(
        ZeniGoogleSignInResult(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ),
      appleSignInClient: const FakeAppleSignInClient.success(
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
      authClient: FakeSupabaseAuthClient(
        signInWithIdTokenError: const AuthException(
          'passed nonce and nonce in id_token should either both exist or not',
        ),
      ),
      googleSignInClient: const FakeGoogleSignInClient.success(
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
      authClient: FakeSupabaseAuthClient(
        signInWithIdTokenError: const AuthException('provider misconfigured'),
      ),
      googleSignInClient: const FakeGoogleSignInClient.success(
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
}
