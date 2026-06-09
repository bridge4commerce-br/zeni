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
import '../support/settings_test_harness.dart';
import '../support/widget_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('authenticated settings show email and sign out action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conta conectada'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
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

    expect(find.text('Família remota preparada'), findsOneWidget);
    expect(find.text('Minha família · Responsável principal'), findsOneWidget);
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

    expect(find.text('Minha família · Responsável'), findsOneWidget);
  });

  testWidgets('account and data section separates account local and cloud areas', (
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

    expect(find.text('Conta e dados'), findsOneWidget);
    expect(find.text('Conta'), findsOneWidget);
    expect(find.text('Neste aparelho'), findsOneWidget);
    expect(find.text('Na nuvem'), findsOneWidget);
    expect(find.text('Conta conectada'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('Apagar dados deste aparelho'), findsOneWidget);
    expect(find.text('Excluir conta e dados da nuvem'), findsWidgets);
    expect(find.text('Gerenciar dados e conta'), findsNothing);
    expect(
      find.text(
        'Os dados locais ficam salvos neste aparelho para o Zeni funcionar mesmo offline.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Quando você sincroniza, uma cópia segura dos dados principais fica vinculada à sua conta.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('legal and support section appears in settings', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
      ),
    );

    expect(find.text('Legal e suporte'), findsOneWidget);
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Suporte'), findsOneWidget);
    expect(find.text('Dados locais e nuvem'), findsOneWidget);
  });

  testWidgets('legal and support items open internal content sheets', (
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

    await tester.tap(find.text('Dados locais e nuvem'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'O Zeni foi pensado para funcionar de forma local/offline. Os dados salvos neste aparelho continuam disponíveis mesmo sem login. Entrar com uma conta é opcional e permite sincronizar ou restaurar dados da família pela nuvem. Sair da conta remove apenas a sessão. Apagar dados deste aparelho não apaga a nuvem. Excluir conta e dados da nuvem não apaga automaticamente os dados locais.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('remote deletion item appears as unavailable and informative', (
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

    expect(find.text('Excluir conta e dados da nuvem'), findsWidgets);
    expect(
      find.text(
        'Exclusão da conta e dados da nuvem ainda não está disponível nesta versão.',
      ),
      findsOneWidget,
    );
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
      await tester.scrollUntilVisible(
        find.text('Apagar dados deste aparelho'),
        300,
      );
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
      expect(find.text('Bem-vindo ao Zeni'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('Apagar dados deste aparelho'),
      300,
    );
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
}
