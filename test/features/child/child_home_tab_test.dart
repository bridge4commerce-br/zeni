import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/core/widgets/base/zeni_surface.dart';
import 'package:zeni/core/widgets/zeni_mascot.dart';
import 'package:zeni/features/child/presentation/widgets/child_home_tab.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
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

  Mission mission(
    String id,
    String title, {
    MissionTimeGroup timeGroup = MissionTimeGroup.morning,
    MissionApprovalMode approvalMode = MissionApprovalMode.automatic,
  }) => Mission(
    id: id,
    familyId: 'family-1',
    childId: child.id,
    title: title,
    description: '',
    stars: 5,
    recurrence: MissionRecurrence.daily,
    timeGroup: timeGroup,
    approvalMode: approvalMode,
    status: MissionStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  Reward reward(String id, String title, {int cost = 25}) => Reward(
    id: id,
    familyId: 'family-1',
    childId: child.id,
    title: title,
    description: '',
    cost: cost,
    renewal: RewardRenewal.once,
    createdAt: now,
    updatedAt: now,
  );

  Widget home({
    List<Mission> missions = const [],
    List<MissionLog> logs = const [],
    List<Reward> rewards = const [],
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      theme: theme,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: widget!,
      ),
      home: ChildHomeTab(
        child: child,
        missions: missions,
        todayLogs: logs,
        rewards: rewards,
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

  Future<void> pumpHomeAt(
    WidgetTester tester, {
    required Size size,
    List<Mission> missions = const [],
    List<MissionLog> logs = const [],
    List<Reward> rewards = const [],
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      home(
        missions: missions,
        logs: logs,
        rewards: rewards,
        theme: theme,
        textScaler: textScaler,
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

    expect(find.text('Agora'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);
    expect(find.text('Vamos nessa! ⭐'), findsOneWidget);
    expect(find.text('Falta só essa! 💚'), findsNothing);
    expect(find.text('+5 estrelas'), findsOneWidget);
    expect(find.text('Ver missão'), findsOneWidget);
    expect(find.byKey(const Key('child-home-balance')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot && widget.state == ZeniMascotState.encourage,
      ),
      findsOneWidget,
    );

    final openMissionButton = find.text('Ver missão');
    await tester.ensureVisible(openMissionButton);
    await tester.tap(openMissionButton);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da missão'), findsOneWidget);
  });

  test('orders current-period missions before past and future periods', () {
    final ordered = orderChildHomePendingMissions(
      localNow: DateTime(2026, 9, 7, 13, 35),
      missions: [
        mission('bed', 'Cama', timeGroup: MissionTimeGroup.morning),
        mission('lunch', 'Almoço', timeGroup: MissionTimeGroup.afternoon),
        mission('homework', 'Lição', timeGroup: MissionTimeGroup.afternoon),
        mission('bag', 'Mochila', timeGroup: MissionTimeGroup.evening),
      ],
    );

    expect(ordered.map((item) => item.id), ['lunch', 'homework', 'bed', 'bag']);
  });

  test('keeps anytime missions predictably after the current period', () {
    final ordered = orderChildHomePendingMissions(
      localNow: DateTime(2026, 9, 7, 13),
      missions: [
        mission('any', 'Qualquer horário', timeGroup: MissionTimeGroup.anytime),
        mission('morning', 'Manhã', timeGroup: MissionTimeGroup.morning),
        mission('afternoon', 'Tarde', timeGroup: MissionTimeGroup.afternoon),
        mission('evening', 'Noite', timeGroup: MissionTimeGroup.evening),
      ],
    );

    expect(ordered.map((item) => item.id), [
      'afternoon',
      'any',
      'morning',
      'evening',
    ]);
  });

  testWidgets('uses the singular encouragement for one pending mission', (
    tester,
  ) async {
    await tester.pumpWidget(home(missions: [mission('one', 'Arrumar a cama')]));

    expect(find.text('Falta só essa! 💚'), findsOneWidget);
    expect(find.text('Vamos nessa! ⭐'), findsNothing);
  });

  testWidgets('current mission explains when a guardian will review it', (
    tester,
  ) async {
    await tester.pumpWidget(
      home(
        missions: [
          mission(
            'one',
            'Arrumar a cama',
            approvalMode: MissionApprovalMode.parentApproval,
          ),
        ],
      ),
    );

    expect(find.text('O responsável confere depois'), findsOneWidget);
    expect(find.text('Ver missão'), findsOneWidget);
  });

  testWidgets('preserves achievement feedback when all missions are complete', (
    tester,
  ) async {
    final item = mission('one', 'Arrumar a cama');
    final log = MissionLog(
      id: 'log-1',
      missionId: item.id,
      childId: child.id,
      scheduledDate: now,
      status: MissionLogStatus.approved,
      starsAwarded: item.stars,
    );
    await tester.pumpWidget(home(missions: [item], logs: [log]));

    expect(find.text('Seu dia está completo! 🎉'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot && widget.state == ZeniMascotState.achievement,
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
    expect(find.text('Aguardando aprovação'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsOneWidget);
    expect(find.text('Aguardando o responsável'), findsOneWidget);
    expect(find.byKey(const Key('child-home-current-mission')), findsNothing);
    expect(find.text('Ver missão'), findsNothing);
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
    expect(find.text('Hoje está tranquilo por aqui.'), findsOneWidget);
    expect(find.textContaining('0 de 0'), findsNothing);
    expect(find.byKey(const Key('child-home-empty-state')), findsOneWidget);
    // Saldo + companion + conteúdo vazio usam as três surfaces semânticas.
    expect(find.byType(ZeniSurface), findsNWidgets(3));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ZeniMascot && widget.state == ZeniMascotState.sleeping,
      ),
      findsOneWidget,
    );
  });

  testWidgets('reward progress uses the child operational balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      home(rewards: [reward('ice-cream', 'Sorvete', cost: 25)]),
    );

    expect(find.text('Mimo no horizonte'), findsOneWidget);
    expect(find.text('Faltam 13 estrelas para chegar lá.'), findsOneWidget);
    expect(find.byKey(const Key('child-home-reward-progress')), findsOneWidget);
  });

  testWidgets('empty day mounts in dark mode with larger text', (tester) async {
    await pumpHomeAt(
      tester,
      size: const Size(390, 844),
      theme: ZeniTheme.dark,
      textScaler: const TextScaler.linear(1.35),
    );

    expect(find.text('Sem missões por enquanto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact supports OpenDyslexic with larger text', (tester) async {
    final dyslexicTheme = ZeniTheme.light.copyWith(
      textTheme: ZeniTypography.applyFontFamily(
        ZeniTheme.light.textTheme,
        ZeniTypography.openDyslexicFontFamily,
      ),
    );

    await pumpHomeAt(
      tester,
      size: const Size(390, 844),
      missions: [mission('one', 'Organizar os materiais da escola')],
      theme: dyslexicTheme,
      textScaler: const TextScaler.linear(1.35),
    );

    final greeting = tester.widget<Text>(
      find.textContaining('Vamos cuidar do seu dia?'),
    );
    expect(greeting.style?.fontFamily, ZeniTypography.openDyslexicFontFamily);
    expect(find.text('Ver missão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact keeps the summary vertical and missions below it', (
    tester,
  ) async {
    final missions = [
      mission('one', 'Arrumar a cama'),
      mission('two', 'Guardar os livros'),
    ];

    await pumpHomeAt(tester, size: const Size(390, 844), missions: missions);

    expect(find.byKey(const Key('child-home-summary-row')), findsNothing);
    expect(find.text('Agora'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanded home keeps summary side by side and missions vertical',
    (tester) async {
      final missions = [
        mission('one', 'Arrumar a cama'),
        mission('two', 'Guardar os livros'),
      ];

      await pumpHomeAt(
        tester,
        size: const Size(1024, 1366),
        missions: missions,
      );

      expect(find.byKey(const Key('child-home-balance')), findsOneWidget);
      final companion = tester.getRect(
        find.byKey(const Key('child-home-companion')),
      );
      final progress = tester.getRect(
        find.byKey(const Key('child-home-day-progress')),
      );
      final currentMission = tester.getRect(
        find.byKey(const Key('child-home-current-mission')),
      );
      expect(find.byKey(const Key('child-home-summary-row')), findsOneWidget);
      expect(progress.left, greaterThan(companion.left));
      expect((progress.top - companion.top).abs(), lessThan(1));
      expect(currentMission.top, greaterThan(companion.bottom));
      expect(find.text('Depois'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large home uses primary and secondary columns with approval accessible',
    (tester) async {
      final item = mission('one', 'Arrumar a cama');
      final log = MissionLog(
        id: 'log-1',
        missionId: item.id,
        childId: child.id,
        scheduledDate: now,
        status: MissionLogStatus.awaitingApproval,
        starsAwarded: 0,
      );
      await pumpHomeAt(
        tester,
        size: const Size(1366, 1024),
        missions: [item],
        logs: [log],
        textScaler: const TextScaler.linear(1.2),
      );

      expect(find.byKey(const Key('child-home-balance')), findsOneWidget);
      final primary = tester.getRect(
        find.byKey(const Key('child-home-primary-column')),
      );
      final secondary = tester.getRect(
        find.byKey(const Key('child-home-secondary-column')),
      );
      expect(
        find.byKey(const Key('child-home-landscape-layout')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('child-home-summary-row')), findsNothing);
      expect(secondary.left, greaterThan(primary.left));
      expect(find.text('Aguardando aprovação'), findsOneWidget);
      expect(find.text('Aguardando o responsável'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
