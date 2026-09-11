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
import 'package:zeni/features/tts/domain/zeni_speech_text_builders.dart';
import 'package:zeni/features/tts/domain/zeni_tts_voice_selector.dart';
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

    final completeMission = find.text('Concluir missão');
    await tester.ensureVisible(completeMission);
    await tester.tap(completeMission);
    await tester.pumpAndSettle();

    expect(platform.calls, contains('heavyImpact'));
  });

  testWidgets('listen actions are available by default in child mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    _seedAppState(
      ZeniAppState.seeded().copyWith(appSettings: const AppSettings()),
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

    expect(find.text('Ouvir missão'), findsOneWidget);
    expect(find.text('Ouvir resumo'), findsNothing);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

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

  testWidgets('legacy child TTS preferences do not hide listen actions', (
    tester,
  ) async {
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

    expect(find.text('Ouvir missão'), findsOneWidget);
    expect(find.text('Ouvir resumo'), findsNothing);
  });

  testWidgets('tapping Ouvir missao starts speech and keeps the sheet open', (
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

    await tester.tap(find.text('Ouvir missão'));
    await tester.pump();

    expect(find.text('Detalhes da missão'), findsOneWidget);
    expect(ttsPlatform.spokenTexts, isNotEmpty);
    expect(
      ttsPlatform.spokenTexts.last,
      contains('Your mission is Arrumar a cama. Deixe sua cama organizada.'),
    );
  });

  testWidgets(
    'tapping Ouvir missão keeps the detail open and avoids technical text',
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

      await tester.tap(find.text('Ouvir missão'));
      await tester.pump();

      expect(find.text('Detalhes da missão'), findsOneWidget);
      expect(ttsPlatform.spokenTexts, isNotEmpty);
      final speech = ttsPlatform.spokenTexts.last.toLowerCase();
      expect(speech, contains('your mission is arrumar a cama'));
      expect(speech, contains('you still need to finish this mission'));
      expect(speech, contains('when you finish, you can earn 10 stars'));
      expect(speech, contains('you can do this mission in the morning'));
      expect(speech, contains('wait for your grown-up to approve it'));
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

  test(
    'tts service keeps speech available despite legacy child preferences',
    () async {
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

      expect(service.isEnabledForChild(child), isTrue);
    },
  );

  test(
    'tts prefers a Brazilian Portuguese voice and central speech settings',
    () async {
      final platform = _RecordingZeniTtsPlatform(
        languages: const ['en-US', 'pt-BR'],
        voices: const [
          ZeniTtsVoice(name: 'Portuguese default', locale: 'pt-BR', quality: 1),
          ZeniTtsVoice(name: 'Portuguese Natural', locale: 'pt-BR', quality: 2),
        ],
      );
      final service = ZeniTtsService(
        settings: const AppSettings(),
        platform: platform,
      );

      final result = await service.speakTextForChild(
        child: ZeniAppState.seeded().children.first,
        text: 'Sua missão é ler um livro.',
        locale: 'pt-BR',
      );

      expect(result.didSpeak, isTrue);
      expect(platform.languagesSet, ['pt-BR']);
      expect(platform.voicesSet.single.name, 'Portuguese Natural');
      expect(platform.speechRates, [ZeniTtsSpeechConfiguration.speechRate]);
      expect(platform.pitches, [ZeniTtsSpeechConfiguration.pitch]);
      expect(platform.volumes, [ZeniTtsSpeechConfiguration.volume]);
    },
  );

  test(
    'tts keeps only the latest request when the child taps listen twice',
    () async {
      final platform = _RecordingZeniTtsPlatform();
      final service = ZeniTtsService(
        settings: const AppSettings(),
        platform: platform,
      );
      final child = ZeniAppState.seeded().children.first;

      await Future.wait([
        service.speakTextForChild(
          child: child,
          text: 'Primeira missão.',
          locale: 'pt-BR',
        ),
        service.speakTextForChild(
          child: child,
          text: 'Segunda missão.',
          locale: 'pt-BR',
        ),
      ]);

      expect(platform.spokenTexts, ['Segunda missão.']);
      expect(platform.stopCalls, greaterThanOrEqualTo(2));
    },
  );

  test(
    'mission short speech avoids technical terms and uses only friendly text',
    () {
      final speech = ZeniMissionSpeechTextBuilder.buildMissionShortSpeech(
        mission: _testMission(
          description: 'Deixe sua cama organizada para comecar bem o dia.',
        ),
        locale: 'pt-BR',
      ).toLowerCase();

      expect(speech, contains('sua missão é arrumar a cama'));
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

  test('automatic mission speech is short and natural', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: _testMission(
        description: 'Deixe sua cama organizada para começar bem o dia.',
        stars: 2,
        timeGroup: MissionTimeGroup.anytime,
        approvalMode: MissionApprovalMode.automatic,
      ),
      locale: 'pt-BR',
    ).toLowerCase();

    expect(speech, contains('sua missão é arrumar a cama'));
    expect(speech, contains('deixe sua cama organizada'));
    expect(speech, contains('quando terminar, você ganha 2 estrelas'));
    expect(speech, isNot(contains('qualquer horário')));
    expect(speech, isNot(contains('aprovação do responsável')));
  });

  test('approval mission speech explains the next step naturally', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: _testMission(
        stars: 10,
        timeGroup: MissionTimeGroup.morning,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
      locale: 'pt-BR',
    ).toLowerCase();

    expect(speech, contains('quando terminar, você pode ganhar 10 estrelas'));
    expect(speech, contains('você pode fazer essa missão de manhã'));
    expect(speech, contains('depois, é só esperar a aprovação do responsável'));
    expect(speech, isNot(contains('requer aprovação')));
  });

  test('mission speech omits an absent description without broken pauses', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: _testMission(
        description: '',
        stars: 1,
        timeGroup: MissionTimeGroup.anytime,
        approvalMode: MissionApprovalMode.automatic,
      ),
      locale: 'pt-BR',
    );

    expect(speech, contains('Quando terminar, você ganha 1 estrela.'));
    expect(speech, isNot(contains('..')));
  });

  test('mission speech keeps long content singular and free of UI labels', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: _testMission(
        description:
            'Organize os livros e os brinquedos com calma antes de escolher outra brincadeira.',
        stars: 8,
        approvalMode: MissionApprovalMode.automatic,
      ),
      locale: 'pt-BR',
    ).toLowerCase();

    expect('sua missão é arrumar a cama'.allMatches(speech).length, 1);
    expect('organize os livros'.allMatches(speech).length, 1);
    expect(speech, contains('8 estrelas'));
    expect(speech, isNot(contains('ouvir missão')));
    expect(speech, isNot(contains('concluir missão')));
    expect(speech, isNot(contains('emoji')));
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
      mission: _testMission(description: 'Restaurada da nuvem'),
      locale: 'pt-BR',
    ).toLowerCase();

    expect(speech, 'sua missão é arrumar a cama.');
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
  ZeniTtsPlatformKind get platformKind => ZeniTtsPlatformKind.other;

  @override
  Future<List<String>> getLanguages() async => const [];

  @override
  Future<List<ZeniTtsVoice>> getVoices() async => const [];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setVoice(ZeniTtsVoice voice) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _RecordingZeniTtsPlatform implements ZeniTtsPlatform {
  _RecordingZeniTtsPlatform({
    this.languages = const ['pt-BR'],
    this.voices = const [],
  });

  final List<String> languages;
  final List<ZeniTtsVoice> voices;
  final List<String> spokenTexts = <String>[];
  final List<String> languagesSet = <String>[];
  final List<ZeniTtsVoice> voicesSet = <ZeniTtsVoice>[];
  final List<double> speechRates = <double>[];
  final List<double> pitches = <double>[];
  final List<double> volumes = <double>[];
  int stopCalls = 0;

  @override
  ZeniTtsPlatformKind get platformKind => ZeniTtsPlatformKind.apple;

  @override
  Future<List<String>> getLanguages() async => languages;

  @override
  Future<List<ZeniTtsVoice>> getVoices() async => voices;

  @override
  Future<void> setLanguage(String language) async {
    languagesSet.add(language);
  }

  @override
  Future<void> setPitch(double pitch) async {
    pitches.add(pitch);
  }

  @override
  Future<void> setVoice(ZeniTtsVoice voice) async {
    voicesSet.add(voice);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    speechRates.add(rate);
  }

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
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
