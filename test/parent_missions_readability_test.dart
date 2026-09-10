import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_mission_card.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_missions_tab.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';

void main() {
  final now = DateTime(2026, 9, 9);
  final luna = ChildProfile(
    id: 'child-luna',
    familyId: 'family-1',
    name: 'Luna',
    emoji: '🦊',
    starBalance: 0,
    streakCount: 0,
    createdAt: now,
  );
  final theo = ChildProfile(
    id: 'child-theo',
    familyId: 'family-1',
    name: 'Theo',
    emoji: '🦁',
    starBalance: 0,
    streakCount: 0,
    createdAt: now,
  );

  Mission mission({
    required String id,
    required ChildProfile child,
    required String title,
    MissionRecurrence recurrence = MissionRecurrence.daily,
    MissionTimeGroup timeGroup = MissionTimeGroup.morning,
    MissionApprovalMode approvalMode = MissionApprovalMode.parentApproval,
    MissionStatus status = MissionStatus.active,
  }) => Mission(
    id: id,
    familyId: 'family-1',
    childId: child.id,
    title: title,
    description: 'Descrição da missão.',
    emoji: '✅',
    stars: 5,
    recurrence: recurrence,
    timeGroup: timeGroup,
    approvalMode: approvalMode,
    status: status,
    createdAt: now,
    updatedAt: now,
  );

  MissionLog awaitingLog(Mission item) => MissionLog(
    id: 'log-${item.id}',
    missionId: item.id,
    childId: item.childId,
    scheduledDate: now,
    status: MissionLogStatus.awaitingApproval,
    starsAwarded: item.stars,
  );

  late Mission lunaMission;
  late Mission theoMission;
  late Mission archivedMission;

  setUp(() {
    lunaMission = mission(
      id: 'mission-luna',
      child: luna,
      title: 'Arrumar a cama',
    );
    theoMission = mission(
      id: 'mission-theo',
      child: theo,
      title: 'Ler antes de dormir',
      recurrence: MissionRecurrence.weekdays,
      timeGroup: MissionTimeGroup.evening,
      approvalMode: MissionApprovalMode.automatic,
    );
    archivedMission = mission(
      id: 'mission-archived',
      child: luna,
      title: 'Guardar os brinquedos',
      status: MissionStatus.archived,
    );
  });

  Future<void> pumpMissions(
    WidgetTester tester, {
    required Size size,
    List<ChildProfile>? children,
    List<Mission>? activeMissions,
    List<Mission>? archivedMissions,
    List<MissionLog>? awaitingLogs,
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
    ValueChanged<MissionLog>? onApproveMission,
    ValueChanged<MissionLog>? onRejectMission,
    ValueChanged<List<MissionLog>>? onApproveMissionBatch,
    ValueChanged<List<MissionLog>>? onRejectMissionBatch,
    ValueChanged<Mission>? onEditMission,
    ValueChanged<Mission>? onArchiveMission,
    ValueChanged<Mission>? onRestoreMission,
    VoidCallback? onOpenSuggestions,
  }) async {
    final resolvedChildren = children ?? [luna, theo];
    final resolvedActiveMissions = activeMissions ?? [lunaMission, theoMission];
    final resolvedArchivedMissions = archivedMissions ?? [archivedMission];
    final resolvedAwaitingLogs = awaitingLogs ?? [awaitingLog(lunaMission)];
    final allMissions = [
      ...resolvedActiveMissions,
      ...resolvedArchivedMissions,
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
          body: ParentMissionsTab(
            activeChildren: resolvedChildren,
            activeMissions: resolvedActiveMissions,
            archivedMissions: resolvedArchivedMissions,
            awaitingLogs: resolvedAwaitingLogs,
            childById: (id) =>
                resolvedChildren.where((child) => child.id == id).firstOrNull,
            missionById: (id) =>
                allMissions.where((item) => item.id == id).firstOrNull,
            onApproveMission: onApproveMission ?? (_) {},
            onRejectMission: onRejectMission ?? (_) {},
            onApproveMissionBatch: onApproveMissionBatch ?? (_) {},
            onRejectMissionBatch: onRejectMissionBatch ?? (_) {},
            onEditMission: onEditMission ?? (_) {},
            onArchiveMission: onArchiveMission ?? (_) {},
            onRestoreMission: onRestoreMission ?? (_) {},
            onOpenSuggestions: onOpenSuggestions ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact keeps the operational sequence in one column', (
    tester,
  ) async {
    await pumpMissions(tester, size: const Size(390, 844));

    expect(
      find.byKey(const Key('parent-missions-single-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('parent-missions-split-layout')), findsNothing);
    expect(find.byType(ParentMissionCard), findsNWidgets(2));
    expect(find.text('Luna · 5 estrelas'), findsWidgets);
    expect(
      find.text('Todos os dias · Manhã · Aprovação do responsável'),
      findsOneWidget,
    );

    final pending = tester.getTopLeft(
      find.byKey(const Key('parent-missions-pending-panel')),
    );
    final active = tester.getTopLeft(
      find.byKey(const Key('parent-missions-active-list')),
    );
    final suggestions = tester.getTopLeft(
      find.byKey(const Key('parent-missions-suggestions')),
    );
    final archived = tester.getTopLeft(
      find.byKey(const Key('parent-missions-archived-toggle')),
    );
    expect(active.dy, greaterThan(pending.dy));
    expect(suggestions.dy, greaterThan(active.dy));
    expect(archived.dy, greaterThan(suggestions.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium keeps a readable single-column composition', (
    tester,
  ) async {
    await pumpMissions(tester, size: const Size(700, 1024));

    expect(
      find.byKey(const Key('parent-missions-single-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('parent-missions-split-layout')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('parent-missions-active-list')))
          .width,
      lessThanOrEqualTo(700),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanded portrait stacks pending work before mission maintenance',
    (tester) async {
      await pumpMissions(tester, size: const Size(1024, 1366));

      expect(
        find.byKey(const Key('parent-missions-single-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('parent-missions-split-layout')),
        findsNothing,
      );
      final pending = tester.getRect(
        find.byKey(const Key('parent-missions-pending-panel')),
      );
      final catalog = tester.getRect(
        find.byKey(const Key('parent-missions-catalog-panel')),
      );
      expect(catalog.top, greaterThan(pending.bottom));
      expect((pending.left - catalog.left).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expanded landscape separates pending work from mission maintenance',
    (tester) async {
      await pumpMissions(tester, size: const Size(1024, 800));

      expect(
        find.byKey(const Key('parent-missions-split-layout')),
        findsOneWidget,
      );
      final pending = tester.getRect(
        find.byKey(const Key('parent-missions-pending-panel')),
      );
      final catalog = tester.getRect(
        find.byKey(const Key('parent-missions-catalog-panel')),
      );
      expect(pending.left, lessThan(catalog.left));
      expect((pending.top - catalog.top).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expanded gives the catalog full width without pending work', (
    tester,
  ) async {
    await pumpMissions(
      tester,
      size: const Size(1024, 1366),
      awaitingLogs: const [],
    );

    expect(find.byKey(const Key('parent-missions-split-layout')), findsNothing);
    expect(
      find.byKey(const Key('parent-missions-single-layout')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('parent-missions-active-list')))
          .width,
      greaterThan(800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large keeps the dashboard frame bounded and uses two panels', (
    tester,
  ) async {
    await pumpMissions(tester, size: const Size(1366, 1024));

    expect(
      find.byKey(const Key('parent-missions-split-layout')),
      findsOneWidget,
    );
    final splitWidth = tester
        .getSize(find.byKey(const Key('parent-missions-split-layout')))
        .width;
    expect(splitWidth, lessThanOrEqualTo(1200));
    expect(splitWidth, greaterThan(1100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger OpenDyslexic text remains complete without overflow', (
    tester,
  ) async {
    final dyslexicTheme = ZeniTheme.light.copyWith(
      textTheme: ZeniTypography.applyFontFamily(
        ZeniTheme.light.textTheme,
        ZeniTypography.openDyslexicFontFamily,
      ),
    );

    await pumpMissions(
      tester,
      size: const Size(390, 844),
      theme: dyslexicTheme,
      textScaler: const TextScaler.linear(1.35),
    );

    final title = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('parent-mission-mission-luna')),
        matching: find.text('Arrumar a cama'),
      ),
    );
    expect(title.style?.fontFamily, ZeniTypography.openDyslexicFontFamily);
    expect(find.text('Aprovação do responsável'), findsNothing);
    expect(
      find.text('Todos os dias · Manhã · Aprovação do responsável'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty lists use calm inline states', (tester) async {
    await pumpMissions(
      tester,
      size: const Size(390, 844),
      activeMissions: const [],
      archivedMissions: const [],
      awaitingLogs: const [],
    );

    expect(find.text('Nada pendente agora'), findsOneWidget);
    expect(find.text('Nenhuma missão aguardando você.'), findsNothing);
    expect(find.text('Nenhuma missão'), findsOneWidget);
    expect(find.text('Sugestões para sua família'), findsOneWidget);
    final pending = tester.getRect(
      find.byKey(const Key('parent-missions-pending-panel')),
    );
    final catalog = tester.getRect(
      find.byKey(const Key('parent-missions-catalog-panel')),
    );
    expect(catalog.top - pending.bottom, lessThanOrEqualTo(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('child filters update pending active and archived content', (
    tester,
  ) async {
    await pumpMissions(tester, size: const Size(390, 844));

    await tester.tap(find.text('Theo'));
    await tester.pumpAndSettle();

    expect(find.text('Ler antes de dormir'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsNothing);
    expect(find.text('Nada pendente agora'), findsOneWidget);
    expect(find.text('1 missão ativa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mission actions preserve edit archive and restore callbacks', (
    tester,
  ) async {
    Mission? edited;
    Mission? archived;
    Mission? restored;
    await pumpMissions(
      tester,
      size: const Size(390, 844),
      onEditMission: (mission) => edited = mission,
      onArchiveMission: (mission) => archived = mission,
      onRestoreMission: (mission) => restored = mission,
    );

    final actions = find.byKey(
      const Key('parent-mission-actions-mission-luna'),
    );
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar missão'));
    await tester.pumpAndSettle();
    expect(edited?.id, lunaMission.id);

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar missão'));
    await tester.pumpAndSettle();
    expect(archived?.id, lunaMission.id);

    await tester.ensureVisible(
      find.byKey(const Key('parent-missions-archived-toggle')),
    );
    await tester.tap(find.byKey(const Key('parent-missions-archived-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Restaurar missão'));
    await tester.tap(find.byTooltip('Restaurar missão'));
    expect(restored?.id, archivedMission.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection mode preserves batch approval behavior', (
    tester,
  ) async {
    List<MissionLog>? approved;
    await pumpMissions(
      tester,
      size: const Size(390, 844),
      onApproveMissionBatch: (logs) => approved = logs,
    );

    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('parent-mission-approval-log-mission-luna')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('parent-missions-batch-actions')),
      findsOneWidget,
    );
    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(approved?.single.id, 'log-mission-luna');
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggestions entry preserves the Smart Content callback', (
    tester,
  ) async {
    var calls = 0;
    await pumpMissions(
      tester,
      size: const Size(390, 844),
      onOpenSuggestions: () => calls += 1,
    );

    await tester.ensureVisible(
      find.byKey(const Key('parent-missions-suggestions')),
    );
    await tester.tap(find.byKey(const Key('parent-missions-suggestions')));
    expect(calls, 1);
  });

  testWidgets('approval uses a dialog on expanded layouts', (tester) async {
    await pumpMissions(tester, size: const Size(1024, 1366));

    await tester.tap(
      find.byKey(const Key('parent-mission-approval-log-mission-luna')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Aprovar missão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approval remains a bottom sheet on compact layouts', (
    tester,
  ) async {
    await pumpMissions(tester, size: const Size(390, 844));

    await tester.tap(
      find.byKey(const Key('parent-mission-approval-log-mission-luna')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Aprovar missão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
