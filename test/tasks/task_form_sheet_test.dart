import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:zeni/core/widgets/layout/zeni_modal_sheet_container.dart';

void main() {
  final child = ChildProfile(
    id: 'child-1',
    familyId: 'family-1',
    name: 'Luna',
    emoji: '⭐',
    starBalance: 0,
    streakCount: 0,
    createdAt: DateTime(2026, 9, 8),
  );

  final legacyMission = Mission(
    id: 'mission-1',
    familyId: 'family-1',
    childId: child.id,
    title: 'Arrumar a cama',
    description: '',
    emoji: '🛏️',
    stars: 5,
    recurrence: MissionRecurrence.daily,
    timeGroup: MissionTimeGroup.morning,
    approvalMode: MissionApprovalMode.parentApproval,
    requiresPhoto: true,
    status: MissionStatus.active,
    createdAt: DateTime(2026, 9, 8),
    updatedAt: DateTime(2026, 9, 8),
  );

  final photoFreeMission = legacyMission.copyWith(requiresPhoto: false);

  Future<void> openForm(
    WidgetTester tester, {
    Mission? initialMission,
    required ValueChanged<TaskFormResult?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                onResult(
                  await showModalBottomSheet<TaskFormResult>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TaskFormSheet(
                      children: [child],
                      initialMission: initialMission,
                    ),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('photo option is disabled and new missions save without it', (
    tester,
  ) async {
    TaskFormResult? result;
    await openForm(tester, onResult: (value) => result = value);

    expect(find.text('Pedir foto'), findsOneWidget);
    expect(find.textContaining('Em breve:'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.enterText(find.byType(TextField).first, 'Ler um livro');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Criar missão').last,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ZeniModalSheetContainer),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Criar missão').last);
    await tester.pumpAndSettle();

    expect(result?.requiresPhoto, isFalse);
  });

  testWidgets('editing a legacy photo mission keeps it valid and saves true', (
    tester,
  ) async {
    expect(legacyMission.requiresPhoto, isTrue);
    TaskFormResult? result;
    await openForm(
      tester,
      initialMission: legacyMission,
      onResult: (value) => result = value,
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.scrollUntilVisible(
      find.text('Salvar missão'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ZeniModalSheetContainer),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Salvar missão'));
    await tester.pumpAndSettle();

    expect(legacyMission.requiresPhoto, isTrue);
    expect(result?.requiresPhoto, isTrue);
  });

  testWidgets('editing a mission without photo keeps it without photo', (
    tester,
  ) async {
    TaskFormResult? result;
    await openForm(
      tester,
      initialMission: photoFreeMission,
      onResult: (value) => result = value,
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.scrollUntilVisible(
      find.text('Salvar missão'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ZeniModalSheetContainer),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Salvar missão'));
    await tester.pumpAndSettle();

    expect(result?.requiresPhoto, isFalse);
  });
}
