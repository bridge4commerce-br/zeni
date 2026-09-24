import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/core/widgets/base/zeni_surface.dart';
import 'package:zeni/features/balance/data/models/star_ledger_entry.dart';
import 'package:zeni/features/child/presentation/widgets/child_balance_tab.dart';

void main() {
  StarLedgerEntry entry({
    required String id,
    required int amount,
    required StarLedgerEntryType type,
    required String title,
    String? description,
  }) {
    return StarLedgerEntry(
      id: id,
      familyId: 'family-1',
      childId: 'child-1',
      amount: amount,
      balanceAfter: 72,
      type: type,
      title: title,
      description: description,
      createdAt: DateTime(2026, 9, 23, 10),
    );
  }

  Future<void> pumpBalance(
    WidgetTester tester, {
    required Size size,
    required int balance,
    required List<StarLedgerEntry> entries,
    bool darkMode = false,
    bool openDyslexic = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final baseTheme = darkMode ? ZeniTheme.dark : ZeniTheme.light;
    final theme = openDyslexic
        ? baseTheme.copyWith(
            textTheme: ZeniTypography.applyFontFamily(
              baseTheme.textTheme,
              ZeniTypography.openDyslexicFontFamily,
            ),
            primaryTextTheme: ZeniTypography.applyFontFamily(
              baseTheme.primaryTextTheme,
              ZeniTypography.openDyslexicFontFamily,
            ),
          )
        : baseTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: ChildBalanceTab(childBalance: balance, ledgerEntries: entries),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone shows current balance and grouped credits and debits', (
    tester,
  ) async {
    final entries = [
      entry(
        id: 'earned',
        amount: 10,
        type: StarLedgerEntryType.earned,
        title: 'Missão concluída',
        description: 'Arrumar a cama',
      ),
      entry(
        id: 'spent',
        amount: -40,
        type: StarLedgerEntryType.spent,
        title: 'Mimo solicitado',
        description: 'Noite do filme',
      ),
    ];

    await pumpBalance(
      tester,
      size: const Size(390, 844),
      balance: 72,
      entries: entries,
    );

    expect(find.byKey(const Key('child-balance-title')), findsOneWidget);
    expect(find.byKey(const Key('child-balance-highlight')), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('+10 ⭐'), findsOneWidget);
    expect(find.text('-40 ⭐'), findsOneWidget);

    final list = find.byKey(const Key('child-balance-history-list'));
    final surface = tester.widget<ZeniSurface>(list);
    expect(surface.role, ZeniSurfaceRole.grouped);
    expect(surface.padding, EdgeInsets.zero);
    expect(
      find.descendant(of: list, matching: find.byType(Divider)),
      findsOneWidget,
    );

    final earned = tester.getTopLeft(
      find.byKey(const Key('child-balance-entry-earned')),
    );
    final spent = tester.getTopLeft(
      find.byKey(const Key('child-balance-entry-spent')),
    );
    expect((earned.dx - spent.dx).abs(), lessThan(1));
    expect(spent.dy, greaterThan(earned.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero balance keeps a friendly empty history visible', (
    tester,
  ) async {
    await pumpBalance(
      tester,
      size: const Size(390, 844),
      balance: 0,
      entries: const [],
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(const Key('child-balance-empty-state')), findsOneWidget);
    expect(find.text('Nenhuma movimentação ainda'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet portrait keeps history below the balance', (
    tester,
  ) async {
    await pumpBalance(
      tester,
      size: const Size(1024, 1366),
      balance: 20,
      entries: [
        entry(
          id: 'earned',
          amount: 20,
          type: StarLedgerEntryType.earned,
          title: 'Missão concluída',
        ),
      ],
    );

    final balance = find.byKey(const Key('child-balance-highlight'));
    final history = find.byKey(const Key('child-balance-history-list'));
    expect(
      tester.getTopLeft(history).dy,
      greaterThan(tester.getTopLeft(balance).dy),
    );
    expect(
      tester.getSize(history).width,
      closeTo(tester.getSize(balance).width, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape preserves the same single-list anatomy', (
    tester,
  ) async {
    await pumpBalance(
      tester,
      size: const Size(1366, 1024),
      balance: 30,
      entries: [
        entry(
          id: 'first',
          amount: 40,
          type: StarLedgerEntryType.earned,
          title: 'Missão concluída',
        ),
        entry(
          id: 'second',
          amount: -10,
          type: StarLedgerEntryType.spent,
          title: 'Mimo solicitado',
        ),
      ],
    );

    final first = tester.getTopLeft(
      find.byKey(const Key('child-balance-entry-first')),
    );
    final second = tester.getTopLeft(
      find.byKey(const Key('child-balance-entry-second')),
    );
    expect((first.dx - second.dx).abs(), lessThan(1));
    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark OpenDyslexic enlarged text has no overflow', (
    tester,
  ) async {
    await pumpBalance(
      tester,
      size: const Size(1024, 1366),
      balance: 120,
      entries: [
        entry(
          id: 'long',
          amount: 10,
          type: StarLedgerEntryType.earned,
          title: 'Missão concluída com sucesso hoje',
          description:
              'Esta descrição mais longa preserva todo o contexto da movimentação.',
        ),
      ],
      darkMode: true,
      openDyslexic: true,
      textScale: 1.4,
    );

    final title = tester.widget<Text>(
      find.byKey(const Key('child-balance-title')),
    );
    expect(title.style?.fontFamily, ZeniTypography.openDyslexicFontFamily);
    expect(
      find.text(
        'Esta descrição mais longa preserva todo o contexto da movimentação.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
