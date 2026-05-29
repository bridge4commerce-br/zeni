import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/core/accessibility/zeni_accessibility_settings.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/local/parent_biometric_auth.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/auth/presentation/widgets/auth_provider_button.dart';
import 'package:zeni/features/child/presentation/pages/child_shell_page.dart';
import 'package:zeni/core/widgets/zeni_flying_star_overlay.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_settings_tab.dart';
import 'package:zeni/features/rewards/presentation/widgets/reward_compact_child_card.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/sync/data/models/cloud_consistency_diagnostic.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/presentation/widgets/task_compact_child_card.dart';

void main() {
  Future<void> openParentSettings(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
  }

  void seedMockAppState() {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
    });
  }

  void seedMockAppStateWith(ZeniAppState state) {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(state.toJson()),
    });
  }

  Widget buildStaticSettingsHarness({
    required ZeniAuthState authState,
    AppSettings appSettings = const AppSettings(),
    bool isSupabaseConfigured = true,
    RemoteFamilySummary? remoteFamilySummary,
    Future<ZeniUpdateRemoteFamilyResult> Function({
      required String familyId,
      required String name,
    })?
    onUpdateRemoteFamilyName,
    int localChildrenCount = 2,
    int? remoteChildrenCount,
    int localMissionsCount = 3,
    int? remoteMissionsCount,
    int localRewardsCount = 2,
    int? remoteRewardsCount,
    int localMissionLogsCount = 0,
    int? remoteMissionLogsCount,
    int localRewardRequestsCount = 0,
    int? remoteRewardRequestsCount,
    int localStarLedgerCount = 0,
    int? remoteStarLedgerCount,
    List<ChildBalanceDiagnostic> childBalanceDiagnostics =
        const <ChildBalanceDiagnostic>[],
    bool hasRemoteChildBalanceData = false,
    CloudConsistencyDiagnostic? cloudConsistencyDiagnostic,
    String? cloudConsistencyErrorText,
    Future<ZeniCloudSyncResult> Function()? onSyncCloudData,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ParentSettingsTab(
          appSettings: appSettings,
          accessibilitySettings: const ZeniAccessibilitySettings(),
          onThemeModeChanged: (_) {},
          onDyslexiaFontChanged: (_) {},
          onTextScaleChanged: (_) {},
          onVibrationChanged: (_) {},
          onNotificationsChanged: (_) {},
          onTtsChanged: (_) {},
          onReadAloudByChildProfileChanged: (_) {},
          onConfigurePin: () {},
          onBiometricsChanged: (_) {},
          authState: authState,
          remoteFamilySummary: remoteFamilySummary,
          localChildrenCount: localChildrenCount,
          remoteChildrenCount: remoteChildrenCount,
          localMissionsCount: localMissionsCount,
          remoteMissionsCount: remoteMissionsCount,
          localRewardsCount: localRewardsCount,
          remoteRewardsCount: remoteRewardsCount,
          localMissionLogsCount: localMissionLogsCount,
          remoteMissionLogsCount: remoteMissionLogsCount,
          localRewardRequestsCount: localRewardRequestsCount,
          remoteRewardRequestsCount: remoteRewardRequestsCount,
          localStarLedgerCount: localStarLedgerCount,
          remoteStarLedgerCount: remoteStarLedgerCount,
          childBalanceDiagnostics: childBalanceDiagnostics,
          hasRemoteChildBalanceData: hasRemoteChildBalanceData,
          cloudConsistencyDiagnostic: cloudConsistencyDiagnostic,
          cloudConsistencyErrorText: cloudConsistencyErrorText,
          lastChildrenSyncAt: appSettings.lastChildrenSyncAt,
          lastMissionsSyncAt: appSettings.lastMissionsSyncAt,
          lastRewardsSyncAt: appSettings.lastRewardsSyncAt,
          lastMissionLogsSyncAt: appSettings.lastMissionLogsSyncAt,
          lastRewardRequestsSyncAt: appSettings.lastRewardRequestsSyncAt,
          lastStarLedgerSyncAt: appSettings.lastStarLedgerSyncAt,
          lastFullSyncAt: appSettings.lastFullSyncAt,
          isSupabaseConfigured: isSupabaseConfigured,
          onOpenAccount: () {},
          onSignOut: () {},
          onUpdateRemoteFamilyName:
              onUpdateRemoteFamilyName ??
              ({required familyId, required name}) async =>
                  const ZeniUpdateRemoteFamilyResult.failure('indisponível'),
          onSyncCloudData:
              onSyncCloudData ??
              () async => const ZeniCloudSyncResult.failure('indisponível'),
        ),
      ),
    );
  }

  Future<void> completeOnboarding(
    WidgetTester tester, {
    String childName = 'Luna',
    bool skipPin = false,
    bool createMission = true,
    bool createReward = true,
  }) async {
    await tester.tap(find.text('Começar configuração'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, childName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();

    if (skipPin) {
      await tester.tap(find.text('Pular por enquanto'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } else {
      await tester.tap(find.text('Continuar sem PIN').first);
      await tester.pumpAndSettle();
    }

    if (!createMission) {
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();

    if (!createReward) {
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Concluir configuração').first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Mission buildMissionForDateFilter({
    required String id,
    required String title,
    required MissionRecurrence recurrence,
    required DateTime createdAt,
    List<int> customDaysOfWeek = const <int>[],
  }) {
    return Mission(
      id: id,
      familyId: 'family-1',
      childId: 'child-1',
      title: title,
      description: 'Descricao',
      stars: 10,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('child missions for today filter', () {
    test('daily appears today', () {
      final today = DateTime.now();
      final filtered = childMissionsForDate(
        missions: [
          buildMissionForDateFilter(
            id: 'daily',
            title: 'Diaria',
            recurrence: MissionRecurrence.daily,
            createdAt: today.subtract(const Duration(days: 1)),
          ),
        ],
        childId: 'child-1',
        date: today,
      );

      expect(filtered.map((mission) => mission.id), ['daily']);
    });

    test('weekdays appears on a weekday and not on a weekend', () {
      final mission = buildMissionForDateFilter(
        id: 'weekdays',
        title: 'Dias uteis',
        recurrence: MissionRecurrence.weekdays,
        createdAt: DateTime(2026, 5, 1),
      );

      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 29),
        ).map((item) => item.id),
        ['weekdays'],
      );
      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 30),
        ),
        isEmpty,
      );
    });

    test('weekends appears on the weekend and not on a weekday', () {
      final mission = buildMissionForDateFilter(
        id: 'weekends',
        title: 'Fim de semana',
        recurrence: MissionRecurrence.weekends,
        createdAt: DateTime(2026, 5, 1),
      );

      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 30),
        ).map((item) => item.id),
        ['weekends'],
      );
      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 29),
        ),
        isEmpty,
      );
    });

    test('customDaysOfWeek appears only on the selected weekdays', () {
      final mission = buildMissionForDateFilter(
        id: 'custom',
        title: 'Personalizada',
        recurrence: MissionRecurrence.customDaysOfWeek,
        createdAt: DateTime(2026, 5, 1),
        customDaysOfWeek: const [DateTime.monday, DateTime.wednesday],
      );

      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 27),
        ).map((item) => item.id),
        ['custom'],
      );
      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 28),
        ),
        isEmpty,
      );
    });

    test('once respects the domain date rule', () {
      final mission = buildMissionForDateFilter(
        id: 'once',
        title: 'Uma vez',
        recurrence: MissionRecurrence.once,
        createdAt: DateTime(2026, 5, 15),
      );

      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 15),
        ).map((item) => item.id),
        ['once'],
      );
      expect(
        childMissionsForDate(
          missions: [mission],
          childId: 'child-1',
          date: DateTime(2026, 5, 16),
        ),
        isEmpty,
      );
    });
  });

  testWidgets('ZeniApp builds profile choice page', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));

    await tester.pumpAndSettle();

    expect(find.text('ZeniKids'), findsOneWidget);
    expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Theo'), findsOneWidget);
    expect(find.text('Entrar como responsável'), findsOneWidget);
  });

  testWidgets('first opening shows onboarding when app is empty', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao Zeni'), findsOneWidget);
    expect(find.text('Começar configuração'), findsOneWidget);
    expect(find.text('Quem está usando o ZeniKids?'), findsNothing);
  });

  testWidgets('finishing onboarding persists the flag and first child', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await completeOnboarding(tester);

    final state = container.read(zeniAppStateControllerProvider).asData!.value;
    final child = state.children.single;
    final mission = state.missions.single;
    final reward = state.rewards.single;
    final preferences = await SharedPreferences.getInstance();
    final persistedState =
        jsonDecode(preferences.getString('zeni_app_state_v1')!)
            as Map<String, dynamic>;

    expect(state.appSettings.hasCompletedOnboarding, isTrue);
    expect(state.children, hasLength(1));
    expect(child.name, 'Luna');
    expect(state.missions, hasLength(1));
    expect(state.rewards, hasLength(1));
    expect(mission.childId, child.id);
    expect(mission.isActive, isTrue);
    expect(mission.occursToday(), isTrue);
    expect(reward.childId, child.id);
    expect(reward.isActive, isTrue);
    expect(persistedState['children'] as List<dynamic>, hasLength(1));
    expect(persistedState['missions'] as List<dynamic>, hasLength(1));
    expect(persistedState['rewards'] as List<dynamic>, hasLength(1));
    expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
  });

  testWidgets('onboarding with skipped PIN completes without creating a PIN', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await completeOnboarding(tester, skipPin: true);

    final settings = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value
        .appSettings;

    expect(settings.hasCompletedOnboarding, isTrue);
    expect(settings.hasParentPin, isFalse);
    expect(settings.parentPin, isNull);
    expect(settings.parentPinHash, isNull);
  });

  testWidgets('skipping PIN advances onboarding to the mission step', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Começar configuração'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Luna');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();

    expect(find.text('Proteção do responsável'), findsOneWidget);

    await tester.tap(find.text('Pular por enquanto'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Primeira missão'), findsWidgets);
    expect(find.text('Concluir configuração'), findsNothing);
  });

  testWidgets(
    'mission and reward created in onboarding appear for the child and parent',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await completeOnboarding(tester, childName: 'Luna');

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      expect(find.text('Arrumar a cama'), findsOneWidget);

      await tester.tap(find.text('Mimos'));
      await tester.pumpAndSettle();

      expect(find.text('Escolher o filme'), findsOneWidget);

      await tester.tap(find.byTooltip('Trocar perfil'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Entrar como responsável'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar como responsável'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();
      expect(find.text('Arrumar a cama'), findsOneWidget);

      await tester.tap(find.text('Mimos'));
      await tester.pumpAndSettle();
      expect(find.text('Escolher o filme'), findsOneWidget);
    },
  );

  testWidgets(
    'reopening after onboarding keeps child, mission and reward persisted',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await completeOnboarding(tester, childName: 'Luna');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao Zeni'), findsNothing);
      expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      expect(find.text('Arrumar a cama'), findsOneWidget);

      await tester.tap(find.text('Mimos'));
      await tester.pumpAndSettle();

      expect(find.text('Escolher o filme'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding can finish intentionally without suggested mission and reward',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await completeOnboarding(
        tester,
        createMission: false,
        createReward: false,
      );

      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(state.appSettings.hasCompletedOnboarding, isTrue);
      expect(state.children, hasLength(1));
      expect(state.missions, isEmpty);
      expect(state.rewards, isEmpty);
    },
  );

  testWidgets('reopening the app does not show onboarding again', (
    tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode({
        'family': {
          'id': 'local-family',
          'name': 'Minha família',
          'inviteCode': 'ZENI00',
          'createdAt': now.toIso8601String(),
        },
        'children': [
          {
            'id': 'child-1',
            'familyId': 'local-family',
            'name': 'Luna',
            'emoji': '🦊',
            'avatarUrl': null,
            'birthDate': null,
            'starBalance': 0,
            'streakCount': 0,
            'ttsEnabled': false,
            'isActive': true,
            'createdAt': now.toIso8601String(),
          },
        ],
        'familyMembers': [
          {
            'id': 'local-parent',
            'familyId': 'local-family',
            'name': 'Responsável',
            'email': null,
            'role': 'parent',
            'childProfileId': null,
            'isOwner': true,
            'createdAt': now.toIso8601String(),
          },
          {
            'id': 'member-child-1',
            'familyId': 'local-family',
            'name': 'Luna',
            'email': null,
            'role': 'child',
            'childProfileId': 'child-1',
            'isOwner': false,
            'createdAt': now.toIso8601String(),
          },
        ],
        'missions': [],
        'missionLogs': [],
        'rewards': [],
        'rewardRequests': [],
        'starLedgerEntries': [],
        'appSettings': {
          'themeMode': 'system',
          'dyslexiaFontEnabled': false,
          'textScale': 1.0,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'ttsEnabled': false,
          'readAloudByChildProfile': false,
          'hasCompletedOnboarding': true,
          'parentBiometricsEnabled': false,
        },
      }),
    });

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
    expect(find.text('Bem-vindo ao Zeni'), findsNothing);
  });

  testWidgets('existing local data is not forced through onboarding', (
    tester,
  ) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
    expect(find.text('Bem-vindo ao Zeni'), findsNothing);
  });

  testWidgets('tapping child opens child mode shell', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Luna!'), findsOneWidget);
    expect(find.text('Seu dia hoje'), findsOneWidget);
    expect(find.text('Arrumar a cama'), findsOneWidget);
  });

  testWidgets('child missions tab hides active missions outside today', (
    tester,
  ) async {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final outOfDayRecurrence = isWeekend
        ? MissionRecurrence.weekdays
        : MissionRecurrence.weekends;

    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode({
        'family': {
          'id': 'family-1',
          'name': 'Família Teste',
          'inviteCode': 'ZENI42',
          'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
        },
        'children': [
          {
            'id': 'child-1',
            'familyId': 'family-1',
            'name': 'Luna',
            'emoji': '🦊',
            'avatarUrl': null,
            'birthDate': null,
            'starBalance': 120,
            'streakCount': 8,
            'ttsEnabled': false,
            'isActive': true,
            'createdAt': now
                .subtract(const Duration(days: 28))
                .toIso8601String(),
          },
        ],
        'familyMembers': [
          {
            'id': 'member-1',
            'familyId': 'family-1',
            'name': 'Responsavel',
            'email': 'responsavel@zeni.app',
            'role': 'parent',
            'childProfileId': null,
            'isOwner': true,
            'createdAt': now
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          },
          {
            'id': 'member-2',
            'familyId': 'family-1',
            'name': 'Luna',
            'email': null,
            'role': 'child',
            'childProfileId': 'child-1',
            'isOwner': false,
            'createdAt': now
                .subtract(const Duration(days: 28))
                .toIso8601String(),
          },
        ],
        'missions': [
          {
            'id': 'mission-daily',
            'familyId': 'family-1',
            'childId': 'child-1',
            'title': 'Missao de hoje',
            'description': 'Deve aparecer',
            'emoji': '✅',
            'stars': 10,
            'recurrence': 'daily',
            'customDaysOfWeek': const <int>[],
            'timeGroup': 'morning',
            'approvalMode': 'automatic',
            'status': 'active',
            'requiresPhoto': false,
            'createdAt': now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          {
            'id': 'mission-out-of-day',
            'familyId': 'family-1',
            'childId': 'child-1',
            'title': 'Missao fora do dia',
            'description': 'Nao deve aparecer',
            'emoji': '✅',
            'stars': 10,
            'recurrence': outOfDayRecurrence.storageValue,
            'customDaysOfWeek': const <int>[],
            'timeGroup': 'evening',
            'approvalMode': 'automatic',
            'status': 'active',
            'requiresPhoto': false,
            'createdAt': now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          {
            'id': 'mission-once-old',
            'familyId': 'family-1',
            'childId': 'child-1',
            'title': 'Missao antiga',
            'description': 'Nao deve aparecer',
            'emoji': '✅',
            'stars': 10,
            'recurrence': 'once',
            'customDaysOfWeek': const <int>[],
            'timeGroup': 'anytime',
            'approvalMode': 'automatic',
            'status': 'active',
            'requiresPhoto': false,
            'createdAt': now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
        'missionLogs': [
          {
            'id': 'log-daily',
            'missionId': 'mission-daily',
            'childId': 'child-1',
            'scheduledDate': DateTime(
              now.year,
              now.month,
              now.day,
            ).toIso8601String(),
            'status': 'pending',
            'starsAwarded': 10,
            'completedAt': null,
            'approvedAt': null,
            'rejectedAt': null,
            'photoUrl': null,
            'note': null,
          },
        ],
        'rewards': [],
        'rewardRequests': [],
        'starLedgerEntries': [],
        'appSettings': {
          'themeMode': 'system',
          'dyslexiaFontEnabled': false,
          'textScale': 1.0,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'ttsEnabled': false,
          'readAloudByChildProfile': false,
        },
      }),
    });

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    expect(find.text('Missao de hoje'), findsOneWidget);
    expect(find.text('Missao fora do dia'), findsNothing);
    expect(find.text('Missao antiga'), findsNothing);
  });

  testWidgets('tapping reward card on today opens rewards tab', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Você tem mimo aguardando aprovação 🎁'));
    await tester.pumpAndSettle();

    expect(find.text('Meus mimos'), findsOneWidget);
  });

  testWidgets(
    'completing auto-approved mission triggers flying star animation',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final seeded = ZeniAppState.seeded();
      seedMockAppStateWith(
        seeded.copyWith(
          missionLogs: seeded.missionLogs
              .where((log) => log.missionId != 'mission-2')
              .toList(),
        ),
      );
      final capturedFlights = <({Offset from, Offset to})>[];
      debugOnFlyingStarShown = (from, to) {
        capturedFlights.add((from: from, to: to));
      };
      addTearDown(() {
        debugOnFlyingStarShown = null;
      });

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();

      final automaticMissionCard = find.widgetWithText(
        TaskCompactChildCard,
        'Escovar os dentes',
      );
      await tester.ensureVisible(automaticMissionCard);
      await tester.tap(automaticMissionCard, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir missão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir agora'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(capturedFlights, hasLength(1));
      expect(
        capturedFlights.single.from.dy,
        greaterThan(capturedFlights.single.to.dy),
      );
      expect(find.text('Missão concluída!'), findsOneWidget);
    },
  );

  testWidgets(
    'mission requiring approval does not trigger flying star animation',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      seedMockAppState();
      var animationCount = 0;
      debugOnFlyingStarShown = (_, _) {
        animationCount += 1;
      };
      addTearDown(() {
        debugOnFlyingStarShown = null;
      });

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();

      final manualMissionCard = find.widgetWithText(
        TaskCompactChildCard,
        'Arrumar a cama',
      );
      await tester.ensureVisible(manualMissionCard);
      await tester.tap(manualMissionCard, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir missão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar para aprovação'));
      await tester.pumpAndSettle();

      expect(animationCount, 0);
      expect(find.text('Missão enviada!'), findsOneWidget);
    },
  );

  testWidgets(
    'flying star animation failure does not break mission completion',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final seeded = ZeniAppState.seeded();
      seedMockAppStateWith(
        seeded.copyWith(
          missionLogs: seeded.missionLogs
              .where((log) => log.missionId != 'mission-2')
              .toList(),
        ),
      );
      debugOnFlyingStarShown = (_, _) {
        throw StateError('overlay test failure');
      };
      addTearDown(() {
        debugOnFlyingStarShown = null;
      });

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      expect(find.text('120'), findsWidgets);

      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();

      final automaticMissionCard = find.widgetWithText(
        TaskCompactChildCard,
        'Escovar os dentes',
      );
      await tester.ensureVisible(automaticMissionCard);
      await tester.tap(automaticMissionCard, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir missão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir agora'));
      await tester.pumpAndSettle();

      expect(find.text('Missão concluída!'), findsOneWidget);
      expect(find.text('125'), findsWidgets);
    },
  );

  testWidgets('birthday child shows special card on today page', (
    tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode({
        'family': {
          'id': 'family-1',
          'name': 'Família Teste',
          'inviteCode': 'ZENI42',
          'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
        },
        'children': [
          {
            'id': 'child-1',
            'familyId': 'family-1',
            'name': 'Luna',
            'emoji': '🦊',
            'avatarUrl': null,
            'birthDate': DateTime(2018, now.month, now.day).toIso8601String(),
            'starBalance': 120,
            'streakCount': 8,
            'ttsEnabled': false,
            'isActive': true,
            'createdAt': now
                .subtract(const Duration(days: 28))
                .toIso8601String(),
          },
        ],
        'familyMembers': [
          {
            'id': 'member-1',
            'familyId': 'family-1',
            'name': 'Guilherme',
            'email': 'responsavel@zeni.app',
            'role': 'parent',
            'childProfileId': null,
            'isOwner': true,
            'createdAt': now
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          },
          {
            'id': 'member-2',
            'familyId': 'family-1',
            'name': 'Luna',
            'email': null,
            'role': 'child',
            'childProfileId': 'child-1',
            'isOwner': false,
            'createdAt': now
                .subtract(const Duration(days: 28))
                .toIso8601String(),
          },
        ],
        'missions': [],
        'missionLogs': [],
        'rewards': [],
        'rewardRequests': [],
        'starLedgerEntries': [],
        'appSettings': {
          'themeMode': 'system',
          'dyslexiaFontEnabled': false,
          'textScale': 1.0,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
          'ttsEnabled': false,
          'readAloudByChildProfile': false,
        },
      }),
    });

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Feliz aniversário, Luna! 🎂'), findsOneWidget);
    expect(find.text('Hoje é seu dia especial.'), findsOneWidget);
  });

  testWidgets('redeeming reward creates pending request for child', (
    tester,
  ) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mimos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RewardCompactChildCard).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pedir mimo'));
    await tester.pumpAndSettle();

    expect(find.text('80'), findsWidgets);
    expect(find.text('Pedidos pendentes'), findsOneWidget);
    expect(find.text('Aguardando responsável'), findsWidgets);

    await tester.tap(find.text('Hoje').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Você tem 2 mimos aguardando aprovação 🎁'),
      findsOneWidget,
    );
  });

  testWidgets('tapping parent opens parent mode shell', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('Painel do responsável'), findsOneWidget);
    expect(find.text('Família Silva'), findsOneWidget);
  });

  testWidgets('configuring a parent PIN in settings protects parent mode', (
    tester,
  ) async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('PIN do responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PIN do responsável'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('parent-pin-input')), '2468');
    await tester.enterText(
      find.byKey(const Key('parent-pin-confirm-input')),
      '2468',
    );
    await tester.tap(find.text('Salvar PIN'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value
          .appSettings
          .parentPin,
      isNull,
    );
    expect(
      container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value
          .appSettings
          .matchesParentPin('2468'),
      isTrue,
    );

    await tester.tap(find.byTooltip('Trocar perfil'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    expect(find.text('Digite seu PIN'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('parent-pin-input')), '0000');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Quem está usando o ZeniKids?'), findsOneWidget);
    expect(find.text('Painel do responsável'), findsNothing);

    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('parent-pin-input')), '2468');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('Painel do responsável'), findsOneWidget);
  });

  testWidgets('biometric parent entry falls back to PIN', (tester) async {
    seedMockAppState();
    final fakeBiometricAuth = _FakeParentBiometricAuth(
      result: const ParentBiometricAuthResult.fallbackToPin(),
    );
    final container = ProviderContainer(
      overrides: [
        parentBiometricAuthProvider.overrideWithValue(fakeBiometricAuth),
      ],
    );
    addTearDown(container.dispose);

    await container.read(zeniAppStateControllerProvider.future);
    await container
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(
          const AppSettings(parentPin: '2468', parentBiometricsEnabled: true),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    expect(fakeBiometricAuth.authenticateCalls, 1);
    expect(find.text('Digite seu PIN'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('parent-pin-input')), '2468');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Responsável'), findsOneWidget);
  });

  testWidgets('unavailable biometrics do not get enabled in settings', (
    tester,
  ) async {
    seedMockAppState();
    final container = ProviderContainer(
      overrides: [
        parentBiometricAuthProvider.overrideWithValue(
          _FakeParentBiometricAuth(
            availability: const ParentBiometricAvailability.unavailable(
              parentBiometricsUnavailableMessage,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como responsável'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('PIN do responsável'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PIN do responsável'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('parent-pin-input')), '2468');
    await tester.enterText(
      find.byKey(const Key('parent-pin-confirm-input')),
      '2468',
    );
    await tester.tap(find.text('Salvar PIN'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Biometria indisponível'), findsOneWidget);
    expect(
      container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value
          .appSettings
          .parentBiometricsEnabled,
      isFalse,
    );
  });

  testWidgets(
    'parent accessibility settings update the source of truth and MaterialApp',
    (tester) async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await openParentSettings(tester);
      await tester.scrollUntilVisible(find.text('Escuro'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Fonte OpenDyslexic'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byTooltip('Aumentar Tamanho da letra'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Aumentar Tamanho da letra'));
      await tester.pumpAndSettle();

      final appSettings = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value
          .appSettings;
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final settingsContext = tester.element(
        find.text('Preferências do app, acessibilidade e recursos da família.'),
      );
      final textScale = MediaQuery.of(settingsContext).textScaler.scale(1);

      expect(appSettings.themeMode, 'dark');
      expect(appSettings.dyslexiaFontEnabled, isTrue);
      expect(appSettings.textScale, 1.05);
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(
        materialApp.theme?.textTheme.bodyMedium?.fontFamily,
        'OpenDyslexic',
      );
      expect(textScale, 1.05);
    },
  );

  testWidgets(
    'parent accessibility settings persist and load from the single source of truth',
    (tester) async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'zeni_app_state_v1': jsonEncode({
          'family': {
            'id': 'family-1',
            'name': 'Família Teste',
            'inviteCode': 'ZENI42',
            'createdAt': now
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          },
          'children': [
            {
              'id': 'child-1',
              'familyId': 'family-1',
              'name': 'Luna',
              'emoji': '🦊',
              'avatarUrl': null,
              'birthDate': null,
              'starBalance': 120,
              'streakCount': 8,
              'ttsEnabled': false,
              'isActive': true,
              'createdAt': now
                  .subtract(const Duration(days: 28))
                  .toIso8601String(),
            },
          ],
          'familyMembers': [
            {
              'id': 'member-1',
              'familyId': 'family-1',
              'name': 'Responsavel',
              'email': 'responsavel@zeni.app',
              'role': 'parent',
              'childProfileId': null,
              'isOwner': true,
              'createdAt': now
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
            },
            {
              'id': 'member-2',
              'familyId': 'family-1',
              'name': 'Luna',
              'email': null,
              'role': 'child',
              'childProfileId': 'child-1',
              'isOwner': false,
              'createdAt': now
                  .subtract(const Duration(days: 28))
                  .toIso8601String(),
            },
          ],
          'missions': [],
          'missionLogs': [],
          'rewards': [],
          'rewardRequests': [],
          'starLedgerEntries': [],
          'appSettings': {
            'themeMode': 'dark',
            'dyslexiaFontEnabled': true,
            'textScale': 1.15,
            'vibrationEnabled': false,
            'notificationsEnabled': false,
            'ttsEnabled': true,
            'readAloudByChildProfile': true,
            'parentBiometricsEnabled': false,
          },
        }),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await openParentSettings(tester);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final settingsContext = tester.element(
        find.text('Preferências do app, acessibilidade e recursos da família.'),
      );
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();

      expect(materialApp.themeMode, ThemeMode.dark);
      expect(
        materialApp.theme?.textTheme.bodyMedium?.fontFamily,
        'OpenDyslexic',
      );
      expect(MediaQuery.of(settingsContext).textScaler.scale(1), 1.15);
      expect(find.text('115 %'), findsOneWidget);
      expect(switches[0].value, isTrue);
      expect(switches[1].value, isFalse);
      expect(switches[2].value, isFalse);
      expect(switches[3].value, isTrue);
      expect(switches[4].value, isTrue);

      final sharedPreferences = await SharedPreferences.getInstance();
      final persistedState =
          jsonDecode(sharedPreferences.getString('zeni_app_state_v1')!)
              as Map<String, dynamic>;
      final persistedSettings =
          persistedState['appSettings'] as Map<String, dynamic>;

      expect(persistedSettings['themeMode'], 'dark');
      expect(persistedSettings['dyslexiaFontEnabled'], isTrue);
      expect(persistedSettings['textScale'], 1.15);
      expect(persistedSettings['vibrationEnabled'], isFalse);
      expect(persistedSettings['notificationsEnabled'], isFalse);
      expect(persistedSettings['ttsEnabled'], isTrue);
      expect(persistedSettings['readAloudByChildProfile'], isTrue);
    },
  );

  testWidgets('settings shows account CTA when unauthenticated', (
    tester,
  ) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openParentSettings(tester);

    expect(find.text('Criar conta para sincronizar'), findsOneWidget);
  });

  testWidgets('authenticated settings show email and sign out action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conta conectada'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('owner role appears as friendly responsible principal label', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Família remota preparada'), findsOneWidget);
    expect(find.text('Minha família · Responsável principal'), findsOneWidget);
  });

  testWidgets('responsible role appears as friendly label', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'responsible',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Minha família · Responsável'), findsOneWidget);
  });

  testWidgets('settings shows a single cloud sync card', (tester) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Sincronização'), findsNothing);

    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        localChildrenCount: 2,
        remoteChildrenCount: 1,
        localRewardsCount: 2,
      ),
    );
    await tester.pump();

    expect(find.text('Sincronização'), findsOneWidget);
    expect(
      find.text(
        'Dados preparados na nuvem · 1 criança preparada · 3 missões locais · 2 mimos locais · 0 conclusões locais · 0 pedidos locais · 0 eventos locais',
      ),
      findsOneWidget,
    );
    expect(find.text('Sincronizar'), findsOneWidget);
  });

  testWidgets(
    'separate children and missions sync actions are no longer shown',
    (tester) async {
      await tester.pumpWidget(
        buildStaticSettingsHarness(
          authState: const ZeniAuthState.authenticated(
            ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
          ),
          remoteFamilySummary: const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
          remoteChildrenCount: 2,
          remoteMissionsCount: 1,
          remoteRewardsCount: 2,
        ),
      );
      await tester.pump();

      expect(find.text('Preparar crianças na nuvem'), findsNothing);
      expect(find.text('Preparar missões na nuvem'), findsNothing);
    },
  );

  testWidgets('editing remote family name calls callback and updates UI', (
    tester,
  ) async {
    var summary = const RemoteFamilySummary(
      familyId: 'family-1',
      familyName: 'Minha família',
      role: 'owner',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: ParentSettingsTab(
                appSettings: const AppSettings(),
                accessibilitySettings: const ZeniAccessibilitySettings(),
                onThemeModeChanged: (_) {},
                onDyslexiaFontChanged: (_) {},
                onTextScaleChanged: (_) {},
                onVibrationChanged: (_) {},
                onNotificationsChanged: (_) {},
                onTtsChanged: (_) {},
                onReadAloudByChildProfileChanged: (_) {},
                onConfigurePin: () {},
                onBiometricsChanged: (_) {},
                authState: const ZeniAuthState.authenticated(
                  ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
                ),
                remoteFamilySummary: summary,
                localChildrenCount: 2,
                remoteChildrenCount: 1,
                localMissionsCount: 3,
                remoteMissionsCount: 1,
                localRewardsCount: 2,
                remoteRewardsCount: 1,
                localMissionLogsCount: 0,
                remoteMissionLogsCount: null,
                localRewardRequestsCount: 0,
                remoteRewardRequestsCount: null,
                localStarLedgerCount: 0,
                remoteStarLedgerCount: null,
                childBalanceDiagnostics: const <ChildBalanceDiagnostic>[],
                hasRemoteChildBalanceData: false,
                cloudConsistencyDiagnostic: null,
                cloudConsistencyErrorText: null,
                lastChildrenSyncAt: null,
                lastMissionsSyncAt: null,
                lastRewardsSyncAt: null,
                lastMissionLogsSyncAt: null,
                lastRewardRequestsSyncAt: null,
                lastStarLedgerSyncAt: null,
                lastFullSyncAt: null,
                isSupabaseConfigured: true,
                onOpenAccount: () {},
                onSignOut: () {},
                onUpdateRemoteFamilyName:
                    ({required familyId, required name}) async {
                      setState(() {
                        summary = RemoteFamilySummary(
                          familyId: familyId,
                          familyName: name,
                          role: summary.role,
                        );
                      });
                      return ZeniUpdateRemoteFamilyResult.success(summary);
                    },
                onSyncCloudData: () async =>
                    const ZeniCloudSyncResult.success(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Editar'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Nome da família remota'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('remote-family-name-input')),
      'Família da Luna',
    );
    await tester.tap(find.text('Salvar nome'));
    await tester.pumpAndSettle();

    expect(
      find.text('Família da Luna · Responsável principal'),
      findsOneWidget,
    );
  });

  testWidgets('empty remote family name shows controlled error', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        onUpdateRemoteFamilyName: ({required familyId, required name}) async =>
            const ZeniUpdateRemoteFamilyResult.failure(
              'Digite um nome para a família.',
            ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Editar'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('remote-family-name-input')),
      '   ',
    );
    await tester.tap(find.text('Salvar nome'));
    await tester.pumpAndSettle();

    expect(find.text('Digite um nome para a família.'), findsWidgets);
  });

  testWidgets('cloud sync failure shows controlled inline error', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        onSyncCloudData: () async => const ZeniCloudSyncResult.failure(
          'Não foi possível sincronizar agora. Tente novamente.',
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Sincronizar'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sincronizar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível sincronizar agora. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('cloud sync card shows last successful synchronization timestamp', (
    tester,
  ) async {
    final appSettings = AppSettings(
      lastChildrenSyncAt: DateTime(2026, 5, 28, 14, 32),
      lastMissionsSyncAt: DateTime(2026, 5, 28, 15, 45),
      lastRewardsSyncAt: DateTime(2026, 5, 28, 15, 55),
      lastMissionLogsSyncAt: DateTime(2026, 5, 28, 16, 00),
      lastRewardRequestsSyncAt: DateTime(2026, 5, 28, 16, 5),
      lastStarLedgerSyncAt: DateTime(2026, 5, 28, 16, 8),
      lastFullSyncAt: DateTime(2026, 5, 28, 16, 10),
    );

    await tester.pumpWidget(
      buildStaticSettingsHarness(
        appSettings: appSettings,
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        remoteChildrenCount: 2,
        remoteMissionsCount: 1,
        remoteRewardsCount: 2,
        remoteMissionLogsCount: 3,
        remoteRewardRequestsCount: 1,
        remoteStarLedgerCount: 4,
      ),
    );
    await tester.pump();

    expect(
      find.text('Última sincronização: 28/05/2026 às 16:10'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Crianças preparadas · Missões preparadas · Mimos preparados · Conclusões preparadas · Pedidos preparados · Eventos preparados',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings shows remote balance diagnosis when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        hasRemoteChildBalanceData: true,
        childBalanceDiagnostics: const [
          ChildBalanceDiagnostic(
            childName: 'Luna',
            localBalance: 12,
            remoteBalance: 12,
            ledgerEventsCount: 4,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.text('Saldo remoto disponível para conferência'),
      findsOneWidget,
    );
    expect(find.text('Saldo local e saldo na nuvem conferem.'), findsOneWidget);
    expect(
      find.text(
        'Luna: Saldo local: 12 estrelas · Saldo na nuvem: 12 estrelas · Eventos no ledger: 4',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings shows remote balance divergence when values differ', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        hasRemoteChildBalanceData: true,
        childBalanceDiagnostics: const [
          ChildBalanceDiagnostic(
            childName: 'Luna',
            localBalance: 12,
            remoteBalance: 10,
            ledgerEventsCount: 4,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.text('Diferença encontrada entre saldo local e saldo na nuvem.'),
      findsOneWidget,
    );
  });

  testWidgets('settings shows cloud consistency as aligned when counts match', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        cloudConsistencyDiagnostic: const CloudConsistencyDiagnostic(
          localChildrenCount: 1,
          remoteChildrenCount: 1,
          localMissionsCount: 2,
          remoteMissionsCount: 2,
          localRewardsCount: 1,
          remoteRewardsCount: 1,
          localMissionLogsCount: 3,
          remoteMissionLogsCount: 3,
          localRewardRequestsCount: 1,
          remoteRewardRequestsCount: 1,
          localStarBalance: 12,
          remoteDerivedBalance: 12,
          childBalanceDiagnostics: [
            ChildBalanceDiagnostic(
              childName: 'Luna',
              localBalance: 12,
              remoteBalance: 12,
              ledgerEventsCount: 4,
            ),
          ],
          warnings: [],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conferência da nuvem'), findsOneWidget);
    expect(
      find.text('Dados locais e nuvem parecem alinhados.'),
      findsOneWidget,
    );
    expect(
      find.text('Crianças: 1/1 · Missões: 2/2 · Mimos: 1/1'),
      findsOneWidget,
    );
    expect(find.text('Conclusões: 3/3 · Pedidos: 1/1'), findsOneWidget);
  });

  testWidgets(
    'settings shows cloud consistency divergence when counts differ',
    (tester) async {
      await tester.pumpWidget(
        buildStaticSettingsHarness(
          authState: const ZeniAuthState.authenticated(
            ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
          ),
          remoteFamilySummary: const RemoteFamilySummary(
            familyId: 'family-1',
            familyName: 'Minha família',
            role: 'owner',
          ),
          cloudConsistencyDiagnostic: const CloudConsistencyDiagnostic(
            localChildrenCount: 2,
            remoteChildrenCount: 1,
            localMissionsCount: 3,
            remoteMissionsCount: 2,
            localRewardsCount: 2,
            remoteRewardsCount: 1,
            localMissionLogsCount: 4,
            remoteMissionLogsCount: 2,
            localRewardRequestsCount: 2,
            remoteRewardRequestsCount: 1,
            localStarBalance: 12,
            remoteDerivedBalance: 10,
            childBalanceDiagnostics: [
              ChildBalanceDiagnostic(
                childName: 'Luna',
                localBalance: 12,
                remoteBalance: 10,
                ledgerEventsCount: 4,
              ),
            ],
            warnings: [
              'A quantidade de crianças locais e remotas é diferente.',
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Conferência da nuvem'), findsOneWidget);
      expect(
        find.text('Encontramos diferenças para conferir.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Saldo local total: 12 estrelas · Saldo remoto total: 10 estrelas',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings shows controlled cloud consistency read failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStaticSettingsHarness(
        authState: const ZeniAuthState.authenticated(
          ZeniAuthUser(id: 'user-1', email: 'responsavel@zeni.app'),
        ),
        remoteFamilySummary: const RemoteFamilySummary(
          familyId: 'family-1',
          familyName: 'Minha família',
          role: 'owner',
        ),
        cloudConsistencyErrorText: 'Não foi possível conferir a nuvem agora.',
      ),
    );
    await tester.pump();

    expect(
      find.text('Não foi possível conferir a nuvem agora.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping account CTA opens account sheet', (tester) async {
    seedMockAppState();

    await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    expect(find.text('Conta da família'), findsOneWidget);
    expect(find.byKey(const Key('auth-email-input')), findsOneWidget);
    expect(find.byKey(const Key('auth-password-input')), findsOneWidget);
    expect(find.byKey(const Key('auth-google-button')), findsOneWidget);
  });

  testWidgets(
    'account sheet shows controlled failure without supabase configured',
    (tester) async {
      seedMockAppState();

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await openParentSettings(tester);
      await tester.scrollUntilVisible(
        find.text('Criar conta para sincronizar'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar conta para sincronizar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('auth-email-input')),
        'responsavel@zeni.app',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password-input')),
        '123456',
      );
      await tester.ensureVisible(find.text('Criar conta').last);
      await tester.tap(find.text('Criar conta').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Supabase Auth não está configurado neste app.'),
        findsOneWidget,
      );
      expect(find.text('Conta da família'), findsOneWidget);
    },
  );

  testWidgets('sign up without session shows confirmation email guidance', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      signUpRequiresEmailConfirmation: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Conta criada. Confirme seu e-mail para entrar.'),
      findsOneWidget,
    );
    expect(find.text('Conta da família'), findsOneWidget);
  });

  testWidgets('email sign in with session updates settings UI', (tester) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'responsavel@zeni.app',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.ensureVisible(find.text('Entrar').last);
    await tester.tap(find.text('Entrar').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Conta conectada'), findsOneWidget);
    expect(find.text('responsavel@zeni.app'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('google sign in failure shows controlled inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      googleSignInFailureMessage:
          'Não foi possível concluir o login com Google.',
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível concluir o login com Google.'),
      findsOneWidget,
    );
    expect(find.text('Conta da família'), findsOneWidget);
  });

  testWidgets('google missing configuration shows inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      isGoogleSignInAvailableOverride: false,
      googleSignInFailureMessage:
          'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping Google leaves only Google button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final googleCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      googleSignInCompleter: googleCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!googleCompleter.isCompleted) {
        googleCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-google-button')));
    await tester.tap(
      find.byKey(const Key('auth-google-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.text('Conectando com Google...'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);

    googleCompleter.complete(
      const ZeniAuthOperationResult.failure(
        'Não foi possível entrar com Google. Tente novamente ou use e-mail.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Apple leaves only Apple button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final appleCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      appleSignInCompleter: appleCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!appleCompleter.isCompleted) {
        appleCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-apple-button')));
    await tester.tap(
      find.byKey(const Key('auth-apple-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.text('Conectando com Apple...'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);

    appleCompleter.complete(
      const ZeniAuthOperationResult.failure(
        'Não foi possível concluir o login com Apple.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Entrar leaves only email sign in button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final signInCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      signInCompleter: signInCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!signInCompleter.isCompleted) {
        signInCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Entrando...'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);

    signInCompleter.complete(
      const ZeniAuthOperationResult.success(
        user: ZeniAuthUser(id: 'signed-in', email: 'a@b.com'),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tapping Criar conta leaves only sign up button in loading', (
    tester,
  ) async {
    seedMockAppState();
    final signUpCompleter = Completer<ZeniAuthOperationResult>();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      signUpCompleter: signUpCompleter,
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      if (!signUpCompleter.isCompleted) {
        signUpCompleter.complete(
          const ZeniAuthOperationResult.failure('cancelled'),
        );
      }
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-input')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-input')),
      '123456',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pump();

    expect(find.text('Criando conta...'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Apple'), findsOneWidget);

    signUpCompleter.complete(
      const ZeniAuthOperationResult.pendingEmailConfirmation(
        message: 'Conta criada. Confirme seu e-mail para entrar.',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'social auth buttons keep icon and label aligned with larger text scale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
            child: Scaffold(
              body: Column(
                children: [
                  AuthProviderButton.google(
                    onPressed: () {},
                    label: 'Entrar com Google',
                  ),
                  AuthProviderButton.apple(
                    onPressed: () {},
                    label: 'Entrar com Apple',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Entrar com Apple'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signing out returns to unauthenticated and keeps local data', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      initialUser: const ZeniAuthUser(
        id: 'user-1',
        email: 'responsavel@zeni.app',
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);

    final initialState = await container.read(
      zeniAppStateControllerProvider.future,
    );
    expect(initialState.children, isNotEmpty);
    expect(initialState.missions, isNotEmpty);
    expect(initialState.rewards, isNotEmpty);

    await container.read(zeniAuthControllerProvider).signOut();
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.signOutCalls, 1);
    expect(find.text('Criar conta para sincronizar'), findsOneWidget);
    expect(find.text('Sair da conta'), findsNothing);
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.children,
      isNotEmpty,
    );
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.missions,
      isNotEmpty,
    );
    expect(
      container.read(zeniAppStateControllerProvider).asData!.value.rewards,
      isNotEmpty,
    );
  });

  testWidgets('apple button appears when Apple sign in is available', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      isAppleSignInAvailableOverride: true,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-apple-button')), findsOneWidget);
  });

  testWidgets('apple sign in failure shows controlled inline error', (
    tester,
  ) async {
    seedMockAppState();
    final fakeAuthRepository = _FakeZeniAuthRepository(
      isAppleSignInAvailableOverride: true,
      appleSignInFailureMessage: 'Não foi possível concluir o login com Apple.',
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(() async {
      await fakeAuthRepository.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await openParentSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Criar conta para sincronizar'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta para sincronizar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('auth-apple-button')));
    await tester.tap(
      find.byKey(const Key('auth-apple-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível concluir o login com Apple.'),
      findsOneWidget,
    );
  });
}

class _FakeParentBiometricAuth implements ParentBiometricAuth {
  _FakeParentBiometricAuth({
    this.result = const ParentBiometricAuthResult.fallbackToPin(),
    this.availability = const ParentBiometricAvailability.available(),
  });

  final ParentBiometricAuthResult result;
  final ParentBiometricAvailability availability;
  int authenticateCalls = 0;

  @override
  Future<ParentBiometricAuthResult> authenticate() async {
    authenticateCalls += 1;
    return result;
  }

  @override
  Future<ParentBiometricAvailability> checkAvailability() async {
    return availability;
  }
}

class _FakeZeniAuthRepository implements ZeniAuthRepository {
  _FakeZeniAuthRepository({
    ZeniAuthUser? initialUser,
    this.signUpRequiresEmailConfirmation = false,
    this.googleSignInFailureMessage,
    this.appleSignInFailureMessage,
    this.isGoogleSignInAvailableOverride = true,
    this.isAppleSignInAvailableOverride = false,
    this.signInCompleter,
    this.signUpCompleter,
    this.googleSignInCompleter,
    this.appleSignInCompleter,
  }) : _currentUser = initialUser;

  final StreamController<ZeniAuthUser?> _controller =
      StreamController<ZeniAuthUser?>.broadcast();
  final bool signUpRequiresEmailConfirmation;
  final String? googleSignInFailureMessage;
  final String? appleSignInFailureMessage;
  final bool isGoogleSignInAvailableOverride;
  final bool isAppleSignInAvailableOverride;
  final Completer<ZeniAuthOperationResult>? signInCompleter;
  final Completer<ZeniAuthOperationResult>? signUpCompleter;
  final Completer<ZeniAuthOperationResult>? googleSignInCompleter;
  final Completer<ZeniAuthOperationResult>? appleSignInCompleter;
  ZeniAuthUser? _currentUser;
  int signOutCalls = 0;

  @override
  ZeniAuthUser? get currentUser => _currentUser;

  @override
  bool get isGoogleSignInAvailable => isGoogleSignInAvailableOverride;

  @override
  bool get isAppleSignInAvailable => isAppleSignInAvailableOverride;

  @override
  Stream<ZeniAuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (signInCompleter != null) {
      final result = await signInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    _currentUser = ZeniAuthUser(id: 'signed-in', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signOut() async {
    signOutCalls += 1;
    _currentUser = null;
    _controller.add(null);
    return const ZeniAuthOperationResult.success();
  }

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (signUpCompleter != null) {
      final result = await signUpCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (signUpRequiresEmailConfirmation) {
      return const ZeniAuthOperationResult.pendingEmailConfirmation(
        message: 'Conta criada. Confirme seu e-mail para entrar.',
      );
    }

    _currentUser = ZeniAuthUser(id: 'signed-up', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    if (googleSignInCompleter != null) {
      final result = await googleSignInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (googleSignInFailureMessage != null) {
      return ZeniAuthOperationResult.failure(googleSignInFailureMessage!);
    }

    _currentUser = const ZeniAuthUser(
      id: 'google-user',
      email: 'google@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    if (appleSignInCompleter != null) {
      final result = await appleSignInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (appleSignInFailureMessage != null) {
      return ZeniAuthOperationResult.failure(appleSignInFailureMessage!);
    }

    _currentUser = const ZeniAuthUser(
      id: 'apple-user',
      email: 'apple@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  Future<void> dispose() {
    return _controller.close();
  }
}
