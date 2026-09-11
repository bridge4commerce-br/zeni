import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';
import 'package:zeni/features/tasks/presentation/widgets/task_child_detail_sheet.dart';

void main() {
  final automaticMission = Mission(
    id: 'mission-auto',
    familyId: 'family-1',
    childId: 'child-1',
    title: 'Escovar os dentes',
    description: 'Escove depois do café da manhã.',
    emoji: '🪥',
    stars: 5,
    recurrence: MissionRecurrence.daily,
    timeGroup: MissionTimeGroup.morning,
    approvalMode: MissionApprovalMode.automatic,
    status: MissionStatus.active,
    createdAt: DateTime(2026, 6, 17, 8),
    updatedAt: DateTime(2026, 6, 17, 8),
  );

  final awaitingApprovalLog = MissionLog(
    id: 'log-awaiting',
    missionId: automaticMission.id,
    childId: 'child-1',
    scheduledDate: DateTime(2026, 6, 17),
    status: MissionLogStatus.awaitingApproval,
    starsAwarded: automaticMission.stars,
  );

  final approvedLog = MissionLog(
    id: 'log-approved',
    missionId: automaticMission.id,
    childId: 'child-1',
    scheduledDate: DateTime(2026, 6, 17),
    status: MissionLogStatus.approved,
    starsAwarded: automaticMission.stars,
    completedAt: DateTime(2026, 6, 17, 8),
    approvedAt: DateTime(2026, 6, 17, 8),
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required MissionLog? log,
    required bool canUndoCompletion,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskChildDetailSheet(
            mission: automaticMission,
            log: log,
            canUndoCompletion: canUndoCompletion,
            onListenToMissionDetails: () {},
          ),
        ),
      ),
    );
  }

  Future<void> pumpModal(
    WidgetTester tester, {
    required Size size,
    required MissionLog? log,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskChildDetailModal(
                context: context,
                mission: automaticMission,
                log: log,
                onListenToMissionDetails: () {},
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

  testWidgets('awaiting approval mission is read only for the child', (
    tester,
  ) async {
    await pumpSheet(tester, log: awaitingApprovalLog, canUndoCompletion: false);

    expect(find.text('Enviada para o responsável aprovar.'), findsOneWidget);
    expect(find.text('Cancelar envio'), findsNothing);
    expect(find.text('Concluir missão'), findsNothing);
    expect(find.text('Desfazer conclusão'), findsNothing);
  });

  testWidgets('approved automatic mission can show undo action', (
    tester,
  ) async {
    await pumpSheet(tester, log: approvedLog, canUndoCompletion: true);

    expect(find.text('Desfazer conclusão'), findsOneWidget);
  });

  testWidgets('child details keep only action-relevant metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskChildDetailSheet(
            mission: automaticMission.copyWith(requiresPhoto: true),
            onListenToMissionDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('5 estrelas'), findsOneWidget);
    expect(find.text('Manhã'), findsOneWidget);
    expect(find.text('Todos os dias'), findsNothing);
    expect(find.text('Pode pedir foto'), findsNothing);
  });

  testWidgets('automatic mission completes directly from its detail', (
    tester,
  ) async {
    TaskChildDetailResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTaskChildDetailModal(
                  context: context,
                  mission: automaticMission,
                  onListenToMissionDetails: () {},
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
    final completeMission = find.text('Concluir missão');
    await tester.ensureVisible(completeMission);
    await tester.pumpAndSettle();
    await tester.tap(completeMission);
    await tester.pumpAndSettle();

    expect(result?.action, TaskChildDetailAction.complete);
    expect(result?.note, isNull);
  });

  testWidgets('approval mission sends an expanded optional note directly', (
    tester,
  ) async {
    TaskChildDetailResult? result;
    final approvalMission = automaticMission.copyWith(
      approvalMode: MissionApprovalMode.parentApproval,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTaskChildDetailModal(
                  context: context,
                  mission: approvalMission,
                  onListenToMissionDetails: () {},
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
    final addNote = find.text('Adicionar observação');
    await tester.ensureVisible(addNote);
    await tester.pumpAndSettle();
    await tester.tap(addNote);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fiz antes da escola.');
    await tester.ensureVisible(find.text('Enviar para aprovação'));
    await tester.tap(find.text('Enviar para aprovação'));
    await tester.pumpAndSettle();

    expect(result?.action, TaskChildDetailAction.complete);
    expect(result?.note, 'Fiz antes da escola.');
  });

  testWidgets('dismissing the detail does not request completion', (
    tester,
  ) async {
    TaskChildDetailResult? result;
    var dismissCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTaskChildDetailModal(
                  context: context,
                  mission: automaticMission,
                  onListenToMissionDetails: () {},
                  onDismiss: () async => dismissCalls++,
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
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(dismissCalls, 1);
  });

  testWidgets('listen action exposes semantics and keeps its callback', (
    tester,
  ) async {
    var detailSpeechCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskChildDetailSheet(
            mission: automaticMission,
            onListenToMissionDetails: () => detailSpeechCalls++,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ouvir missão'), findsOneWidget);
    await tester.tap(find.text('Ouvir missão'));

    expect(detailSpeechCalls, 1);
    expect(find.text('Ouvir resumo'), findsNothing);
  });

  testWidgets('long titles remain scrollable with larger OpenDyslexic text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longTitle =
        'Organizar todos os brinquedos e livros antes de dormir hoje';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'OpenDyslexic',
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: TaskChildDetailSheet(
            mission: automaticMission.copyWith(title: longTitle),
            onListenToMissionDetails: () {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Concluir missão'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(longTitle), findsOneWidget);
    expect(find.text('Concluir missão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a bottom sheet in compact windows', (tester) async {
    await pumpModal(tester, size: const Size(390, 844), log: null);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Concluir missão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a centered dialog in expanded and large windows', (
    tester,
  ) async {
    for (final size in const [Size(1024, 1366), Size(1366, 1024)]) {
      await pumpModal(tester, size: size, log: awaitingApprovalLog);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Enviada para o responsável aprovar.'), findsOneWidget);
      expect(find.text('Concluir missão'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
    }
  });
}
