import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
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

  test(
    'ensureRemoteFamilyForCurrentUser with absent user fails safely',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
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
      final accountRepository = FakeAccountRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
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
    'initial family creation failure is returned in a controlled way',
    () async {
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final accountRepository = FakeAccountRepository(
        ensureResult: const ZeniEnsureRemoteFamilyResult.failure(
          'Não foi possível preparar a família remota agora.',
        ),
      );
      final authRepository = TestAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
        ],
      );
      addTearDown(() async {
        await authRepository.dispose();
        container.dispose();
      });

      final result = await container
          .read(zeniAuthControllerProvider)
          .signInWithGoogle();

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível preparar a família remota agora.',
      );
      expect(accountRepository.createCalls, 1);
      expect(accountRepository.ensureCalls, 0);
    },
  );

  test('updating remote family name without auth fails safely', () async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
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
    final accountRepository = FakeAccountRepository();
    final authRepository = TestAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        accountRepositoryProvider.overrideWithValue(accountRepository),
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
      final accountRepository = FakeAccountRepository(
        updateResult: const ZeniUpdateRemoteFamilyResult.failure(
          'Não foi possível atualizar a família remota agora.',
        ),
      );
      final authRepository = TestAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
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
    'remote account deletion succeeds, signs out, and preserves local data',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final authRepository = TestAuthRepository();
      final accountRepository = FakeAccountRepository(
        deleteResult: const ZeniDeleteAccountResult.success(
          familyId: 'family-1',
          message: 'Sua conta e os dados da família foram removidos da nuvem.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
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
      final before = await container.read(
        zeniAppStateControllerProvider.future,
      );

      final result = await container
          .read(zeniAccountControllerProvider)
          .deleteAccountAndRemoteFamily();

      final after = await container.read(zeniAppStateControllerProvider.future);
      expect(result.isSuccess, isTrue);
      expect(accountRepository.deleteCalls, 1);
      expect(authRepository.signOutCalls, 1);
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
      expect(jsonEncode(after.toJson()), jsonEncode(before.toJson()));
    },
  );

  test(
    'remote account deletion failure does not sign out or clear local data',
    () async {
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
      });
      await ZeniSupabaseBootstrap.initialize(
        config: const ZeniSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'anon',
        ),
        initializeOverride: ({required url, required anonKey}) async {},
      );
      final authRepository = TestAuthRepository();
      final accountRepository = FakeAccountRepository(
        deleteResult: const ZeniDeleteAccountResult.failure(
          message:
              'Os dados da família foram removidos, mas não foi possível finalizar a exclusão da conta. Entre em contato com o suporte.',
          errorCode: 'auth_delete_failed',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          accountRepositoryProvider.overrideWithValue(accountRepository),
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
      final before = await container.read(
        zeniAppStateControllerProvider.future,
      );

      final result = await container
          .read(zeniAccountControllerProvider)
          .deleteAccountAndRemoteFamily();

      final after = await container.read(zeniAppStateControllerProvider.future);
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'auth_delete_failed');
      expect(accountRepository.deleteCalls, 1);
      expect(authRepository.signOutCalls, 0);
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
      expect(jsonEncode(after.toJson()), jsonEncode(before.toJson()));
    },
  );
}
