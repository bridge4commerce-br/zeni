import 'package:flutter_test/flutter_test.dart';
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

    test('valida faixa etária', () {
      final routine = SmartRoutineTemplate.fromJson(
        globalJson: globalJson,
        localizedJson: localizedJson,
      );

      expect(routine.supportsAge(5), isTrue);
      expect(routine.supportsAge(10), isTrue);
      expect(routine.supportsAge(14), isTrue);
      expect(routine.supportsAge(4), isFalse);
      expect(routine.supportsAge(15), isFalse);
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
