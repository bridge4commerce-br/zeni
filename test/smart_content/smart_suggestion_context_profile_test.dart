import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/smart_content/data/repositories/asset_smart_content_repository.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_context_profile.dart';
import 'package:zeni/features/smart_content/domain/smart_suggestion_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('todos os contextos mapeados existem no conteúdo real', () async {
    final repository = AssetSmartContentRepository();
    final missions = await repository.getMissions('pt-BR');

    final availableContexts = missions
        .expand((mission) => mission.contexts)
        .toSet();

    for (final context in SmartSuggestionContext.values) {
      for (final tag in context.contentTags) {
        expect(
          availableContexts,
          contains(tag),
          reason:
              'O contexto ${context.name} referencia uma tag inexistente: $tag',
        );
      }
    }
  });

  test('none não força nenhum contexto', () {
    expect(SmartSuggestionContext.none.contentTags, isEmpty);
  });

  test('contextos principais possuem tags', () {
    for (final context in SmartSuggestionContext.values) {
      if (context == SmartSuggestionContext.none) {
        continue;
      }

      expect(
        context.contentTags,
        isNotEmpty,
        reason: '${context.name} deveria possuir ao menos uma tag.',
      );
    }
  });
}
