import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/app/zeni_app.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/feedback/zeni_haptics.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_child_form_sheet.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/rewards/presentation/widgets/reward_compact_child_card.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';
import 'package:zeni/features/tts/domain/zeni_speech_text_builders.dart';
import 'package:zeni/features/tts/presentation/providers/zeni_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('haptics do not call platform when vibration is disabled', () async {
    final platform = _FakeZeniHapticsPlatform();
    final haptics = ZeniHaptics(
      settings: const AppSettings(vibrationEnabled: false),
      platform: platform,
    );

    await haptics.confirm();
    await haptics.celebrate();
    await haptics.cancel();
    await haptics.selection();
    await haptics.warn();

    expect(platform.calls, isEmpty);
  });

  testWidgets('main child action triggers haptics when vibration is enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final platform = _FakeZeniHapticsPlatform();
    _seedAppState(
      ZeniAppState.seeded().copyWith(
        missionLogs: ZeniAppState.seeded().missionLogs
            .where((log) => log.missionId != 'mission-2')
            .toList(),
        appSettings: const AppSettings(vibrationEnabled: true),
      ),
    );

    final container = ProviderContainer(
      overrides: [zeniHapticsPlatformProvider.overrideWithValue(platform)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    final missionCard = find.text('Escovar os dentes');
    await tester.ensureVisible(missionCard);
    await tester.tap(missionCard, warnIfMissed: false);
    await tester.pumpAndSettle();

    platform.calls.clear();

    await tester.tap(find.text('Concluir missão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir agora'));
    await tester.pumpAndSettle();

    expect(platform.calls, contains('heavyImpact'));
  });

  testWidgets('listen button appears in child mode when tts is enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    _seedAppState(
      ZeniAppState.seeded().copyWith(
        appSettings: const AppSettings(ttsEnabled: true),
      ),
    );

    final ttsPlatform = _RecordingZeniTtsPlatform();
    final container = ProviderContainer(
      overrides: [zeniTtsPlatformProvider.overrideWithValue(ttsPlatform)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arrumar a cama'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Missão'), findsOneWidget);
    expect(find.text('Completo'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(2));

    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mimos'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(RewardCompactChildCard, 'Escolher o filme'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Mimo'), findsOneWidget);
    expect(find.text('Completo'), findsOneWidget);
  });

  testWidgets(
    'profile based read aloud hides child listen action when child tts is disabled',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final seeded = ZeniAppState.seeded();
      final updatedChildren = [
        for (final child in seeded.children)
          child.id == 'child-1' ? child.copyWith(ttsEnabled: false) : child,
      ];
      _seedAppState(
        seeded.copyWith(
          children: updatedChildren,
          appSettings: const AppSettings(
            ttsEnabled: true,
            readAloudByChildProfile: true,
          ),
        ),
      );

      await tester.pumpWidget(const ProviderScope(child: ZeniApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arrumar a cama'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Missão'), findsNothing);
      expect(find.text('Completo'), findsNothing);
    },
  );

  testWidgets('tapping Missao starts short speech and keeps the sheet open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    _seedAppState(
      _stateWithMissionDescription(
        'Deixe sua cama organizada.',
      ).copyWith(appSettings: const AppSettings(ttsEnabled: true)),
    );
    final ttsPlatform = _RecordingZeniTtsPlatform();
    final container = ProviderContainer(
      overrides: [zeniTtsPlatformProvider.overrideWithValue(ttsPlatform)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arrumar a cama'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missão'));
    await tester.pump();

    expect(find.text('Detalhes da missão'), findsOneWidget);
    expect(ttsPlatform.spokenTexts, isNotEmpty);
    expect(
      ttsPlatform.spokenTexts.last,
      contains('Missão: Arrumar a cama. Deixe sua cama organizada.'),
    );
  });

  testWidgets(
    'tapping Completo starts full speech, keeps the sheet open, and avoids technical text',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      _seedAppState(
        _stateWithMissionDescription(
          'Restaurada da nuvem',
        ).copyWith(appSettings: const AppSettings(ttsEnabled: true)),
      );
      final ttsPlatform = _RecordingZeniTtsPlatform();
      final container = ProviderContainer(
        overrides: [zeniTtsPlatformProvider.overrideWithValue(ttsPlatform)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ZeniApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Missões'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arrumar a cama'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completo'));
      await tester.pump();

      expect(find.text('Detalhes da missão'), findsOneWidget);
      expect(ttsPlatform.spokenTexts, isNotEmpty);
      final speech = ttsPlatform.spokenTexts.last.toLowerCase();
      expect(speech, contains('missão: arrumar a cama'));
      expect(speech, contains('ainda falta concluir'));
      expect(speech, contains('vale 10 estrelas'));
      expect(speech, contains('de manhã'));
      expect(
        speech,
        contains('depois que você enviar, um responsável precisa aprovar'),
      );
      expect(speech, isNot(contains('restaurada da nuvem')));
      expect(speech, isNot(contains('restaurado da nuvem')));
      expect(speech, isNot(contains('nuvem')));
      expect(speech, isNot(contains('sync')));
      expect(speech, isNot(contains('local')));
      expect(speech, isNot(contains('remoto')));
      expect(speech, isNot(contains('ledger')));
      expect(speech, isNot(contains('supabase')));
      expect(speech, isNot(contains('pending')));
      expect(speech, isNot(contains('awaitingapproval')));
      expect(speech, isNot(contains('parentapproval')));
      expect(speech, isNot(contains('automatic')));
    },
  );

  testWidgets('reward audio actions keep the sheet open', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    _seedAppState(
      ZeniAppState.seeded().copyWith(
        appSettings: const AppSettings(ttsEnabled: true),
      ),
    );
    final ttsPlatform = _RecordingZeniTtsPlatform();
    final container = ProviderContainer(
      overrides: [zeniTtsPlatformProvider.overrideWithValue(ttsPlatform)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZeniApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mimos'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(RewardCompactChildCard, 'Escolher o filme'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mimo'));
    await tester.pump();
    expect(find.text('Detalhes do mimo'), findsOneWidget);

    await tester.tap(find.text('Completo'));
    await tester.pump();
    expect(find.text('Detalhes do mimo'), findsOneWidget);
    expect(ttsPlatform.spokenTexts.length, greaterThanOrEqualTo(2));
  });

  testWidgets('editing child form allows changing ttsEnabled', (tester) async {
    ParentChildFormResult? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: _ChildFormHost(
          onResult: (result) {
            submitted = result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();

    expect(find.text('Leitura em voz alta para esta criança'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar perfil'));
    await tester.tap(find.text('Salvar perfil'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(submitted?.ttsEnabled, isTrue);
  });

  test('tts service uses child profile rule when enabled', () async {
    final service = ZeniTtsService(
      settings: const AppSettings(
        ttsEnabled: true,
        readAloudByChildProfile: true,
      ),
      platform: _FakeZeniTtsPlatform(),
    );
    final child = ZeniAppState.seeded().children.first.copyWith(
      ttsEnabled: false,
    );

    expect(service.isEnabledForChild(child), isFalse);
  });

  test(
    'mission short speech avoids technical terms and uses only friendly text',
    () {
      final speech = ZeniMissionSpeechTextBuilder.buildMissionShortSpeech(
        _testMission(
          description: 'Deixe sua cama organizada para comecar bem o dia.',
        ),
      ).toLowerCase();

      expect(speech, contains('missão: arrumar a cama'));
      expect(speech, contains('deixe sua cama organizada'));
      expect(speech, isNot(contains('nuvem')));
      expect(speech, isNot(contains('restaurado')));
      expect(speech, isNot(contains('sync')));
      expect(speech, isNot(contains('local')));
      expect(speech, isNot(contains('remoto')));
      expect(speech, isNot(contains('ledger')));
      expect(speech, isNot(contains('supabase')));
      expect(speech, isNot(contains('awaitingapproval')));
    },
  );

  test(
    'mission details speech translates status to child friendly language',
    () {
      final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
        mission: _testMission(),
        log: _testMissionLog(status: MissionLogStatus.awaitingApproval),
      ).toLowerCase();

      expect(speech, contains('esperando aprovação do responsável'));
      expect(speech, isNot(contains('awaitingapproval')));
      expect(speech, isNot(contains('pending')));
    },
  );

  test('mission details speech includes stars, time and approval guidance', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: _testMission(
        stars: 10,
        timeGroup: MissionTimeGroup.morning,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
    ).toLowerCase();

    expect(speech, contains('vale 10 estrelas'));
    expect(speech, contains('pode ser feita de manhã'));
    expect(
      speech,
      contains('depois que você enviar, um responsável precisa aprovar'),
    );
  });

  test('reward details speech explains cost, pending status and waiting', () {
    final speech = ZeniRewardSpeechTextBuilder.buildRewardDetailsSpeech(
      reward: _testReward(cost: 25),
      childBalance: 30,
      request: _testRewardRequest(status: RewardRequestStatus.pending),
    ).toLowerCase();

    expect(speech, contains('custa 25 estrelas'));
    expect(speech, contains('seu pedido está esperando o responsável'));
    expect(speech, contains('agora é só aguardar o responsável'));
  });

  test('technical mission description is ignored in short speech', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionShortSpeech(
      _testMission(description: 'Restaurada da nuvem'),
    ).toLowerCase();

    expect(speech, 'missão: arrumar a cama');
    expect(speech, isNot(contains('restaurada')));
    expect(speech, isNot(contains('nuvem')));
  });
}

void _seedAppState(ZeniAppState state) {
  SharedPreferences.setMockInitialValues({
    'zeni_app_state_v1': jsonEncode(state.toJson()),
  });
}

class _FakeZeniHapticsPlatform implements ZeniHapticsPlatform {
  final List<String> calls = <String>[];

  @override
  Future<void> heavyImpact() async {
    calls.add('heavyImpact');
  }

  @override
  Future<void> lightImpact() async {
    calls.add('lightImpact');
  }

  @override
  Future<void> mediumImpact() async {
    calls.add('mediumImpact');
  }

  @override
  Future<void> selectionClick() async {
    calls.add('selectionClick');
  }

  @override
  Future<void> vibrate() async {
    calls.add('vibrate');
  }
}

class _FakeZeniTtsPlatform implements ZeniTtsPlatform {
  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _RecordingZeniTtsPlatform implements ZeniTtsPlatform {
  final List<String> spokenTexts = <String>[];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {}
}

class _ChildFormHost extends StatelessWidget {
  const _ChildFormHost({required this.onResult});

  final ValueChanged<ParentChildFormResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final result = await showModalBottomSheet<ParentChildFormResult>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) {
                return const ParentChildFormSheet(
                  initialName: 'Luna',
                  initialEmoji: '🦊',
                  initialTtsEnabled: false,
                  title: 'Editar perfil',
                  submitLabel: 'Salvar perfil',
                );
              },
            );
            onResult(result);
          },
          child: const Text('Abrir formulário'),
        ),
      ),
    );
  }
}

