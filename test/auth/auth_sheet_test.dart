import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/auth/presentation/widgets/auth_provider_button.dart';
import '../support/settings_test_harness.dart';
import '../support/widget_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings shows account CTA when unauthenticated', (
    tester,
  ) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openParentSettings(tester);

    expect(find.text('Conectar conta'), findsOneWidget);
  });

  testWidgets('tapping account CTA opens account sheet', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Conta da família'), findsOneWidget);
    expect(find.byKey(const Key('auth-email-input')), findsOneWidget);
    expect(find.byKey(const Key('auth-password-input')), findsOneWidget);
    expect(find.byKey(const Key('auth-google-button')), findsOneWidget);
  });

  testWidgets(
    'account sheet shows controlled failure without supabase configured',
    (tester) async {
      seedMockAppState();

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await openParentSettings(tester);
      await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conectar conta'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('auth-email-input')),
        'responsavel@zeni.app',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password-input')),
        '123456',
      );
      await tester.ensureVisible(find.text('Criar conta').last);
      await tester.tap(find.text('Criar conta').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('A conexão com a nuvem não foi incluída neste build.'),
        findsOneWidget,
      );
      expect(find.text('Conta da família'), findsOneWidget);
    },
  );

  testWidgets('sign up without session shows confirmation email guidance', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      signUpRequiresEmailConfirmation: true,
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.ensureVisible(find.text('Criar conta').last);
    await tester.tap(find.text('Criar conta').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('Conta criada. Confirme seu e-mail para entrar.'),
      findsOneWidget,
    );
    expect(find.text('Conta da família'), findsOneWidget);
  });

  testWidgets('email sign in with session updates settings UI', (tester) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository();
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.ensureVisible(find.text('Entrar').last);
    await tester.tap(find.text('Entrar').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('google sign in failure shows controlled inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      googleSignInFailureMessage:
          'Não foi possível concluir o login com Google.',
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível concluir o login com Google.'),
      findsOneWidget,
    );
    expect(find.text('Conta da família'), findsOneWidget);
  });

  testWidgets('google missing configuration shows inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      isGoogleSignInAvailableOverride: false,
      googleSignInFailureMessage:
          'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping Google leaves only Google button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final googleCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = FakeZeniAuthRepository(
      googleSignInCompleter: googleCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!googleCompleter.isCompleted) {
        googleCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.text('Conectando com Google...'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);

    googleCompleter.complete(
      const ZeniAuthOperationResult.failure(
        'Não foi possível entrar com Google. Tente novamente ou use e-mail.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Apple leaves only Apple button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final appleCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = FakeZeniAuthRepository(
      appleSignInCompleter: appleCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!appleCompleter.isCompleted) {
        appleCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-apple-button')));
    await tester.tap(
      find.byKey(const Key('auth-apple-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.text('Conectando com Apple...'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);

    appleCompleter.complete(
      const ZeniAuthOperationResult.failure(
        'Não foi possível concluir o login com Apple.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Entrar leaves only email sign in button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final signInCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = FakeZeniAuthRepository(
      signInCompleter: signInCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!signInCompleter.isCompleted) {
        signInCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Entrando...'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);

    signInCompleter.complete(
      const ZeniAuthOperationResult.success(
        user: ZeniAuthUser(id: 'signed-in', email: 'a@b.com'),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Criar conta leaves only sign up button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final signUpCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = FakeZeniAuthRepository(
      signUpCompleter: signUpCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!signUpCompleter.isCompleted) {
        signUpCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.ensureVisible(find.text('Criar conta').last);
    await tester.tap(find.text('Criar conta').last, warnIfMissed: false);
    await tester.pump();

    expect(find.text('Criando conta...'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);

    signUpCompleter.complete(
      const ZeniAuthOperationResult.pendingEmailConfirmation(
        message: 'Conta criada. Confirme seu e-mail para entrar.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'social auth buttons keep icon and label aligned with larger text scale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
            child: Scaffold(
              body: Column(
                children: [
                  AuthProviderButton.google(
                    onPressed: () {},
                    label: 'Entrar com Google',
                  ),
                  AuthProviderButton.apple(
                    onPressed: () {},
                    label: 'Entrar com Apple',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Entrar com Apple'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signing out returns to unauthenticated and keeps local data', (
    tester,
  ) async {
    seedMockAppState();
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

    final initialState = await container.read(
      zeniAppStateControllerProvider.future,
    );
    expect(initialState.children, isNotEmpty);
    expect(initialState.missions, isNotEmpty);
    expect(initialState.rewards, isNotEmpty);

    await container.read(zeniAuthControllerProvider).signOut();
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.signOutCalls, 1);
    expect(find.text('Conectar conta'), findsOneWidget);
    expect(find.text('Sair da conta'), findsNothing);
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.children,
      isNotEmpty,
    );
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.missions,
      isNotEmpty,
    );
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.rewards,
      isNotEmpty,
    );
  });

  testWidgets('apple button appears when Apple sign in is available', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      isAppleSignInAvailableOverride: true,
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-apple-button')), findsOneWidget);
  });

  testWidgets('apple sign in failure shows controlled inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = FakeZeniAuthRepository(
      isAppleSignInAvailableOverride: true,
      appleSignInFailureMessage: 'Não foi possível concluir o login com Apple.',
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
    await tester.scrollUntilVisible(find.text('Conectar conta'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conectar conta'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-apple-button')));
    await tester.tap(
      find.byKey(const Key('auth-apple-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível concluir o login com Apple.'),
      findsOneWidget,
    );
  });
}
