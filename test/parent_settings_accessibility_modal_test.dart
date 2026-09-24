import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';

import 'support/settings_test_harness.dart';

void main() {
  testWidgets('text scale picker remains a bottom sheet on a phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
      ),
    );

    await tester.tap(find.text('Tamanho da letra'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zeni-modal-drag-handle')), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.byTooltip('Diminuir Tamanho da letra'), findsOneWidget);
    expect(find.byTooltip('Aumentar Tamanho da letra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale picker uses a handle-free dialog on a tablet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1024, 1366);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.unauthenticated(),
      ),
    );

    await tester.tap(find.text('Tamanho da letra'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('zeni-modal-drag-handle')), findsNothing);
    expect(find.text('100%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