Mission _testMission({
  String description = 'Deixe sua cama organizada para comecar bem o dia.',
  int stars = 10,
  MissionTimeGroup timeGroup = MissionTimeGroup.morning,
  MissionApprovalMode approvalMode = MissionApprovalMode.parentApproval,
}) {
  return Mission(
    id: 'mission-1',
    familyId: 'family-1',
    childId: 'child-1',
    title: 'Arrumar a cama',
    description: description,
    stars: stars,
    recurrence: MissionRecurrence.daily,
    timeGroup: timeGroup,
    approvalMode: approvalMode,
    status: MissionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

MissionLog _testMissionLog({
  MissionLogStatus status = MissionLogStatus.pending,
}) {
  return MissionLog(
    id: 'log-1',
    missionId: 'mission-1',
    childId: 'child-1',
    scheduledDate: DateTime(2026, 1, 1),
    status: status,
    starsAwarded: 0,
  );
}

Reward _testReward({int cost = 20}) {
  return Reward(
    id: 'reward-1',
    familyId: 'family-1',
    title: 'Escolher o filme',
    description: 'Voce escolhe o filme da noite.',
    cost: cost,
    renewal: RewardRenewal.once,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

RewardRequest _testRewardRequest({
  RewardRequestStatus status = RewardRequestStatus.pending,
}) {
  return RewardRequest(
    id: 'request-1',
    rewardId: 'reward-1',
    childId: 'child-1',
    status: status,
    requestedAt: DateTime(2026, 1, 1),
  );
}

ZeniAppState _stateWithMissionDescription(String description) {
  final seeded = ZeniAppState.seeded();
  final updatedMissions = [
    for (final mission in seeded.missions)
      mission.id == 'mission-1'
          ? mission.copyWith(description: description)
          : mission,
  ];

  return seeded.copyWith(missions: updatedMissions);
}
