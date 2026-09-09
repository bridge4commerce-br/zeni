import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/presentation/widgets/task_completion_sheet.dart';

void main() {
  final mission = Mission(
    id: 'mission-1',
    familyId: 'family-1',
    childId: 'child-1',
    title: 'Organizar os brinquedos',
    description: 'Guarde todos os brinquedos antes do jantar.',
    emoji: '🧸',
    stars: 10,
    recurrence: MissionRecurrence.daily,
    timeGroup: MissionTimeGroup.evening,
    approvalMode: MissionApprovalMode.parentApproval,
    requiresPhoto: true,
    status: MissionStatus.active,
    createdAt: DateTime(2026, 9, 8),
    updatedAt: DateTime(2026, 9, 8),
  );

  Future<void> pumpModal(
    WidgetTester tester, {
    required Size size,
    Mission? shownMission,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    final modalMission = shownMission ?? mission;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskCompletionModal(
                context: context,
                mission: modalMission,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('completion sheet scrolls on a small screen with larger text', (
    tester,
  ) async {
    await pumpModal(
      tester,
      size: const Size(390, 844),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Enviar para aprovação'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Enviar para aprovação'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cancelar'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Foto recomendada'), findsNothing);
    expect(find.text('Foto da missão'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completion uses a scrollable dialog on tablet sizes', (
    tester,
  ) async {
    for (final size in const [Size(1024, 1366), Size(1366, 1024)]) {
      await pumpModal(
        tester,
        size: size,
        textScaler: const TextScaler.linear(1.3),
      );

      expect(find.byType(Dialog), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Enviar para aprovação'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Enviar para aprovação'), findsOneWidget);
      expect(
        find.text(
          'Foto ainda não disponível nesta versão. Você pode concluir a missão normalmente.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('normal missions do not show photo availability information', (
    tester,
  ) async {
    await pumpModal(
      tester,
      size: const Size(390, 844),
      shownMission: mission.copyWith(requiresPhoto: false),
    );

    expect(
      find.text(
        'Foto ainda não disponível nesta versão. Você pode concluir a missão normalmente.',
      ),
      findsNothing,
    );
  });
}
