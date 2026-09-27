import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import '../support/settings_test_harness.dart';
import '../support/widget_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openAccountSheet(WidgetTester tester) async {
    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conta e dados').last, 300);
    await tester.tap(find.text('Conta e dados').last);
    await tester.pumpAndSettle();
    final signedOutLinkedAccount = find.text('Sessão encerrada neste aparelho');
    if (signedOutLinkedAccount.evaluate().isNotEmpty) {
      await tester.tap(signedOutLinkedAccount.last);
    } else {
      await tester.tap(find.text('Conta não conectada').last);
    }
    await tester.pumpAndSettle();
  }

  Future<void> openEmailForm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('auth-email-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('account sheet prioritizes providers before e-mail fields', (
    tester,
  ) async {
    seedMockAppState();
    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openAccountSheet(tester);

    expect(find.text('Conta da família'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Continuar com e-mail'), findsOneWidget);
    expect(find.byKey(const Key('auth-email-input')), findsNothing);
    expect(find.textContaining('SUPABASE'), findsNothing);
  });

  testWidgets('choosing e-mail reveals the existing e-mail sign in form', (
    tester,
  ) async {
    seedMockAppState();
    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await openEmailForm(tester);

    expect(find.byKey(const Key('auth-email-input')), findsOneWidget);
    expect(find.byKey(const Key('auth-password-input')), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('email sign in still updates the settings account state', (
    tester,
  ) async {
    seedMockAppState();
    final repository = FakeZeniAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await openEmailForm(tester);
    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(container.read(authStateProvider).isAuthenticated, isTrue);
    expect(
      container.read(authStateProvider).user?.email,
      'responsavel@zeni.app',
    );
  });

  testWidgets('email sign up requires and persists the responsible name', (
    tester,
  ) async {
    seedMockAppState();
    final repository = FakeZeniAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await openEmailForm(tester);
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-name-input')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(repository.signUpCalls, 0);

    await tester.enterText(find.byKey(const Key('auth-name-input')), 'Carla');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(repository.signUpCalls, 1);
    expect(repository.lastSignUpDisplayName, 'Carla');
  });

  testWidgets('identity block is explained without presenting login failure', (
    tester,
  ) async {
    seedMockAppState();
    final operation = Completer<ZeniAuthOperationResult>();
    final repository = FakeZeniAuthRepository(
      googleSignInCompleter: operation,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await tester.tap(find.byKey(const Key('auth-google-button')));
    operation.complete(
      const ZeniAuthOperationResult.localFamilyConflict(
        user: ZeniAuthUser(
          id: 'google-user',
          email: 'carla@zeni.app',
          displayName: 'Carla',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(authStateProvider).isAuthenticated, isTrue);
    expect(container.read(authStateProvider).isFamilyIdentityBlocked, isTrue);
    expect(repository.currentUser?.id, 'google-user');
    expect(repository.signOutCalls, 0);
    expect(find.text(localFamilyConflictTitle), findsOneWidget);
    expect(find.text(localFamilyConflictMessage), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('carla@zeni.app'), findsOneWidget);
    expect(find.text('Conectado'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(
      find.text('Apagar dados deste aparelho e entrar com esta conta'),
      findsOneWidget,
    );
    expect(find.text('Continuar com Google'), findsNothing);
    expect(find.text('Continuar com Apple'), findsNothing);
    expect(find.text('Continuar com e-mail'), findsNothing);
    expect(find.text('Não foi possível entrar.'), findsNothing);
  });

  testWidgets('legacy cleanup reuses the strong APAGAR confirmation', (
    tester,
  ) async {
    seedMockAppState();
    final operation = Completer<ZeniAuthOperationResult>();
    final repository = FakeZeniAuthRepository(googleSignInCompleter: operation);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await tester.tap(find.byKey(const Key('auth-google-button')));
    operation.complete(
      const ZeniAuthOperationResult.localFamilyConflict(
        user: ZeniAuthUser(id: 'google-user', email: 'carla@zeni.app'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('legacy-clear-local-data-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Os dados da nuvem não serão apagados.'),
      findsOneWidget,
    );
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
  });

  testWidgets('blocked authenticated account signs out only explicitly', (
    tester,
  ) async {
    seedMockAppState();
    final operation = Completer<ZeniAuthOperationResult>();
    final repository = FakeZeniAuthRepository(
      googleSignInCompleter: operation,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await tester.tap(find.byKey(const Key('auth-google-button')));
    operation.complete(
      const ZeniAuthOperationResult.localFamilyConflict(
        user: ZeniAuthUser(
          id: 'google-user',
          email: 'carla@zeni.app',
          displayName: 'Carla',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 0);
    repository.emitCurrentSessionRefresh();
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).isFamilyIdentityBlocked, isTrue);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    expect(repository.signOutCalls, 0);

    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 1);
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
    expect(container.read(authStateProvider).user, isNull);
    expect(
      container.read(authStateProvider).familyIdentityAccess,
      ZeniFamilyIdentityAccess.pending,
    );
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Continuar com Apple'), findsOneWidget);
    expect(find.text('Continuar com e-mail'), findsOneWidget);
    expect(find.text('Conectado'), findsNothing);

    repository.emitStaleAuthEvent(
      const ZeniAuthUser(
        id: 'google-user',
        email: 'carla@zeni.app',
        displayName: 'Carla',
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
    expect(find.text('Continuar com Google'), findsOneWidget);
  });

  testWidgets('provider failure stays user-facing and non-technical', (
    tester,
  ) async {
    seedMockAppState();
    final repository = FakeZeniAuthRepository(
      isGoogleSignInAvailableOverride: false,
      googleSignInFailureMessage:
          'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);
    await tester.tap(find.byKey(const Key('auth-google-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível continuar com Google neste momento. Tente outro método.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('GOOGLE_SERVER_CLIENT_ID'), findsNothing);
  });

  testWidgets('apple option appears when it is available', (tester) async {
    seedMockAppState();
    final repository = FakeZeniAuthRepository(
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openAccountSheet(tester);

    expect(find.text('Continuar com Apple'), findsOneWidget);
  });
}
