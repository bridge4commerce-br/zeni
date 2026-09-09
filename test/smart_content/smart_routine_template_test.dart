import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/smart_content/data/models/smart_mission_template.dart';
import 'package:zeni/features/smart_content/data/models/smart_routine_template.dart';

void main() {
  group('SmartRoutineTemplate', () {
    final globalJson = <String, dynamic>{
      'id': 'after_school',
      'tier': 'primary',
      'ageMin': 5,
      'ageMax': 14,
      'steps': <String>[
        'put_backpack_away_on_arrival',
        'organize_shoes',
        'wash_hands_on_arrival',
      ],
      'defaultPresentationSource': 'Uma etapa por vez',
      'orderEditable': true,
      'rewardModeSource': 'Sem estrelas ou por rotina',
      'autonomyValueSource': 'Alta',
      'transitionSupportSource': 'Alta',
      'priority': 'P0',
      'culturalRelevance': 'global',
      'status': 'approved',
    };

    final localizedJson = <String, dynamic>{
      'id': 'after_school',
      'title': 'Cheguei em casa',
      'description':
          'Uma rotina passo a passo para guardar as coisas da escola.',
    };

    test('combina conteúdo global e localizado', () {
      final routine = SmartRoutineTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(routine.id, 'after_school');
      expect(routine.title, 'Cheguei em casa');
      expect(routine.tier, 'primary');
      expect(routine.orderEditable, isTrue);
      expect(routine.steps, hasLength(3));
    });

    test('preserva a ordem das etapas', () {
      final routine = SmartRoutineTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(routine.steps, <String>[
        'put_backpack_away_on_arrival',
        'organize_shoes',
        'wash_hands_on_arrival',
      ]);
    });

    test('deriva adequação etária de todas as missões', () {
      final routine = SmartRoutineTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );
      final missions = <SmartMissionTemplate>[
        _mission('put_backpack_away_on_arrival', ageMin: 5, ageMax: 14),
        _mission('organize_shoes', ageMin: 6, ageMax: 14),
        _mission('wash_hands_on_arrival', ageMin: 5, ageMax: 14),
      ];

      expect(routine.isSuitableForAge(6, missions), isTrue);
      expect(routine.isSuitableForAge(5, missions), isFalse);
      expect(routine.isSuitableForAge(15, missions), isFalse);
    });

    test('considera rotina inadequada quando uma missão não existe', () {
      final routine = SmartRoutineTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );
      final missions = <SmartMissionTemplate>[
        _mission('put_backpack_away_on_arrival', ageMin: 5, ageMax: 14),
      ];

      expect(routine.isSuitableForAge(10, missions), isFalse);
    });

    test('rejeita localização com id diferente', () {
      final wrongLocalizedJson = <String, dynamic>{
        ...localizedJson,
        'id': 'bedtime',
      };

      expect(
        () => SmartRoutineTemplate.fromJson(
          globalJson: globalJson,
          localizedJson: wrongLocalizedJson,
        ),
        throwsFormatException,
      );
    });
  });
}

SmartMissionTemplate _mission(
  String id, {
  required int? ageMin,
  required int? ageMax,
}) {
  return SmartMissionTemplate(
    id: id,
    domain: 'self_care',
    priority: 'P0',
    ageMin: ageMin,
    ageMax: ageMax,
    estimatedDuration: '5 min',
    suggestedStars: 1,
    eligibleAsExtra: false,
    requiresApprovalByDefault: false,
    support: const SmartMissionSupport(
      oneStepAtATime: 'recommended',
      visual: 'optional',
      tts: 'optional',
      timer: 'neutral',
      transition: 'low',
      sensoryLoad: 'low',
      cognitiveLoad: 'low',
      canSplit: true,
    ),
    masteryPath: 'support',
    culturalRelevance: 'global',
    culturalTags: const <String>[],
    status: 'approved',
    familyFit: 'general',
    contexts: const <String>[],
    skills: const <String>[],
    effort: 'low',
    rewardMode: 'optional',
    adultSupport: 'none',
    safetyLevel: 'safe',
    applicability: 'general',
    localePriority: const <String, dynamic>{},
    title: id,
    description: '',
    helpSteps: const <String>[],
  );
}
