import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/smart_content/data/repositories/asset_smart_content_repository.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_enums.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_goal_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartSuggestionGoalProfile', () {
    late AssetSmartContentRepository repository;

    setUp(() {
      repository = AssetSmartContentRepository();
    });

    test('todos os domínios preferidos existem no conteúdo real', () async {
      final missions = await repository.getMissions('pt-BR');

      final availableDomains = missions
          .map((mission) => mission.domain)
          .toSet();

      for (final goal in SmartSuggestionGoal.values) {
        for (final domain in goal.profile.preferredDomains) {
          expect(
            availableDomains,
            contains(domain),
            reason:
                'O objetivo ${goal.name} referencia um domínio inexistente: '
                '$domain',
          );
        }
      }
    });

    test('todas as habilidades-alvo existem no conteúdo real', () async {
      final missions = await repository.getMissions('pt-BR');

      final availableSkills = missions
          .expand((mission) => mission.skills)
          .toSet();

      for (final goal in SmartSuggestionGoal.values) {
        for (final skill in goal.profile.targetSkills) {
          expect(
            availableSkills,
            contains(skill),
            reason:
                'O objetivo ${goal.name} referencia uma skill inexistente: '
                '$skill',
          );
        }
      }
    });

    test('cada objetivo possui ao menos um domínio e uma habilidade', () {
      for (final goal in SmartSuggestionGoal.values) {
        expect(
          goal.profile.preferredDomains,
          isNotEmpty,
          reason: 'O objetivo ${goal.name} não possui domínio preferido.',
        );

        expect(
          goal.profile.targetSkills,
          isNotEmpty,
          reason: 'O objetivo ${goal.name} não possui habilidade-alvo.',
        );
      }
    });
  });
}
