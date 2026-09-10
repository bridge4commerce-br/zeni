import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/widgets/feedback/zeni_feedback_popup.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/smart_content/data/models/smart_mission_template.dart';
import 'package:zeni/features/smart_content/data/models/smart_routine_template.dart';
import 'package:zeni/features/smart_content/data/repositories/asset_smart_content_repository.dart';
import 'package:zeni/features/smart_content/data/repositories/smart_content_repository.dart';
import 'package:zeni/features/smart_content/presentation/pages/smart_suggestions_page.dart';

class _SmartContentTestRepository implements SmartContentRepository {
  const _SmartContentTestRepository();

  static const _mission = SmartMissionTemplate(
    id: 'test-mission',
    domain: 'self_care',
    priority: 'high',
    estimatedDuration: '5 min',
    suggestedStars: 2,
    eligibleAsExtra: false,
    requiresApprovalByDefault: false,
    support: SmartMissionSupport(
      oneStepAtATime: '',
      visual: '',
      tts: '',
      timer: '',
      transition: '',
      sensoryLoad: '',
      cognitiveLoad: '',
      canSplit: false,
    ),
    masteryPath: '',
    culturalRelevance: '',
    culturalTags: [],
    status: 'active',
    familyFit: '',
    contexts: [],
    skills: [],
    effort: 'low',
    rewardMode: '',
    adultSupport: '',
    safetyLevel: '',
    applicability: '',
    localePriority: {},
    title: 'Missão de teste',
    description: 'Uma missão para validar o feedback.',
    helpSteps: [],
  );

  @override
  Future<List<SmartMissionTemplate>> getMissions(String localeTag) =>
      SynchronousFuture(const [_mission]);

  @override
  Future<List<SmartRoutineTemplate>> getRoutines(String localeTag) =>
      SynchronousFuture(const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetSmartContentRepository', () {
    late AssetSmartContentRepository repository;

    setUp(() {
      repository = AssetSmartContentRepository();
    });

    test('carrega as 94 missões reais', () async {
      final missions = await repository.getMissions('pt-BR');

      expect(missions, hasLength(94));
      expect(missions.map((mission) => mission.id).toSet(), hasLength(94));
      expect(missions.first.id, 'brush_teeth');
      expect(missions.first.title, 'Escovar os dentes');
    });

    test('carrega as 26 rotinas reais', () async {
      final routines = await repository.getRoutines('pt-BR');

      expect(routines, hasLength(26));
      expect(routines.map((routine) => routine.id).toSet(), hasLength(26));
      expect(routines.first.id, 'after_school');
      expect(routines.first.title, 'Cheguei em casa');
    });

    test(
      'hora de dormir usa sugestão noturna, não o fallback de manhã',
      () async {
        final missions = await repository.getMissions('pt-BR');
        final bedtime = missions.singleWhere(
          (mission) => mission.id == 'bedtime_checklist',
        );

        expect(bedtime.suggestedTimeGroup?.label, 'Noite');
        expect(bedtime.suggestedRecurrence?.label, 'Todos os dias');
      },
    );

    test('resolve locale regional para idioma suportado', () async {
      final regional = await repository.getMissions('en-US');
      final base = await repository.getMissions('en');

      expect(regional, hasLength(94));
      expect(
        regional.map((mission) => mission.title).toList(),
        base.map((mission) => mission.title).toList(),
      );
    });

    test('usa inglês como fallback para locale não suportado', () async {
      final unsupported = await repository.getMissions('it-IT');
      final fallback = await repository.getMissions('en');

      expect(
        unsupported.map((mission) => mission.title).toList(),
        fallback.map((mission) => mission.title).toList(),
      );
    });

    test('mantém conteúdo correspondente em locale suportado', () async {
      final spanish = await repository.getRoutines('es-MX');
      final base = await repository.getRoutines('es');

      expect(
        spanish.map((routine) => routine.title).toList(),
        base.map((routine) => routine.title).toList(),
      );
    });

    test(
      'todas as etapas das rotinas apontam para missões existentes',
      () async {
        final missions = await repository.getMissions('pt-BR');
        final routines = await repository.getRoutines('pt-BR');

        final missionIds = missions.map((mission) => mission.id).toSet();

        for (final routine in routines) {
          for (final stepId in routine.steps) {
            expect(
              missionIds,
              contains(stepId),
              reason:
                  'A rotina ${routine.id} referencia uma missão inexistente: '
                  '$stepId',
            );
          }
        }
      },
    );
  });

  testWidgets('suggestions page resolves pt-BR without English titles', (
    tester,
  ) async {
    final child = ChildProfile(
      id: 'child-1',
      familyId: 'family-1',
      name: 'Luna',
      emoji: '⭐',
      starBalance: 0,
      streakCount: 0,
      createdAt: DateTime(2026, 9, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SmartSuggestionsPage(
          children: [child],
          activeMissions: const [],
          onConfirmBatch: (_, _) async =>
              const SmartBatchCreationResult(created: 0, skipped: 0),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sugestões para sua família'), findsWidgets);
    expect(find.text('Brush your teeth'), findsNothing);
    expect(find.text('I\'m home'), findsNothing);
  });

  testWidgets('batch mission creation shows the Zeni success feedback', (
    tester,
  ) async {
    final child = ChildProfile(
      id: 'child-1',
      familyId: 'family-1',
      name: 'Luna',
      emoji: '⭐',
      starBalance: 0,
      streakCount: 0,
      createdAt: DateTime(2026, 9, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SmartSuggestionsPage(
          children: [child],
          activeMissions: const [],
          repository: const _SmartContentTestRepository(),
          onConfirmBatch: (_, _) async =>
              const SmartBatchCreationResult(created: 1, skipped: 0),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Checkbox), findsWidgets);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    final reviewButton = find.text('Revisar 1 missões');
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final recipientsFinder = find.text('Para: Luna');
    final reviewScaffold = find.ancestor(
      of: recipientsFinder,
      matching: find.byType(Scaffold),
    );
    final appBar = tester.getRect(
      find.descendant(of: reviewScaffold, matching: find.byType(AppBar)),
    );
    final recipients = tester.getRect(recipientsFinder);
    expect(recipients.top - appBar.bottom, lessThanOrEqualTo(48));
    expect(tester.takeException(), isNull);

    final confirmButton = find.text('Adicionar 1 missões');
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pump();

    expect(find.byType(ZeniFeedbackPopup), findsOneWidget);
    expect(find.text('Missões adicionadas!'), findsOneWidget);
    expect(find.text('1 missões adicionadas.'), findsOneWidget);
  });
}
