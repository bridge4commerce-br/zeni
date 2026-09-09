import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/smart_content/data/models/smart_mission_template.dart';

void main() {
  group('SmartMissionTemplate', () {
    final globalJson = <String, dynamic>{
      'id': 'brush_teeth',
      'domain': 'self_care',
      'priority': 'P0',
      'ageMin': 6,
      'ageMax': 14,
      'estimatedDuration': '2–10 min',
      'suggestedStars': 0,
      'eligibleAsExtra': false,
      'requiresApprovalByDefault': false,
      'support': <String, dynamic>{
        'oneStepAtATime': 'recommended',
        'visual': 'optional',
        'tts': 'recommended',
        'timer': 'neutral',
        'transition': 'low',
        'sensoryLoad': 'variable',
        'cognitiveLoad': 'short_sequence',
        'canSplit': true,
      },
      'masteryPath': 'support_reminder_independent',
      'culturalRelevance': 'global',
      'culturalTags': <String>['family_defined', 'self_care'],
      'status': 'approved',
      'familyFit': 'autonomy_core',
      'contexts': <String>['family_defined'],
      'skills': <String>['self_care', 'sequence_working_memory'],
      'effort': 'low',
      'rewardMode': 'optional',
      'adultSupport': 'none_or_reminder',
      'safetyLevel': 'routine_safe',
      'applicability': 'general',
      'localePriority': <String, dynamic>{},
    };

    final localizedJson = <String, dynamic>{
      'id': 'brush_teeth',
      'title': 'Escovar os dentes',
      'description': 'Cuide do seu sorriso.',
      'helpSteps': <String>[
        'Coloque um pouco de creme dental na escova.',
        'Escove todos os lados dos dentes.',
        'Enxágue e guarde a escova.',
      ],
    };

    test('combina conteúdo global e localizado', () {
      final mission = SmartMissionTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(mission.id, 'brush_teeth');
      expect(mission.title, 'Escovar os dentes');
      expect(mission.domain, 'self_care');
      expect(mission.suggestedStars, 0);
      expect(mission.support.tts, 'recommended');
      expect(mission.helpSteps, hasLength(3));
    });

    test('valida faixa etária', () {
      final mission = SmartMissionTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(mission.supportsAge(6), isTrue);
      expect(mission.supportsAge(10), isTrue);
      expect(mission.supportsAge(14), isTrue);
      expect(mission.supportsAge(5), isFalse);
      expect(mission.supportsAge(15), isFalse);
    });

    test('lê sugestões globais opcionais de turno e recorrência', () {
      final mission = SmartMissionTemplate.fromJson(
        globalJson: <String, dynamic>{
          ...globalJson,
          'suggestedTimeGroup': 'evening',
          'suggestedRecurrence': 'daily',
        },
        localizedJson: localizedJson,
      );

      expect(mission.suggestedTimeGroup, MissionTimeGroup.evening);
      expect(mission.suggestedRecurrence, MissionRecurrence.daily);
    });

    test('aceita missão sem sugestões operacionais', () {
      final mission = SmartMissionTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(mission.suggestedTimeGroup, isNull);
      expect(mission.suggestedRecurrence, isNull);
    });

    test('aceita limite inferior ou superior isoladamente', () {
      final onlyMin = SmartMissionTemplate.fromJson(
        globalJson: <String, dynamic>{...globalJson, 'ageMax': null},
        localizedJson: localizedJson,
      );
      final onlyMax = SmartMissionTemplate.fromJson(
        globalJson: <String, dynamic>{...globalJson, 'ageMin': null},
        localizedJson: localizedJson,
      );

      expect(onlyMin.isSuitableForAge(5), isFalse);
      expect(onlyMin.isSuitableForAge(99), isTrue);
      expect(onlyMax.isSuitableForAge(0), isTrue);
      expect(onlyMax.isSuitableForAge(15), isFalse);
    });

    test('considera conteúdo sem faixa adequado para qualquer idade', () {
      final mission = SmartMissionTemplate.fromJson(
        globalJson: <String, dynamic>{
          ...globalJson,
          'ageMin': null,
          'ageMax': null,
        },
        localizedJson: localizedJson,
      );

      expect(mission.ageMin, isNull);
      expect(mission.ageMax, isNull);
      expect(mission.isSuitableForAge(0), isTrue);
      expect(mission.isSuitableForAge(99), isTrue);
    });

    test('rejeita faixa inválida', () {
      expect(
        () => SmartMissionTemplate.fromJson(
          globalJson: <String, dynamic>{...globalJson, 'ageMin': -1},
          localizedJson: localizedJson,
        ),
        throwsFormatException,
      );
      expect(
        () => SmartMissionTemplate.fromJson(
          globalJson: <String, dynamic>{
            ...globalJson,
            'ageMin': 10,
            'ageMax': 9,
          },
          localizedJson: localizedJson,
        ),
        throwsFormatException,
      );
      expect(
        () => SmartMissionTemplate.fromJson(
          globalJson: <String, dynamic>{...globalJson, 'ageMax': '14'},
          localizedJson: localizedJson,
        ),
        throwsFormatException,
      );
    });

    test('rejeita localização com id diferente', () {
      final wrongLocalizedJson = <String, dynamic>{
        ...localizedJson,
        'id': 'make_bed',
      };

      expect(
        () => SmartMissionTemplate.fromJson(
          globalJson: globalJson,
          localizedJson: wrongLocalizedJson,
        ),
        throwsFormatException,
      );
    });
  });
}
