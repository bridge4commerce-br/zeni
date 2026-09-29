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
      expect(accountRepository.resolveCalls, 0);
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
        createResult: const ZeniCreateInitialFamilyResult.failure(
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
    },
  );

  test('rename RPC updated response is parsed explicitly', () {
    final result = ZeniUpdateRemoteFamilyResult.fromRpcResponse({
      'contract_version': 1,
      'status': 'updated',
      'reason': null,
      'family_id': 'family-1',
      'membership_id': 'membership-1',
      'family_name': 'Família Silva',
      'role': 'owner',
      'updated_at': '2026-09-27T12:00:00Z',
    });

    expect(result.status, ZeniUpdateRemoteFamilyStatus.updated);
    expect(result.summary?.familyName, 'Família Silva');
    expect(result.membershipId, 'membership-1');
    expect(result.updatedAt, DateTime.utc(2026, 9, 27, 12));
  });

  test('rename RPC maps invalid_name and forbidden', () {
    Map<String, dynamic> response(String status, String reason) => {
      'contract_version': 1,
      'status': status,
      'reason': reason,
      'family_id': 'family-1',
      'membership_id': 'membership-1',
      'family_name': 'Família Silva',
      'role': status == 'forbidden' ? 'responsible' : 'owner',
      'updated_at': null,
    };

    final invalid = ZeniUpdateRemoteFamilyResult.fromRpcResponse(
      response('invalid_name', 'invalid_family_name'),
    );
    final forbidden = ZeniUpdateRemoteFamilyResult.fromRpcResponse(
      response('forbidden', 'owner_required'),
    );

    expect(invalid.status, ZeniUpdateRemoteFamilyStatus.invalidName);
    expect(invalid.isSuccess, isFalse);
    expect(forbidden.status, ZeniUpdateRemoteFamilyStatus.forbidden);
    expect(forbidden.isSuccess, isFalse);
  });

  test('malformed rename RPC response fails safely', () {
    final result = ZeniUpdateRemoteFamilyResult.fromRpcResponse({
      'contract_version': 1,
      'status': 'updated',
      'family_id': 'family-1',
    });

    expect(result.status, ZeniUpdateRemoteFamilyStatus.failure);
    expect(
      result.message,
      'A resposta de atualização da família remota é inválida.',
    );
  });

  test('updating remote family name without auth fails safely', () async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(zeniAccountControllerProvider)
        .updateRemoteFamilyName(name: 'Família da Luna');

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
        .updateRemoteFamilyName(name: '   ');

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
          .updateRemoteFamilyName(name: 'Família da Luna');

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Não foi possível atualizar a família remota agora.',
      );
      expect(accountRepository.updateCalls, 1);
    },
  );

  test(
    'normalized remote family name is persisted locally only after ACK',
    () async {
      final initial = ZeniAppState.seeded().copyWith(
        family: ZeniAppState.seeded().family.copyWith(name: 'Nome anterior'),
      );
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode(initial.toJson()),
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
        updateResult: ZeniUpdateRemoteFamilyResult.success(
          const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Família Silva',
            role: 'owner',
          ),
          membershipId: 'membership-1',
          updatedAt: DateTime.utc(2026, 9, 27, 12),
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
      await container.read(zeniAppStateControllerProvider.future);

      final result = await container
          .read(zeniAccountControllerProvider)
          .updateRemoteFamilyName(name: '  Família   Silva  ');

      expect(result.isSuccess, isTrue);
      expect(
        (await container.read(
          zeniAppStateControllerProvider.future,
        )).family.name,
        'Família Silva',
      );
      final persisted = (await SharedPreferences.getInstance()).getString(
        'zeni_app_state_v1',
      );
      expect(
        ZeniAppState.fromJson(
          jsonDecode(persisted!) as Map<String, dynamic>,
        ).family.name,
        'Família Silva',
      );
    },
  );

  test('rename failure preserves the previous local family name', () async {
    final initial = ZeniAppState.seeded().copyWith(
      family: ZeniAppState.seeded().family.copyWith(name: 'Nome anterior'),
    );
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(initial.toJson()),
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
      updateResult: const ZeniUpdateRemoteFamilyResult.failure(
        'Não foi possível atualizar a família remota agora.',
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
    await container.read(zeniAppStateControllerProvider.future);

    final result = await container
        .read(zeniAccountControllerProvider)
        .updateRemoteFamilyName(name: 'Novo nome');

    expect(result.isSuccess, isFalse);
    expect(
      (await container.read(zeniAppStateControllerProvider.future)).family.name,
      'Nome anterior',
    );
    expect(accountRepository.updateCalls, 1);
  });

  test('remote ACK for another family preserves the local name', () async {
    final initial = ZeniAppState.seeded().copyWith(
      family: ZeniAppState.seeded().family.copyWith(name: 'Nome anterior'),
    );
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(initial.toJson()),
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
      updateResult: ZeniUpdateRemoteFamilyResult.success(
        const RemoteFamilySummary(
          familyId: 'unexpected-family',
          familyName: 'Nome remoto',
          role: 'owner',
        ),
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
    await container.read(zeniAppStateControllerProvider.future);

    final result = await container
        .read(zeniAccountControllerProvider)
        .updateRemoteFamilyName(name: 'Nome remoto');

    expect(result.isSuccess, isFalse);
    expect(
      (await container.read(zeniAppStateControllerProvider.future)).family.name,
      'Nome anterior',
    );
  });

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
