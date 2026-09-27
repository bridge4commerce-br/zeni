import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_account_providers.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';
import '../support/settings_test_harness.dart';
import '../support/widget_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openAccountAndData(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Conta e dados').last, 300);
    await tester.tap(find.text('Conta e dados').last);
    await tester.pumpAndSettle();
  }

  Future<void> revealInAccountData(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('main settings points to the simplified account experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        parentDisplayName: 'Carla',
      ),
    );
    await tester.pump();

    expect(find.text('Carla'), findsNothing);
    expect(find.text('Conta e dados'), findsWidgets);
    expect(find.text('responsavel@zeni.app'), findsNothing);
  });

  testWidgets('owner role appears as friendly responsible principal label', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conta e dados'), findsWidgets);
    expect(find.text('Minha família'), findsNothing);
  });

  testWidgets('tapping profile card opens parent name editor', (tester) async {
    var savedName = '';

    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        parentDisplayName: 'Carla',
        onUpdateParentDisplayName: (name) async {
          savedName = name;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Carla'), findsNothing);
    expect(savedName, isEmpty);
  });

  testWidgets('responsible role appears as friendly label', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'responsible',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Minha família'), findsNothing);
  });

  testWidgets('settings use simple groups and no danger zone label', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
      ),
    );

    expect(find.text('Segurança'), findsOneWidget);
    expect(find.text('Aparência e acessibilidade'), findsOneWidget);
    expect(find.text('Sincronização e backup'), findsNothing);
    expect(find.text('Ajuda e informações'), findsOneWidget);
    expect(find.text('Conta e dados'), findsWidgets);
    expect(find.text('Zona de perigo'), findsNothing);
    expect(find.text('Sair da conta'), findsNothing);
    expect(find.text('Apagar dados deste aparelho'), findsNothing);
  });

  testWidgets('help and support section appears in settings', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
      ),
    );

    expect(find.text('Ajuda e informações'), findsOneWidget);
    expect(find.text('Suporte'), findsOneWidget);
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Dados locais e nuvem'), findsOneWidget);
    expect(find.text('Informações técnicas para suporte'), findsNothing);
  });

  testWidgets('sync section shows a simple summary on the main screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        appSettings: AppSettings(lastFullSyncAt: DateTime(2026, 6, 15, 10, 30)),
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    expect(find.text('Tudo atualizado'), findsOneWidget);
    expect(
      find.text('Última sincronização: 15/06/2026 às 10:30'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Crianças preparadas · Missões preparadas'),
      findsNothing,
    );
  });

  testWidgets('blocked identity shows connected account without sync actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(
            id: 'user-1',
            email: 'responsavel@zeni.app',
            displayName: 'Carla',
          ),
          familyIdentityAccess: ZeniFamilyIdentityAccess.blocked,
        ),
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);

    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    expect(find.text('Conectado'), findsOneWidget);
    expect(find.text(localFamilyConflictTitle), findsOneWidget);
    expect(find.text(localFamilyConflictMessage), findsOneWidget);
    expect(find.text('Sincronização'), findsNothing);
    expect(find.text('Sincronizar agora'), findsNothing);
  });

  testWidgets('linked family never falls back to connect-account messaging', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
        isFamilyLinked: true,
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);

    expect(find.text('Minha conta'), findsWidgets);
    expect(find.text('Sessão encerrada neste aparelho'), findsWidgets);
    expect(find.text('Conta não conectada'), findsNothing);
    expect(find.textContaining('Conecte uma conta'), findsNothing);
    expect(find.text('Sincronização'), findsOneWidget);
    expect(
      find.textContaining('Pausada até você entrar novamente'),
      findsOneWidget,
    );
    expect(find.text('Dados neste aparelho'), findsOneWidget);
  });

  testWidgets('account row opens details without signing out', (tester) async {
    var signOutCalls = 0;
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(
            id: 'user-1',
            email: 'responsavel@zeni.app',
            displayName: 'Carla',
          ),
        ),
        parentDisplayName: 'Nome local',
        onSignOut: () => signOutCalls += 1,
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    await tester.tap(find.text('Carla'));
    await tester.pumpAndSettle();

    expect(find.text('Minha conta'), findsWidgets);
    expect(find.text('responsavel@zeni.app'), findsWidgets);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(signOutCalls, 0);
  });

  testWidgets('sign out requires an explicit action and confirmation', (
    tester,
  ) async {
    var signOutCalls = 0;
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(
            id: 'user-1',
            email: 'responsavel@zeni.app',
            displayName: 'Carla',
          ),
        ),
        onSignOut: () => signOutCalls += 1,
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    await tester.tap(find.text('Carla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    expect(
      find.text(
        'Os dados desta família continuarão disponíveis neste aparelho.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(signOutCalls, 0);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(signOutCalls, 1);
  });

  testWidgets('profile name is the source and can be edited immediately', (
    tester,
  ) async {
    var savedName = '';
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(
            id: 'user-1',
            email: 'responsavel@zeni.app',
            displayName: 'Nome do Google',
          ),
        ),
        accountProfile: const ZeniAccountProfile(
          userId: 'user-1',
          displayName: 'Nome escolhido no Zeni',
          email: 'responsavel@zeni.app',
        ),
        onUpdateAccountDisplayName: (displayName) async {
          savedName = displayName;
          return ZeniUpdateAccountProfileResult.success(
            ZeniAccountProfile(
              userId: 'user-1',
              displayName: displayName,
              email: 'responsavel@zeni.app',
            ),
          );
        },
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    expect(find.text('Nome escolhido no Zeni'), findsOneWidget);
    expect(find.text('Nome do Google'), findsNothing);
    await tester.tap(find.text('Nome escolhido no Zeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('account-name-input')),
      '  Carla Silva  ',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(savedName, 'Carla Silva');
    expect(find.text('Carla Silva'), findsOneWidget);
  });

  testWidgets('empty account name is rejected and email stays read-only', (
    tester,
  ) async {
    var updateCalls = 0;
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        accountProfile: const ZeniAccountProfile(
          userId: 'user-1',
          displayName: 'Carla',
          email: 'responsavel@zeni.app',
        ),
        onUpdateAccountDisplayName: (displayName) async {
          updateCalls++;
          return ZeniUpdateAccountProfileResult.success(
            ZeniAccountProfile(
              userId: 'user-1',
              displayName: displayName,
              email: 'responsavel@zeni.app',
            ),
          );
        },
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    await tester.tap(find.text('Carla'));
    await tester.pumpAndSettle();
    expect(find.text('Somente leitura'), findsOneWidget);
    await tester.tap(find.text('E-mail'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-name-input')), findsNothing);

    await tester.tap(find.text('Nome'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name-input')), '   ');
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(updateCalls, 0);
  });

  testWidgets('main account view hides technical and restore tasks', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        appSettings: AppSettings(
          lastChildrenSyncAt: DateTime(2026, 6, 15, 10),
          lastMissionsSyncAt: DateTime(2026, 6, 15, 10),
          lastRewardsSyncAt: DateTime(2026, 6, 15, 10),
          lastMissionLogsSyncAt: DateTime(2026, 6, 15, 10),
          lastRewardRequestsSyncAt: DateTime(2026, 6, 15, 10),
          lastStarLedgerSyncAt: DateTime(2026, 6, 15, 10),
          lastFullSyncAt: DateTime(2026, 6, 15, 10),
        ),
        remoteChildrenCount: 2,
        remoteMissionsCount: 2,
        remoteRewardsCount: 1,
        remoteMissionLogsCount: 3,
        remoteRewardRequestsCount: 1,
        remoteStarLedgerCount: 4,
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);

    expect(find.text('Detalhes da sincronização'), findsNothing);
    expect(find.text('Backup e restauração'), findsNothing);
    expect(find.text('Restaurar em aparelho novo'), findsNothing);
    expect(find.text('Dados da nuvem'), findsNothing);
  });

  testWidgets('technical diagnostics show safe bootstrap and auth availability', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
        isSupabaseConfigured: true,
        supabaseBootstrapState: const ZeniSupabaseBootstrapState.failed(
          'Failed to connect to https://project.supabase.co with token abcdefghijklmnopqrstuv and GOOGLE_CLIENT_ID ios-123456.apps.googleusercontent.com',
        ),
        isGoogleSignInAvailable: false,
        isAppleSignInAvailable: true,
      ),
    );

    await tester.scrollUntilVisible(find.text('Suporte'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suporte'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diagnóstico técnico'));
    await tester.pumpAndSettle();

    expect(find.text('Supabase configurado'), findsOneWidget);
    expect(find.text('Sim'), findsWidgets);
    expect(find.text('Supabase inicializado'), findsOneWidget);
    expect(find.text('Não'), findsWidgets);
    expect(find.text('Google disponível'), findsOneWidget);
    expect(find.text('Apple disponível'), findsOneWidget);
    expect(find.textContaining('[url oculta]'), findsOneWidget);
    expect(find.textContaining('abcdefghijklmnopqrstuv'), findsNothing);
    expect(find.textContaining('project.supabase.co'), findsNothing);
    expect(
      find.textContaining('ios-123456.apps.googleusercontent.com'),
      findsNothing,
    );
  });

  testWidgets('account CTA reflects bootstrap failure safely', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
        isSupabaseConfigured: true,
        supabaseBootstrapState: const ZeniSupabaseBootstrapState.failed('boom'),
      ),
    );

    await openAccountAndData(tester);
    expect(find.text('Conta não conectada'), findsWidgets);
  });

  testWidgets('help and support items open internal content sheets', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
      ),
    );

    await tester.scrollUntilVisible(find.text('Política de Privacidade'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Política de Privacidade'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'O Zeni mantém os dados neste aparelho e, quando você conecta uma conta, pode manter uma cópia na nuvem para recuperação.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Termos de Uso'));
    await tester.pumpAndSettle();
    expect(
      find.text('O responsável gerencia a família, missões e aprovações.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Suporte'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suporte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Precisa de ajuda com o Zeni? Fale com a gente.'),
      findsOneWidget,
    );
    expect(find.text('suporte@luminadigital.app'), findsOneWidget);
    await tester.tap(find.text('Diagnóstico técnico'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Resumo seguro para suporte interno.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Dados locais e nuvem'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dados locais e nuvem'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Conecte uma conta para manter uma cópia dos seus dados na nuvem e recuperá-los quando precisar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('remote deletion is not exposed as a main account task', (
    tester,
  ) async {
    seedMockAppState();
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final fakeAuthRepository = FakeZeniAuthRepository(
      initialUser: const ZeniAuthUser(
        id: 'user-1',
        email: 'responsavel@zeni.app',
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.pumpAndSettle();

    await openAccountAndData(tester);

    expect(find.text('Excluir conta e dados da nuvem'), findsNothing);
    expect(find.text('Dados da nuvem'), findsNothing);
    expect(find.byKey(const Key('delete-account-confirm-input')), findsNothing);
  });

  testWidgets('remote deletion UI does not execute real deletion', (
    tester,
  ) async {
    seedMockAppState();
    await ZeniSupabaseBootstrap.initialize(
      config: const ZeniSupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
      ),
      initializeOverride: ({required url, required anonKey}) async {},
    );
    final fakeAuthRepository = FakeZeniAuthRepository(
      initialUser: const ZeniAuthUser(
        id: 'user-1',
        email: 'responsavel@zeni.app',
      ),
    );
    final fakeAccountRepository = FakeZeniAccountRepository(
      summary: const RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        accountRepositoryProvider.overrideWithValue(fakeAccountRepository),
      ],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await openAccountAndData(tester);
    expect(fakeAccountRepository.deleteCalls, 0);
    expect(find.text('Excluir conta e dados da nuvem'), findsNothing);
    expect(find.byKey(const Key('delete-account-confirm-input')), findsNothing);
  });

  testWidgets(
    'clearing local device data remains available from the account and data section',
    (tester) async {
      seedMockAppState();
      final fakeAuthRepository = FakeZeniAuthRepository(
        initialUser: const ZeniAuthUser(
          id: 'user-1',
          email: 'responsavel@zeni.app',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      );
      addTearDown(() async {
        await fakeAuthRepository.dispose();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await openParentSettings(tester);
      await openAccountAndData(tester);
      await revealInAccountData(
        tester,
        find.text('Apagar dados deste aparelho'),
      );
      await tester.tap(find.text('Apagar dados deste aparelho'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Digite APAGAR para confirmar.'),
        findsOneWidget,
      );

      final clearButton = find.widgetWithText(
        ElevatedButton,
        'Apagar dados deste aparelho',
      );
      expect(tester.widget<ElevatedButton>(clearButton).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('clear-local-data-confirm-input')),
        'APAGAR',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<ElevatedButton>(clearButton).onPressed, isNotNull);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.signOutCalls, 0);
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

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
      expect(resetState.appSettings.hasParentPin, isFalse);
      expect(resetState.appSettings.parentBiometricsEnabled, isFalse);
      expect(
        find.text('Pequenas atitudes. Grandes conquistas.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('wrong clear local confirmation does not erase device data', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      initialUser: const ZeniAuthUser(
        id: 'user-1',
        email: 'responsavel@zeni.app',
      ),
    );
    final fakeAccountRepository = FakeZeniAccountRepository(
      summary: const RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        accountRepositoryProvider.overrideWithValue(fakeAccountRepository),
      ],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    final before = await container.read(zeniAppStateControllerProvider.future);

    await openParentSettings(tester);
    await openAccountAndData(tester);
    await revealInAccountData(tester, find.text('Apagar dados deste aparelho'));
    await tester.tap(find.text('Apagar dados deste aparelho'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('clear-local-data-confirm-input')),
      'APAG',
    );
    await tester.pumpAndSettle();

    final clearButton = find.widgetWithText(
      ElevatedButton,
      'Apagar dados deste aparelho',
    );
    expect(tester.widget<ElevatedButton>(clearButton).onPressed, isNull);
    expect(fakeAuthRepository.signOutCalls, 0);
    expect(fakeAccountRepository.deleteCalls, 0);

    final after = await container.read(zeniAppStateControllerProvider.future);
    expect(jsonEncode(after.toJson()), jsonEncode(before.toJson()));
  });

  testWidgets('account section opens cloud data sheet for manual sync', (
    tester,
  ) async {
    var syncCalls = 0;
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        onSyncCloudData: () async {
          syncCalls += 1;
          return const ZeniCloudSyncResult(
            status: ZeniCloudSyncStatus.success,
            message: 'Dados sincronizados neste aparelho.',
          );
        },
      ),
    );
    await tester.pump();

    await openAccountAndData(tester);
    await revealInAccountData(tester, find.text('Sincronizar agora'));

    expect(find.text('Sincronizar agora'), findsWidgets);

    await tester.tap(find.text('Sincronizar agora').last);
    await tester.pumpAndSettle();

    expect(syncCalls, 1);
  });
}
