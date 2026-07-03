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
            onListenToMission: () {},
            onListenToMissionDetails: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('awaiting approval mission shows cancel submission action', (
    tester,
  ) async {
    await pumpSheet(tester, log: awaitingApprovalLog, canUndoCompletion: false);

    expect(find.text('Cancelar envio'), findsOneWidget);
    expect(find.text('Desfazer conclusão'), findsNothing);
  });

  testWidgets('approved automatic mission can show undo action', (
    tester,
  ) async {
    await pumpSheet(tester, log: approvedLog, canUndoCompletion: true);

    expect(find.text('Desfazer conclusão'), findsOneWidget);
  });
}
