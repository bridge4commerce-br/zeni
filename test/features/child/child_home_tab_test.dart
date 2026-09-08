import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/widgets/zeni_mascot.dart';
import 'package:zeni/features/child/presentation/widgets/child_home_tab.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';

void main() {
  final now = DateTime(2026, 9, 7);
  final child = ChildProfile(
    id: 'child-1',
    familyId: 'family-1',
    name: 'Luna',
    emoji: '🦊',
    starBalance: 12,
    streakCount: 0,
    createdAt: now,
  );

  Mission mission(String id, String title) => Mission(
    id: id,
    familyId: 'family-1',
    childId: child.id,
    title: title,
    description: '',
    stars: 5,
    recurrence: MissionRecurrence.daily,
    timeGroup: MissionTimeGroup.morning,
    approvalMode: MissionApprovalMode.automatic,
    status: MissionStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  Widget home({
    List<Mission> missions = const [],
    List<MissionLog> logs = const [],
  }) {
    return MaterialApp(
      home: ChildHomeTab(
        child: child,
        missions: missions,
        todayLogs: logs,
        rewards: const [],
        pendingRewardRequests: const [],
        logForMission: (id) =>
            logs.where((log) => log.missionId == id).firstOrNull,
        missionAnchorKeyFor: (_) => GlobalKey(),
        onCompleteMission: (_, _, _) {},
        onCancelMissionSubmission: (_, _) {},
        onUndoMissionCompletion: (_, _) {},
        onListenToMission: (_) {},
        onListenToMissionDetails: (_, _) {},
        canListenToMission: false,
        onOpenRewards: () {},
      ),
    );
  }

  testWidgets('shows the first pending mission as the current mission', (
    tester,
  ) async {
    await tester.pumpWidget(
      home(
        missions: [
          mission('one', 'Arrumar a cama'),
          mission('two', 'Guardar os livros'),
        ],
      ),
    );

    expect(find.text('Missão de agora'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot && widget.state == ZeniMascotState.encourage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses waiting approval mascot state and day progress', (
    tester,
  ) async {
    final item = mission('one', 'Arrumar a cama');
    final log = MissionLog(
      id: 'log-1',
      missionId: item.id,
      childId: child.id,
      scheduledDate: now,
      status: MissionLogStatus.awaitingApproval,
      starsAwarded: 0,
    );
    await tester.pumpWidget(home(missions: [item], logs: [log]));

    expect(find.text('1 aguardando aprovação'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot &&
            widget.state == ZeniMascotState.waitingApproval,
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses a friendly empty day without 0 of 0 progress', (
    tester,
  ) async {
    await tester.pumpWidget(home());

    expect(find.text('Sem missões por enquanto'), findsOneWidget);
    expect(find.textContaining('0 de 0'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot && widget.state == ZeniMascotState.sleeping,
      ),
      findsOneWidget,
    );
  });
}
