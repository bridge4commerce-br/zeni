import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_missions_tab.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';

void main() {
  final child = ChildProfile(
    id: 'child-1',
    familyId: 'family-1',
    name: 'Pedro',
    emoji: '⭐',
    starBalance: 0,
    streakCount: 0,
    createdAt: DateTime(2026, 9, 9),
  );
  final mission = Mission(
    id: 'mission-1',
    familyId: 'family-1',
    childId: child.id,
    title: 'Arrumar a cama',
    description: 'Organizar antes do café.',
    stars: 5,
    recurrence: MissionRecurrence.daily,
    timeGroup: MissionTimeGroup.morning,
    approvalMode: MissionApprovalMode.parentApproval,
    status: MissionStatus.active,
    createdAt: DateTime(2026, 9, 9),
    updatedAt: DateTime(2026, 9, 9),
  );

  Future<void> pumpMissions(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ZeniTheme.light,
        home: Scaffold(
          body: ParentMissionsTab(
            activeChildren: [child],
            activeMissions: [mission],
            archivedMissions: const [],
            awaitingLogs: const [],
            childById: (id) => id == child.id ? child : null,
            missionById: (id) => id == mission.id ? mission : null,
            onApproveMission: (_) {},
            onRejectMission: (_) {},
            onApproveMissionBatch: (_) {},
            onRejectMissionBatch: (_) {},
            onEditMission: (_) {},
            onArchiveMission: (_) {},
            onRestoreMission: (_) {},
            onOpenSuggestions: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Text textWidget(Finder finder) => testerWidget(finder);

  testWidgets('mission list preserves compact typography at 390px', (
    tester,
  ) async {
    await pumpMissions(tester, const Size(390, 844));

    expect(textWidget(find.text('Missões ativas')).style?.fontSize, 20);
    expect(textWidget(find.text('Arrumar a cama')).style?.fontSize, 20);
    expect(
      textWidget(find.text('Pedro · 5 estrelas · Manhã')).style?.fontSize,
      14,
    );
    expect(textWidget(find.text('Todas')).style?.fontSize, 15);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mission list increases reading styles at expanded and large widths',
    (tester) async {
      await pumpMissions(tester, const Size(1024, 1366));

      expect(
        textWidget(find.text('Missões ativas')).style?.fontSize,
        closeTo(22.4, .001),
      );
      expect(
        textWidget(find.text('Arrumar a cama')).style?.fontSize,
        closeTo(22.4, .001),
      );
      expect(
        textWidget(find.text('Pedro · 5 estrelas · Manhã')).style?.fontSize,
        closeTo(15.68, .001),
      );
      expect(
        textWidget(find.text('Todas')).style?.fontSize,
        closeTo(16.8, .001),
      );
      expect(tester.takeException(), isNull);

      await pumpMissions(tester, const Size(1366, 1024));

      expect(
        textWidget(find.text('Missões ativas')).style?.fontSize,
        closeTo(22.4, .001),
      );
      expect(
        textWidget(find.text('Arrumar a cama')).style?.fontSize,
        closeTo(22.4, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Text testerWidget(Finder finder) => finder.evaluate().single.widget as Text;
