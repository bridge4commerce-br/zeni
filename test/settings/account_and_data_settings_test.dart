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

  testWidgets('responsible profile appears at the top with name and email', (
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

    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    final profileTop = tester.getTopLeft(find.text('Carla')).dy;
    final securityTop = tester.getTopLeft(find.text('Segurança')).dy;
    expect(profileTop, lessThan(securityTop));
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

    expect(find.text('Nome da família no backup'), findsOneWidget);
    expect(find.text('Minha família'), findsOneWidget);
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

    await tester.tap(find.text('Carla'));
    await tester.pumpAndSettle();
    expect(find.text('Perfil do responsável'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('parent-display-name-input')),
      'Marina',
    );
    await tester.tap(find.text('Salvar nome'));
    await tester.pumpAndSettle();

    expect(savedName, 'Marina');
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

    expect(find.text('Minha família'), findsOneWidget);
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
    expect(find.text('Preferências'), findsOneWidget);
    expect(find.text('Sincronização e backup'), findsWidgets);
    expect(find.text('Ajuda e informações'), findsOneWidget);
    expect(find.text('Conta e dados'), findsOneWidget);
    expect(find.text('Zona de perigo'), findsNothing);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('Apagar dados deste aparelho'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Segurança')).dy,
      lessThan(tester.getTopLeft(find.text('Sincronização e backup').first).dy),
    );
    expect(
      tester.getTopLeft(find.text('Apagar dados deste aparelho')).dy,
      greaterThan(
        tester.getTopLeft(find.text('Sincronização e backup').first).dy,
      ),
    );
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
    expect(find.text('Como seus dados são salvos'), findsOneWidget);
    expect(find.text('Informações técnicas para suporte'), findsOneWidget);
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

    expect(find.text('Tudo salvo na sua conta'), findsOneWidget);
    expect(
      find.text('Última sincronização: 15/06/2026 às 10:30'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Crianças preparadas · Missões preparadas'),
      findsNothing,
    );
  });

  testWidgets('sync technical details appear only after tapping view details', (
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

    expect(
      find.text(
        'Crianças preparadas · Missões preparadas · Mimos preparados · Conclusões preparadas · Pedidos preparados · Eventos preparados',
      ),
      findsNothing,
    );

    await tester.scrollUntilVisible(find.text('Ver detalhes'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Crianças preparadas · Missões preparadas · Mimos preparados · Conclusões preparadas · Pedidos preparados · Eventos preparados',
      ),
      findsOneWidget,
    );
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

    await tester.scrollUntilVisible(
      find.text('Informações técnicas para suporte'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informações técnicas para suporte'));
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

    expect(find.text('Conectar conta'), findsOneWidget);
    expect(
      find.text('A conexão com a nuvem falhou ao iniciar neste aparelho.'),
      findsOneWidget,
    );
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
        'O Zeni salva dados da família para organizar crianças, missões, mimos, pedidos e histórico de estrelas. O app pode funcionar apenas neste aparelho. Quando você entra com uma conta, parte desses dados pode ser sincronizada na nuvem para permitir restauração e continuidade em outro aparelho. Você pode apagar dados locais deste aparelho e também solicitar a exclusão da conta e dos dados da nuvem.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Termos de Uso'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'O Zeni é uma ferramenta de organização familiar. O responsável é quem cria e gerencia crianças, missões, mimos e aprovações. O app não substitui acompanhamento parental, financeiro, educacional ou profissional. Ao usar recursos de conta e nuvem, você concorda em manter suas credenciais seguras e usar o app de forma adequada à sua família.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Suporte'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suporte'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Para ajuda com conta, sincronização, restauração, exclusão de conta ou dúvidas sobre privacidade',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('suporte@luminadigital.app'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Fechar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Como seus dados são salvos'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Como seus dados são salvos'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'O Zeni foi pensado para funcionar de forma local/offline. Os dados salvos neste aparelho continuam disponíveis mesmo sem login. Entrar com uma conta é opcional e permite sincronizar ou restaurar dados da família pela nuvem. Sair da conta remove apenas a sessão. Apagar dados deste aparelho não apaga a nuvem. A exclusão completa da conta e dos dados da nuvem ficará para uma etapa própria.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('remote deletion area appears as unavailable and informative', (
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

    await tester.scrollUntilVisible(find.text('Conta e dados'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir conta e dados da nuvem'));
    await tester.pumpAndSettle();

    expect(find.text('Gerenciar dados e conta'), findsOneWidget);
    expect(
      find.text(
        'Indisponível nesta versão. A exclusão completa da conta e dos dados da nuvem ficará para uma etapa própria.',
      ),
      findsOneWidget,
    );
    expect(find.text('Indisponível'), findsOneWidget);
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
    await tester.scrollUntilVisible(find.text('Conta e dados'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir conta e dados da nuvem'));
    await tester.pumpAndSettle();

    expect(fakeAccountRepository.deleteCalls, 0);
    expect(find.text('Indisponível'), findsOneWidget);
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
      await tester.scrollUntilVisible(find.text('Conta e dados'), 300);
      await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(find.text('Conta e dados'), 300);
    await tester.pumpAndSettle();
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
        onSyncCloudData: () async => const ZeniCloudSyncResult(
          status: ZeniCloudSyncStatus.success,
          message: 'Dados sincronizados neste aparelho.',
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Dados na nuvem'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dados na nuvem'));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar agora'), findsWidgets);

    await tester.tap(find.text('Sincronizar agora').last);
    await tester.pumpAndSettle();

    expect(find.text('Dados sincronizados neste aparelho.'), findsOneWidget);
  });
}
