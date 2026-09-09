import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/smart_content/data/models/smart_mission_template.dart';
import 'package:zeni/features/smart_content/data/models/smart_routine_template.dart';
import 'package:zeni/features/smart_content/data/models/smart_suggestion_history.dart';
import 'package:zeni/features/smart_content/data/repositories/smart_content_repository.dart';
import 'package:zeni/features/smart_content/domain/family_smart_preferences.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_enums.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_service.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';

void main() {
  final now = DateTime(2026, 9, 7);

  ChildProfile child({DateTime? birthDate, bool hasBirthDate = true}) {
    return ChildProfile(
      id: 'child-1',
      familyId: 'family-1',
      name: 'Criança',
      emoji: '⭐',
      birthDate: hasBirthDate ? birthDate ?? DateTime(2016, 6, 1) : null,
      starBalance: 0,
      streakCount: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  SmartMissionTemplate template({
    required String id,
    required String title,
    required String domain,
    required List<String> skills,
    List<String> contexts = const <String>['family_defined'],
    int ageMin = 6,
    int ageMax = 14,
  }) {
    return SmartMissionTemplate(
      id: id,
      domain: domain,
      priority: 'P0',
      ageMin: ageMin,
      ageMax: ageMax,
      estimatedDuration: '5 min',
      suggestedStars: 1,
      eligibleAsExtra: true,
      requiresApprovalByDefault: false,
      support: const SmartMissionSupport(
        oneStepAtATime: 'recommended',
        visual: 'optional',
        tts: 'optional',
        timer: 'neutral',
        transition: 'low',
        sensoryLoad: 'low',
        cognitiveLoad: 'short_sequence',
        canSplit: true,
      ),
      masteryPath: 'support_reminder_independent',
      culturalRelevance: 'global',
      culturalTags: const <String>[],
      status: 'approved',
      familyFit: 'autonomy_core',
      contexts: contexts,
      skills: skills,
      effort: 'low',
      rewardMode: 'optional',
      adultSupport: 'none_or_reminder',
      safetyLevel: 'routine_safe',
      applicability: 'general',
      localePriority: const <String, dynamic>{},
      title: title,
      description: 'Descrição',
      helpSteps: const <String>['Passo'],
    );
  }

  Mission activeMission(String title) {
    return Mission(
      id: 'active-1',
      familyId: 'family-1',
      childId: 'child-1',
      title: title,
      description: '',
      stars: 1,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.anytime,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('prioriza missão ligada ao objetivo escolhido', () async {
    final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
      template(
        id: 'self-care',
        title: 'Cuidar de mim',
        domain: 'self_care',
        skills: const <String>['self_care'],
      ),
      template(
        id: 'study',
        title: 'Estudar',
        domain: 'study',
        skills: const <String>['task_initiation_focus'],
      ),
    ]);

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.autonomy,
      preferences: const FamilySmartPreferences(),
      activeMissions: const <Mission>[],
      history: const <SmartSuggestionHistory>[],
      now: now,
    );

    expect(result.first.contentId, 'self-care');
  });

  test('dá preferência ao contexto escolhido', () async {
    final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
      template(
        id: 'after-school',
        title: 'Guardar mochila',
        domain: 'belongings',
        skills: const <String>['organization'],
        contexts: const <String>['after_school'],
      ),
      template(
        id: 'planning',
        title: 'Planejar',
        domain: 'belongings',
        skills: const <String>['organization'],
        contexts: const <String>['planning'],
      ),
    ]);

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.organization,
      context: SmartSuggestionContext.afterSchool,
      preferences: const FamilySmartPreferences(),
      activeMissions: const <Mission>[],
      history: const <SmartSuggestionHistory>[],
      now: now,
    );

    expect(result.first.contentId, 'after-school');
  });

  test('remove domínio desabilitado pela família', () async {
    final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
      template(
        id: 'study',
        title: 'Estudar',
        domain: 'study',
        skills: const <String>['task_initiation_focus'],
      ),
    ]);

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.study,
      preferences: const FamilySmartPreferences(
        enabledDomains: <String>{'self_care'},
      ),
      activeMissions: const <Mission>[],
      history: const <SmartSuggestionHistory>[],
      now: now,
    );

    expect(result, isEmpty);
  });

  test(
    'mantém todas as missões quando a data de nascimento é ausente',
    () async {
      final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
        template(
          id: 'older',
          title: 'Missão para mais velhos',
          domain: 'life_skills',
          skills: const <String>['independence'],
          ageMin: 13,
          ageMax: 14,
        ),
        template(
          id: 'younger',
          title: 'Missão para mais novos',
          domain: 'life_skills',
          skills: const <String>['independence'],
          ageMin: 5,
          ageMax: 7,
        ),
      ]);

      final service = SmartSuggestionService(repository);

      final result = await service.suggest(
        child: child(hasBirthDate: false),
        goal: SmartSuggestionGoal.lifeSkills,
        preferences: const FamilySmartPreferences(),
        activeMissions: const <Mission>[],
        history: const <SmartSuggestionHistory>[],
        now: now,
      );

      expect(
        result.map((suggestion) => suggestion.contentId),
        containsAll(<String>['older', 'younger']),
      );
      expect(result.map((suggestion) => suggestion.score).toSet(), <int>{60});
    },
  );

  test(
    'usa faixa compatível como bônus de relevância sem bloquear catálogo',
    () async {
      final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
        template(
          id: 'inside-range',
          title: 'Missão adequada',
          domain: 'life_skills',
          skills: const <String>['independence'],
          ageMin: 9,
          ageMax: 11,
        ),
        template(
          id: 'outside-range',
          title: 'Missão fora da faixa',
          domain: 'life_skills',
          skills: const <String>['independence'],
          ageMin: 13,
          ageMax: 14,
        ),
      ]);

      final service = SmartSuggestionService(repository);

      final result = await service.suggest(
        child: child(),
        goal: SmartSuggestionGoal.lifeSkills,
        preferences: const FamilySmartPreferences(),
        activeMissions: const <Mission>[],
        history: const <SmartSuggestionHistory>[],
        now: now,
      );

      expect(
        result.map((suggestion) => suggestion.contentId),
        containsAll(<String>['inside-range', 'outside-range']),
      );
      expect(result.first.contentId, 'inside-range');
      expect(result.first.score, 70);
      expect(
        result
            .singleWhere(
              (suggestion) => suggestion.contentId == 'outside-range',
            )
            .score,
        60,
      );
    },
  );

  test('não sugere equivalente já ativo para a criança', () async {
    final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
      template(
        id: 'brush-teeth',
        title: 'Escovar os dentes',
        domain: 'self_care',
        skills: const <String>['self_care'],
      ),
    ]);

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.autonomy,
      preferences: const FamilySmartPreferences(),
      activeMissions: <Mission>[activeMission('Escovar os dentes')],
      history: const <SmartSuggestionHistory>[],
      now: now,
    );

    expect(result, isEmpty);
  });

  test('penaliza conteúdo rejeitado recentemente', () async {
    final repository = _FakeSmartContentRepository(<SmartMissionTemplate>[
      template(
        id: 'rejected',
        title: 'Missão rejeitada',
        domain: 'self_care',
        skills: const <String>['self_care'],
      ),
      template(
        id: 'fresh',
        title: 'Missão nova',
        domain: 'self_care',
        skills: const <String>['self_care'],
      ),
    ]);

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.autonomy,
      preferences: const FamilySmartPreferences(),
      activeMissions: const <Mission>[],
      history: <SmartSuggestionHistory>[
        SmartSuggestionHistory(
          childId: 'child-1',
          contentId: 'rejected',
          type: SmartSuggestionContentType.mission,
          action: SmartSuggestionAction.rejected,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      now: now,
    );

    expect(result.first.contentId, 'fresh');
  });

  test('nunca retorna mais de cinco sugestões', () async {
    final repository = _FakeSmartContentRepository(
      List<SmartMissionTemplate>.generate(
        8,
        (index) => template(
          id: 'mission-$index',
          title: 'Missão $index',
          domain: 'self_care',
          skills: const <String>['self_care'],
        ),
      ),
    );

    final service = SmartSuggestionService(repository);

    final result = await service.suggest(
      child: child(),
      goal: SmartSuggestionGoal.autonomy,
      preferences: const FamilySmartPreferences(),
      activeMissions: const <Mission>[],
      history: const <SmartSuggestionHistory>[],
      now: now,
      limit: 8,
    );

    expect(result, hasLength(5));
  });
}

class _FakeSmartContentRepository implements SmartContentRepository {
  const _FakeSmartContentRepository(this.missions);

  final List<SmartMissionTemplate> missions;

  @override
  Future<List<SmartMissionTemplate>> getMissions(String localeTag) async {
    return missions;
  }

  @override
  Future<List<SmartRoutineTemplate>> getRoutines(String localeTag) async {
    return const <SmartRoutineTemplate>[];
  }
}
