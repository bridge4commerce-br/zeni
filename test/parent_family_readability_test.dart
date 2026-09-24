import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/family/data/models/family.dart';
import 'package:zeni/features/family/data/models/family_member.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_family_tab.dart';

void main() {
  final now = DateTime(2026, 9, 10);
  final family = Family(
    id: 'family',
    name: 'Família Silva',
    inviteCode: 'ZENI-123',
    createdAt: now,
  );
  ChildProfile child(String id, String name, {bool active = true}) =>
      ChildProfile(
        id: id,
        familyId: family.id,
        name: name,
        emoji: '🦊',
        starBalance: 12,
        streakCount: 3,
        isActive: active,
        createdAt: now,
      );

  Future<void> pumpFamily(
    WidgetTester tester, {
    required Size size,
    List<ChildProfile>? children,
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
    VoidCallback? onAdd,
    ValueChanged<ChildProfile>? onRestore,
  }) async {
    final profiles =
        children ??
        [
          child('luna', 'Luna'),
          child('theo', 'Theo'),
          child('archived', 'Bia', active: false),
        ];
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ZeniTheme.light,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: widget!,
        ),
        home: Scaffold(
          body: ParentFamilyTab(
            family: family,
            children: profiles,
            members: [
              FamilyMember(
                id: 'owner',
                familyId: family.id,
                name: 'Gui',
                role: ZeniUserRole.parent,
                isOwner: true,
                createdAt: now,
              ),
            ],
            activeMissions: const [],
            activeRewards: const [],
            ledgerEntries: const [],
            onAddChild: onAdd ?? () {},
            onEditChild: (_) {},
            onArchiveChild: (_) {},
            onRestoreChild: onRestore ?? (_) {},
            onUpdateParentDisplayName: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'uses grouped Family V2 lists and preserves primary and restore callbacks',
    (tester) async {
      var added = 0;
      ChildProfile? restored;
      await pumpFamily(
        tester,
        size: const Size(390, 844),
        onAdd: () => added++,
        onRestore: (item) => restored = item,
      );
      expect(
        find.byKey(const Key('parent-family-single-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('parent-family-children-list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('parent-family-members-list')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Adicionar criança'));
      await tester.tap(find.text('Adicionar criança'));
      expect(added, 1);
      await tester.ensureVisible(find.text('Restaurar criança'));
      await tester.tap(find.text('Restaurar criança'));
      expect(restored?.id, 'archived');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps empty states calm in the shared vertical tablet layout', (
    tester,
  ) async {
    await pumpFamily(tester, size: const Size(1024, 1366), children: const []);
    expect(
      find.byKey(const Key('parent-family-single-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('parent-family-wide-layout')), findsNothing);
    expect(find.text('Nenhuma criança ativa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports OpenDyslexic with larger text without overflow', (
    tester,
  ) async {
    final theme = ZeniTheme.light.copyWith(
      textTheme: ZeniTypography.applyFontFamily(
        ZeniTheme.light.textTheme,
        ZeniTypography.openDyslexicFontFamily,
      ),
    );
    await pumpFamily(
      tester,
      size: const Size(390, 844),
      theme: theme,
      textScaler: const TextScaler.linear(1.35),
    );
    expect(find.text('Família'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
