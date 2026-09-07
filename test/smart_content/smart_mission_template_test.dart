import 'package:flutter_test/flutter_test.dart';
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
