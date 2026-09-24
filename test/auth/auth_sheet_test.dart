import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import '../support/settings_test_harness.dart';
import '../support/widget_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openAccountSheet(WidgetTester tester) async {
    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Conta, backup e restauração'),
      300,
    );
    await tester.tap(find.text('Conta, backup e restauração'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conta não conectada').last);
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

    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
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
